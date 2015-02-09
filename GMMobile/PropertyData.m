//  PropertyData.m
//  GMMobile

#import "PropertyData.h"

#define COORDINATE_FACTOR 100000000.0

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
    sqlite3_stmt *statement;
    NSString *query = [[NSString alloc]init];
    
    [self open];
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
        {
            query = [NSString stringWithFormat:@"SELECT LAT,LON FROM PARCELPOINT Where PID = '%@'", PID];
            
        }
            break;
        case PROJECT_METROGIS:
        {
            query = [NSString stringWithFormat:@"SELECT LATITUDE,LONGITUDE FROM PROPINFO Where PIN = '%@'", PID];
            
        }
            break;
    }
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
    
    NSString *query = [NSString stringWithFormat:@"SELECT PIN FROM PROPINFO Where PIN LIKE '%@%%'",
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

- (NSMutableArray *)getPIDsWithOwnerMatchingString:(NSString *)matchChar limitOf:(int)lim
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    int n=0;
    
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PIN,\"Owner_Name\" FROM PROPINFO Where PIN LIKE '%@%%'",
                       matchChar];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0),"preparegetPIDsMatchingString");
    
    while (n++ < lim && sqlite3_step(statement) == SQLITE_ROW)
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
    NSString *query;
    [self open];
    //NSString *query = [NSString stringWithFormat:@"SELECT HOUSE_NUM,STREET_NAME,UDIValue,AdditionalValue FROM ADDLOC4 Where STREET_NAME LIKE '%@%%' AND HOUSE_NUM = %i",matchChar,houseNumber];
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
        {
            query = [NSString stringWithFormat:@"SELECT HOUSENUM,STREET,PID,\"Owner Name\" FROM PROPINFO Where STREET LIKE '%@%%' AND HOUSENUM = %i", matchChar,houseNumber];
        }
            break;
        case PROJECT_METROGIS:
        {
            query = [NSString stringWithFormat:@"SELECT BLDG_NUM,STREETNAME,PIN,\"Owner_Name\" FROM PROPINFO Where STREETNAME LIKE '%@%%' AND BLDG_NUM = %i", matchChar,houseNumber];
           
        }
            break;
    }
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

- (NSString *)pickPID:(LLPOINT*)pt
{
    NSString *minPID = [[NSString alloc] init];
    dbounds bnds;
    CGFloat d, mind = DBL_MAX;
    CGFloat pickap = 0.0005;
    DPOINT p1, p2, minpt;
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    bnds.xmn = p1.x - pickap;
    bnds.xmx = p1.x + pickap;
    bnds.ymn = p1.y - pickap;
    bnds.ymx = p1.y + pickap;
    [self open];

    NSString *query = [NSString stringWithFormat:@"SELECT PIN, LATITUDE, LONGITUDE FROM PROPINFO,PROPINFO_index WHERE PROPINFO.id=PROPINFO_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
             bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];

    //NSString *query = [NSString stringWithFormat:@"SELECT PID,LAT,LON FROM PARCELPOINT Where LAT > %f AND LAT < %f AND LON > %f AND LON < %f",
    //                   bnds.ymn, bnds.ymx, bnds.xmn, bnds.xmx];
    
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
            minpt = p2;
            minPID = [NSString stringWithUTF8String:cpid];
        }
    }
    
    SQLOK(sqlite3_finalize(statement), "pickPID");
    [self close];
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    return minPID;
}

