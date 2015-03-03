//  PropertyData.m
//  GMMobile

#import "PropertyData.h"

#define COORDINATE_FACTOR 10000000.0

extern int keepProcessing;

@interface PropertyData ()

@property (nonatomic) GSSiPopoverView *popover;

@end

@implementation BoundaryAreaData

@end

@implementation PropertyData

static PropertyData *_propData;

int SQLOKpd(int sqlReturn, char *method)
{
    if (sqlReturn != SQLITE_OK)
    {
        [_propData logError:sqlReturn
                     method:method];
    }
    
    return sqlReturn;
}

- (void)logError:(int)sqlReturn
          method:(char *)method
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i in %s = %i:%s",
                  sqlReturn, method, sqlite3_errcode(_database), sqlite3_errmsg(_database)]);
}

- (BOOL) continue
{
    if (self.processingID == keepProcessing)
        return YES;
    return NO;
}

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
- (void)open
{
    if (!_isOpen)
    {
        self.isOpen = !SQLOK(sqlite3_open(self.path.UTF8String, &_database), "open(Property)");
        NSLog(@"Property Database open");
        
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                   error:nil].fileSize;
    }
}

- (void)close
{
    SQLOK(sqlite3_close(_database),"Close");
    NSLog(@"Property Database close");
    self.isOpen = NO;
}

- (void)clear
{
    [self close];
    
    BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
                                                       error:nil];
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

- (BOOL)getDistinctUseCodes:(NSString *)outFile
{
    BOOL rtn;
    sqlite3_stmt *statement;
    NSString *query = [[NSString alloc] init];
    NSString *outString = @"Distinct Use Codes";
    
    [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = @"SELECT DISTINCT XUSE1_DESC FROM PROPINFO";
            break;
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetDistinctUseCodes");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR useCode = (LPSTR)sqlite3_column_text(statement, 0);
        outString = [outString stringByAppendingString:[NSString stringWithFormat:@"\r\n%s", useCode]];
    }
    
    SQLOK(sqlite3_finalize(statement), "getDistinctUseCodes");
    
    [self close];
    
    rtn = [outString writeToFile:outFile
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:nil];
    
    return rtn;
}

- (LLPOINT)getPointForPID:(NSString *)PID
{
    LLPOINT pt = {0};
    sqlite3_stmt *statement;
    NSString *query = [[NSString alloc] init];
    
    [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT LAT,LON FROM PARCELPOINT Where PID = '%@'",
                     PID];
            break;
            
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT LATITUDE,LONGITUDE FROM PROPINFO Where PIN = '%@'",
                     PID];
            break;
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetPointForPID");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        pt.lat = sqlite3_column_double(statement, 0);
        pt.lon = sqlite3_column_double(statement, 1);
    }
    
   SQLOK(sqlite3_finalize(statement), "getPointforPID");
    
    [self close];
    return pt;
}

- (MNMXCORD)getBoundsForPID:(NSString *)PID
{
    MNMXCORD bounds;
    
    sqlite3_stmt *statement;
    NSString *query = [[NSString alloc] init];
    
    [self open];
    [self startTransaction];
    [self executeCmd:"CREATE INDEX IF NOT EXISTS PARCELPOLY_pinindex ON PARCELPOLY ('PID' ASC)"];
    [self commitTransaction];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT LAT,LON FROM PARCELPOINT Where PID = '%@'",
                     PID];
            break;
            
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT PARCELPOLY.id,minX,maxX,minY,maxY FROM PARCELPOLY,PARCELPOLY_index WHERE PARCELPOLY.PID='%@' AND PARCELPOLY_index.id=PARCELPOLY.id",
                     PID];
            break;
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetBoundsForPID");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        bounds.xmn = sqlite3_column_double(statement, 1);
        bounds.xmx = sqlite3_column_double(statement, 2);
        bounds.ymn = sqlite3_column_double(statement, 3);
        bounds.ymx = sqlite3_column_double(statement, 4);
    }
    
    SQLOK(sqlite3_finalize(statement), "getBoundsforPID");
    
    [self close];
    return bounds;
}

