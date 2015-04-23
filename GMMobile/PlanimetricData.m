//  PlanimetricData.m
//  GMMobile

extern int keepProcessing;

#define COORDINATE_FACTOR 10000000.0

#import "PlanimetricData.h"
#import "PropertyData.h"
#import "ConfigurationControl.h"

@interface PlanimetricData ()

@property (nonatomic) LPTRANDATA pTranLLtoView, pTranViewtoLL;

@end

@implementation PlanimetricData

- (BOOL)continue
{
    if (self.processingID == keepProcessing)
        return YES;
    
    return NO;
}
-(void)displayPlanArea:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
{
    if (![self continue])
        return;
    
    NSString *query = @"";
    //NSString *querys;
    sqlite3_stmt *statement;
    DPOINT BasePt;
    CGColorRef color = CGColorCreateCopyWithAlpha(UIColor.redColor.CGColor, 0.5);
    int numPoints,numLoops;
    //LPSTR symName;
    PropertyData * pd = [[PropertyData alloc]init];

    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    [pd open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,SYMBOLNAME FROM PLAN_AREA,PLAN_AREA_index WHERE PLAN_AREA.id=PLAN_AREA_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            
            //querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
    }
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "prepareDisplayLandUse");
    
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
        //symName = (LPSTR)sqlite3_column_text(statement,6);
        
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
        
        [self fillPlanArea:context
                   nPoints:numPoints
                    nLoops:numLoops
                   partLen:polyPartLen
                    points:llpoints
                 withColor:color
                  andWidth:3];
    }
    
    SQLOK(sqlite3_finalize(statement), "displayParcels");
    [pd close];
}
- (void)fillPlanArea:(CGContextRef)context
             nPoints:(int)np
              nLoops:(int)nLoops
             partLen:(int *)pPartLen
              points:(LPDPOINT)pPoints
           withColor:(CGColorRef)color
            andWidth:(CGFloat)width
{
    CGContextSetLineWidth(context, width);
    //CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
    
    
    CGContextMoveToPoint(context, pPoints[0].x, pPoints[0].y);
    
    for (int i = 1; i < np; i++)
        CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
    
    CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
    
    if (!CGContextIsPathEmpty(context))
    {
        CGContextSetStrokeColorWithColor(context,UIColor.blackColor.CGColor);
        CGContextSetFillColorWithColor(context,color);
        CGContextDrawPath(context, kCGPathFillStroke);
    }
}

- (void)drawPlanArea:(CGContextRef)context
             nPoints:(int)np
              nLoops:(int)nLoops
             partLen:(int *)pPartLen
              points:(LPDPOINT)pPoints
           withColor:(CGColorRef)color
            andWidth:(int)width
{
    CGContextSetLineWidth(context, width);
    //CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
    
    if (nLoops > 1)
    {
        int ip = 0;
        //int ii;
        
        for (int loop=0; loop < nLoops; loop++)
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

-(void)displayPlanLine:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
{
    
    if (![self continue])
        return;
    
    NSString *query = @"";
    //NSString *querys;
    sqlite3_stmt *statement;
    DPOINT BasePt;
    int numPoints,numLoops;
    //LPSTR symName;
    PropertyData *pd = [[PropertyData alloc] init];
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    [pd open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,SYMBOLNAME FROM PLAN_LINE,PLAN_LINE_index WHERE PLAN_LINE.id=PLAN_LINE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            
    }
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "prepare PLAN_LINE");
    
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
        //symName = (LPSTR)sqlite3_column_text(statement,6);
        
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
        
        [self drawPlanLine:context
                   nPoints:numPoints
                    nLoops:numLoops
                   partLen:polyPartLen
                    points:llpoints
                 withColor:UIColor.blackColor.CGColor
                  andWidth:3];
    }
    
    SQLOK(sqlite3_finalize(statement), "displayParcels");
    [pd close];
}

- (void)drawPlanLine:(CGContextRef)context
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
        
        for (int loop=0; loop < nLoops; loop++)
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
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path,0, pPoints[0].x, pPoints[0].y);
        
        for (int i = 1; i < np; i++)
            CGPathAddLineToPoint(path,0,pPoints[i].x, pPoints[i].y);
        
        if (!CGPathIsEmpty(path))
        {
            if (ConfigurationControl.sharedInstance.GMTilesVisible)
            {
                CGContextSetLineWidth(context, width*2);
                CGContextSetStrokeColorWithColor(context,UIColor.whiteColor.CGColor);
                CGContextAddPath(context, path);
                CGContextDrawPath(context, kCGPathStroke);
                CGContextSetLineWidth(context, width);
            }
            CGContextAddPath(context, path);
            CGContextSetStrokeColorWithColor(context,color);
            CGContextDrawPath(context, kCGPathStroke);
        }
        CGPathRelease(path);
    }
}

