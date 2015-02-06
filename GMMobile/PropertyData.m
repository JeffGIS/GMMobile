//  PropertyData.m
//  GMMobile

#import "PropertyData.h"

@interface PropertyData ()

@property (nonatomic) GSSiPopoverView *popover;

@end

@implementation PropertyData

static PropertyData *_propData;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.localFilePath;
        _fileName = @"Property.sqlite";
        _path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _fileName];
        _propData = (__bridge PropertyData *)((__bridge sqlite3 *)((PropertyData *)self));
    }
    
    return self;
}

- (void)dealloc
{
    CloseTRANS2 (&_pTranLLtoView);
    CloseTRANS2 (&_pTranViewtoLL);
    sqlite3_close(_database);
    NSLog(@"Property Database dealloc");
}

- (BOOL)load
{
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = self;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = NO;
    
    [_popover showAfter:0.5
              withTitle:@"Get Property File"];
    
    [pull getFile:_fileName
    fromDirectory:@"GMMobile"
           toFile:_fileName
      toDirectory:_documentsDirectory
     forceRefresh:YES];
    
    return YES;
}

- (void)clear
{
    [self close];
    
    BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
                                                       error:nil];
}

- (void)FTPdidComplete:(int)option
            withStatus:(int)status
              filePath:(NSString *)path
{
    [_popover hide];
    
    if (status == FTPStatusOK)
    {
        
    }
}

- (LLPOINT)getPointForPID:(NSString *)PID
{
    LLPOINT pt = {0};
    
    [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT LAT,LON FROM PARCELPOINT Where PID = '%@'", PID];
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "getPointForPID");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        pt.lat = sqlite3_column_double(statement, 0);
        pt.lon = sqlite3_column_double(statement, 1);
    }
    
    SQLOK(sqlite3_finalize(statement), "getPointforPID");
    
    [self close];
    return pt;
}

- (NSMutableArray *)getPIDsMatchingString:(NSString *)matchChar
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PID FROM PROPINFO Where PID LIKE '%@%%'",
                       matchChar];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "preparegetPIDsMatchingString");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 0);
        NSString *pid = [NSString stringWithFormat:@"%s", cpid];
        [array addObject:pid];
    }
    
    SQLOK(sqlite3_finalize(statement), "getPIDsMatchingString");
    
    [self close];
    return array;
}

- (NSMutableArray *)getPIDsWithOwnerMatchingString:(NSString *)matchChar
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PID,\"Owner Name\" FROM PROPINFO Where PID LIKE '%@%%'",
                       matchChar];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0),"preparegetPIDsMatchingString");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 0);
        LPSTR owner = (LPSTR)sqlite3_column_text(statement, 1);
        NSString *pid = [NSString stringWithFormat:@"%s\t%s", cpid, owner];
        [array addObject:pid];
    }
    
    SQLOK(sqlite3_finalize(statement), "getPIDsMatchingString");
    
    [self close];
    return array;
}

- (NSMutableArray *)getPIDsMatchingAddress:(int)houseNumber
                                streetName:(NSString *)matchChar
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT HOUSE_NUM,STREET_NAME,UDIValue,AdditionalValue FROM ADDLOC4 Where STREET_NAME LIKE '%@%%' AND HOUSE_NUM = %i",matchChar,houseNumber];
    //NSString *query = [NSString stringWithFormat:@"SELECT HOUSENUM,STREET,PID_TEXT,\"Owner Name\" FROM PROPINFO Where STREET LIKE '%@%%' AND HOUSENUM = %i", matchChar,houseNumber];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0), "preparegetPIDsMatchingAddress");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int house = sqlite3_column_int(statement, 0);
        LPSTR street = (LPSTR)sqlite3_column_text(statement, 1);
        LPSTR pid = (LPSTR)sqlite3_column_text(statement, 2);
        LPSTR additionalVal = (LPSTR)sqlite3_column_text(statement, 3);
        
        NSString *output = [NSString stringWithFormat:@"%i\t%s\t%s\t%s",
                         house, street, pid, additionalVal];
        
        [array addObject:output];
    }
    
    SQLOK(sqlite3_finalize(statement), "getPIDsMatchingAddress");
    
    [self close];
    return array;
}

