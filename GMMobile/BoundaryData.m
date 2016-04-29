//  BoundaryData.m
//  GMMobile

#define COORDINATE_FACTOR 10000000.0

#import "BoundaryData.h"
#import "PropertyData.h"
#import "CCodeLibrary/NVTextDrawing.h"
#import "CCodeLibrary/NVColor.h"
#import "ConfigurationControl.h"

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

-(void)displayCircularBoundaryAt:(LLPOINT)pt
                      withRadius:(double)radiusInMeters
                          asMask:(CGFloat)mask
                       inContext:(CGContextRef)context
                       llCorners:(CORNERPOINTS *) latlonCornerPoints
                        LLBounds:(MNMXCORD *)platlonBounds
                      viewBounds:(MNMXCORD *)pvbounds
{
    int numPoints = 256;
    
    LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
    double ainc = (HALFPI * 4) / numPoints;
    double az = 0;
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    for (int i=0;i<numPoints-1;i++,az+=ainc)
    {
        llpoints[i] = NewLatLong(pt.lat, pt.lon, radiusInMeters, az);
        llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
    }
    llpoints[numPoints-1] = llpoints[0];
    if (CRAPI.sharedInstance.showPolylineForBounds)
    {
        UIColor *boundaryColor = [UIColor colorWithRed:0.75 green:0 blue:0.25 alpha:0.60];
        [self drawBoundary:context
                   nPoints:numPoints
                    nLoops:0
                   partLen:0
                    points:llpoints
                 withColor:boundaryColor.CGColor];
    }
    if (mask)
    {
        UIColor *maskColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:mask];
        
        CreateMask(&llpoints, &numPoints,pvbounds);
        [self fillUseCode:context
                  nPoints:numPoints
                   points:llpoints
                withColor:maskColor.CGColor];
        
    }
    
    free(llpoints);
   
}

-(void)displayBoundary:(int)refno
                ofType:(NSString*)areaType
                asMask:(CGFloat)mask
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
    NSString * table = [self getTableNameFromType:areaType];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            query = [NSString stringWithFormat:@"SELECT PROPINFO.PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USECODE,USE_DESC,TAX_EXEMPT,TOTAL_VALUE FROM PARCELPOLY,PARCELPOLY_index, PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PID=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            break;
            
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,id FROM %@ WHERE id=%i",table,
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
                UIColor *boundaryColor = [UIColor colorWithRed:0.75 green:0 blue:0.25 alpha:0.60];
                [self drawBoundary:context
                           nPoints:numPoints
                            nLoops:numLoops
                           partLen:polyPartLen
                            points:llpoints
                         withColor:boundaryColor.CGColor];
            }
            if (mask)
            {
                UIColor *maskColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:mask];
                
                CreateMask(&llpoints, &numPoints,pvbounds);
                [self fillUseCode:context
                          nPoints:numPoints
                           points:llpoints
                        withColor:maskColor.CGColor];
                
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
    if (self.processingID == CRAPI.sharedInstance.keepProcessing)
        return YES;
    return NO;
}
- (NSMutableArray *)getBoundaryAreaTypes
{
    NSMutableArray * types=[[NSMutableArray alloc] init];
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes)
    {
        [types addObject:@"Entire City"];
        [types addObject:@"Minneapolis Precincts"];
        [types addObject:@"Minneapolis Wards"];
        [types addObject:@"Minneapolis Neighborhoods"];
        [types addObject:@"Minneapolis Sectors"];
        [types addObject:@"Other"];
    }
    else
    {
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
    }
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
- (NSString *)getTableNameFromType:(NSString*)areaType
{
    NSString * table = [NSString stringWithFormat:@"CENSUS%@POLY",areaType];
    
    if ([areaType isEqualToString:@"Minneapolis Precincts"] ||
        [areaType isEqualToString:@"Minneapolis Wards"] ||
        [areaType isEqualToString:@"Minneapolis Sectors"] ||
        [areaType isEqualToString:@"Minneapolis Neighborhoods"] ||
        [areaType isEqualToString:@"BOUNDARY"])
    {
        table = @"BOUNDARYAREA";
    }
    return table;
}