- (NSString *)getOwnerNameForPID:(NSString *)PID
{
    NSString *ownerName = @"";
    
    [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT \"Owner_Name\" FROM PROPINFO Where PIN = '%@'", PID];
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
/*
 CREATE TABLE PROPINFO ('id' INT,'PIN' CHAR(17),'BLDG_NUM' CHAR(10),'STREETNAME' CHAR(60),'UNIT_INFO' CHAR(12),'CITY' CHAR(30),'CITY_USPS' CHAR(30),'ZIP' CHAR(5),'ZIP4' CHAR(4),'PLAT_NAME' CHAR(50),'BLOCK' CHAR(5),'LOT' CHAR(5),'ACRES_POLY' REAL,'ACRES_DEED' REAL,'USE1_DESC' CHAR(100),'USE2_DESC' CHAR(100),'USE3_DESC' CHAR(100),'USE4_DESC' CHAR(100),'MULTI_USES' CHAR(1),'LANDMARK' CHAR(100),'OWNER_NAME' CHAR(50),'OWNER_MORE' CHAR(50),'OWN_ADD_L1' CHAR(40),'OWN_ADD_L2' CHAR(40),'OWN_ADD_L3' CHAR(40),'TAX_NAME' CHAR(40),'TAX_ADD_L1' CHAR(40),'TAX_ADD_L2' CHAR(40),'TAX_ADD_L3' CHAR(40),'HOMESTEAD' CHAR(1),'EMV_LAND' REAL,'EMV_BLDG' REAL,'EMV_TOTAL' REAL,'TAX_CAPAC' REAL,'TOTAL_TAX' REAL,'SPEC_ASSES' REAL,'TAX_EXEMPT' CHAR(1),'XUSE1_DESC' CHAR(100),'XUSE2_DESC' CHAR(100),'XUSE3_DESC' CHAR(100),'XUSE4_DESC' CHAR(100),'DWELL_TYPE' CHAR(30),'HOME_STYLE' CHAR(30),'FIN_SQ_FT' REAL,'GARAGE' CHAR(1),'GARAGESQFT' CHAR(11),'BASEMENT' CHAR(1),'HEATING' CHAR(30),'COOLING' CHAR(30),'YEAR_BUILT' CHAR(5),'NUM_UNITS' CHAR(6),'SALE_DATE' CHAR(8),'SALE_VALUE' REAL,'SCHOOL_DST' CHAR(6),'WSHD_DIST' CHAR(50),'GREEN_ACRE' CHAR(1),'OPEN_SPACE' CHAR(1),'AG_PRESERV' CHAR(1),'AGPRE_ENRD' CHAR(8),'AGPRE_EXPD' CHAR(8),'PARC_CODE' CHAR(5),'CENBLOCK' CHAR(15),'LONGITUDE' REAL,'LATITUDE' REAL,PRIMARY KEY('id' ASC))
 */


-(void) displayParcels:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
{
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANBoundsToBounds(platlonBounds, pvbounds);
    
    NSString *query;    sqlite3_stmt *statement;
    LPSTR pid;
    DPOINT BasePt;
    int numPoints,numLoops, refno;
    CGFloat emvTotal;
    LPSTR homeStead,useCode,useDesc,taxExempt;
    char homeSteadCode = 'H';
    char taxExemptCode = 'E';
    [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT PROPINFO.PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USECODE,USE_DESC,TAX_EXEMPT,TOTAL_VALUE FROM PARCELPOLY,PARCELPOLY_index, PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PID=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            break;
        case PROJECT_METROGIS:
            homeSteadCode = 'Y';
            taxExemptCode = 'Y';
            query = [NSString stringWithFormat:@"SELECT PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USE1_DESC,USE2_DESC,TAX_EXEMPT,EMV_TOTAL  FROM PARCELPOLY,PARCELPOLY_index,PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PIN=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
   
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "displayParcels");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        refno = sqlite3_column_int(statement,7);
        homeStead = (LPSTR)sqlite3_column_text(statement, 8);
        useCode = (LPSTR)sqlite3_column_text(statement, 9);
        useDesc = (LPSTR)sqlite3_column_text(statement, 10);
        taxExempt = (LPSTR)sqlite3_column_text(statement, 11);
        emvTotal = (CGFloat)sqlite3_column_double(statement, 12);
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
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
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
                    if (*homeStead == homeSteadCode)
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
                    if (*taxExempt == taxExemptCode)
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
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
        {
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
        }
            break;
        case PROJECT_METROGIS:
        {
            NSString *query = [NSString stringWithFormat:@"SELECT BLDG_NUM,STREETNAME,UNIT_INFO,CITY,CITY_USPS,ZIP,ZIP4,PLAT_NAME,BLOCK,LOT,ACRES_POLY,ACRES_DEED,USE1_DESC,USE2_DESC,USE3_DESC,USE4_DESC,MULTI_USES,LANDMARK,OWNER_NAME,OWNER_MORE,EMV_LAND,EMV_BLDG,EMV_TOTAL,TAX_CAPAC,TOTAL_TAX,SPEC_ASSES FROM PROPINFO WHERE PROPINFO.PIN='%s'",
                               pid.UTF8String];
            
            SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "getReportForPID");
/*
    CREATE TABLE PROPINFO ('id' INT,'PIN' CHAR(17),'BLDG_NUM' CHAR(10),'STREETNAME' CHAR(60),'UNIT_INFO' CHAR(12),'CITY' CHAR(30),'CITY_USPS' CHAR(30),'ZIP' CHAR(5),'ZIP4' CHAR(4),'PLAT_NAME' CHAR(50),'BLOCK' CHAR(5),'LOT' CHAR(5),'ACRES_POLY' REAL,'ACRES_DEED' REAL,'USE1_DESC' CHAR(100),'USE2_DESC' CHAR(100),'USE3_DESC' CHAR(100),'USE4_DESC' CHAR(100),'MULTI_USES' CHAR(1),'LANDMARK' CHAR(100),'OWNER_NAME' CHAR(50),'OWNER_MORE' CHAR(50),'OWN_ADD_L1' CHAR(40),'OWN_ADD_L2' CHAR(40),'OWN_ADD_L3' CHAR(40),'TAX_NAME' CHAR(40),'TAX_ADD_L1' CHAR(40),'TAX_ADD_L2' CHAR(40),'TAX_ADD_L3' CHAR(40),'HOMESTEAD' CHAR(1),'EMV_LAND' REAL,'EMV_BLDG' REAL,'EMV_TOTAL' REAL,'TAX_CAPAC' REAL,'TOTAL_TAX' REAL,'SPEC_ASSES' REAL,'TAX_EXEMPT' CHAR(1),'XUSE1_DESC' CHAR(100),'XUSE2_DESC' CHAR(100),'XUSE3_DESC' CHAR(100),'XUSE4_DESC' CHAR(100),'DWELL_TYPE' CHAR(30),'HOME_STYLE' CHAR(30),'FIN_SQ_FT' REAL,'GARAGE' CHAR(1),'GARAGESQFT' CHAR(11),'BASEMENT' CHAR(1),'HEATING' CHAR(30),'COOLING' CHAR(30),'YEAR_BUILT' CHAR(5),'NUM_UNITS' CHAR(6),'SALE_DATE' CHAR(8),'SALE_VALUE' REAL,'SCHOOL_DST' CHAR(6),'WSHD_DIST' CHAR(50),'GREEN_ACRE' CHAR(1),'OPEN_SPACE' CHAR(1),'AG_PRESERV' CHAR(1),'AGPRE_ENRD' CHAR(8),'AGPRE_EXPD' CHAR(8),'PARC_CODE' CHAR(5),'CENBLOCK' CHAR(15),'LONGITUDE' REAL,'LATITUDE' REAL,PRIMARY KEY('id' ASC))
 */
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                LPSTR house = (LPSTR)sqlite3_column_text(statement,0);
                LPSTR street = (LPSTR)sqlite3_column_text(statement, 1);
                LPSTR unit = (LPSTR)sqlite3_column_text(statement, 2);
                LPSTR city = (LPSTR)sqlite3_column_text(statement, 3);
                LPSTR cityUSPS = (LPSTR)sqlite3_column_text(statement, 4);
                LPSTR zipcode = (LPSTR)sqlite3_column_text(statement, 5);
                LPSTR zip4 = (LPSTR)sqlite3_column_text(statement, 6);
                LPSTR platName = (LPSTR)sqlite3_column_text(statement, 7);
                LPSTR block = (LPSTR)sqlite3_column_text(statement, 8);
                LPSTR lot = (LPSTR)sqlite3_column_text(statement, 9);
                CGFloat acresPoly = sqlite3_column_double(statement, 10);
                CGFloat acresDeed = sqlite3_column_double(statement, 11);
                LPSTR UseDesc1 = (LPSTR)sqlite3_column_text(statement, 12);
                LPSTR UseDesc2 = (LPSTR)sqlite3_column_text(statement, 13);
                LPSTR UseDesc3 = (LPSTR)sqlite3_column_text(statement, 14);
                LPSTR UseDesc4 = (LPSTR)sqlite3_column_text(statement, 15);
                LPSTR multiUses = (LPSTR)sqlite3_column_text(statement,16);
                LPSTR landMark = (LPSTR)sqlite3_column_text(statement, 17);
                LPSTR ownerName = (LPSTR)sqlite3_column_text(statement, 18);
                LPSTR ownerMore = (LPSTR)sqlite3_column_text(statement, 19);
                CGFloat landEMV = sqlite3_column_double(statement, 20);
                CGFloat bldgEMV = sqlite3_column_double(statement, 21);
                CGFloat totalEMV = sqlite3_column_double(statement, 22);
                CGFloat taxCapac = sqlite3_column_double(statement, 23);
                CGFloat totalTax = sqlite3_column_double(statement, 24);
                CGFloat specAsses = sqlite3_column_double(statement, 25);
            
                NSNumberFormatter *dollarFmt = [[NSNumberFormatter alloc] init];
                dollarFmt.numberStyle = NSNumberFormatterCurrencyStyle;
                dollarFmt.groupingSeparator = @"'";
                dollarFmt.groupingSize = 3;
                dollarFmt.alwaysShowsDecimalSeparator = NO;
                dollarFmt.usesGroupingSeparator = YES;
                dollarFmt.maximumFractionDigits = 0;
                
                NSString *line;
                line = [NSString stringWithFormat:@"PIN:%@", pid];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"House Number: %s", house];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Street:%s", street];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Unit:%s", unit];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"City:%s", city];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Owner:%s", ownerName];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Owner more:%s", ownerMore];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Land EMV:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)landEMV]]];
                [report addObject:line];
 
                line = [NSString stringWithFormat:@"Building EMV:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)bldgEMV]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Total EMV:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)totalEMV]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Total Tax:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)totalTax]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"City USPS:%s", cityUSPS];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Zipcode:%s", zipcode];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Zip4:%s", zip4];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Plat:%s", platName];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Block:%s", block];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Lot:%s", lot];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Acres:%.1f", acresDeed];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Use Desc1:%s", UseDesc1];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Use Desc2:%s", UseDesc2];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Use Desc3:%s", UseDesc3];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Use Desc4:%s", UseDesc4];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Multi Uses:%s", multiUses];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Landmark:%s", landMark];
                [report addObject:line];
                
            }
            
        }
    }
   
    SQLOK(sqlite3_finalize(statement), "getReportForPID");
    [self close];
    return report;
}
/*MENUITEM "Taxpayer Name",		"[%NAMEINDEXDB]=[%DL]attribut\[PROPDATE]\taxpayernameindex.gmd;[%NAMEDB]=[%DL]attribut\[PROPDATE]\propinfo.gmd;[%PROPERTYDB]=[%DL]attribut\[PROPDATE]\propinfo.gmd;[%NAMEDISPLAY]=$STR(IF([Taxpayer Addr3]>''){[Taxpayer Name] [Taxpayer Addr1]$CHR(1)[Taxpayer Addr2][Taxpayer Addr3]}ELSE{[Taxpayer Name]$CHR(1)[Taxpayer Addr1][Taxpayer Addr2]};$CHR(1)[PID]);[%PROPERTYPREFIX]=PINCA;[%PROPERTYDISPLAY]=$STR([PID]$CHR(1)[Housenum] [HouseFract] [Street] [UnitNum] [Address] [Zipcode]$CHR(1)[Area_SqFt]sqft$CHR(1)@$$RND([Total_Value],0,T)$CHR(1)[PID]);[%PROPERTYKEYFIELD]=PID;[%PROPERTYINDEXFIELD]=PID;[%C]=$OWNERLOC(MPLS);"


BOOL  OWNERLOCMsgProc2(HWND hWndDlg, int Message, WPARAM wParam, LPARAM lParam)
{ 	int		st, choice, n,idx,ifile,i;
    int		Trigger=3;
    BOOL	HaveWildcard;
    char	str[1024], teststr[1024],lastowner[4096];
    static	char Wildcard[128]="";
    static	char WantStr[128]="";
    char	WantStr2[128],propkeyfld[64];
    LPGWDHEADER lpGWDHeadNameIndex, lpGWDHeadName, lpGWDHeadProperty;
    LPOPENFILEDATA  FilePtrNameIndex, FilePtrName, FilePtrProperty;
    LPOPENSQLDATA   SQLPtrNameIndex, SQLPtrName, SQLPtrProperty;
    long	Offset;
    int		nParts, nPartsTest, PartLen[MAXPARTS], PartLenTest[MAXPARTS];
    LPSTR	PartLoc[MAXPARTS], PartLocTest[MAXPARTS], pTab;
    static	HANDLE	hDBNameIndex=0, hDBName=0, hDBProperty=0;
    static	HANDLE	hSaveBM=0;
    static	BOOL	First;
    static	short	iOwner=-1, SaveProperty=-1;
    short	Item;
    char	propprefix[32];
    TAGKEY TAGKey;
    LPSTR	pTAB;
    HWND	hwndCtl;
    int		nowner;
    static	char	NameDelim;
    UINT	nPrompts=4;
    UINT	PrmtDat[4*3] = {
        IDC_OWNERNAMEWC,PRMT_IDC_OWNERNAMEWC,0,
        IDC_OWNERNAME, PRMT_IDC_OWNERNAME,0,
        IDC_OWNERLIST, PRMT_IDC_OWNERLIST,0,
        IDC_PROPERTYLIST, PRMT_IDC_PROPERTYLIST,0
    };
    
    
    int	BRtn;
    if (Message==WM_INITDIALOG)
    {
        UINT	pw=0, pn=1, pm=2;
        HWND	hwnd;
        short	ii;
        
        InitDlgPrompts (hWndDlg);
        while (nPrompts--)
        {
            hwnd = GetDlgItem(hWndDlg,PrmtDat[pw]);
            if (!hwnd)
                ii=1;
            SetDlgPrompt (hwnd,PrmtDat[pn],PrmtDat[pm]);
            pw+=3;
            pn+=3;
            pm+=3;
        }
    }
    if ((BRtn = DIALOGSTYLEMsgProc (hWndDlg,Message, wParam, lParam)))
        return (BRtn);
    switch(Message)
    {
        case WM_DESTROY:
            InitDlgPrompts (0);
            break;
        case WM_INITDIALOG:
        {
            int	nTabs;
            HANDLE	hList;
            LPINT	pTabs;
            
            ClearDlgPrompts ();
            //hSaveBM = EnterBlockingWindow (hWndDlg);
            First = TRUE;
            SendDlgItemMessage (hWndDlg,IDC_AUTOHIGHLIGHT,BM_SETCHECK,AutoHighlight,0L);
            GetGlobalCVal ("[%OWNERTABS]",str,"250 2000");
            nTabs = GetIntsFromList (str,&hList);
            if (nTabs)
            {
                pTabs = (LPINT)GlobalLock (hList);
                SendDlgItemMessage (hWndDlg,IDC_OWNERLIST,LB_SETTABSTOPS,nTabs,(LPARAM)pTabs);
                GSSiGlobUlFree (&hList);
            }
            GetGlobalCVal ("[%PROPERTYTABS]",str,"80 200 250 2000");
            nTabs = GetIntsFromList (str,&hList);
            if (nTabs)
            {
                pTabs = (LPINT)GlobalLock (hList);
                SendDlgItemMessage (hWndDlg,IDC_PROPERTYLIST,LB_SETTABSTOPS,nTabs,(LPARAM)pTabs);
                GSSiGlobUlFree (&hList);
            }
            cwCenter(hWndDlg, 0);
            GetGlobalCVal ("[%NAMEINDEXDB]",str,"[%DL]attribut\\nameindex.gmd");
            if (!OpenDataFile (str, "",BT_READ, &hDBNameIndex))
            {
                MessageBox( GetFocus(), str,"Cannot open name index database", MB_OK);
                PostMessage(hWndDlg, WM_COMMAND, IDCANCEL, 0L);
                return FALSE;
            }
            CloseDataFile (TRUE,&hDBNameIndex);
            GetGlobalCVal ("[%NAMEDB]",str,"[%DL]attribut\\name.gmd");
            if (!OpenDataFile (str, "",BT_READ, &hDBName))
            {
                MessageBox( GetFocus(), str,"Cannot open name database", MB_OK);
                PostMessage(hWndDlg, WM_COMMAND, IDCANCEL, 0L);
                return FALSE;
            }
            CloseDataFile (TRUE,&hDBName);
            GetGlobalCVal ("[%PROPERTYDB]",str,"[%DL]attribut\\master.gmd");
            if (!OpenDataFile (str, "",BT_READ, &hDBProperty))
            {
                MessageBox( GetFocus(), str,"Cannot open property database", MB_OK);
                PostMessage(hWndDlg, WM_COMMAND, IDCANCEL, 0L);
                return FALSE;
            }
            CloseDataFile (TRUE,&hDBProperty);
            SetDlgItemText (hWndDlg,IDC_OWNERNAMEWC,Wildcard);
            PostMessage(GetDlgItem(hWndDlg,IDC_OWNERLIST), LB_SETCURSEL,iOwner,0);
            PostMessage(hWndDlg, WM_COMMAND, IDC_SETPROPLIST, 0L);
            PostMessage(GetDlgItem(hWndDlg,IDC_PROPERTYLIST), LB_SETSEL,TRUE,SaveProperty);
        }
            
            break;
        case WM_CLOSE:
            PostMessage(hWndDlg, WM_COMMAND, IDCANCEL, 0L);
            break;
        case WM_COMMAND:
            switch(LOWORD(wParam))
        {
            case IDC_OWNERNAMEWC:
                SetDlgItemText (hWndDlg,IDC_PROPMESSAGE,"");
                hwndCtl = (HWND) LOWORD(lParam);
                switch (HIWORD(wParam))
            {	case EN_CHANGE:
                {
                    int	nParts, ipart,iparttest, nOwners;
                    LPWORDINDEX	pRec;
                    WORDINDEX	Rec;
                    HANDLE	hPartOffsets[MAXPARTS];
                    int		nPartOffsets[MAXPARTS];
                    int		nHits;
                    BOOL	GetNext = TRUE;
                    MSG     msg;
                    char	Name[66];
                    
                    SetDlgItemText (hWndDlg,IDC_NUMOWNERS,"Searching...");
                    GetGlobalCVal ("[%NAMEINDEXDB]",str,"[%DL]attribut\\nameindex.gmd");
                    OpenDataFile (str, "",BT_READ, &hDBNameIndex);
                    SQLPtrNameIndex = (LPOPENSQLDATA) GlobalLock (hDBNameIndex);
                    FilePtrNameIndex = (LPOPENFILEDATA) GlobalLock (SQLPtrNameIndex->OFHandle);
                    lpGWDHeadNameIndex = (LPGWDHEADER)GlobalLock (FilePtrNameIndex->FileHandle);
                    pRec = (LPWORDINDEX)&lpGWDHeadNameIndex->GWDData;
                    SendDlgItemMessage (hWndDlg,IDC_OWNERLIST,LB_RESETCONTENT,0,0);
                    SendDlgItemMessage (hWndDlg,IDC_PROPERTYLIST,LB_RESETCONTENT,0,0);
           		      	GetDlgItemText (hWndDlg,IDC_OWNERNAMEWC,Name,64);
                    nParts = GetNameParts (Name,PartLoc,PartLen,MAXPARTS);
           		      	
                    for (ipart=0;ipart<nParts;ipart++)
                    {
                        nPartOffsets[ipart] = 0;
                        hPartOffsets[ipart] = 0;
                    }
                    for (ipart=0;ipart<nParts;ipart++)
           		      	{
                            short	pos=BT_FIRST, cond=BT_GE;
                            int		nOffsets, nSeqRec;
                            
                            if (PartLen[ipart] >= Trigger)
                            {
                                strncpy (Rec.Word,PartLoc[ipart],8);
                                Rec.Seq = SHRT_MIN;
                                while (GetNext && !BT_FIND (lpGWDHeadNameIndex->BTHandle[0],(LPSTR)&Rec,pos,cond,(LPSTR)&Offset))
                                {
                                    LPLONG	pOffsets;
                                    
                                    pos = BT_NEXT;
                                    cond = BT_ANY;
                                    
                                    FillGWDData (lpGWDHeadNameIndex,Offset);
                                    if (strnicmp (pRec->Word,PartLoc[ipart],min(8,PartLen[ipart])))
                                        break;
                                    nSeqRec = -(pRec->Seq + 1);
                                    nOffsets = nSeqRec * 100 + pRec->nOffsets;
                                    if (!nPartOffsets[ipart])
                                        hPartOffsets[ipart] = GSSiGlobAlloc (0,GMEM_MOVEABLE,MAXOFFSETS * sizeof(int));
                                    pOffsets = (LPLONG)GlobalLock (hPartOffsets[ipart]);
                                    if (nPartOffsets[ipart] + pRec->nOffsets >= MAXOFFSETS)
                                        GetNext = FALSE;
                                    else
                                    {
                                        pOffsets += nPartOffsets[ipart];
                                        memmove (pOffsets,pRec->Offsets,pRec->nOffsets*sizeof(long));
                                        pOffsets += pRec->nOffsets;
                                        nPartOffsets[ipart] += pRec->nOffsets;
                                        while (GetNext && nSeqRec--)
                                        {
                                            BT_FIND (lpGWDHeadNameIndex->BTHandle[0],(LPSTR)pRec,pos,cond,(LPSTR)&Offset);
                                            FillGWDData (lpGWDHeadNameIndex,Offset);
                                            if (nPartOffsets[ipart] + pRec->nOffsets >= MAXOFFSETS)
                                                GetNext = FALSE;
                                            else
                                            {
                                                memmove (pOffsets,pRec->Offsets,pRec->nOffsets*sizeof(long));
                                                pOffsets += pRec->nOffsets;
                                                nPartOffsets[ipart] += pRec->nOffsets;
                                            }
                                        }
                                    }
                                    GlobalUnlock (hPartOffsets[ipart]);
                                    if (GSSiPeekMessage(&msg,hwndCtl,WM_KEYDOWN,WM_KEYDOWN,PM_NOREMOVE))
                                        GetNext = FALSE;
                                }
                                if (!nPartOffsets[ipart])
                                    GetNext = FALSE;
                            }
                            else
                                nPartOffsets[ipart] = INT_MAX;
                        }
                    
                    if (GetNext)
                        nHits = GetWIHits (Hits,nParts,nPartOffsets,hPartOffsets,MAXHITS,hwndCtl);
                    for (ipart=0;ipart<nParts;ipart++)
                        GSSiGlobFree (&hPartOffsets[ipart]);
                    GlobalUnlock (FilePtrNameIndex->FileHandle);
                    GlobalUnlock (SQLPtrNameIndex->OFHandle);
                    GlobalUnlock (hDBNameIndex);
                    CloseDataFile (TRUE,&hDBNameIndex);
                    GetGlobalCVal ("[%NAMEDB]",str,"[%DL]attribut\\name.gmd");
                    OpenDataFile (str, "",BT_READ, &hDBName);
                    SQLPtrName = (LPOPENSQLDATA) GlobalLock (hDBName);
                    FilePtrName = (LPOPENFILEDATA) GlobalLock (SQLPtrName->OFHandle);
                    lpGWDHeadName = (LPGWDHEADER)GlobalLock (FilePtrName->FileHandle);
                    nowner = 0;
                    while (GetNext && nHits--)
                    {
                        BOOL	ShowThisOwner = TRUE;
                        
                        if (Hits[nHits] <= sizeof (GWDHEADER16))
                            continue;
                        FillGWDData (lpGWDHeadName,Hits[nHits]);
                        SQLPtrName->st = 0;
                        SQLPtrName->Offset = Hits[nHits];
                        SQLPtrName->lastreadtime = ULONG_MAX;
                        if (ShowThisOwner)
                        {
                            if (nowner == 81)
                                idx = 0;
                            GetGlobalCVal ("[%NAMEDISPLAY]",str,"[NAMETAXPAYER]$CHR(1)[NAMEADDR1] [NAMEADDR2] [NAMECITY],[NAMESTATE]$CHR(1)[NAMEACCTOWNER]");
                            ExpandText (str);
                            OneSpace (str);
                            ReplaceChar (str,0x01,0x09);
                            strcpy (teststr,str);
                            if ((pTab = strchr (teststr,'\t')))
                                *pTab = 0;
                            nPartsTest = GetNameParts (teststr,PartLocTest,PartLenTest,MAXPARTS);
                            for (ipart = 0;ipart < nParts;ipart++)
                            {
                                for (iparttest=0;iparttest<nPartsTest;iparttest++)
                                {
                                    if (!strnicmp (PartLoc[ipart],PartLocTest[iparttest],PartLen[ipart]))
                                    {
                                        *PartLocTest[iparttest] = 0;
                                        goto FoundPart;
                                    }
                                }
                                ShowThisOwner = FALSE;
                                break;
                            FoundPart:							;
                            }
                            if (ShowThisOwner)
                            {
                                nowner++;
                                strcpy (lastowner,str);
                                if ((idx=SendDlgItemMessage (hWndDlg,IDC_OWNERLIST,LB_ADDSTRING,0,(LPARAM)str)) ==
                                    LB_ERRSPACE)
                                    GetNext = FALSE;
                            }
                        }
                        if (GSSiPeekMessage(&msg,hwndCtl,WM_KEYDOWN,WM_KEYDOWN,PM_NOREMOVE))
                            GetNext = FALSE;
                    }
                    GlobalUnlock (FilePtrName->FileHandle);
                    GlobalUnlock (SQLPtrName->OFHandle);
                    GlobalUnlock (hDBName);
                    CloseDataFile (TRUE,&hDBName);
                    if (GetNext)
                    {
                        nOwners=SendDlgItemMessage(hWndDlg,IDC_OWNERLIST,LB_GETCOUNT,0,0);
                        sprintf (str,"%ld selected",nOwners);
                    }
                    else
                        strcpy (str,"Search cancelled");
                    SetDlgItemText (hWndDlg,IDC_NUMOWNERS,str);
                }
                    if (First && SaveProperty >= 0)
                        PostMessage(GetDlgItem(hWndDlg,IDC_PROPERTYLIST), LB_SETSEL,TRUE,SaveProperty);
                    First = FALSE;
            }
                break;
                
            case IDC_PROPERTYLIST:
                switch(HIWORD(wParam))
            {
                case LBN_SELCHANGE:
                {
                    HANDLE	hItems;
                    int n=GetLBSelectedItems (hWndDlg,IDC_PROPERTYLIST,&hItems);
                    LPINT	pItem;
                    
                    SetDlgItemText (hWndDlg,IDC_PROPMESSAGE,"");
                    EnableWindow (GetDlgItem(hWndDlg,IDOK),FALSE);
                    if (n>0)
                    {
                        pItem=(LPINT)GlobalLock (hItems);
                        //if (n==1)
                        {
                            short	DoZoom=0;
                            
                            GetGlobalCVal ("[%PROPERTYPREFIX]",propprefix,"PINA");
                            
                            ClearHighlightList(FALSE);
                            while (n--)
                            {
                                SendDlgItemMessage(hWndDlg,IDC_PROPERTYLIST,LB_GETTEXT,*pItem++,(DWORD)str);
                                pTAB = _fstrrchr (str,'\t');
                                pTAB++;
                                Strip (pTAB,' ');
                                if (PickByRefno (0,propprefix,pTAB,-1))
                                {
                                    if (PickList[0].IsDeleted)
                                        DoZoom = -1;
                                    else
                                    {
                                        AddToHighlightList (PickList[0].Refno,&PickList[0],TRUE);
                                        DoZoom=1;
                                    }
                                }
                            }
                            if (DoZoom>0)
                            {
                                EnableWindow (GetDlgItem(hWndDlg,IDOK),TRUE);
                                PostMessage(hWndMain, WM_COMMAND, IDM_Z_HLTLIMITS, 0L);
                            }
                            else if (DoZoom < 0)
                                SetDlgItemText (hWndDlg,IDC_PROPMESSAGE,"Property is marked deleted");
                            else
                                SetDlgItemText (hWndDlg,IDC_PROPMESSAGE,"Property not found");
                        }
                        GSSiGlobUlFree (&hItems);
                    }
                }
                    break;
                    
                case LBN_DBLCLK:
                    PostMessage(hWndDlg, WM_COMMAND, IDOK, 0L);
                    IgnoreLbutton = TRUE;
                    break;
            }
                break;
                
            case IDC_OWNERLIST:
                switch(HIWORD(wParam))
            {
                case LBN_SELCHANGE:
                    SetDlgItemText (hWndDlg,IDC_PROPMESSAGE,"");
                    PostMessage(hWndDlg, WM_COMMAND, IDC_SETPROPLIST, 0L);
            }
                break;
                
            case IDC_SETPROPLIST:
            {
                GetGlobalCVal ("[%PROPERTYDB]",str,"[%DL]attribut\\master.gmd");
                if (!OpenDataFile (str, "",BT_READ, &hDBProperty))
                {
                    MessageBox( GetFocus(), str,"Cannot open property database", MB_OK);
                }
                else
                {
                    HANDLE	hItems=0;
                    int	 n=GetLBSelectedItems (hWndDlg,IDC_OWNERLIST,&hItems);
                    LPINT	pItem;
                    
                    SendDlgItemMessage (hWndDlg,IDC_PROPERTYLIST,LB_RESETCONTENT,0,0);
                    if (n)
                    {
                        pItem = (LPINT)GlobalLock (hItems);
                        while (n--)
                        {    
                            
                            Item = *pItem++;
                            SendDlgItemMessage(hWndDlg,IDC_OWNERLIST,LB_GETTEXT,Item,(DWORD)str);
                            if ((pTAB = _fstrrchr (str,'\t')))
                            {
                                *pTAB++ = 0;   
                                _fstrcpy (WantStr2,pTAB);
                                ReplaceChar (str,'\t','-');
                                //SetDlgItemText (hWndDlg,IDC_OWNERNAME,str); 
                                {               
                                    short	IDIndex=GetGlobalLVal2 ("[%PROPERTYINDEX]",0), IDLen=0; 
                                    short	pos=BT_FIRST, cond=BT_GE;
                                    BOOL	GetNext=TRUE;
                                    char	propindexfld[66];
                                    
                                    SQLPtrProperty = (LPOPENSQLDATA) GlobalLock (hDBProperty);
                                    FilePtrProperty = (LPOPENFILEDATA) GlobalLock (SQLPtrProperty->OFHandle);
                                    lpGWDHeadProperty = (LPGWDHEADER)GlobalLock (FilePtrProperty->FileHandle);                             
                                    //for (i=0;i<abs(lpGWDHeadProperty->NumIndexFields[IDIndex]);i++)
                                    //	IDLen += lpGWDHeadProperty->pFldInfo[lpGWDHeadProperty->IndexFields[IDIndex][i]].Len;
                                    //_fstrncpy (lpGWDHeadProperty->pKeys[IDIndex],WantStr2,IDLen);
                                    GetGlobalCVal ("[%PROPERTYINDEXFIELD]",propindexfld,"[PID]");
                                    SetFieldValFromCharAndName(lpGWDHeadProperty,propindexfld,(LPSTR)WantStr2,FALSE);
                                    GWDFormKey(lpGWDHeadProperty,IDIndex,TRUE,0,0);
                                    
                                    while (GetNext && !BT_FIND (lpGWDHeadProperty->BTHandle[IDIndex],lpGWDHeadProperty->pKeys[IDIndex],pos,cond,(LPSTR)&Offset))
                                    {
                                        char	CharKeyVal[128];
                                        
                                        pos = BT_NEXT;
                                        cond = BT_ANY;
                                        
                                        //lpGWDHeadProperty->pKeys[IDIndex][IDLen]=0;   
                                        //Truncate (lpGWDHeadProperty->pKeys[IDIndex]);
                                        GMDGetCharKeyVal (lpGWDHeadProperty,IDIndex,0,CharKeyVal); 
                                        if (!_fstricmp (WantStr2,CharKeyVal))
                                        {
                                            FillGWDData (lpGWDHeadProperty,Offset); 
                                            SQLPtrProperty->st = 0;  
                                            SQLPtrProperty->Offset = Offset; 
                                            SQLPtrProperty->lastreadtime = ULONG_MAX;
                                            GetGlobalCVal ("[%PROPERTYDISPLAY]",str,"[GEOACCT]$CHR(1)[PROPADDR] [STREET] [DIRECTION] [SFX]$CHR(1)[DEEDVOLUME]/[DEEDPAGE]$CHR(1)[ACRES]");
                                            ExpandText (str); 
                                            OneSpace (str); 
                                            //GetGlobalCVal ("[%PROPERTYKEYFIELD]",propkeyfld,"[GEOACCT]");
                                            ReplaceChar (str,0x01,0x09); 
                                            //sprintf (_fstrchr(str,0),"\t%s",propkeyfld);
                                            //ExpandText (str);
                                            if ((idx=SendDlgItemMessage (hWndDlg,IDC_PROPERTYLIST,LB_ADDSTRING,0,(LPARAM)str)) ==
                                                LB_ERRSPACE) 
                                                GetNext = FALSE; 
                                        } 
                                        else
                                            GetNext = FALSE;
                                    }
                                    GlobalUnlock (FilePtrProperty->FileHandle); 
                                    GlobalUnlock (SQLPtrProperty->OFHandle);
                                    GlobalUnlock (hDBProperty); 
                                }
                            }
                        }
                    }
                    CloseDataFile (TRUE,&hDBProperty); 
                    GSSiGlobUlFree (&hItems);
                }  
            }
                break; 
                
            case IDOK:
            {   
                HANDLE	hItems; 
                int	 n=GetLBSelectedItems (hWndDlg,IDC_PROPERTYLIST,&hItems);
                LPINT	pItem=(LPINT)GlobalLock (hItems);  
                LPSTR	pTAB; 
                BOOL	Err=TRUE;
                
                if (n == 1)
                    SaveProperty = *pItem;
                else
                    SaveProperty = -1;
                iOwner = SendDlgItemMessage(hWndDlg,IDC_OWNERLIST,LB_GETCURSEL,0,0);
                SendDlgItemMessage(hWndDlg,IDC_OWNERLIST,LB_GETTEXT,iOwner,(DWORD)str); 
                if ((pTAB = _fstrchr (str,'\t')))
                    *pTAB = 0;
                SetGlobalValue ("%SELECTEDOWNER",str);
                ClearHighlightList(FALSE); 
                AutoHighlight=SendDlgItemMessage(hWndDlg,IDC_AUTOHIGHLIGHT,BM_GETCHECK,0,0); 
                while (n--)
                {   
                    SendDlgItemMessage(hWndDlg,IDC_PROPERTYLIST,LB_GETTEXT,*pItem++,(DWORD)str);
                    pTAB = _fstrrchr (str,'\t');
                    pTAB++; 
                    Strip (pTAB,' ');
                    GetGlobalCVal ("[%PROPERTYPREFIX]",propprefix,"PINA");
                    if (PickByRefno (0,propprefix,pTAB,-1))
                    {
                        if (PickList[0].Type != 6 && AutoHighlight) 
                            AddToHighlightList (PickList[0].Refno,&PickList[0],TRUE); 
                        Err=FALSE;
                    }
                    else 
                    {
                        SetDlgItemText (hWndDlg,IDC_PROPMESSAGE,"Property not found"); 
                    }
                } 
                GSSiGlobUlFree (&hItems);
                if (Err)
                    break; 
                GetDlgItemText (hWndDlg,IDC_OWNERNAME,WantStr,sizeof(WantStr)-1); 
                GetDlgItemText (hWndDlg,IDC_OWNERNAMEWC,Wildcard,sizeof(Wildcard)-1);            
                GSSiEndDialog(hWndDlg, 2,hSaveBM); 
                ExpandBounds (&HLTBounds, LocationOffset);
                ZoomToRect(HLTBounds,FALSE);  
                //			    PostMessage(hWndMain, WM_COMMAND, IDM_Z_HLTLIMITS, 0L);
                
            }
                break;   
                
            case IDCANCEL:
                CloseDataFile (TRUE,&hDBName);
                GSSiEndDialog(hWndDlg, FALSE,hSaveBM);
                break;
        }
            break;              
        default:
            return FALSE;
    }
    return TRUE;
}      
*/
@end