- (NSString *)pickPID:(LLPOINT)pt
{
    NSString *minPID = [[NSString alloc] init];
    dbounds bnds;
    CGFloat d, mind = DBL_MAX;
    CGFloat pickap = 0.001;
    DPOINT p1, p2;
    
    p1.x = pt.lon;
    p1.y = pt.lat;
    bnds.xmn = p1.x - pickap;
    bnds.xmx = p1.x + pickap;
    bnds.ymn = p1.y - pickap;
    bnds.ymx = p1.y + pickap;
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PID,LAT,LON FROM PARCELPOINT Where LAT > %f AND LAT < %f AND LON > %f AND LON < %f",
                       bnds.ymn, bnds.ymx, bnds.xmn, bnds.xmx];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "pickPID");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 0);
        CGFloat lat = sqlite3_column_double(statement, 1);
        CGFloat lon = sqlite3_column_double(statement, 2);
        p2.x = lon;
        p2.y = lat;
        d = ArcDistance(p1, p2);
        
        if (d < mind)
        {
            mind = d;
            minPID = [NSString stringWithUTF8String:cpid];
        }
    }
    
    SQLOK(sqlite3_finalize(statement), "pickPID");
    [self close];
    return minPID;
}

- (NSString *)getOwnerNameForPID:(NSString *)PID
{
    NSString *ownerName = @"";
    
    [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT \"Owner Name\" FROM PROPINFO Where PID = '%@'", PID];
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "getOwnerNameForPID");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR owner = (LPSTR)sqlite3_column_text(statement, 0);
        ownerName = [NSString stringWithUTF8String:owner];
    }
    
    SQLOK(sqlite3_finalize(statement), "getOwnerNameForPID");
    [self close];
    return ownerName;
}

- (void)open
{
    if (!_isOpen)
    {
        self.isOpen = !SQLOK(sqlite3_open(self.path.UTF8String, &_database), "open(Property)");
        NSLog(@"Property Database open");
    }
}

- (void)close
{
    sqlite3_close(_database);
    NSLog(@"Property Database close");
    self.isOpen = NO;
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOK(sqlite3_exec(_database, cmd, 0, 0, 0), "Execute cmd");
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOK(sqlite3_exec(_database, "BEGIN", 0, 0, 0), "Start transaction");
}

- (void)commitTransaction
{
    SQLOK(sqlite3_exec(_database, "COMMIT", 0, 0, 0), "End transaction");
}

/*
- (void)logError:(int)sqlReturn
          method:(char *)method
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i in %s = %i:%s",
                  sqlReturn, method, sqlite3_errcode(_database), sqlite3_errmsg(_database)]);
}

int SQLOK(int sqlReturn, char *method)
{
    if (sqlReturn != SQLITE_OK)
    {
        NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i in %s = %i:%s",
                      sqlReturn, method, sqlite3_errcode((__bridge sqlite3 *)(_database)),
                      sqlite3_errmsg((__bridge sqlite3 *)(_database))]);
    }
    
    return sqlReturn;
}
*/

- (void)logError:(int)sqlReturn
          method:(char *)method
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i in %s = %i:%s",
                  sqlReturn, method, sqlite3_errcode(_database), sqlite3_errmsg(_database)]);
}

int SQLOK(int sqlReturn, char *method)
{
    if (sqlReturn != SQLITE_OK)
    {
        [_propData logError:sqlReturn
                     method:method];
    }
    
    return sqlReturn;
}

- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    [_popover hide];
}

- (BOOL)loadParcelPolygons:(NSString *)fromPath
{
    BOOL rtn = NO;
    
    [self open];
    
    NSString *cmd = @"CREATE VIRTUAL TABLE demo_index USING rtree(id,minX,maxX,minY,maxY);";
    
    [self executeCmd:(char *)cmd.UTF8String];
    [self close];
    return rtn;
}

