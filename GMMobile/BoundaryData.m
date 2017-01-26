//  BoundaryData.m
//  GMMobile

#define COORDINATE_FACTOR 10000000.0

#import "BoundaryData.h"
#import "PropertyData.h"
#import "CCodeLibrary/NVTextDrawing.h"
#import "CCodeLibrary/NVColor.h"
#import "ConfigurationControl.h"
#import "NVMetroSettings.h"

@implementation BoundaryAreaData

@end

@interface BoundaryData ()

@property (nonatomic) LPTRANDATA pTranLLtoView, pTranViewtoLL;
@property double acres;

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
        _cenfileName = @"censusdata.slt";
        _cenpath = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _cenfileName];
        _propfileName =  @"PropertyData.slt";
        _proppath = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _propfileName];

        NSLog(@"Boundary Database init");
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
        _isOpen = !SQLOK(0,sqlite3_open(_path.UTF8String, &_database), _database);
//        _isOpen = !SQLOK(0,sqlite3_open(_proppath.UTF8String, &_database), _database);
        NSLog(@"Boundary Database open");
        
        if (_isOpen)
        {
            NSString *attachCmd = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS CENSUSDB",_cenpath];
            [self executeCmd:(LPSTR)attachCmd.UTF8String];
            attachCmd = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS PROPERTYDB",_proppath];
            [self executeCmd:(LPSTR)attachCmd.UTF8String];

        }
        _fileSize = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                              error:nil].fileSize;
        rtn = TRUE;
    }
    return rtn;
}

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        SQLOK(0,sqlite3_close(_database),_database);
        NSLog(@"Boundary Database close");
        _isOpen = NO;
    }
}

- (void)clear
{
    [self close:TRUE];
    
    //BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
    //error:nil];
}

- (void) createVersionTable
{
    NSString * cmd = @"CREATE TABLE IF NOT EXISTS BOUNDARY_VERSION (id INTEGER PRIMARY KEY,Version REAL); INSERT INTO BOUNDARY_VERSION VALUES(1,1.0);";
    [self executeCmd:(LPSTR)cmd.UTF8String];
}
- (int) datasetVersion
{
    int rtn = -1;
    BOOL opened = [self open];
    if (_isOpen && _fileSize > 0)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT max(Version) FROM BOUNDARY_VERSION"];
        
        sqlite3_stmt *statement = NULL;
        
        BOOL st = sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0);
        if (st)
            [self createVersionTable];
        else
        {
            
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                LPSTR version = (LPSTR)sqlite3_column_text(statement, 0);
                
                if (version)
                    rtn = atoi(version);
            }
            
            SQLOK(0,sqlite3_finalize(statement), _database);
        }
    }
    [self close:opened];
    if ( _fileSize > 100)
        rtn = 0;
    return rtn;
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOK(0,sqlite3_exec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOK(0,sqlite3_exec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOK(0,sqlite3_exec(_database, "COMMIT", 0, 0, 0),_database);
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
        
        CreateMask(&llpoints, &numPoints,pvbounds,TRUE);
        [self fillUseCode:context
                  nPoints:numPoints
                   points:llpoints
                withColor:maskColor.CGColor
                drawLines:NO];
        
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
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
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
            LPDPOINT existingPoints = llpoints;
            int numExistingPoints = numPoints;
            if (mask)
            {
                UIColor *maskColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.85];
                
                CreateMask(&llpoints, &numPoints,pvbounds,FALSE);
                [self fillUseCode:context
                          nPoints:numPoints
                           points:llpoints
                        withColor:maskColor.CGColor
                        drawLines:NO];
                
            }
            if (CRAPI.sharedInstance.showPolylineForBounds)
            {
                UIColor *boundaryColor = [UIColor colorWithRed:0.75 green:0 blue:0.25 alpha:0.80];
                [self drawBoundary:context
                           nPoints:numExistingPoints
                            nLoops:numLoops
                           partLen:polyPartLen
                            points:existingPoints
                         withColor:boundaryColor.CGColor];
            }
            
            free(llpoints);
        }
    }
 
    SQLOK(0,sqlite3_finalize(statement), _database);
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
        int ii;
        
        for (int loop = 0; loop < nLoops; loop++)
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
        
        SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
        
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            LPSTR type = (LPSTR)sqlite3_column_text(statement, 0);
            NSString *outString = [NSString stringWithFormat:@"%s", type];
            [types addObject:outString];
        }
        
        SQLOK(0,sqlite3_finalize(statement), _database);
        
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
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR name = (LPSTR)sqlite3_column_text(statement, 1);
        BoundaryAreaData *baData = [[BoundaryAreaData alloc] init];
        baData.refno = refno;
        baData.name = [NSString stringWithUTF8String:name];
        [data addObject:baData];
    }
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    
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
    else if ([areaType isEqualToString:@"PARCEL"])
        table = @"PARCELPOLY";
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
    SQLOK(0,sqlite3_prepare_v2(bad.database, query.UTF8String, -1, &statement, 0), bad.database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        refno = sqlite3_column_int(statement, 0);
    }
    
    SQLOK(0,sqlite3_finalize(statement), bad.database);
    
    [bad close:opened];
    return refno;
}


