//  SewerData.m
//  GMMobile

extern int keepProcessing;

#import "SewerData.h"
#define COORDINATE_FACTOR 10000000.0

static BOOL createDirectory = YES;
@interface SewerData ()

@property (nonatomic) GSSiPopoverView *popover;

@end

@implementation SewerData

static SewerData *_sewerData;

- (BOOL) continue
{
    if (self.processingID == keepProcessing)
        return YES;
    return NO;
}

- (void)logError:(int)sqlReturn
          method:(char *)method
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i in %s = %i:%s",
                  sqlReturn, method, sqlite3_errcode(_database), sqlite3_errmsg(_database)]);
}

int SQLOKswr(int sqlReturn, char *method)
{
    if (sqlReturn != SQLITE_OK)
    {
        [_sewerData logError:sqlReturn
                      method:method];
    }
    
    return sqlReturn;
}


- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.localFilePath;
        _fileName = @"Sewer.sqlite";
        _path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _fileName];
        _sewerData = (__bridge SewerData *)((__bridge sqlite3 *)((SewerData *)self));
        
    }
    
    return self;
}

- (void)dealloc
{
    CloseTRANS2 (&_pTranLLtoView);
    CloseTRANS2 (&_pTranViewtoLL);
    sqlite3_close(_database);
    NSLog(@"Sewer Database dealloc");
}

- (void)open
{
    if (!_isOpen)
    {
        _isOpen = !SQLOKswr(sqlite3_open(self.path.UTF8String, &_database), "open(Sewer)");
        NSLog(@"Sewer Database open");
        
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                   error:nil].fileSize;
    }
}

- (void)close
{
    SQLOKswr(sqlite3_close(_database),"Close");
    NSLog(@"Sewer Database close");
    _isOpen = NO;
}

- (void)clear
{
    [self close];
    
    BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
                                                       error:nil];
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOKswr(sqlite3_exec(_database, cmd, 0, 0, 0), "Execute cmd");
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOKswr(sqlite3_exec(_database, "BEGIN", 0, 0, 0), "Start transaction");
}

- (void)commitTransaction
{
    SQLOKswr(sqlite3_exec(_database, "COMMIT", 0, 0, 0), "End transaction");
}

- (NSString *)getActualPlatFileName:(NSString *)platID
{
    NSString *outName;
    char name[128];
    strncpy (name, platID.UTF8String, 126);
    LPSTR pU = strrchr(name,'_');
    
    if (pU)
        *pU = 0;
    
    outName = [NSString stringWithUTF8String:name];
    return outName;
}