- (void)fillParcel:(CGContextRef)context
           nPoints:(int)np
            points:(LPDPOINT)pPoints
         withColor:(CGColorRef)color
{
    CGContextSetLineWidth(context, 3);
    //CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
    
    
    CGContextMoveToPoint(context, pPoints[0].x, pPoints[0].y);
    
    for (int i = 1; i < np; i++)
        CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
    
    CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
    
    if (!CGContextIsPathEmpty(context))
    {
        //CGContextSetStrokeColorWithColor(context,color);
        CGContextSetFillColorWithColor(context,color);
        CGContextDrawPath(context, kCGPathFill);
    }
}

- (void)drawParcel:(CGContextRef)context
           nPoints:(int)np
            nLoops:(int)nLoops
           partLen:(int *)pPartLen
            points:(LPDPOINT)pPoints
         withColor:(CGColorRef)color
{
    CGContextSetLineWidth(context, 1);
    //CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
    
    if (nLoops > 1)
    {
        int ip=0;
        int ii;
        
        for (int loop=0; loop < nLoops; loop++)
        {
            CGContextMoveToPoint(context, pPoints[ip].x, pPoints[ip].y);
            ip++;
            ii = pPartLen[loop];
            
            for (int i = 1; i < pPartLen[loop]; i++)
            {
                CGContextAddLineToPoint(context, pPoints[ip].x, pPoints[ip].y);
                ip++;
            }
            
            if (loop)
                ip++;
            
            if (!CGContextIsPathEmpty(context))
            {
                CGContextSetStrokeColorWithColor(context,color);
                CGContextDrawPath(context, kCGPathStroke);
            }
        }
        
        ii = ip;
    }
    
    else
    {
        CGContextMoveToPoint(context, pPoints[0].x, pPoints[0].y);
        
        for (int i = 1; i < np; i++)
            CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
        
        CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
        
        if (!CGContextIsPathEmpty(context))
        {
            CGContextSetStrokeColorWithColor(context,color);
            CGContextDrawPath(context, kCGPathStroke);
        }
    }
}


-(void) displayParcels:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
{
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANBoundsToBounds(platlonBounds, pvbounds);
    
    sqlite3_stmt *statement;
    LPSTR pid;
    DPOINT BasePt;
    int numPoints,numLoops, refno;
    LPSTR homeStead,useCode,useDesc,taxExempt;
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PROPINFO.PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USECODE,USE_DESC,TAX_EXEMPT,HOMESTEAD,TOTAL_VALUE FROM PARCELPOLY,PARCELPOLY_index, PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PID=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "displayParcels");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        refno = sqlite3_column_int(statement,7);
        homeStead = (LPSTR)sqlite3_column_text(statement, 8);
        useCode = (LPSTR)sqlite3_column_text(statement, 9);
        useDesc = (LPSTR)sqlite3_column_text(statement, 10);
        taxExempt = (LPSTR)sqlite3_column_text(statement, 11);
        pid = (LPSTR)sqlite3_column_text(statement, 0);
        BasePt.x = sqlite3_column_double(statement,1);
        BasePt.y = sqlite3_column_double(statement,2);
        numPoints = sqlite3_column_int(statement,3);
        numLoops = sqlite3_column_int(statement,4);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,5);
        int nBlobBytes = sqlite3_column_bytes(statement,5);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,6);
        nBlobBytes = sqlite3_column_bytes(statement,6);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / 100000000.0);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / 100000000.0);
                llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / 100000000.0);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / 100000000.0);
            llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
        }
        
        if (CRAPI.sharedInstance.parcelShadingOption)
        {
            CGFloat alpha = 0;
            UIColor *color;
            int opt = CRAPI.sharedInstance.parcelShadingOption;
            
            switch (opt)
            {
                case 1://homestead
                    if (*homeStead == 'H')
                        alpha = 0.6;
                    
                    color = [[UIColor alloc]initWithRed:1.0
                                                  green:1.0
                                                   blue:0.0
                                                  alpha:alpha];
                    break;
                    
                case 2://res-com
                    color = [self resComColor:useCode];
                    break;
                    
                case 5://tax_exempt
                    if (*taxExempt == 'E')
                        alpha = 0.6;
                    
                    color = [[UIColor alloc]initWithRed:0.0
                                                  green:1.0
                                                   blue:0.0
                                                  alpha:alpha];
                    break;
            }
            
            [self fillParcel:context
                     nPoints:numPoints
                      points:llpoints
                   withColor:color.CGColor];
        }
        
        if (CRAPI.sharedInstance.showParcelBoundary)
        {
            [self drawParcel:context
                     nPoints:numPoints
                      nLoops:numLoops
                     partLen:polyPartLen
                      points:llpoints
                   withColor:UIColor.redColor.CGColor];
        }
        
        free (llpoints);
    }
    
    SQLOK(sqlite3_finalize(statement), "getOwnerNameForPID");
    [self close];
}

                             
- (UIColor *)resComColor:(char *)useCode
{
    UIColor *color = nil;
    CGFloat alpha = 0.6;
    
    switch ([self useCodeClass:useCode])
    {
        case 'N':
            color = [[UIColor alloc]initWithRed:0.0
                                          green:1.0
                                           blue:0.0
                                          alpha:alpha];
            break;
            
        case 'M':
            color = [[UIColor alloc]initWithRed:1.0
                                          green:1.0
                                           blue:0.0
                                          alpha:alpha];
            break;
            
        case 'R':
            color = [[UIColor alloc]initWithRed:0.0
                                          green:0.0
                                           blue:1.0
                                          alpha:alpha];
            break;
            
        case 'V':
            color = [[UIColor alloc]initWithRed:0.0
                                          green:1.0
                                           blue:1.0
                                          alpha:alpha];
            break;
    }
    
    return color;
}