- (MNMXCORD)getBoundaryAreaBounds:(long long)refno
                           ofType:(NSString*)type
{
    MNMXCORD bounds = {0};
    
    sqlite3_stmt *statement = NULL;
    NSString *query = [[NSString alloc] init];
    NSString * table = [self getTableNameFromType:type];
    
    BOOL opened = [self open];
    
    if ([type isEqualToString:@"BOUNDARY"])
    {
        query = [NSString stringWithFormat:@"SELECT BOUNDARYAREA.id,minX,maxX,minY,maxY FROM BOUNDARYAREA,BOUNDARYAREA_index WHERE BOUNDARYAREA.ID=%lli AND BOUNDARYAREA_index.id=BOUNDARYAREA.id",
                 refno];
    }
    else
    {
        query = [NSString stringWithFormat:@"SELECT id,minX,maxX,minY,maxY FROM %@_index WHERE ID=%lli",table,refno];

    }
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        long long ref = sqlite3_column_int64(statement, 0);
        bounds.xmn = sqlite3_column_double(statement, 1);
        bounds.xmx = sqlite3_column_double(statement, 2);
        bounds.ymn = sqlite3_column_double(statement, 3);
        bounds.ymx = sqlite3_column_double(statement, 4);
    }
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    
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
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
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
    
    SQLOK(0,sqlite3_finalize(statement), _database);
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
    
    SQLOK(0,sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
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
                    withColor:dc.fillColor.CGColor
                    drawLines:NO];
            [self drawUseCode:context
                      nPoints:numPoints
                       nLoops:numLoops
                      partLen:polyPartLen
                       points:llpoints
                    withColor:dc.penColor.CGColor
                     andWidth:dc.width];
        }
    }
    
    SQLOK(0,sqlite3_finalize(statement), self.database);
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
          drawLines:(BOOL) drawLines
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
    CGContextClosePath(context);
    if (!CGContextIsPathEmpty(context))
    {
        CGContextSetFillColorWithColor(context,color);
        if (drawLines)
        {
            CGContextSetLineWidth(context, 1);
            CGContextSetStrokeColorWithColor(context,UIColor.blackColor.CGColor);
            CGContextDrawPath(context, kCGPathEOFillStroke);
        }
        else
            CGContextDrawPath(context, kCGPathEOFill);
        
    }
}
- (BOOL) createSortedValuesTable
{
    BOOL rtn = FALSE;
    
    NSString * cmd = @"DROP TABLE IF EXISTS SORTEDVALUES;CREATE TEMP TABLE SORTEDVALUES (ID INTEGER PRIMARY KEY,Value INT8);";
    rtn = [self executeCmd:(LPSTR)cmd.UTF8String];
    [self startTransaction];
    return rtn;
}
- (INT64)getQueryCount:(NSString*)query
{
    sqlite3_stmt *statement = NULL;
    INT64 count = 0;
    CRAPI.sharedInstance.mapToolbar.showIndicator = YES;

    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, NULL), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
        count = sqlite3_column_int64(statement, 0);
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    CRAPI.sharedInstance.mapToolbar.showIndicator = NO;

    return count;
}
- (INT64)getCountOfSortedValues
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM SORTEDVALUES"];
    sqlite3_stmt *statement = NULL;
    INT64 count = 0;
    CRAPI.sharedInstance.mapToolbar.showIndicator = YES;

    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, NULL), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
        count = sqlite3_column_int64(statement, 0);
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    CRAPI.sharedInstance.mapToolbar.showIndicator = NO;

    return count;
}


- (void) addToSortedValues:(long long)value
                        id:(long long)id
{
    if (NVMetroSettings.sharedInstance.themeClassType > -1)
    {
        NSString * cmd = [NSString stringWithFormat:@"INSERT INTO SORTEDVALUES VALUES(%lli,%lli);",id,value];
      //  int st = [self executeCmd:(LPSTR)cmd.UTF8String];
        int st = sqlite3_exec(_database,(LPSTR)cmd.UTF8String, 0, 0, 0);
        if (st)
            st = 0;
    }
}

