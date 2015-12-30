//  BoundaryData.m
//  GMMobile

#define COORDINATE_FACTOR 10000000.0

#import "BoundaryData.h"
#import "PropertyData.h"

extern int keepProcessing;
@implementation BoundaryAreaData

@end


@interface BoundaryData ()

@property (nonatomic) LPTRANDATA pTranLLtoView, pTranViewtoLL;

@end

@implementation BoundaryData
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.sharedFilePath;
        _fileName = @"Boundary.sqlite";
        _path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _fileName];
    }
    
    return self;
}

- (void)dealloc
{
    [self close:TRUE];
    NSLog(@"Boundary Database dealloc");
}

- (BOOL)open
{
    BOOL rtn = FALSE;
    if (!_isOpen)
    {
        _isOpen = !SQLOK(sqlite3_open(self.path.UTF8String, &_database), _database);
        NSLog(@"Boundary Database open");
        
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                   error:nil].fileSize;
        rtn = TRUE;
    }
    return rtn;
}

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        SQLOK(sqlite3_close(_database),_database);
        NSLog(@"Boundary Database close");
    }
    _isOpen = NO;
}

- (void)clear
{
    [self close:TRUE];
    
    //BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
    //error:nil];
}

- (int) datasetVersion
{
    int rtn = -1;
    BOOL opened = [self open];
    if (_isOpen && _fileSize > 0)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT max(Version) FROM BOUNDARY_VERSION"];
        
        sqlite3_stmt *statement = NULL;
        
        SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
        
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            LPSTR version = (LPSTR)sqlite3_column_text(statement, 0);
            
            if (version)
                rtn = atoi(version);
        }
        
        SQLOK(sqlite3_finalize(statement), _database);
    }
    [self close:opened];
    if ( _fileSize > 100)
        rtn = 0;
    return rtn;
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOK(sqlite3_exec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOK(sqlite3_exec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOK(sqlite3_exec(_database, "COMMIT", 0, 0, 0),_database);
}


-(void)displayBoundary:(int)refno
             inContext:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
             LLBounds:(MNMXCORD *)platlonBounds
           viewBounds:(MNMXCORD *)pvbounds
{
    NSString *query = @"";
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints, numLoops;
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    BOOL opened = [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT PROPINFO.PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USECODE,USE_DESC,TAX_EXEMPT,TOTAL_VALUE FROM PARCELPOLY,PARCELPOLY_index, PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PID=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            break;
            
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,BOUNDARYAREA.id FROM BOUNDARYAREA WHERE BOUNDARYAREA.id=%i",
                     refno];
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        
        if (numPoints != 0)
        {
            numLoops = sqlite3_column_int(statement,3);
            int *polyPartLen = (int *)sqlite3_column_blob(statement,4);
            //int nBlobBytes = sqlite3_column_bytes(statement,4);
            LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
            //nBlobBytes = sqlite3_column_bytes(statement,5);
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
            if (CRAPI.sharedInstance.showPolylineForBounds)
            {
                UIColor *boundaryColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.80];
                [self drawBoundary:context
                           nPoints:numPoints
                            nLoops:numLoops
                           partLen:polyPartLen
                            points:llpoints
                         withColor:boundaryColor.CGColor];
            }
            
            free(llpoints);
        }
    }
 
    SQLOK(sqlite3_finalize(statement), _database);
    [self close:opened];
}