- (NSMutableArray *)getBoundaryAreaTypes
{
    NSMutableArray * types=[[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    NSString *query = [[NSString alloc] init];
    
    [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = @"SELECT DISTINCT TYPE FROM BOUNDARYAREA";
            break;
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetBoundaryAreaTypes");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR type = (LPSTR)sqlite3_column_text(statement, 0);
        NSString *outString = [NSString stringWithFormat:@"%s", type];
        [types addObject:outString];
    }
    
    SQLOK(sqlite3_finalize(statement), "getBoundaryAreaTypes");
    
    [self close];
    
    return types;
}

- (NSMutableArray *)getBoundaryAreaDataForType:(NSString *)type
{
    NSMutableArray * data = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    NSString *query = [[NSString alloc] init];
    
    [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT id,NAME FROM BOUNDARYAREA WHERE TYPE='%@'",type];
            break;
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetBoundaryAreaData");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR name = (LPSTR)sqlite3_column_text(statement, 1);
        BoundaryAreaData *baData = [[BoundaryAreaData alloc] init];
        baData.refno = refno;
        baData.name = [NSString stringWithUTF8String:name];
        [data addObject:baData];
    }
    
    SQLOK(sqlite3_finalize(statement), "getBoundaryAreaData");
    
    [self close];
    return data;
}

- (MNMXCORD)getBoundaryAreaBounds:(int)refno
{
    MNMXCORD bounds;
    
    sqlite3_stmt *statement;
    NSString *query = [[NSString alloc] init];
    
    [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT LAT,LON FROM PARCELPOINT Where PID = %i",
                     refno];
            break;
            
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BOUNDARYAREA.id,minX,maxX,minY,maxY FROM BOUNDARYAREA,BOUNDARYAREA_index WHERE BOUNDARYAREA.ID=%i AND BOUNDARYAREA_index.id=BOUNDARYAREA.id",
                     refno];
            break;
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetBoundsForBoundary");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        bounds.xmn = sqlite3_column_double(statement, 1);
        bounds.xmx = sqlite3_column_double(statement, 2);
        bounds.ymn = sqlite3_column_double(statement, 3);
        bounds.ymx = sqlite3_column_double(statement, 4);
    }
    
    SQLOK(sqlite3_finalize(statement), "getBoundsforBoundary");
    
    [self close];
    return bounds;
}

- (NSMutableArray *)getPIDsMatchingString:(NSString *)matchChar
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PIN FROM PROPINFO Where PIN LIKE '%@%%'",
                       matchChar];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetPIDsMatchingString");
    
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
                                           limitOf:(int)lim
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    int n = 0;
    
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PIN,\"Owner_Name\" FROM PROPINFO Where PIN >= '%@'",
                       matchChar];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0),"prepareGetPIDsMatchingString");
    
    while (n++ < lim && sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 0);
        
        if (strncasecmp(cpid, matchChar.UTF8String, matchChar.length))
            break;
        
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
    NSString *lastName = [NSString stringWithFormat:@"%@%@", matchChar, @"Z"];
    [self open];
    //NSString *query = [NSString stringWithFormat:@"SELECT HOUSE_NUM,STREET_NAME,UDIValue,AdditionalValue FROM ADDLOC4 Where STREET_NAME LIKE '%@%%' AND HOUSE_NUM = %i",matchChar,houseNumber];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT HOUSENUM,STREET,PID,\"Owner Name\" FROM PROPINFO Where STREET LIKE '%@%%' AND HOUSENUM = %i",
                     matchChar,houseNumber];
            break;
            
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BLDG_NUM,STREETNAME,PIN,\"Owner_Name\" FROM PROPINFO Where STREETNAME >= '%@' AND STREETNAME < '%@' AND BLDG_NUM = %i",
                     matchChar.uppercaseString, lastName.uppercaseString, houseNumber];
            break;
    }
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0), "prepareGetPIDsMatchingAddress");
    
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

- (NSString *)pickPID:(LLPOINT *)pt
{
    NSString *minPID = [[NSString alloc] init];
    dbounds bnds;
    CGFloat d, mind = DBL_MAX;
    CGFloat pickap = 0.005;
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
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "preparePickPID");
    
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
    NSString *query = [NSString stringWithFormat:@"SELECT \"Owner_Name\" FROM PROPINFO Where PIN = '%@'",
                       PID];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetOwnerNameForPID");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR owner = (LPSTR)sqlite3_column_text(statement, 0);
        ownerName = [NSString stringWithUTF8String:owner];
    }
    
    SQLOK(sqlite3_finalize(statement), "getOwnerNameForPID");
    [self close];
    return ownerName;
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