- (long long) getClassBounds:(int)numValues
                  maxClasses:(int)maxClass
                    minValue:(double)minVal
                    maxValue:(double)maxVal
                       theme:(Theme*)thm
{
    //NSMutableArray * classBounds = NSMutableArray.new;
    long long rtn = -1;
    double value=0, lastValue=DBL_MIN;
    double d95percentValue=maxVal;
    int i95percentCount = 0.95 * numValues;
    [self commitTransaction];
    sqlite3_stmt *statement = NULL;
    int factor = 1;
    if (maxVal > 0 && maxVal <= 1.0)
        factor = 100;
    else if (maxVal > 0 && maxVal <= 100.0)
        factor = 10;
    INT64 * classCounts = calloc (maxClass*3,sizeof(INT64)+maxClass*sizeof(double));
    INT64  * classMin = classCounts + maxClass;
    INT64  * classMax = classMin + maxClass;
    double * classAve = (double *)(classMax + maxClass);
    double numPerClass = (double)numValues / maxClass;
    double classTot = 0;
    
    if (NVMetroSettings.sharedInstance.themeClassType > -1)
    {
        NSString * query = @"SELECT ID,Value FROM SORTEDVALUES ORDER BY Value";
        SQLOK(0,sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
        int iClass = 0;
        int startClass = 0;
        int startValue = 0;
        int iValue = 0;
        long long ID=-1;
        while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
        {
            ID = sqlite3_column_int64(statement,0);
            value = sqlite3_column_double(statement,1);
            value *= factor;
            if (iValue == i95percentCount)
                d95percentValue = value;
            if (!iValue)
                classMin[0] = value;
            else if (value != lastValue)
            {
                if ((iValue-startValue) > ((iClass-startClass)+1) * numPerClass)
                {
                    classAve[iClass] = classTot / classCounts[iClass];
                    classMax[iClass++] = lastValue;
                    classMin[iClass] = value;
                    classTot = 0;
                    startClass = iClass;
                    startValue = iValue;
                    numPerClass = (double)(numValues - iValue) / (maxClass - startClass);
                }
            }
            lastValue = value;
            classTot += value;
            classCounts[iClass]++;
            iValue++;
        }
        rtn = ID;
        classMax[iClass] = value;
        classAve[iClass] = classTot / classCounts[iClass];
        SQLOK(0,sqlite3_finalize(statement), self.database);
        query = @"DROP TABLE IF EXISTS SORTEDVALUES;";
//        [self executeCmd:(LPSTR)query.UTF8String];
        NVMetroSettings.sharedInstance.numThemeClasses = iClass+1;
    }
    else
    {
        NVMetroSettings.sharedInstance.numThemeClasses = maxClass;
        double classInc = (maxVal - minVal) / maxClass;
        classMin[0] = minVal * factor;
        for (int iclass = 0;iclass < maxClass-1;iclass++)
        {
            classMax[iclass] = IDNINT64 ((iclass+1) * classInc);
            classMin[iclass+1] = classMax[iclass]+1;
        }
        classMax[maxClass-1] = IDNINT64 (maxVal);
    }
    if (!NVMetroSettings.sharedInstance.themeClassType)
    {
        NVMetroSettings.sharedInstance.numThemeClasses = maxClass;
        double maxVal2 = maxVal;//d95percentValue;
        double classInc = (maxVal2 - minVal) / maxClass;
        classMin[0] = minVal * factor;
        for (int iclass = 0;iclass < maxClass-1;iclass++)
        {
            classMax[iclass] = classMin[0] + IDNINT64 ((iclass+1) * classInc);
            classAve[iclass] = (classMin[iclass] + classMax[iclass])/2;
            classMin[iclass+1] = classMax[iclass]+1;
        }
        classMax[maxClass-1] = IDNINT64 (maxVal);
        classAve[maxClass-1] = (classMin[maxClass-1] + classMax[maxClass-1])/2;
    }
    NVMetroSettings.sharedInstance.valueMultiplier = factor;
    NVMetroSettings.sharedInstance.themeClassCounts = NSMutableArray.new;
    NVMetroSettings.sharedInstance.themeClassMin = NSMutableArray.new;
    NVMetroSettings.sharedInstance.themeClassMax = NSMutableArray.new;
    NVMetroSettings.sharedInstance.themeClassAve = NSMutableArray.new;
    for (int iClass = 0;iClass < NVMetroSettings.sharedInstance.numThemeClasses;iClass++)
    {
        NSNumber * count = [NSNumber numberWithLongLong:classCounts[iClass]];
        NSNumber * min = [NSNumber numberWithLongLong:classMin[iClass]];
        NSNumber * max = [NSNumber numberWithLongLong:classMax[iClass]];
        NSNumber * ave = [NSNumber numberWithDouble:classAve[iClass]];
        [NVMetroSettings.sharedInstance.themeClassCounts addObject:count];
        [NVMetroSettings.sharedInstance.themeClassMin addObject:min];
        [NVMetroSettings.sharedInstance.themeClassMax addObject:max];
        [NVMetroSettings.sharedInstance.themeClassAve addObject:ave];
    }
    free (classCounts);
    return rtn;
}

NSString * formatValueText (long long ival,double factor,int ndecimals)
{
    double ndfac = pow (10,ndecimals);
    NSString * fmt = [NSString stringWithFormat:@"%%.%if",ndecimals];
    double dvalue = ival / ndfac;
    NSString *text = [NSString stringWithFormat:fmt,dvalue];
    
    return text;
}
-(void)displayCensusAreas:(CGContextRef)context
                     type:(NSString *)type
   displayCharacteristics:(DisplayCharacteristics*)dc
                llCorners:(CORNERPOINTS *) latlonCornerPoints
                 LLBounds:(MNMXCORD *)platlonBounds
               viewBounds:(MNMXCORD *)pvbounds
                   themes:(Themes*)themes
              pointInArea:(PointInArea *)pia
{
#define MIN_PARCEL_ACRES 0.01
    BOOL isParcel = NO;
    NSString * field = [NVMetroSettings.sharedInstance currentValueField];
    NSString *query = @"";
    //NSString *querys;
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints;
    int numValues = 0;
    //NSInteger keyval;
    int numLoops;
    NSString * key = type;
    NSString * polyTable = [NSString stringWithFormat:@"CENSUS%@POLY",key];
    NSString * dataTable = [NSString stringWithFormat:@"CENSUSDB.CENSUS%@DATA",key];
    if ([type isEqualToString:@"PARCEL"])
    {
        polyTable = [NSString stringWithFormat:@"PARCELPOLY"];
        dataTable = [NSString stringWithFormat:@"PROPINFO"];
        isParcel = YES;
    }
    else if ([type isEqualToString:@"BLOCKGROUP_ACS"])
    {
        polyTable = [NSString stringWithFormat:@"CENSUSBLOCKGROUPPOLY"];
        dataTable = [NSString stringWithFormat:@"CENSUSDB.CENSUSBLOCKGROUPACS"];
        type = @"BLOCKGROUP";
    }
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    double minValue=DBL_MAX, maxValue=DBL_MIN;
    double area;
    int factor = 1;
    double divisor = 1;
    double areaFactor = 1;
    int nDecimals = 0;
    int ii=0;
    double waterArea = 0;
    double totalPop = 0;
    double totalHousingUnits = 0;
    int genUseCode;
    static INT64 totRecords=-1;
    INT64 currentRec=0;
    int iPass = 0;
    CGFloat fontSize = 48.0;
    CGFloat minFontSize = 6.0;
    static int wantGenUseCode = 0;
    static char wantHomeStead = 0;
    
    if (_pass == DataPass && !field.length)
        return;
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);

    switch (NVMetroSettings.sharedInstance.currentAdjustmentValue)
    {
        case CPAdjustCount:
        case CPAdjustRawCounts:
            break;
        case CPAdjustCountPerAcre:
            if (!isParcel)
            {
                factor = 10;
                nDecimals = 1;
                areaFactor = ACRES_PER_SQMETER;
            }
            break;
        case CPAdjustCountPerSQMile:
            if (isParcel)
            {
                areaFactor = 1.0/ACRES_PER_SQMETER;
                areaFactor *= SQMILES_PER_SQMETER;
            }
            else
                areaFactor = SQMILES_PER_SQMETER;
            break;
        case CPAdjustPctOfTotalPop:
            factor = 1000;
            nDecimals = 1;
            break;
        case CPAdjustCountPerHousingUnit:
        case CPAdjustPctOfTotalHousingUnits:
            factor = 1000;
            nDecimals = 1;
            break;
    }
    BOOL opened = [self open];
    if (_pass == DataPass)
    {
        [CRAPI.sharedInstance updateProgress:-1
                                     current:0
                                       range:1
                                   numRanges:2];
        iPass = 0;
        [self createSortedValuesTable];
        if (isParcel)
        {
            query = [NSString stringWithFormat:@"SELECT COUNT(%@.id) FROM %@_index,%@  WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",polyTable,polyTable,polyTable,polyTable,polyTable,
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            totRecords = [self getQueryCount:query];
            
            if (NVMetroSettings.sharedInstance.overUnder && CRAPI.sharedInstance.currentPID)
            {
                query = [NSString stringWithFormat:@"SELECT %@,ACRES_POLY,GENUSECODE,HOMESTEAD,id FROM PROPINFO WHERE PIN = '%@'",field,CRAPI.sharedInstance.currentPID];
                SQLOK(0,sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
                currentRec = 0;
                if ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
                {
                    double dataValue = sqlite3_column_double(statement,0);
                    double landArea = sqlite3_column_double(statement,1);
                    wantGenUseCode = sqlite3_column_int(statement,2);
                    LPSTR homeStead = (LPSTR)sqlite3_column_text(statement,3);
                    INT64 ID = sqlite3_column_int64(statement,4);
                    wantHomeStead = *homeStead;

                    landArea *= areaFactor;
                    dataValue *= factor;
                    switch (NVMetroSettings.sharedInstance.currentAdjustmentValue)
                    {
                        default:
                            break;
                        case CPAdjustCountPerAcre:
                        case CPAdjustCountPerSQMile:
                            dataValue /= landArea;
                            break;
                    }
                    minValue = min (minValue,dataValue);
                    maxValue = max (maxValue,dataValue);
                    [self addToSortedValues:IDNINT64(dataValue) id:ID];

                    NVMetroSettings.sharedInstance.targetValue = dataValue;
                }
                SQLOK(0,sqlite3_finalize(statement), self.database);
            }

            query = [NSString stringWithFormat:@"SELECT %@.id,%@, ACRES_POLY,GENUSECODE,HOMESTEAD,minX,maxX,minY,maxY FROM %@_index,%@,%@  WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f AND %@.PIN = %@.PID",polyTable,field,polyTable,polyTable,dataTable,polyTable,polyTable,
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx,dataTable,polyTable];
        }
        else
        {
            query = [NSString stringWithFormat:@"SELECT COUNT(%@.id) FROM %@,%@_index  WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",polyTable,polyTable,polyTable,polyTable,polyTable,
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            totRecords = [self getQueryCount:query];
            query = [NSString stringWithFormat:@"SELECT %@.id,%@, LANDAREA,WATERAREA,POPTOTAL,HUTOTAL,minX,maxX,minY,maxY FROM %@,%@_index,%@  WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f AND %@.GEOG_UNIT = %@.%@",polyTable,field,polyTable,polyTable,dataTable,polyTable,polyTable,
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx,dataTable,polyTable,type];
        }
    }
    else
    {
        if (!field.length)//no theme
        {
            if (isParcel)
            {
                query = [NSString stringWithFormat:@"SELECT %@.id,ACRES_DEED,ACRES_POLY,GENUSECODE,HOMESTEAD,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM %@,%@_index,%@ WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f AND %@.PIN = %@.PID",polyTable,polyTable,polyTable,dataTable,polyTable,polyTable,
                         platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx,dataTable,polyTable];
            }
            else
            {
                /*           query = [NSString stringWithFormat:@"SELECT %@.id,%@,LandArea,WaterArea,POPTOTAL,HUTOTAL,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM %@,%@_index,%@,SORTEDVALUES  WHERE %@.id=%@_index.id AND SORTEDVALUES.ID=%@.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f AND %@.GEOG_UNIT = %@.%@ ORDER BY SORTEDVALUES.Value ASC",polyTable,field,polyTable,polyTable,dataTable,polyTable,polyTable,polyTable,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx,dataTable,polyTable,type];
                query = [NSString stringWithFormat:@"SELECT %@.id,LandArea,WaterArea,POPTOTAL,HUTOTAL,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM %@,%@,SORTEDVALUES  WHERE %@.id=SORTEDVALUES.ID AND %@.GEOG_UNIT = %@.%@ ORDER BY SORTEDVALUES.Value ASC",polyTable,polyTable,dataTable,polyTable,
                         dataTable,polyTable,type];*/
                
                query = [NSString stringWithFormat:@"SELECT %@.id,LANDAREA,LANDAREA,WATERAREA,POPTOTAL,HUTOTAL,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM %@,%@_index,%@  WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f AND %@.GEOG_UNIT = %@.%@",polyTable,polyTable,polyTable,dataTable,polyTable,polyTable,
                         platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx,dataTable,polyTable,type];
            }
            
        }
        else
        {
            iPass = 1;
            totRecords = [self getCountOfSortedValues];
            if (isParcel)
            {
                /*            query = [NSString stringWithFormat:@"SELECT %@.id,%@,ACRES_POLY,GENUSECODE,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM %@,%@_index,%@,SORTEDVALUES  WHERE %@.id=%@_index.id AND SORTEDVALUES.ID=%@.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f AND %@.PIN = %@.PID ORDER BY SORTEDVALUES.Value ASC",polyTable,field,polyTable,polyTable,dataTable,polyTable,polyTable,polyTable,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx,dataTable,polyTable];*/
                query = [NSString stringWithFormat:@"SELECT %@.id,%@,ACRES_POLY,GENUSECODE,HOMESTEAD,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM SORTEDVALUES,%@,%@  WHERE %@.id= SORTEDVALUES.ID AND %@.PIN = %@.PID ORDER BY SORTEDVALUES.Value ASC",polyTable,field,polyTable,dataTable,polyTable,
                         dataTable,polyTable];
            }
            else
            {
                /*           query = [NSString stringWithFormat:@"SELECT %@.id,%@,LandArea,WaterArea,POPTOTAL,HUTOTAL,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM %@,%@_index,%@,SORTEDVALUES  WHERE %@.id=%@_index.id AND SORTEDVALUES.ID=%@.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f AND %@.GEOG_UNIT = %@.%@ ORDER BY SORTEDVALUES.Value ASC",polyTable,field,polyTable,polyTable,dataTable,polyTable,polyTable,polyTable,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx,dataTable,polyTable,type];*/
                query = [NSString stringWithFormat:@"SELECT %@.id,%@,LandArea,WaterArea,POPTOTAL,HUTOTAL,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM %@,%@,SORTEDVALUES  WHERE %@.id=SORTEDVALUES.ID AND %@.GEOG_UNIT = %@.%@ ORDER BY SORTEDVALUES.Value ASC",polyTable,field,polyTable,dataTable,polyTable,
                         dataTable,polyTable,type];
                
            }
        }
    }
    CRAPI.sharedInstance.mapToolbar.showIndicator = YES;
    SQLOK(0,sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    currentRec = 0;
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        if (!currentRec)
            CRAPI.sharedInstance.mapToolbar.showIndicator = NO;
        int i = 0;
        MNMXCORD bounds;
        long long ID = sqlite3_column_int64(statement,i++);
        double dataValue = sqlite3_column_double(statement,i++);
        double landArea = sqlite3_column_double(statement,i++);
        if (isParcel)
        {
            if (landArea < MIN_PARCEL_ACRES)
                goto SkipRecord;
            genUseCode = sqlite3_column_int(statement,i++);
            LPSTR homeStead = (LPSTR)sqlite3_column_text(statement,i++);
            if (field.length > 0 && NVMetroSettings.sharedInstance.overUnder)
            {
                if (genUseCode != wantGenUseCode)
                    goto SkipRecord;
                if (*homeStead != wantHomeStead)
                    goto SkipRecord;
            }
            if (![NVMetroSettings.sharedInstance wantUseCode:genUseCode])
                goto SkipRecord;
        }
        else
        {
            waterArea = sqlite3_column_double(statement,i++);
            totalPop = sqlite3_column_double(statement,i++);
            totalHousingUnits = sqlite3_column_double(statement,i++);
        }
        area = landArea;
        if (!area)
            goto SkipRecord;
        area *= areaFactor;
        dataValue *= factor;
        switch (NVMetroSettings.sharedInstance.currentAdjustmentValue)
        {
            case CPAdjustCount:
            case CPAdjustRawCounts:
                break;
            case CPAdjustCountPerAcre:
            case CPAdjustCountPerSQMile:
                dataValue /= area;
                break;
            case CPAdjustPctOfTotalPop:
                dataValue /= totalPop;
                break;
            case CPAdjustCountPerHousingUnit:
            case CPAdjustPctOfTotalHousingUnits:
                dataValue /= totalHousingUnits;
               break;
        }
        NVMetroSettings.sharedInstance.valueMultiplier = factor;
        NVMetroSettings.sharedInstance.roundTo = nDecimals;

        if (_pass == DataPass)
        {
            BOOL haveInPoint = TRUE;
            DPOINT points[4];
            bounds.xmn = sqlite3_column_double(statement,i++);
            bounds.xmx = sqlite3_column_double(statement,i++);
            bounds.ymn = sqlite3_column_double(statement,i++);
            bounds.ymx = sqlite3_column_double(statement,i++);
            
            
            if (pia)
            {
                haveInPoint = FALSE;
                BoundsToPoints (&bounds, points,0);
                for (int ip = 0;ip < 4; ip++)
                {
                    if ([pia DPointInArea:&points[ip]] == 1)
                    {
                        haveInPoint = TRUE;
                        break;
                    }
                }
            }
            if (!haveInPoint)
                goto SkipRecord;
            else
            {
                [self addToSortedValues:IDNINT64(dataValue) id:ID];
                minValue = min (minValue,dataValue);
                maxValue = max (maxValue,dataValue);
                numValues++;
            }
        }
        
        else
        {
            BasePt.x = sqlite3_column_double(statement,i++);
            BasePt.y = sqlite3_column_double(statement,i++);
            numPoints = sqlite3_column_int(statement,i++);
            numLoops = sqlite3_column_int(statement,i++);
            int *polyPartLen = (int *)sqlite3_column_blob(statement,i++);
            LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,i++);
            LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
            //keyval = sqlite3_column_int64(statement,6);
            
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
            dc.iValue = IDNINT64(dataValue);
            if (!NVMetroSettings.sharedInstance.currentFeatureValue)
                [self drawUseCode:context
                          nPoints:numPoints
                           nLoops:numLoops
                          partLen:polyPartLen
                           points:llpoints
                        withColor:UIColor.redColor.CGColor
                         andWidth:3];
            else if ([themes setDisplayCharacteristics:dc
                                             displayID:_processingID] != DO_NOT_DISPLAY_ITEM)
            {
                [self fillUseCode:context
                          nPoints:numPoints
                           points:llpoints
                        withColor:dc.fillColor.CGColor
                        drawLines:YES];
                if (NVMetroSettings.sharedInstance.currentTextOption.numTextFields < 0)
                {
                    NSString * text = formatValueText (dc.iValue,factor,nDecimals);
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
                               processingID:_processingID];
                }

            }
            else
                ii=1;
            free (llpoints);
        }
    SkipRecord:
        [CRAPI.sharedInstance updateProgress:(NSInteger)totRecords
                                     current:(NSInteger)++currentRec
                                       range:iPass
                                   numRanges:2];
        
    }
    iPass++;
    
    SQLOK(0,sqlite3_finalize(statement), self.database);
    //svc = [self getCountOfSortedValues];
    if (_pass == DataPass)
    {
        Theme * thm = themes.themeList[0];
        long long maxValID = [self getClassBounds:numValues
                  maxClasses:10
                    minValue:minValue
                    maxValue:maxValue
                       theme:thm];
        [themes setAppThemes];
        thm = themes.themeList[0];
        thm.numDecimals = nDecimals;
        if (isParcel)
            thm.maxValBounds = [self getBoundaryAreaBounds:maxValID ofType:@"PARCEL"];
        else
            thm.maxValBounds = [self getBoundaryAreaBounds:maxValID ofType:type];
    }
    else
    {
        [CRAPI.sharedInstance updateProgress:(int)totRecords
                                     current:(int)totRecords
                                       range:2
                                   numRanges:2];
    }
    
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
    SQLOK(0,sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
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
    
    SQLOK(0,sqlite3_finalize(statement), self.database);
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
    SQLOK(0,sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
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
                withColor:color
                drawLines:NO];
        
        [self drawUseCode:context
                  nPoints:numPoints
                   nLoops:numLoops
                  partLen:polyPartLen
                   points:llpoints
                withColor:UIColor.blackColor.CGColor
                 andWidth:3];
        
        free (llpoints);
    }
    
    SQLOK(0,sqlite3_finalize(statement), self.database);
    [self close:opened];
    
    return nLoaded;
    
}

- (int) displayText:(CGContextRef)context
               from:(TextFromOption)from
       areaType:(NSString*)areaType
          textOptions:(TextOptions *)to
   pointInAreas:(PointInAreas*)pias
      llCorners:(CORNERPOINTS *) latlonCornerPoints
       LLBounds:(MNMXCORD *)platlonBounds
     viewBounds:(MNMXCORD *)pvbounds
{
    if (!NVMetroSettings.sharedInstance.currentTextOption)
        return 0;
    extern MNMXCORD curbounds;
    int nLoaded = 0;
    NSString *query = @"";
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt = {0};
    NSString *keyval = @"";
    int numPoints = 0;
    int numLoops = 0;
    NSString *key = areaType;
    NSString *table = [NSString stringWithFormat:@"CENSUS%@POLY",key];
    CGFloat fontSize = 48.0;
    CGFloat minFontSize = 6.0;
    NSString * textFields = @"";
    LPSTR pTextValue[MAX_NVM_TEXT_FIELDS];
    
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
    else if ([areaType isEqualToString:@"PARCEL"])
    {
        NSString * fields = NVMetroSettings.sharedInstance.currentTextOption.fields;
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PID,ACRES_POLY,%@ FROM PARCELPOLY,PARCELPOLY_index,PROPINFO  WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PIN=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",fields,platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    else
    {
        NSString * fields = NVMetroSettings.sharedInstance.currentTextOption.fields;
        NSString * dataTable = [NSString stringWithFormat:@"CENSUSDB.CENSUS%@DATA",key];
        NSString * field = [NVMetroSettings.sharedInstance currentValueField];
        query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,%@,%@ FROM %@,%@_index,%@ WHERE %@.id=%@_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f AND %@.GEOG_UNIT = %@.%@",key,field,table,table,dataTable,table,table,
                 platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx,dataTable,table,areaType];
        
    }
    //querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
NextPass:
    SQLOK(0,sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        int *polyPartLen;
        int i=0;
        BasePt.x = sqlite3_column_double(statement,i++);
        BasePt.y = sqlite3_column_double(statement,i++);
        numPoints = sqlite3_column_int(statement,i++);
        if (abs (numPoints) <3)
            continue;
        numLoops = sqlite3_column_int(statement,i++);
        int nBlobBytes = sqlite3_column_bytes(statement,i);
        if (nBlobBytes > 0)
            polyPartLen = (int *)sqlite3_column_blob(statement,i);
        else
            polyPartLen = &numPoints;
        i++;
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,i++);
        //nBlobBytes = sqlite3_column_bytes(statement,5);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        LPSTR pkeyval = (LPSTR)sqlite3_column_text(statement,i++);
        keyval = [NSString stringWithUTF8String:pkeyval];

        _acres = sqlite3_column_double(statement,i++);
        
        for (int iField=0;iField<NVMetroSettings.sharedInstance.currentTextOption.numTextFields;iField++)
        {
            pTextValue[iField] = (LPSTR)sqlite3_column_text(statement,i++);
            
        }
        int numNewPoints = 0;
        int iloop = 0;
        int nextLoopi = polyPartLen[0] - 1;
        int lastLoopn = 0;
        
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                llpoints[numNewPoints] = TranDPOINT(&llpoints[i], _pTranLLtoView);
                
                if (!numNewPoints || !sameDPoint(&llpoints[numNewPoints],&llpoints[numNewPoints-1],1))
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
            
            if (!numNewPoints || !sameDPoint(&llpoints[numNewPoints],&llpoints[numNewPoints-1],1))
                numNewPoints++;
            
            if (i == nextLoopi)
            {
                nextLoopi += polyPartLen[iloop];
                polyPartLen[iloop++] = numNewPoints - lastLoopn;
                lastLoopn = numNewPoints;
            }
        }
        
        numPoints = numNewPoints;
        if (numPoints > 2)
        {
            NSString * text=@"";
            double count;
            if (pias)
            {
//                count = [pias countForArea:keyval] * to.adjustCount;
                NSString *fmt = [NSString stringWithFormat:@"%%.%ilf",to.numDecimals];
                text = [NSString stringWithFormat:fmt,count];
            }
            else if (from == TFONVMetroDisplay)
            {
                count = 1;
                for (int iField=0;iField<NVMetroSettings.sharedInstance.currentTextOption.numTextFields;iField++)
                {
                    if (iField)
                        text = [text stringByAppendingString:@"\n"];
                    
                    NSString *line = formatText (pTextValue[iField],NVMetroSettings.sharedInstance.currentTextOption.format,NVMetroSettings.sharedInstance.currentTextOption.nDecimals);
                    text = [text stringByAppendingString:line];
                    
                }
            }
            else
            {
                text = keyval;
                count = 1;
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
                           processingID:_processingID];
            }
        }
        free (llpoints);
    }
    
    SQLOK(0,sqlite3_finalize(statement), self.database);
    [self close:opened];
    
    return nLoaded;
    
}
NSString * formatText (LPSTR text,int option,int nDecimals)
{
    NSString * rtn = [NSString stringWithUTF8String:text];
    
    return rtn;
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
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
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
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    
    [self close:opened];
    
    return bounds;
}