-(void)displayPlanPoint:(CGContextRef)context
              llCorners:(CORNERPOINTS *) latlonCornerPoints
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds
{
    NSString *query = @"";
    sqlite3_stmt *statement;
    DPOINT BasePt;
    //int numPoints, numLoops;
    //LPSTR symName;
    PropertyData *pd = [[PropertyData alloc] init];
    
    if (![self continue])
        return;
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    [pd open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT PointX,PointY,SYMBOLNAME FROM PLAN_POINT,PLAN_POINT_index WHERE PLAN_POINT.id=PLAN_POINT_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "prepareDisplayLandUse");
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        //symName = (LPSTR)sqlite3_column_text(statement,2);
        
        DPOINT llpoint = TranDPOINT(&BasePt, _pTranLLtoView);
        [self drawPlanPoint:context
                    atPoint:&llpoint
                 withColor:UIColor.greenColor.CGColor];
    }
    
    SQLOK(sqlite3_finalize(statement), "displayParcels");
    [pd close];

}

- (void) drawPlanPoint:(CGContextRef)context
               atPoint:(DPOINT*)pPoint
             withColor:(CGColorRef)color

{
    CGFloat size = 5;
    CGRect pointRect = CGRectMake((pPoint->x - size / 2.0),
                                  (pPoint->y - size / 2.0), size, size);
    
    CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
    
}
- (int)pickAlleyWallPoint:(LLPOINT)point highlightList:(NSMutableArray*)hlist
{
    if (![ConfigurationControl.sharedInstance layer:HCLayerAlleys
                                      visibleAtZoom:_zoom])
        return 0;
    
    NSString *minID = [[NSString alloc] init];
    CGFloat d, mind = DBL_MAX;
    DPOINT p1, p2, minpt;
    LPLLPOINT pt = &point;
    int minref = 0;
    int npicked = 0;
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    dbounds bnds = [CRAPI.sharedInstance getPickApBoundsAtPoint:pt];
    PropertyData *pd = [[PropertyData alloc] init];
    [pd open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT ALLEYWALLS.id,\"Wall ID\",LATITUDE,LONGITUDE FROM ALLEYWALLS,ALLEYWALLS_index WHERE ALLEYWALLS.id=ALLEYWALLS_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
             bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "preparePickPID");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR wallID = (LPSTR)sqlite3_column_text(statement, 1);
        CGFloat lat = sqlite3_column_double(statement, 2);
        CGFloat lon = sqlite3_column_double(statement, 3);
        p2.x = lon;
        p2.y = lat;
        d = ArcDistance(p1, p2);
        
        if (d < mind)
        {
            npicked++;
            minref = refno;
            mind = d;
            minpt = p2;
            minID = [NSString stringWithUTF8String:wallID];
        }
    }
    
    SQLOK(sqlite3_finalize(statement), "pickPID");
    [pd close];
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    
    if (npicked)
    {
        PickedItem *pi = [[PickedItem alloc]init];
        pi.itemType = PTAlleyWallPt;
        pi.distance = mind;
        pi.pickedPoint = minpt;
        pi.identifier = minID;
        pi.symbolName = @"ALLEYWALLPT";
        pi.refno = minref;
        [hlist addObject:pi];
    }
    
    return npicked;
}