- (void)displayParcels:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
{
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANBoundsToBounds(platlonBounds, pvbounds);
    
    NSString *query;
    sqlite3_stmt *statement;
    LPSTR pid;
    DPOINT BasePt;
    int numPoints,numLoops, refno;
    CGFloat emvTotal, specAssmt;
    LPSTR homeStead, useCode, useDesc, taxExempt, owner;
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
            query = [NSString stringWithFormat:@"SELECT PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USE1_DESC,USE2_DESC,TAX_EXEMPT,EMV_TOTAL,SPEC_ASSES,OWNER_NAME  FROM PARCELPOLY,PARCELPOLY_index,PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PIN=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
   
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareDisplayParcels");
    NSLog (@"Prepared");
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        refno = sqlite3_column_int(statement,7);
        homeStead = (LPSTR)sqlite3_column_text(statement, 8);
        useCode = (LPSTR)sqlite3_column_text(statement, 9);
        useDesc = (LPSTR)sqlite3_column_text(statement, 10);
        taxExempt = (LPSTR)sqlite3_column_text(statement, 11);
        emvTotal = (CGFloat)sqlite3_column_double(statement, 12);
        specAssmt = (CGFloat)sqlite3_column_double(statement, 13);
        owner = (LPSTR)sqlite3_column_text(statement, 14);
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
                    
                case 4://Special Assessment
                    if (specAssmt > 0)
                        alpha = 0.6;
                    
                    color = [[UIColor alloc]initWithRed:1.0
                                                  green:1.0
                                                   blue:0.0
                                                  alpha:alpha];
                    break;
                    
                case 5://tax_exempt
                    if (*taxExempt == taxExemptCode)
                        alpha = 0.6;
                    
                    color = [[UIColor alloc]initWithRed:0.0
                                                  green:1.0
                                                   blue:0.0
                                                  alpha:alpha];
                case 6://tax_forfeit
                    if (!strcasecmp (owner,"HENNEPIN FORFEITED LAND"))
                        alpha = 0.8;
                    
                    color = [[UIColor alloc]initWithRed:0.0
                                                  green:1.0
                                                   blue:1.0
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
    
    SQLOK(sqlite3_finalize(statement), "displayParcels");
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

- (char)useCodeClass:(char *)useCode
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

- (void)displayText:(NSString *)text
            atPoint:(LPDPOINT)pviewPoint
          maxPixels:(CGFloat)maxPixels
            context:(CGContextRef)context
{
    CGFloat fontSize = 24.0;
    CGFloat minFontSize = 12.0;
    CGFloat size = sqrtf(maxPixels);
    static int yoffinc = 0;
   
    while (fontSize > minFontSize)
    {
        CGContextSaveGState(context);
        text = [text stringByReplacingOccurrencesOfString:@"&"
                                               withString:@"\n&\n"];
        
        CGMutablePathRef path = CGPathCreateMutable();
        
        
        CTFontRef fontRef = CTFontCreateWithName((CFStringRef)NULL,
                                                 fontSize, NULL);
        
        NSMutableParagraphStyle *style = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
        style.alignment = NSTextAlignmentCenter;
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (__bridge id)fontRef, kCTFontAttributeName,
                                    style, kCTParagraphStyleAttributeName,
                                    nil];
        
        CFRelease(fontRef);
        
        CGSize textSize = [text sizeWithAttributes:attributes];
        
        if (textSize.width < size)
        {
            CGFloat yoffset = (textSize.height / 2);// * (yoffinc++ % 2);
            CGPathAddRect(path, NULL, CGRectMake((pviewPoint->x - (size / 2.0)),
                                                 (pviewPoint->y - size + yoffset), size, size));
            
            NSAttributedString *attString = [[NSAttributedString alloc] initWithString:text
                                                                            attributes:attributes];
            
            CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
            CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attString.length), path, NULL);
            
            CTFrameDraw(frame, context);
            CFRelease(frame);
            CFRelease(path);
            CFRelease(framesetter);
            CGContextRestoreGState(context);
            return;
        }
        
        fontSize -= 2.0;
        CGContextRestoreGState(context);
    }
}