+ (int)getBoundaryAreaRefnoForType:(NSString *)type
                           andName:(NSString *)name
{
    BoundaryData *bad = [[BoundaryData alloc]init];
    
    int refno = 0;
    sqlite3_stmt *statement = NULL;
    NSString *query = [[NSString alloc] init];
    NSString * table = [bad getTableNameFromType:type];
    
    BOOL opened = [bad open];

    if ([type isEqualToString:@"Minneapolis Precincts"] ||
        [type isEqualToString:@"Minneapolis Wards"] ||
        [type isEqualToString:@"Minneapolis Sectors"] ||
        [type isEqualToString:@"Minneapolis Neighborhoods"])
    {
        table = @"BOUNDARYAREA";
        query = [NSString stringWithFormat:@"SELECT id FROM %@ WHERE TYPE='%@' AND NAME='%@'",table,type,name];

    }
    else
    {
        query = [NSString stringWithFormat:@"SELECT id FROM %@ WHERE %@='%@'",table,type,name];
    }
    SQLOK(sqlite3_prepare_v2(bad.database, query.UTF8String, -1, &statement, 0), bad.database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        refno = sqlite3_column_int(statement, 0);
    }
    
    SQLOK(sqlite3_finalize(statement), bad.database);
    
    [bad close:opened];
    return refno;
}