- (PickedItem *)pickBoundaryArea:(LLPOINT)point
                            type:(NSString*)areaType
{
    int nPicked = 0;
    PickedItem *pi = nil;
    NSString *query = @"";
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int numPoints;
    int refno = 0;
    int pickedRefno=0;
    LPSTR pkeyval;
    NSString * keyval;
    NSString * pickedName;
    int numLoops;
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
    SQLOK(0,sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), self.database);
    
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
        {
            nPicked++;
            pickedRefno = refno;
            pickedName = keyval;
        }
        free (llpoints);
    }
    
    SQLOK(0,sqlite3_finalize(statement), self.database);
    [self close:opened];
    if (nPicked == 1)
    {
        pi = PickedItem.new;
        pi.identifier = pickedName;
        pi.symbolName = areaType;
        pi.refno = pickedRefno;
    }
    return pi;
}
- (void) setCityAndCounty
{
    DPOINT pt;
    LLPOINT llpt;
    MNMXCORD bnds = CRAPI.sharedInstance.lastDisplayBounds;
    pt = DBoundsMid(&bnds);
    llpt.lat = pt.y;
    llpt.lon = pt.x;
    PickedItem *pi = [self pickBoundaryArea:llpt type:@"Counties"];
    if (pi)
        CRAPI.sharedInstance.currentCountyName = pi.identifier;
    pi = [self pickBoundaryArea:llpt type:@"Cities And Townships"];
    if (pi)
        CRAPI.sharedInstance.currentCity = pi.identifier;
}

@end