- (void)displayParcelText:(CGContextRef)context
                 LLBounds:(MNMXCORD *)platlonBounds
               viewBounds:(MNMXCORD *)pvbounds
{
    if (!CRAPI.sharedInstance.parcelTextOption)
        return;
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANBoundsToBounds(platlonBounds, pvbounds);
    
    DPOINT p1, p2;
    CGFloat boundsWidthInMeters, boundsHeightInMeters;
    p1.x = platlonBounds->xmn;
    p1.y = platlonBounds->ymn;
    p2.x = platlonBounds->xmn;
    p2.y = platlonBounds->ymx;
    boundsHeightInMeters = ArcDistance(p1, p2);
    p2.x = platlonBounds->xmx;
    p2.y = platlonBounds->ymn;
    boundsWidthInMeters = ArcDistance(p1, p2);
    CGFloat boundsInAcres = boundsWidthInMeters * boundsHeightInMeters * ACRES_PER_SQMETER;
    CGFloat boundsInPixels = (pvbounds->xmx - pvbounds->xmn) * (pvbounds->ymx - pvbounds->ymn);
    CGFloat acresToPixelsFactor = fabs(boundsInPixels / boundsInAcres);
    NSString *query;
    sqlite3_stmt *statement;
    LPSTR pid;
    DPOINT BasePt, viewPoint;
    CGFloat emvTotal, specAssmt, acres;
    LPSTR homeStead,useCode,useDesc,taxExempt,owner;
    char homeSteadCode = 'H';
    char taxExemptCode = 'E';
    NSString *text = @"Test Text\nLine 2";
    NSNumberFormatter *dollarFmt = [[NSNumberFormatter alloc] init];
    dollarFmt.numberStyle = NSNumberFormatterCurrencyStyle;
    dollarFmt.groupingSeparator = @"'";
    dollarFmt.groupingSize = 3;
    dollarFmt.alwaysShowsDecimalSeparator = NO;
    dollarFmt.usesGroupingSeparator = YES;
    dollarFmt.maximumFractionDigits = 0;
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
            query = [NSString stringWithFormat:@"SELECT PIN,LATITUDE,LONGITUDE,ACRES_POLY,HOMESTEAD,USE1_DESC,USE2_DESC,TAX_EXEMPT,EMV_TOTAL,SPEC_ASSES,OWNER_NAME FROM PROPINFO,PROPINFO_index WHERE PROPINFO.id=PROPINFO_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareDisplayParcels");
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        pid = (LPSTR)sqlite3_column_text(statement, 0);
        BasePt.y = sqlite3_column_double(statement,1);
        BasePt.x = sqlite3_column_double(statement,2);
        acres = (CGFloat)sqlite3_column_double(statement, 3);
        homeStead = (LPSTR)sqlite3_column_text(statement, 4);
        useCode = (LPSTR)sqlite3_column_text(statement, 5);
        useDesc = (LPSTR)sqlite3_column_text(statement, 6);
        taxExempt = (LPSTR)sqlite3_column_text(statement, 7);
        emvTotal = (CGFloat)sqlite3_column_double(statement, 8);
        specAssmt = (CGFloat)sqlite3_column_double(statement, 9);
        owner = (LPSTR)sqlite3_column_text(statement, 10);

        CGFloat alpha = 0.0;
        UIColor *color;
        int opt = CRAPI.sharedInstance.parcelTextOption;
        NSNumber *num;
        
        switch (CRAPI.sharedInstance.parcelTextOption)
        {
            case 1://homestead
                num = [[NSNumber alloc] initWithDouble:emvTotal];
                text = [NSString stringWithFormat:@"%s\n%@", owner, [dollarFmt stringFromNumber:num]];
                break;
            
            default:
                break;
        }
        
        viewPoint = TranDPOINT(&BasePt, _pTranLLtoView);
        
        [self displayText:text
                  atPoint:&viewPoint
                maxPixels:acres *acresToPixelsFactor
                  context:context];
    }
    
    SQLOK(sqlite3_finalize(statement), "displayParcelText");
    [self close];
}