-(char)useCodeClass:(char *)useCode
{
    if (!strcasecmp(useCode, "CAUT"))
        return 'N';
    
    if (!strcasecmp(useCode, "CBRE"))
        return 'N';
    
    if (!strcasecmp(useCode, "CMXD"))
        return 'M';
    
    if (!strcasecmp(useCode, "COFF"))
        return 'N';
    
    if (!strcasecmp(useCode, "CRET"))
        return 'N';
    
    if (!strcasecmp(useCode, "CSCH"))
        return 'N';
    
    if (!strcasecmp(useCode, "CUTL"))
        return 'N';
    
    if (!strcasecmp(useCode, "CWKS"))
        return 'N';
    
    if (!strcasecmp(useCode, "GMRS"))
        return 'R';
    
    if (!strcasecmp(useCode, "GRES"))
        return 'R';
    
    if (!strcasecmp(useCode, "HMTL"))
        return 'N';
    
    if (!strcasecmp(useCode, "IWFW"))
        return 'N';
    
    if (!strcasecmp(useCode, "MFAP"))
        return 'R';
    
    if (!strcasecmp(useCode, "MFRS"))
        return 'R';
    
    if (!strcasecmp(useCode, "MISC"))
        return 'N';
    
    if (!strcasecmp(useCode, "RCMS"))
        return 'R';
    
    if (!strcasecmp(useCode, "SFAD"))
        return 'R';
    
    if (!strcasecmp(useCode, "SFDD"))
        return 'R';
    
    if (!strcasecmp(useCode, "SPRC"))
        return 'N';
    
    if (!strcasecmp(useCode, "VLND"))
        return 'V';
    
    return '?';
}