- (int)addAlleyWallPoint:(LLPOINT)point
{
    int newRefno = 0;
    
    /*BOOL rtn = FALSE;
    PropertyData *pd = [[PropertyData alloc] init];
    [pd open];
    
    NSString *query = [NSString stringWithFormat:@"UPDATE ALLEYWALLS SET LATITUDE = %f,LONGITUDE = %f lastUpdateTime=%i WHERE id=%i",
                       iTime, refno];
     
    NSString *query = [NSString stringWithFormat:@"UPDATE ALLEYWALLS SET LATITUDE = %f,LONGITUDE = %f WHERE id=%i",
                       point.lat,point.lon, refno];
     
    rtn = sqlite3_exec(pd.database, query.UTF8String, NULL, NULL, NULL);
     
    if (rtn)
    {
        query = [NSString stringWithFormat:@"UPDATE ALLEYWALLS_index SET minY=%f AND minX=%f AND maxY=%f AND maxX=%f WHERE ALLEYWALLS_index.id=%i",
                 point.lat,point.lon, point.lat,point.lon, refno];
        rtn = sqlite3_exec(pd.database, query.UTF8String, NULL, NULL, NULL);
    }
     
    [pd close];*/
    
    return newRefno;
}
-(void)displayAlleyLine:(CGContextRef)context
              llCorners:(CORNERPOINTS *) latlonCornerPoints
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds
{
    if (![self continue])
        return;
    CGFloat sizeFactor = 1;
    
    /*if (_zoom > 18)
        sizeFactor *= (2.0 * (_zoom - 18.0));
    
    else if (_zoom < 18)
        */sizeFactor /= (2.0 * (22.0 - _zoom));
    CGFloat width = 100 * sizeFactor;
    
    NSString *query;
    sqlite3_stmt *statement;
    DPOINT BasePt;
    CGColorRef alleyLineColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1].CGColor;
    int numPoints,numLoops;
    //LPSTR symName;
    PropertyData *pd = [[PropertyData alloc] init];
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    [pd open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points FROM ALLEY_LINE,ALLEY_LINE_index WHERE ALLEY_LINE.id=ALLEY_LINE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            
            //querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
    }
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "displayAlleyLine");
    
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
        //symName = (LPSTR)sqlite3_column_text(statement,6);
        
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
        
        [self drawPlanLine:context
                   nPoints:numPoints
                    nLoops:numLoops
                   partLen:polyPartLen
                    points:llpoints
                 withColor:alleyLineColor
                  andWidth:width];
    }
    
    SQLOK(sqlite3_finalize(statement), "displayAlleyLine");
    [pd close];
}

- (int)pickAlleyLine:(LLPOINT)pt
              atZoom:(CGFloat)zoom
       highlightList:(NSMutableArray *)hlist
{
    if (![ConfigurationControl.sharedInstance layer:HCLayerAlleys
                                      visibleAtZoom:zoom])
        return 0;
    
    PropertyData *pd = [[PropertyData alloc] init];
    int nPicked = 0;
    CGFloat mind = DBL_MAX;
    DPOINT p1, pickedPoint, minpt, BasePt;
    NSString *minFid = @"";
    int minref = 0;
    int numPoints;
    
    p1.x = pt.lon;
    p1.y = pt.lat;
    minpt = p1;
    dbounds bnds = [CRAPI.sharedInstance getPickApBoundsAtPoint:&pt];
    [pd open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT ALLEY_LINE.id, ALLEY_LINE.ALLEYSEG, BasePointX, BasePointY,NumPoints,NumLoops,PolyPartLen,Points  FROM ALLEY_LINE,ALLEY_LINE_index WHERE  ALLEY_LINE.id=ALLEY_LINE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "preparePickPLAT");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR ALLEYSEG = (LPSTR)sqlite3_column_text(statement, 1);
        BasePt.x = sqlite3_column_double(statement, 2);
        BasePt.y = sqlite3_column_double(statement, 3);
        numPoints = sqlite3_column_int(statement,4);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,7);
        
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
        
        if (PICK_POINT_ON_LINE(p1, bnds, &pickedPoint, numPoints, llpoints))
        {
            if (findClosestPoint (&pickedPoint, &minpt, &mind, &p1))
            {
                nPicked++;
                minref = refno;
                minFid = [NSString stringWithUTF8String:ALLEYSEG];
            }
        }
        free (llpoints);
    }
    
    SQLOK(sqlite3_finalize(statement), "pickAlley");
    [pd close];
    pt.lon = minpt.x;
    pt.lat = minpt.y;
    
    if (nPicked)
    {
        PickedItem *pi = [[PickedItem alloc] init];
        pi.refno = minref;
        pi.itemType = PTAlleyLine;
        pi.distance = mind;
        pi.pickedPoint = minpt;
        pi.identifier = minFid;
        pi.symbolName = @"ALLEYDL";
        [hlist addObject:pi];
    }
    
    return nPicked;
}


