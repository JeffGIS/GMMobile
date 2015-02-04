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
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0),"getPointForPID");
    
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
    NSString *query = [NSString stringWithFormat:@"SELECT PID FROM PROPINFO Where PID LIKE '%@%%'", matchChar];
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0),"preparegetPIDsMatchingString");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 0);
        NSString *pid = [NSString stringWithFormat:@"%s",cpid];
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
    NSString *query = [NSString stringWithFormat:@"SELECT PID,\"Owner Name\" FROM PROPINFO Where PID LIKE '%@%%'", matchChar];
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0),"preparegetPIDsMatchingString");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 0);
        LPSTR owner = (LPSTR)sqlite3_column_text(statement, 1);
        NSString *pid = [NSString stringWithFormat:@"%s\t%s",cpid,owner];
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
    NSString *query = [NSString stringWithFormat:@"SELECT HOUSE_NUM,STREET_NAME,UDIValue,AdditionalValue FROM ADDLOC Where STREET_NAME LIKE '%@%%' AND HOUSE_NUM = %i", matchChar,houseNumber];
    //NSString *query2 = [NSString stringWithFormat:@"SELECT '%%HOUSE_NUM','%%STREET_NAME',UDIValue,AdditionalValue FROM ADDLOC"];
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0),"preparegetPIDsMatchingAddress");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int house = sqlite3_column_int(statement, 0);
        LPSTR street = (LPSTR)sqlite3_column_text(statement, 1);
        LPSTR pid = (LPSTR)sqlite3_column_text(statement, 2);
        LPSTR additionalVal = (LPSTR)sqlite3_column_text(statement, 3);
        NSString *out = [NSString stringWithFormat:@"%i\t%s\t%s\t%s",house,street,pid,additionalVal];
        [array addObject:out];
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
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0),"pickPID");
    
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
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0),"getOwnerNameForPID");
    
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
    BOOL rtn = !SQLOK(sqlite3_exec(_database, cmd, 0, 0, 0),"Execute cmd");
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOK(sqlite3_exec(_database, "BEGIN", 0, 0, 0),"Start transaction");
}

- (void)commitTransaction
{
    SQLOK(sqlite3_exec(_database, "COMMIT", 0, 0, 0),"End transaction");
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
    CGContextSetLineWidth(context, 3);
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
        {
            CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
        }
        
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
    sqlite3_stmt *statement;
    LPSTR pid;
    DPOINT BasePt;
    int numPoints,numLoops, refno;
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANBoundsToBounds(platlonBounds, pvbounds);
    
    [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id FROM PARCELPOLY, PARCELPOLY_index WHERE PARCELPOLY.id=PARCELPOLY_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0),"displayParcels");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        refno = sqlite3_column_int(statement,7);
       
        pid = (LPSTR)sqlite3_column_text(statement, 0);
        BasePt.x = sqlite3_column_double(statement, 1);
        BasePt.y = sqlite3_column_double(statement, 2);
        numPoints = sqlite3_column_int(statement, 3);
        numLoops = sqlite3_column_int(statement, 4);
        NSString *cpid = [NSString stringWithUTF8String:pid];
        
        int *polyPartLen = (int *)sqlite3_column_blob(statement, 5);
        int nBlobBytes = sqlite3_column_bytes(statement, 5);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement, 6);
        nBlobBytes = sqlite3_column_bytes(statement, 6);
        LPDPOINT llpoints = malloc (numPoints * sizeof(DPOINT) + 4);
        
        for (int i=0; i<numPoints; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / 1000000.0);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / 1000000.0);
            llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
        }
        
        [self fillParcel:context
                 nPoints:numPoints
                  points:llpoints
               withColor:UIColor.yellowColor.CGColor];
        
        [self drawParcel:context
                 nPoints:numPoints
                  nLoops:numLoops
                 partLen:polyPartLen
                  points:llpoints
               withColor:UIColor.redColor.CGColor];
        
        free(llpoints);
    }
    
    SQLOK(sqlite3_finalize(statement), "getOwnerNameForPID");
    [self close];
}

@end