- (void)computeStability:(CGFloat *)stability
               openSpace:(CGFloat *)openSpacePCT
           commercialPCT:(CGFloat *)pctCommercial
              totEMVRank:(CGFloat *)rankTotEMV
            inCensusArea:(LPSTR)cenBlock
{
    sqlite3_stmt *statement;
    double sumEMV=0;
    double sumAcres=0;
    double pctAveEMV, pctMedEMV, aveEMV;
    int myTotEMV = *rankTotEMV;
    
    *stability = 0;
    *openSpacePCT = 0;
    *pctCommercial = 0;
    *rankTotEMV = 0;
    NSString *query = [NSString stringWithFormat:@"SELECT ACRES_POLY,USE1_DESC,SALE_DATE,EMV_TOTAL,TOTAL_TAX,HOMESTEAD FROM PROPINFO WHERE CENBLOCK='%s'",
                       cenBlock];
    
    [self open];
    NSMutableArray * array=[[NSMutableArray alloc]init];
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "computeStabilityEtc");
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        CGFloat acres = sqlite3_column_double(statement,0);
        LPSTR useDesc = (LPSTR)sqlite3_column_text(statement, 1);
        LPSTR saleDate = (LPSTR)sqlite3_column_text(statement, 2);
        int totEMV = (int)sqlite3_column_double(statement, 3);
        double totTax = sqlite3_column_double(statement, 4);
        LPSTR homestead = (LPSTR)sqlite3_column_text(statement, 5);
        
        if (*homestead == 'Y')
        {
            NSNumber * emv = [NSNumber numberWithInteger:totEMV];
            [array addObject:emv];
            sumAcres += acres;
            sumEMV += totEMV;
        }
    }
    [array sortUsingComparator: ^(id obj1, id obj2)
     {
         NSNumber *v1 = obj1;
         NSNumber *v2 = obj2;
         
         if (v1 > v2)
             return (NSComparisonResult)NSOrderedDescending;
         
         if (v1 < v2)
             return (NSComparisonResult)NSOrderedAscending;
         
         return (NSComparisonResult)NSOrderedSame;
     }];
    if ([array count])
    {
        int n=1;
        int myStartRank=-1, myEndRank=-1;
        int medianN = (int)array.count / 2;
        int medianM = array.count % 2;
        int medianEMV = 0;
        NSNumber * minEMV = array[0];
        NSNumber * maxEMV = array[array.count-1];
        for (NSNumber * EMVvalue in array)
        {
            if (n == medianN)
                medianEMV = EMVvalue.intValue;
            if (n == medianN + medianM)
                medianEMV = (medianEMV + EMVvalue.intValue) / 2;
            if (EMVvalue.integerValue == myTotEMV)
            {
                if (myStartRank < 0)
                    myStartRank = n;
                myEndRank = n;
            }
            n++;
        }
        aveEMV = sumEMV / [array count];
        pctAveEMV = ((double)myTotEMV / aveEMV) * 100;
        pctMedEMV = ((double)myTotEMV / medianEMV) * 100;
        *rankTotEMV = pctAveEMV;
    }
    SQLOK(sqlite3_finalize(statement), "getReportForPID");
}

- (NSMutableArray *)getReport:(PropDataOption)option
                       forPID:(NSString *)pid
{
    NSMutableArray *report = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    char censusBlock[32];
    [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
        {
            NSString *query = [NSString stringWithFormat:@"SELECT HOUSENUM,HOUSEFRACT,STREET,UNITNUM,ZIPCODE,\"OWNER NAME\",\"TAXPAYER NAME\",\"TAXPAYER ADDR1\",\"TAXPAYER ADDR2\",\"TAXPAYER ADDR3\",PARCEL_DEPTH,PARCEL_FRONTAGE,AREA_SQFT,USECODE,USE_DESC,TAX_EXEMPT,LAND_VALUE,BLDG_VALUE,TOTAL_VALUE,TOTAL_TAX,HOMESTEAD,WTRSHD,PARCELZONE.ZONETYPE,ASSESSMENT_YEAR,Date_of_Query FROM PROPINFO,PARCELZONE WHERE PROPINFO.PID='%s' AND PARCELZONE.PID='%s'",
                       pid.UTF8String,pid.UTF8String];
    
            SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetReportForPID");
            
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
                SQLOK(sqlite3_finalize(statement), "getReportForPID");
            }
        }
            break;
            
        case PROJECT_METROGIS:
        {
            NSString *query = [NSString stringWithFormat:@"SELECT BLDG_NUM,STREETNAME,UNIT_INFO,CITY,CITY_USPS,ZIP,ZIP4,PLAT_NAME,BLOCK,LOT,ACRES_POLY,ACRES_DEED,USE1_DESC,USE2_DESC,USE3_DESC,USE4_DESC,MULTI_USES,LANDMARK,OWNER_NAME,OWNER_MORE,EMV_LAND,EMV_BLDG,EMV_TOTAL,TAX_CAPAC,TOTAL_TAX,SPEC_ASSES,SALE_DATE,SALE_VALUE,CENBLOCK FROM PROPINFO WHERE PROPINFO.PIN='%s'",
                               pid.UTF8String];
            
            SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetReportForPID");
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
                LPSTR saleDate = (LPSTR)sqlite3_column_text(statement, 26);
                CGFloat saleValue = sqlite3_column_double(statement, 27);
                LPSTR cenBlock = (LPSTR)sqlite3_column_text(statement,28);
                strcpy (censusBlock,cenBlock);
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
                
                line = [NSString stringWithFormat:@"Last Sale Date:%s", saleDate];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Sale Value:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)saleValue]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Building EMV:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)bldgEMV]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Total EMV:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)totalEMV]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Total Tax:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)totalTax]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Special Assessment:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)specAsses]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Tax Capacity:%@", [dollarFmt stringFromNumber:[NSNumber numberWithInt:(int)taxCapac]]];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"City USPS:%s", cityUSPS];
                [report addObject:line];
                
                if (*zip4)
                    line = [NSString stringWithFormat:@"Zipcode:%s-%s", zipcode,zip4];
                else
                    line = [NSString stringWithFormat:@"Zipcode:%s", zipcode];
                [report addObject:line];
           
                line = [NSString stringWithFormat:@"Plat:%s", platName];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Block:%s", block];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Lot:%s", lot];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Acres:%.2f (deed) %.2f (map)", acresDeed,acresPoly];
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
                
                SQLOKpd(sqlite3_finalize(statement), "getReportForPID");
                
                double stability, openSpacePCT, pctCommercial, rankTotEMV;
                rankTotEMV = totalEMV;
                [self computeStability:&stability openSpace:&openSpacePCT commercialPCT:&pctCommercial totEMVRank:&rankTotEMV inCensusArea:censusBlock];
                line = [NSString stringWithFormat:@"Stability:%.1f years", stability];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Open Space:%.1f%%", openSpacePCT];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Percent Commercial:%.1f%%", pctCommercial];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"EMV Rank:%.1f%%", rankTotEMV];
                [report addObject:line];
                
                line = [NSString stringWithFormat:@"Census Block:%s", cenBlock];
                [report addObject:line];
            }
            
            else
                SQLOKpd(sqlite3_finalize(statement), "getReportForPID");
        }
    }
   
    [self close];
    return report;
}