-(void)displayWallPoint:(CGContextRef)context
              llCorners:(CORNERPOINTS *) latlonCornerPoints
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds
{
    NSString *query = @"";
    sqlite3_stmt *statement;
    DPOINT BasePt;
    //LPSTR symName;
    
    if (![self continue])
        return;
    CGFloat sizeFactor = 1;
    
    /*if (_zoom > 18)
        sizeFactor *= (2.0 * (_zoom - 18.0));
    
    else if (_zoom < 18)
        */sizeFactor /= (2.0 * (22.0 - _zoom));
    CGFloat size = 150 * sizeFactor;;
    
    PropertyData *pd = [[PropertyData alloc] init];
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBounds(latlonCornerPoints, pvbounds);
    
    [pd open];
    //CREATE TABLE ALLEYWALLS ('id' INT,'Wall ID' CHAR(8),'Hse No' INT,'STREET' CHAR(64),'City' CHAR(4),'Length' REAL,'Max Hght' REAL,'Offset' REAL,'Gar/Struc' CHAR(12),' COST' CHAR(12),'Type Const' CHAR(32),'InspDate' CHAR(12),'InspBy' CHAR(8),'Rating' CHAR(16),'Comments' CHAR(255),'LONGITUDE' REAL,'LATITUDE' REAL,PRIMARY KEY('id' ASC))

    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT LONGITUDE,LATITUDE FROM ALLEYWALLS,ALLEYWALLS_index WHERE ALLEYWALLS.id=ALLEYWALLS_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "prepareWallPt");
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);

        DPOINT llpoint = TranDPOINT(&BasePt, _pTranLLtoView);
        
        [self drawWallPoint:context
                    atPoint:&llpoint
                  withColor:UIColor.greenColor.CGColor
                    andSize:size];
    }
    
    SQLOK(sqlite3_finalize(statement), "displayWallPt");
    [pd close];
    
}

- (void)drawWallPoint:(CGContextRef)context
              atPoint:(DPOINT *)pPoint
            withColor:(CGColorRef)color
              andSize:(CGFloat)size
{
    CGRect pointRect = CGRectMake((pPoint->x - size / 2.0),
                                  (pPoint->y - size / 2.0), size, size);
    
    CGContextSetFillColorWithColor(context,color);
    CGContextFillEllipseInRect(context, pointRect);
    CGContextSetLineWidth(context, 2);
    
    if (ConfigurationControl.sharedInstance.GMTilesVisible)
        CGContextSetRGBStrokeColor(context, 1, 1, 0, 1);
    
    else
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
    
    CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
}

- (NSArray *)getDistinctSymbols:(NSString *)tableName
{
    NSMutableArray *symList = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    
    PropertyData *pd = [[PropertyData alloc] init];
    [pd open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT SYMBOLNAME FROM %@", tableName];
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "prepareDistinctSymbols");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        NSString * symName = [NSString stringWithUTF8String:(LPSTR)sqlite3_column_text(statement, 0)];
        [symList addObject:symName];
    }
    
    SQLOK(sqlite3_finalize(statement), "distinctSymbols");
    
    [pd close];
    
    
    return symList;
}

- (BOOL)moveAlleyWallPoint:(NSInteger)refno
                        to:(CLLocationCoordinate2D)point
{
    BOOL rtn = FALSE;
    PropertyData *pd = [[PropertyData alloc] init];
    [pd open];
    
    //rtn = sqlite3_exec(pd.database,"CREATE TABLE IF NOT EXISTS MOVEWALLPTUNDO ('id','LONGITUDE' REAL,'LATITUDE' REAL,PRIMARY KEY('id' ASC))", NULL, NULL, NULL);
    // NSString *query = [NSString stringWithFormat:@"UPDATE ALLEYWALLS SET LATITUDE = %f,LONGITUDE = %f lastUpdateTime=%i WHERE id=%i",
    //                    iTime, refno];
    
    NSString *query = [NSString stringWithFormat:@"UPDATE ALLEYWALLS SET LATITUDE = %f,LONGITUDE = %f WHERE id=%ld",
                       point.latitude,point.longitude, refno];
    
    rtn = sqlite3_exec(pd.database, query.UTF8String, NULL, NULL, NULL);
    
    if (!rtn)
    {
        query = [NSString stringWithFormat:@"UPDATE ALLEYWALLS_index SET minY=%f,minX=%f,maxY=%f,maxX=%f WHERE ALLEYWALLS_index.id=%ld",
                 point.latitude,point.longitude, point.latitude,point.longitude, refno];
        rtn = sqlite3_exec(pd.database, query.UTF8String, NULL, NULL, NULL);
    }
    
    [pd close];
    return !rtn;
}

- (void)userSavedAlleyWallPointMove:(BOOL)saved
{
    int ii = 1;
    ii = 2;
}

@end