- (MNMXCORD)getBoundaryAreaBounds:(int)refno
                           ofType:(NSString*)type
{
    MNMXCORD bounds = {0};
    
    sqlite3_stmt *statement = NULL;
    NSString *query = [[NSString alloc] init];
    NSString * table = [self getTableNameFromType:type];
    
    BOOL opened = [self open];
    
    if ([type isEqualToString:@"BOUNDARY"])
    {
        query = [NSString stringWithFormat:@"SELECT BOUNDARYAREA.id,minX,maxX,minY,maxY FROM BOUNDARYAREA,BOUNDARYAREA_index WHERE BOUNDARYAREA.ID=%i AND BOUNDARYAREA_index.id=BOUNDARYAREA.id",
                 refno];
    }
    else
    {
        query = [NSString stringWithFormat:@"SELECT id,minX,maxX,minY,maxY FROM %@_index WHERE ID=%i",table,refno];

    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        int ref = sqlite3_column_int(statement, 0);
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

-(void) displayLandUse:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
displayCharacteristics:(DisplayCharacteristics *)dc
                themes:(Themes*)themes
           pointInArea:(PointInArea *)pia
{
    NSString *query = @"";
    //NSString *querys;
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints, useCode;
    int numLoops;
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    BOOL opened = [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE FROM LANDUSE,LANDUSE_index WHERE LANDUSE.id=LANDUSE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            //querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
    }
    
    SQLOK(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        numLoops = sqlite3_column_int(statement,3);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,4);
        int nBlobBytes = sqlite3_column_bytes(statement,4);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
        //nBlobBytes = sqlite3_column_bytes(statement,5);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        useCode = sqlite3_column_int(statement,6);
        dc.iValue = useCode;
        
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
        if ([themes setDisplayCharacteristics:dc
                                    displayID:_processingID] != DO_NOT_DISPLAY_ITEM)
        {
            
            [self fillUseCode:context
                      nPoints:numPoints
                       points:llpoints
                    withColor:dc.fillColor.CGColor];
            [self drawUseCode:context
                      nPoints:numPoints
                       nLoops:numLoops
                      partLen:polyPartLen
                       points:llpoints
                    withColor:dc.penColor.CGColor
                     andWidth:dc.width];
        }
    }
    
    SQLOK(sqlite3_finalize(statement), self.database);
    [self close:opened];
}

- (void)drawUseCode:(CGContextRef)context
             nPoints:(int)np
              nLoops:(int)nLoops
             partLen:(int *)pPartLen
              points:(LPDPOINT)pPoints
           withColor:(CGColorRef)color
           andWidth:(CGFloat)width
{
    CGContextSetLineWidth(context, width);
    
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
    
    if (!color)
        return;
    CGContextMoveToPoint(context, pPoints[0].x, pPoints[0].y);
    
    for (int i = 1; i < np; i++)
        CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
    
    CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
    
    if (!CGContextIsPathEmpty(context))
    {
        CGContextSetStrokeColorWithColor(context,color);
        CGContextSetFillColorWithColor(context,color);
        CGContextDrawPath(context, kCGPathFill);
    }
}

-(void)displayCensusAreas:(CGContextRef)context
                    type:(NSString *)type
            llCorners:(CORNERPOINTS *) latlonCornerPoints
             LLBounds:(MNMXCORD *)platlonBounds
           viewBounds:(MNMXCORD *)pvbounds
{
    NSString *query = @"";
    //NSString *querys;
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints;
    NSInteger keyval;
    //int numLoops;
    NSString * key = type;
    NSString * table = [NSString stringWithFormat:@"CENSUS%@POLY",key];
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    BOOL opened = [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,%@ FROM %@,%@_index WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",key,table,table,table,table,
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            //querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
    }
    
    SQLOK(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
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
        keyval = sqlite3_column_int64(statement,6);
        
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
             [self fillUseCode:context
                      nPoints:numPoints
                       points:llpoints
                    withColor:UIColor.redColor.CGColor];
    }
    
    SQLOK(sqlite3_finalize(statement), self.database);
    [self close:opened];
}

- (int)       load:(NSString*)areaType
    toPointInAreas:(PointInAreas*)pias
boundsPointInAreas:(PointInAreas*)bpias
  usingPointInArea:(PointInArea*)pia
         llCorners:(CORNERPOINTS *) latlonCornerPoints
          LLBounds:(MNMXCORD *)platlonBounds
        viewBounds:(MNMXCORD *)pvbounds
{
    //PointInAreas (pias) will be in screen coord while PointInArea(pia) will be in lat/lon
    int nLoaded = 0;
    NSString *query = @"";
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints;
    LPSTR pkeyval;
    NSString * keyval;
    int numLoops;
    int pass = 0;
    NSString * key = areaType;
    NSString * table = [self getTableNameFromType:key];
    
    pias.areaType = areaType;
    BOOL opened = [self open];
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    _pTranViewtoLL = STRANBoundsToCorners(latlonCornerPoints, pvbounds);
    
    if ([areaType isEqualToString:@"Minneapolis Precincts"] ||
        [areaType isEqualToString:@"Minneapolis Wards"] ||
        [areaType isEqualToString:@"Minneapolis Sectors"] ||
        [areaType isEqualToString:@"Minneapolis Neighborhoods"])
    {
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,NAME FROM %@,%@_index WHERE TYPE='%@' AND %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",table,table,areaType,table,table,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    else
    {
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,%@ FROM %@,%@_index WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",key,table,table,table,table,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
        
    }
    //querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
NextPass:
    SQLOK(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        BOOL haveInPoint = FALSE;
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        numLoops = sqlite3_column_int(statement,3);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,4);
        //int nBlobBytes = sqlite3_column_bytes(statement,4);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
        //nBlobBytes = sqlite3_column_bytes(statement,5);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        pkeyval = (LPSTR)sqlite3_column_text(statement,6);
        keyval = [NSString stringWithUTF8String:pkeyval];
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                if (!pass && (!pia || [pia DPointInArea:&llpoints[i]] == 1))
                    haveInPoint = TRUE;
                llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
            if (!pass && (!pia || [pia DPointInArea:&llpoints[i]] == 1))
                haveInPoint = TRUE;
            llpoints[i] = TranDPOINT(&llpoints[i], _pTranLLtoView);
        }
        if (pass || haveInPoint)
        {
            if (!pass)
                nLoaded++;
            [pias loadArea:keyval numPoints:numPoints numLoops:numLoops polyPartLen:polyPartLen points:llpoints];
        }
        free (llpoints);
    }
    
    SQLOK(sqlite3_finalize(statement), self.database);
    [pias areasLoaded:bpias
          convertToLL:_pTranViewtoLL];
    if (pass++ < 3)
        goto NextPass;
    [self close:opened];
    
    return nLoaded;
    
}
- (int) display:(CGContextRef)context
       areaType:(NSString*)areaType
   pointInAreas:(PointInAreas*)pias
      llCorners:(CORNERPOINTS *) latlonCornerPoints
       LLBounds:(MNMXCORD *)platlonBounds
     viewBounds:(MNMXCORD *)pvbounds
{
    int nLoaded = 0;
    NSString *query = @"";
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints;
    LPSTR pkeyval;
    NSString * keyval;
    int numLoops;
    NSString * key = areaType;
    NSString * table = [NSString stringWithFormat:@"CENSUS%@POLY",key];

    BOOL opened = [self open];
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    if ([areaType isEqualToString:@"Minneapolis Precincts"] ||
        [areaType isEqualToString:@"Minneapolis Wards"] ||
        [areaType isEqualToString:@"Minneapolis Sectors"] ||
        [areaType isEqualToString:@"Cities And Townships"] ||
        [areaType isEqualToString:@"Counties"] ||
        [areaType isEqualToString:@"Minneapolis Neighborhoods"])
    {
        table = @"BOUNDARYAREA";
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,NAME FROM %@,%@_index WHERE TYPE='%@' AND %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",table,table,areaType,table,table,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    else
    {
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,%@ FROM %@,%@_index WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",key,table,table,table,table,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
        
    }
    //querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
NextPass:
    SQLOK(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        numLoops = sqlite3_column_int(statement,3);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,4);
        //int nBlobBytes = sqlite3_column_bytes(statement,4);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
        //nBlobBytes = sqlite3_column_bytes(statement,5);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        pkeyval = (LPSTR)sqlite3_column_text(statement,6);
        keyval = [NSString stringWithUTF8String:pkeyval];
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
        CGColorRef color;
        
        if (pias)
            color = [pias colorForArea:keyval];
        
        else
        {
            color = [NVColor randomColorFromArray:NVColor.pastelColors
                                        forString:keyval].CGColor;
        }

        [self fillUseCode:context
                  nPoints:numPoints
                   points:llpoints
                withColor:color];
        
        [self drawUseCode:context
                  nPoints:numPoints
                   nLoops:numLoops
                  partLen:polyPartLen
                   points:llpoints
                withColor:UIColor.blackColor.CGColor
                 andWidth:3];
        
        free (llpoints);
    }
    
    SQLOK(sqlite3_finalize(statement), self.database);
    [self close:opened];
    
    return nLoaded;
    
}