#define MAXHITS 4096
#define MAXOFFSETS 262136L
#define	MAXWIOFFSETS 100
#define MAXPARTS 32

typedef struct	{char Word[8];
    short Seq;
    short nOffsets;
    long Offsets[MAXWIOFFSETS];} WORDINDEX;
typedef WORDINDEX *LPWORDINDEX;

int GetWIHits(LPINT Hits, int nParts, LPINT nPartOffsets, LPINT *pPartOffsets, int MaxHits)
{
    int	nHits = 0;
    int	Order[32];
    int	i,j,k,ihit, ipart, nValidParts=0,ii;
    LPINT pOff1, pOff2;
    BOOL HaveHit;
    
    Order[0] = 0;
    
    for (ipart = 1; ipart < nParts; ipart++)
    {
        for (i = 0; i < ipart; i++)
        {
            if (nPartOffsets[ipart] < nPartOffsets[Order[i]])
            {
                for (j = ipart; j > i; j--)
                    Order[j] = Order[j - 1];
                
                Order[i] = ipart;
                goto Inserted;
            }
        }
        
        Order[ipart] = ipart;
 
    Inserted:;
    }
    
    for (ipart = 0; ipart < nParts; ipart++)
    {
        if (nPartOffsets[ipart] < INT_MAX)
            nValidParts++;
    }
    
    if (!nValidParts)
        return 0;
    
    pOff1 = pPartOffsets[Order[0]];
    
    for (i = 0; i < nPartOffsets[Order[0]]; i++)
    {
        HaveHit = TRUE;
        
        for (j = 1; j < nValidParts; j++)
        {
            pOff2 = pPartOffsets[Order[j]];
            
            for (k = 0; k < nPartOffsets[Order[j]] ;k++)
            {
                if (*pOff1 == *pOff2++)
                    goto Next;
            }
            
            HaveHit = FALSE;
            
        Next:
            if (!HaveHit)
                goto NextOff;
        }
        
        if (nHits >= MaxHits)
            break;
        
        for (ihit = 0; ihit < nHits; ihit++)
        {
            if (Hits[ihit] == *pOff1)
                goto NextOff;
        }
        
        Hits[nHits++] = *pOff1;
        
        if (!*pOff1)
            ii = 1;
        
    NextOff:
        pOff1++;
       // if (GSSiPeekMessage(&msg,hwndCtl,WM_KEYDOWN,WM_KEYDOWN,PM_NOREMOVE))
       //     break;
    }
    
    return nHits;
}