- (void)drawBoundary:(CGContextRef)context
             nPoints:(int)np
              nLoops:(int)nLoops
             partLen:(int *)pPartLen
              points:(LPDPOINT)pPoints
           withColor:(CGColorRef)color
{
    CGContextSetLineWidth(context, 10);
    
    if (nLoops > 1)
    {
        int ip = 0;
        //int ii;
        
        for (int loop = 0; loop < nLoops; loop++)
        {
            CGContextMoveToPoint(context, pPoints[ip].x, pPoints[ip].y);
            ip++;
            //ii = pPartLen[loop];
            
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
        
        //ii = ip;
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

- (BOOL) continue
{
    if (self.processingID == keepProcessing)
        return YES;
    return NO;
}
- (NSMutableArray *)getBoundaryAreaTypes
{
    NSMutableArray * types=[[NSMutableArray alloc] init];
    sqlite3_stmt *statement = NULL;
    NSString *query = [[NSString alloc] init];
    
    BOOL opened = [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = @"SELECT DISTINCT TYPE FROM BOUNDARYAREA";
            break;
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR type = (LPSTR)sqlite3_column_text(statement, 0);
        NSString *outString = [NSString stringWithFormat:@"%s", type];
        [types addObject:outString];
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    
    [self close:opened];
    
    return types;
}

- (NSMutableArray *)getBoundaryAreaDataForType:(NSString *)type
{
    NSMutableArray * data = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement = NULL;
    NSString *query = [[NSString alloc] init];
    
    BOOL opened = [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT id,NAME FROM BOUNDARYAREA WHERE TYPE='%@'",type];
            break;
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR name = (LPSTR)sqlite3_column_text(statement, 1);
        BoundaryAreaData *baData = [[BoundaryAreaData alloc] init];
        baData.refno = refno;
        baData.name = [NSString stringWithUTF8String:name];
        [data addObject:baData];
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    
    [self close:opened];
    return data;
}

- (MNMXCORD)getBoundaryAreaBounds:(int)refno
{
    MNMXCORD bounds = {0};
    
    sqlite3_stmt *statement = NULL;
    NSString *query = [[NSString alloc] init];
    
    BOOL opened = [self open];
    
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
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        bounds.xmn = sqlite3_column_double(statement, 1);
        bounds.xmx = sqlite3_column_double(statement, 2);
        bounds.ymn = sqlite3_column_double(statement, 3);
        bounds.ymx = sqlite3_column_double(statement, 4);
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    
    [self close:opened];
    return bounds;
}

- (LPDPOINT)getPolygonPointsForBoundary:(int)refno
                               numPoints:(int *)numPoints
                                numLoops:(int *)numLoops
                             polyPartLen:(int **)polyPartLen
{
    DPOINT basePoint = {0};
    LPDPOINT llpoints = NULL;
    sqlite3_stmt *statement = NULL;
    if (polyPartLen)
        *polyPartLen = 0;
    BOOL opened = [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points, BOUNDARYAREA.id FROM BOUNDARYAREA WHERE BOUNDARYAREA.id=%i", refno];
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        basePoint.x = sqlite3_column_double(statement, 0);
        basePoint.y = sqlite3_column_double(statement, 1);
        *numPoints = sqlite3_column_int(statement, 2);
        *numLoops = sqlite3_column_int(statement, 3);
        if (*numLoops > 1 && polyPartLen)
        {
            *polyPartLen = malloc (*numLoops * sizeof (int));
            memcpy (*polyPartLen,(int *)sqlite3_column_blob(statement,4),*numLoops * sizeof(int));
        }
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement, 5);
        llpoints = malloc(abs(*numPoints) * sizeof(DPOINT) + 4);
        
        if (*numPoints < 0)
        {
            *numPoints = -*numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < *numPoints; i++)
            {
                llpoints[i].x = (basePoint.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (basePoint.y + offsetPoints16[i].y / COORDINATE_FACTOR);
            }
        }
        
        else for (int i = 0; i < *numPoints; i++)
        {
            llpoints[i].x = (basePoint.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[i].y = (basePoint.y + offsetPoints[i].y / COORDINATE_FACTOR);
        }
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    [self close:opened];
    
    return llpoints;
}

-(void)displayLandUse:(CGContextRef)context
            llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
{
    NSString *query = @"";
    //NSString *querys;
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints, useCode;
    //int numLoops;
    PropertyData * pd = [[PropertyData alloc]init];
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    BOOL pdopened = [pd open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE FROM LANDUSE,LANDUSE_index WHERE LANDUSE.id=LANDUSE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            //querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
    }
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), pd.database);
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        //numLoops = sqlite3_column_int(statement,3);
        //int *polyPartLen = (int *)sqlite3_column_blob(statement,4);
        //int nBlobBytes = sqlite3_column_bytes(statement,4);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
        //nBlobBytes = sqlite3_column_bytes(statement,5);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        useCode = sqlite3_column_int(statement,6);
        
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
        
        /*[self drawUseCode:context
                  nPoints:numPoints
                   nLoops:numLoops
                  partLen:polyPartLen
                   points:llpoints
                withColor:UIColor.redColor.CGColor];*/
        if (useCode >=160 && useCode <161)
            [self fillUseCode:context
                  nPoints:numPoints
                   points:llpoints
                withColor:UIColor.redColor.CGColor];
    }
    
    SQLOK(sqlite3_finalize(statement), pd.database);
    [pd close:pdopened];
}

- (void)drawUseCode:(CGContextRef)context
             nPoints:(int)np
              nLoops:(int)nLoops
             partLen:(int *)pPartLen
              points:(LPDPOINT)pPoints
           withColor:(CGColorRef)color
{
    CGContextSetLineWidth(context, 5);
    
    if (nLoops > 1)
    {
        int ip = 0;
        //int ii;
        
        for (int loop = 0; loop < nLoops; loop++)
        {
            CGContextMoveToPoint(context, pPoints[ip].x, pPoints[ip].y);
            ip++;
            //ii = pPartLen[loop];
            
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
        
        //ii = ip;
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
- (void)fillUseCode:(CGContextRef)context
           nPoints:(int)np
            points:(LPDPOINT)pPoints
         withColor:(CGColorRef)color
{
    //CGContextSetLineWidth(context, 3);
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


@end