- (int) displayText:(CGContextRef)context
       areaType:(NSString*)areaType
          textOptions:(TextOptions *)to
   pointInAreas:(PointInAreas*)pias
      llCorners:(CORNERPOINTS *) latlonCornerPoints
       LLBounds:(MNMXCORD *)platlonBounds
     viewBounds:(MNMXCORD *)pvbounds
{
    extern MNMXCORD curbounds;
    int nLoaded = 0;
    NSString *query = @"";
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints;
    LPSTR pkeyval;
    NSString * keyval;
    int numLoops;
    NSString * key = areaType;
    NSString * table = [NSString stringWithFormat:@"CENSUS%@POLY",key];
    CGFloat fontSize = 48.0;
    CGFloat minFontSize = 6.0;
    
    BOOL opened = [self open];
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    if ([areaType isEqualToString:@"Minneapolis Precincts"] ||
        [areaType isEqualToString:@"Minneapolis Wards"] ||
        [areaType isEqualToString:@"Cities And Townships"] ||
        [areaType isEqualToString:@"Counties"] ||
        [areaType isEqualToString:@"Minneapolis Sectors"] ||
        [areaType isEqualToString:@"Minneapolis Neighborhoods"])
    {
        table = @"BOUNDARYAREA";
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,NAME FROM %@,%@_index WHERE TYPE='%@' AND %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",table,table,areaType,table,table,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    else
    {
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,%@ FROM %@,%@_index WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",key,table,table,table,table,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
        
    }
    //querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
NextPass:
    SQLOK(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        int *polyPartLen;
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        numLoops = sqlite3_column_int(statement,3);
        int nBlobBytes = sqlite3_column_bytes(statement,4);
        if (nBlobBytes > 0)
            polyPartLen = (int *)sqlite3_column_blob(statement,4);
        else
            polyPartLen = &numPoints;

        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
        //nBlobBytes = sqlite3_column_bytes(statement,5);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        pkeyval = (LPSTR)sqlite3_column_text(statement,6);
        keyval = [NSString stringWithUTF8String:pkeyval];
        int numNewPoints = 0;
        int iloop = 0;
        int nextLoopi = polyPartLen[0] - 1;
        int lastLoopn = 0;
        if (numLoops > 1)
        {
            int ii = polyPartLen[0];
            for (int i = 1;i<numLoops;i++)
            {
                ii = polyPartLen[i];
                ii = polyPartLen[i-1];
                ii = 0;
            }
            
        }
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                llpoints[numNewPoints] = TranDPOINT(&llpoints[i], _pTranLLtoView);
                if (i && !sameDPoint(&llpoints[numNewPoints],&llpoints[numNewPoints-1],1))
                    numNewPoints++;
                if (i == nextLoopi)
                {
                    nextLoopi += polyPartLen[iloop];
                    polyPartLen[iloop++] = numNewPoints - lastLoopn;
                    lastLoopn = numNewPoints;
                }
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
            llpoints[numNewPoints] = TranDPOINT(&llpoints[i], _pTranLLtoView);
            if (i && !sameDPoint(&llpoints[numNewPoints],&llpoints[numNewPoints-1],1))
                numNewPoints++;
            if (i == nextLoopi)
            {
                nextLoopi += polyPartLen[iloop];
                polyPartLen[iloop++] = numNewPoints - lastLoopn;
                lastLoopn = numNewPoints;
            }
        }
        numPoints = numNewPoints;
        NSString * text;
        double count;
        if (pias)
        {
            count = [pias countForArea:keyval] * to.adjustCount;
            NSString *fmt = [NSString stringWithFormat:@"%%.%ilf",to.numDecimals];
            text = [NSString stringWithFormat:fmt,count];
        }
        else
        {
            count = 1;
            text = keyval;
        }
        if (count >= 0)
        {
            UIColor *textColor = UIColor.redColor;
            [NVTextDrawing drawText:text
                          inContext:context
                      withinPolygon:llpoints
                      withNumPoints:numPoints
                        andNumLoops:numLoops
                            loopLen:polyPartLen
                       withinBounds:pvbounds
                           fontSize:fontSize
                        minFontSize:minFontSize
                          textColor:textColor
                       processingID:0];
        }
        free (llpoints);
    }
    
    SQLOK(sqlite3_finalize(statement), self.database);
    [self close:opened];
    
    return nLoaded;
    
}