- (NSMutableArray *)getOwnersMatchingString:(NSString *)INstring
{
    if (!INstring)
        return nil;
    
    NSMutableArray *ownerArray = [[NSMutableArray alloc] init];
    int	nParts, ipart, iparttest, nOwners;
    LPWORDINDEX	pRec;
    WORDINDEX Rec;
    LPINT partOffsets[MAXPARTS], partoff;
    int nPartOffsets[MAXPARTS], PartLen[MAXPARTS], PartLenTest[MAXPARTS];
    LPSTR PartLoc[MAXPARTS], PartLocTest[MAXPARTS];
    int Trigger = 3, nHits = 0, nowner;
    BOOL GetNext = TRUE;
    char Name[66];
    LPINT Hits = malloc(MAXHITS * sizeof(int));
    sqlite3_stmt *statement;

    NSString *string = INstring.uppercaseString;
    strncpy(Name, string.UTF8String, 64);
    nParts = GetNameParts(Name, PartLoc, PartLen, MAXPARTS);
    
    for (ipart = 0; ipart < nParts; ipart++)
    {
        nPartOffsets[ipart] = 0;
        partOffsets[ipart] = 0;
    }
    
    for (ipart = 0; ipart < nParts; ipart++)
    {
        if (PartLen[ipart] >= Trigger)
        {
            char endWord[12] = {0};
            [self open];
            
            strncpy (endWord, PartLoc[ipart], 8);
            
            for (int i= (int)strlen(PartLoc[ipart]); i < 11; i++)
                endWord[i] = 'Z';
            
            endWord[11] = 0;
            
            NSString *query = [NSString stringWithFormat:@"SELECT Word,NOFFSETS,OFFSETS FROM NAMEINDEX WHERE Word >='%s' AND Word < '%s'",
                               PartLoc[ipart],endWord];
            
            SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepare1GetOwners");
            
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                LPSTR word = (LPSTR)sqlite3_column_text(statement, 0);
                int nOffsets = sqlite3_column_int(statement,1);
                LPINT pOffsets = (LPINT)sqlite3_column_blob(statement, 2);
                
                if (nPartOffsets[ipart] + nOffsets >= MAXOFFSETS)
                    GetNext = FALSE;
                
                else
                {
                    partOffsets[ipart] = realloc(partOffsets[ipart], (nPartOffsets[ipart]+nOffsets)*sizeof(int));
                    partoff = partOffsets[ipart] + nPartOffsets[ipart];
                    memmove (partoff,pOffsets,nOffsets*sizeof(int));
                    nPartOffsets[ipart] += nOffsets;
                }
            }
            
            SQLOKpd(sqlite3_finalize(statement), "getOwners");
            
            if (!nPartOffsets[ipart])
                GetNext = FALSE;
        }
        
        else
            nPartOffsets[ipart] = INT_MAX;
    }
    
    if (GetNext && nParts > 1)
        nHits = GetWIHits (Hits, nParts, nPartOffsets, partOffsets, MAXHITS);

    for (ipart = 0; ipart < nParts; ipart++)
    {
        if (partOffsets[ipart])
            free (partOffsets[ipart]);
    }
    
    if (nHits)
    {
        NSString *inList=[[NSString alloc] init];
        char delim = 0;
        
        for (int i = 0; i < nHits; i++)
        {
            inList = [inList stringByAppendingString:[NSString stringWithFormat:@"%c%i", delim, Hits[i]]];
            delim = ',';
        }
        
        NSString *query = [NSString stringWithFormat:@"SELECT PIN,OWNER_NAME,BLDG_NUM,STREETNAME,CITY, OWNER_MORE,TAX_NAME FROM PROPINFO WHERE id IN(%@)",
                           inList];
        
        SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepare2GetOwners");
        
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            LPSTR pin = (LPSTR)sqlite3_column_text(statement, 0);
            LPSTR owner = (LPSTR)sqlite3_column_text(statement,1);
            LPSTR house = (LPSTR)sqlite3_column_text(statement,2);
            LPSTR street = (LPSTR)sqlite3_column_text(statement,3);
            LPSTR city = (LPSTR)sqlite3_column_text(statement,4);
            char testName[256];
            strcpy(testName,owner);
            int nPartsTest = GetNameParts(testName, PartLocTest, PartLenTest, MAXPARTS);
            BOOL ShowThisOwner = YES;
            
            for (ipart = 0; ipart < nParts; ipart++)
            {
                for (iparttest = 0; iparttest <nPartsTest; iparttest++)
                {
                    if (!strncasecmp (PartLoc[ipart], PartLocTest[iparttest], PartLen[ipart]))
                    {
                        *PartLocTest[iparttest] = 0;
                        goto FoundPart;
                    }
                }
                
                ShowThisOwner = NO;
                break;
                
            FoundPart:;
            }
            
            if (ShowThisOwner)
            {
                NSString *output = [NSString stringWithFormat:@"%s\t%s\t%s %s, %s",
                                    owner, pin, house, street, city];
                
                [ownerArray addObject:output];
            }
        }
        
        SQLOKpd(sqlite3_finalize(statement), "getOwners");
    }
    /*
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
*/
    free (Hits);
    [self close];
    return ownerArray;
}