- (BOOL)loadPlat:(NSString *)platID
    usingPopover:(GSSiPopoverView*)popover
     andDelegate:(id)delegate
{
    BOOL fileExists = NO;
    NSString *actualPlatID = [self getActualPlatFileName:platID];
    NSString *toDir = [NSString stringWithFormat:@"%@/SanPlats", _documentsDirectory];
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", actualPlatID];
    FTPDataPull *pull = FTPDataPull.pull;
    pull.delegate = delegate;
    pull.popover = _popover;
    pull.useOnlyPrimaryFTP = YES;
    pull.option = GET_SANPLAT;
    //pull.ipAddress = http://74.42.137.128/icons/MPLS/;
    
    [popover showAfter:0.5
              withTitle:[NSString stringWithFormat:@"Get Sanitary Plat %@", actualPlatID]];
    
    pull.ftpSiteOveride = @"74.42.137.128";
    pull.usernameOveride = @"GMMobile";
    pull.passwordOveride = @"GeoMaster";
    pull.portOveride = @"21";
    pull.createDirectory = createDirectory;
    pull.returnIfExists = NO;
    
    if ([pull getFile:fileName
        fromDirectory:@"Sewer/Sanitary/Plats"
               toFile:fileName
          toDirectory:toDir
         forceRefresh:NO] == FTPStatusFileExists)
    {
        fileExists = YES;
    }
    
    createDirectory = NO;
    return fileExists;
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
/*- (MNMXCORD)getBoundsForSanPlat:(int)refno
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
}*/

- (NSString *)getSanPlatIDFromRefno:(int)refno
{
    NSString *platID = [[NSString alloc] init];
    return platID;
}
- (void)displayPlats:(CGContextRef)context
                type:(NSString*)platType
            LLBounds:(MNMXCORD *)platlonBounds
          viewBounds:(MNMXCORD *)pvbounds
{
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANBoundsToBounds(platlonBounds, pvbounds);
    
    NSString *query;
    sqlite3_stmt *statement;
    DPOINT BasePt;
    int numPoints,numLoops, refno;
    CGFloat emvTotal, specAssmt;
    LPSTR platID;
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
    query = [NSString stringWithFormat:@"SELECT SANPLATAREAS.id, SANPLATAREAS.PLAT, BasePointX, BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM SANPLATAREAS,SANPLATAREAS_index WHERE SANPLATAREAS.id=SANPLATAREAS_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareDisplayParcels");
    NSLog (@"Prepared");
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        refno = sqlite3_column_int(statement,0);
        platID = (LPSTR)sqlite3_column_text(statement, 1);
        BasePt.x = sqlite3_column_double(statement,2);
        BasePt.y = sqlite3_column_double(statement,3);
        numPoints = sqlite3_column_int(statement,4);
        numLoops = sqlite3_column_int(statement,5);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,6);
        int nBlobBytes = sqlite3_column_bytes(statement,6);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,7);
        nBlobBytes = sqlite3_column_bytes(statement,7);
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
        
        {
            CGFloat alpha = 0.7;
            UIColor *color;
            
            
            color = [[UIColor alloc]initWithRed:1.0
                                                  green:1.0
                                                   blue:0.0
                                                  alpha:alpha];
            [self fillPlat:context
                     nPoints:numPoints
                      points:llpoints
                   withColor:color.CGColor];
        
            [self drawPlat:context
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
- (void)fillPlat:(CGContextRef)context
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

- (void)drawPlat:(CGContextRef)context
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

- (int)pickSanPlat:(LLPOINT *)pt
{
    int minRef = 0;
    dbounds bnds;
    CGFloat d, mind = DBL_MAX;
    CGFloat pickap = 0.005;
    DPOINT p1, p2, minpt;
    NSString *minPlatID=[[NSString alloc] init];
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    bnds.xmn = p1.x - pickap;
    bnds.xmx = p1.x + pickap;
    bnds.ymn = p1.y - pickap;
    bnds.ymx = p1.y + pickap;
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT SANPLATAREAS.id, SANPLATAREAS.PLAT, BasePointX, BasePointY FROM SANPLATAREAS,SANPLATAREAS_index WHERE SANPLATAREAS.id=SANPLATAREAS_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement;
    
    SQLOKswr(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "preparePickPLAT");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR platID = (LPSTR)sqlite3_column_text(statement, 1);
        CGFloat lat = sqlite3_column_double(statement, 2);
        CGFloat lon = sqlite3_column_double(statement, 3);
        p2.x = lon;
        p2.y = lat;
        d = ArcDistance(p1, p2);
        
        if (d < mind)
        {
            mind = d;
            minpt = p2;
            minRef = refno;
            minPlatID = [NSString stringWithUTF8String:platID];
        }
    }
    
    SQLOKswr(sqlite3_finalize(statement), "pickPLAT");
    [self close];
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    NSString *platFile = [NSString stringWithFormat:@"%@/SanPlats/%@.jpg", _documentsDirectory, minPlatID];
    CRAPI.sharedInstance.currentPlatImagePath = platFile;
    return minRef;
}

- (NSMutableArray *)getAllSanPlats
{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    [self open];
    
    NSString *query = @"SELECT PLAT FROM SANPLATAREAS";
    
    sqlite3_stmt *statement;
    
    SQLOKswr(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), "prepareGetAllSanPlats");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR platID = (LPSTR)sqlite3_column_text(statement, 0);
        NSString * plat = [NSString stringWithUTF8String:platID];
        [list addObject:plat];
    }
    
    SQLOKswr(sqlite3_finalize(statement), "getAllSanPlats");
    [self close];
    return list;
}

@end