- (MNMXCORD) selectBoundaryFromMapInit:(NSString*)type
{
    MNMXCORD bounds = {0};
    
    sqlite3_stmt *statement = NULL;
    NSString *query = [[NSString alloc] init];
    
    BOOL opened = [self open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_MPLS:
            break;
            
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BOUNDARYAREA.id,minX,maxX,minY,maxY FROM BOUNDARYAREA,BOUNDARYAREA_index WHERE BOUNDARYAREA.TYPE='%@' AND BOUNDARYAREA_index.id=BOUNDARYAREA.id",
                     type];
            break;
    }
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    DBoundsInit(&bounds);
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        MNMXCORD bounds2;
        bounds2.xmn = sqlite3_column_double(statement, 1);
        bounds2.xmx = sqlite3_column_double(statement, 2);
        bounds2.ymn = sqlite3_column_double(statement, 3);
        bounds2.ymx = sqlite3_column_double(statement, 4);
        AddMinMaxD (&bounds, &bounds2);
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    
    [self close:opened];
    
    return bounds;
}

- (int)pickBoundaryArea:(LLPOINT)point
{
    int nPicked = 0;
    NSString *query = @"";
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints;
    int refno = 0;
    LPSTR pkeyval;
    NSString * keyval;
    int numLoops;
    NSString * areaType = CRAPI.sharedInstance.selectBoundaryFromMapType;
    NSString * key = areaType;
    NSString * table = [NSString stringWithFormat:@"CENSUS%@POLY",key];
    BOOL opened = [self open];
    
    if ([areaType isEqualToString:@"Minneapolis Precincts"] ||
        [areaType isEqualToString:@"Minneapolis Wards"] ||
        [areaType isEqualToString:@"Minneapolis Sectors"] ||
        [areaType isEqualToString:@"Cities And Townships"] ||
        [areaType isEqualToString:@"Counties"] ||
        [areaType isEqualToString:@"Minneapolis Neighborhoods"])
    {
        table = @"BOUNDARYAREA";
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,NAME, %@.id FROM %@,%@_index WHERE TYPE='%@' AND %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",table,table,table,areaType,table,table,
                 point.lon,point.lon,point.lat,point.lat];
    }
    else
    {
    }
    SQLOK(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        numLoops = sqlite3_column_int(statement,3);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        pkeyval = (LPSTR)sqlite3_column_text(statement,6);
        keyval = [NSString stringWithUTF8String:pkeyval];
        refno = sqlite3_column_int(statement,7);
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
        DPOINT dp;
        dp.x = point.lon;
        dp.y = point.lat;
        if (POINT_IN_AREAD(dp, numPoints, llpoints, 1, 0, 0, 0))
            nPicked++;
        free (llpoints);
    }
    
    SQLOK(sqlite3_finalize(statement), self.database);
    [self close:opened];
    if (nPicked == 1)
    {
        CRAPI.sharedInstance.GMMSetting = GMMSettingBoundaries;
        CRAPI.sharedInstance.currentOverallBoundaryName = keyval;
        CRAPI.sharedInstance.currentOverallBoundaryType = areaType;
        CRAPI.sharedInstance.currentOverallBoundaryRefno = refno;
        CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
    }
    return nPicked;
}

@end