void TRAN (void *source, void *dest, size_t count)
{
    memmove(dest, source, count);
    return;
}

LPSTR REPLAC(LPSTR STRING, LPSTR OLD, LPSTR NEW, int MAXLEN)
{
    LPSTR IBEG, loc, new;
    
    short STRLEN, CURLEN, OLDLEN, NEWLEN, IDIFF;
    long  MOVELEN;
    
    OLDLEN = strlen(OLD);
    NEWLEN = strlen(NEW);
    STRLEN = strlen(STRING);
    IBEG = STRING;
    IDIFF = NEWLEN - OLDLEN;
    
    while (*IBEG)
    {
        IBEG = strstr(IBEG, OLD);
        
        if (!IBEG)
            goto Exit;
        
        if (!IDIFF)
        {
            new = NEW;
            
            while (*new)
                *IBEG++ = *new++;
        }
        
        else if (IDIFF < 0)
        {
            loc = IBEG + OLDLEN;
            new = NEW;
            
            while (*new)
                *IBEG++ = *new++;
            
            new = IBEG;
            
            while (*loc)
                *new++ = *loc++;
            
            *new = 0;
            STRLEN += IDIFF;
        }
        
        else
        {
            CURLEN = IBEG - STRING;
            MOVELEN = STRLEN - CURLEN;
            STRLEN += IDIFF;
            
            if (STRLEN > MAXLEN)
            {
                STRLEN = MAXLEN;
                goto Exit;
            }
            
            TRAN (IBEG + OLDLEN, IBEG + NEWLEN, (size_t)MOVELEN);
            new = NEW;
            
            while (*new)
                *IBEG++ = *new++;
        }
    }
    
Exit:
    loc = STRING + STRLEN;
    *loc = '\0';
    return (STRING);
}

LPSTR ReplaceChar(LPSTR str, char from, char to)
{
    LPSTR Instr = str;
    
    while (*str)
    {
        if (*str == from)
            *str = to;
        
        str++;
    }
    
    return Instr;
}

LPSTR OneSpace(LPSTR Arg1)
{
    BOOL LastWasBlank, HaveNonBlank = NO;
    LPSTR OutLoc, SaveArg1, SaveOutLoc;
    long l;
    
    Truncate(Arg1);
    SaveArg1 = Arg1;
    l = strlen(Arg1);
    
    if (!l)
        return (Arg1);
    
    OutLoc = malloc(l + 1);
    SaveOutLoc = OutLoc;
    LastWasBlank = NO;
    
    while (*Arg1)
    {
        if (*Arg1 == '\t')
            *Arg1 = ' ';
        
        if (*Arg1 != ' ')
        {
            if (LastWasBlank && HaveNonBlank)
                *OutLoc++ = ' ';
            
            LastWasBlank = NO;
            HaveNonBlank = YES;
            *OutLoc++ = *Arg1;
        }
        
        else
            LastWasBlank = YES;
        
        Arg1++;
    }
    
    *OutLoc = 0;
    strcpy(SaveArg1, SaveOutLoc);
    return (Arg1);
}

LPSTR Truncate(LPSTR Text)
{
    LPSTR rtn, EndChar;
    
    rtn = Text;
    EndChar = strchr(Text, 0);
    
    while (EndChar > Text)
    {
        EndChar--;
        
        if (*EndChar != ' ')
            goto Exit;
        
        *EndChar = 0;
    }
    
Exit:
    return (rtn);
}

int GetNameParts(LPSTR Field, LPSTR *pLoc, LPINT pLen, int MaxParts)
{
    int	nParts = 0;
    LPSTR pWord, pEnd;

    pWord = Field;
    ReplaceChar(Field,'-',' ');
    ReplaceChar(Field,'/',' ');
    ReplaceChar(Field,'(',' ');
    ReplaceChar(Field,')',' ');
    ReplaceChar(Field,'&',' ');
    ReplaceChar(Field,',',' ');
    ReplaceChar(Field,'\'',' ');
    ReplaceChar(Field,'#',' ');
    ReplaceChar(Field,'"',' ');
    ReplaceChar(Field,'.',' ');
    OneSpace(Field);
    
    while (*pWord && nParts < MaxParts)
    {
        if (*pWord == ' ')
            pWord++;
        
        if ((pEnd = strchr (pWord,' ')))
            *pEnd++ = 0;
        
        else
            pEnd = strchr (pWord,0);
        
        *(pLoc + nParts) = pWord;
        *(pLen + nParts++) = (int)strlen(pWord);
        pWord = pEnd;
    }
    
    return nParts;
}

@end