- (NSMutableArray *) getReport:(PropDataOption)option
                        forPID:(NSString*)pid
{
    NSMutableArray *report = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT HOUSENUM,HOUSEFRACT,STREET,UNITNUM,ZIPCODE,\"OWNER NAME\",\"TAXPAYER NAME\",\"TAXPAYER ADDR1\",\"TAXPAYER ADDR2\",\"TAXPAYER ADDR3\",PARCEL_DEPTH,PARCEL_FRONTAGE,AREA_SQFT,USECODE,USE_DESC,TAX_EXEMPT,LAND_VALUE,BLDG_VALUE,TOTAL_VALUE,TOTAL_TAX,HOMESTEAD,WTRSHD,PARCELZONE.ZONETYPE,ASSESSMENT_YEAR,Date_of_Query FROM PROPINFO,PARCELZONE WHERE PROPINFO.PID='%s' AND PARCELZONE.PID='%s'",
                       pid.UTF8String,pid.UTF8String];
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "getReportForPID");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        int house = sqlite3_column_int(statement,0);
        LPSTR houseFrac = (LPSTR)sqlite3_column_text(statement, 1);
        LPSTR street = (LPSTR)sqlite3_column_text(statement, 2);
        LPSTR unit = (LPSTR)sqlite3_column_text(statement, 3);
        LPSTR zipcode = (LPSTR)sqlite3_column_text(statement, 4);
        LPSTR ownerName = (LPSTR)sqlite3_column_text(statement, 5);
        LPSTR taxpayerName = (LPSTR)sqlite3_column_text(statement, 6);
        LPSTR taxpayerAddr1 = (LPSTR)sqlite3_column_text(statement, 7);
        LPSTR taxpayerAddr2 = (LPSTR)sqlite3_column_text(statement, 8);
        LPSTR taxpayerAddr3 = (LPSTR)sqlite3_column_text(statement, 9);
        CGFloat depth = sqlite3_column_double(statement, 10);
        CGFloat frontage = sqlite3_column_double(statement, 11);
        CGFloat sqfeet = sqlite3_column_double(statement, 12);
        LPSTR useCode = (LPSTR)sqlite3_column_text(statement, 13);
        LPSTR useDesc = (LPSTR)sqlite3_column_text(statement, 14);
        LPSTR taxExempt = (LPSTR)sqlite3_column_text(statement, 15);
        CGFloat landValue = sqlite3_column_double(statement, 16);
        CGFloat bldgValue = sqlite3_column_double(statement, 17);
        CGFloat totalValue = sqlite3_column_double(statement, 18);
        CGFloat totalTax = sqlite3_column_double(statement, 19);
        LPSTR homeStead = (LPSTR)sqlite3_column_text(statement, 20);
        LPSTR waterShed = (LPSTR)sqlite3_column_text(statement, 21);
        LPSTR zoning = (LPSTR)sqlite3_column_text(statement, 22);
        LPSTR assessmentYr = (LPSTR)sqlite3_column_text(statement, 23);
        LPSTR dateOfQuery = (LPSTR)sqlite3_column_text(statement, 24);

        NSNumberFormatter *dollarFmt = [[NSNumberFormatter alloc] init];
        dollarFmt.numberStyle = NSNumberFormatterCurrencyStyle;
        dollarFmt.groupingSeparator = @"'";
        dollarFmt.groupingSize = 3;
        dollarFmt.alwaysShowsDecimalSeparator = NO;
        dollarFmt.usesGroupingSeparator = YES;
        dollarFmt.maximumFractionDigits = 0;
        
        NSString *line;
        line = [NSString stringWithFormat:@"PID:%@", pid];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"House Number:%i %s", house, houseFrac];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Street:%s", street];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Unit:%s", unit];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Zipcode:%s", zipcode];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Owner:%s", ownerName];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Taxpayer:%s", taxpayerName];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Taxpayer Addr1:%s", taxpayerAddr1];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Taxpayer Addr2:%s", taxpayerAddr2];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Taxpayer Addr3:%s", taxpayerAddr3];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Parcel Depth:%.0f", depth];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Parcel Width:%.0f", frontage];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Parcel Area Sqft:%.0f", sqfeet];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Use Code:%s", useCode];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Use Desc:%s", useDesc];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Tax Exempt Status:%s", taxExempt];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Land Value:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)landValue]]];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Bldg Value:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)bldgValue]]];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Total Value:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)totalValue]]];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Total Tax:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)totalTax]]];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Homestead:%s", homeStead];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Watershed:%s", waterShed];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Zoning:%s", zoning];
        [report addObject:line];
        
        line = [NSString stringWithFormat:@"Assessment Year:%s", assessmentYr];
        [report addObject:line];
        
        LPSTR pSpace = strrchr(dateOfQuery,' ');
        
        if (pSpace)
            *pSpace = 0;
        
        line = [NSString stringWithFormat:@"Date of Query:%s", dateOfQuery];
        [report addObject:line];
    }
    
    SQLOK(sqlite3_finalize(statement), "getReportForPID");
    [self close];
    return report;
}

@end