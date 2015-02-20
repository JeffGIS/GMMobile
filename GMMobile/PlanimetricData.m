//
//  PlanimetricData.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 2/19/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//
#define COORDINATE_FACTOR 10000000.0

#import "PlanimetricData.h"
#import "PropertyData.h"

@implementation PlanimetricData
{
    LPTRANDATA _pTranLLtoView;
    LPTRANDATA _pTranViewtoLL;

}

-(void)displayPlanArea:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
{
    NSString *query,*querys;
    sqlite3_stmt *statement;
    DPOINT BasePt;
    int numPoints,numLoops;
    LPSTR symName;
    PropertyData * pd = [[PropertyData alloc]init];
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANBoundsToBounds(platlonBounds, pvbounds);
    
    [pd open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,SYMBOLNAME FROM PLAN_AREA,PLAN_AREA_index WHERE PLAN_AREA.id=PLAN_AREA_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
            querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
    }
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "prepareDisplayLandUse");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        numLoops = sqlite3_column_int(statement,3);
        int *polyPartLen = (int *)sqlite3_column_blob(statement,4);
        int nBlobBytes = sqlite3_column_bytes(statement,4);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
        nBlobBytes = sqlite3_column_bytes(statement,5);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        symName = (LPSTR)sqlite3_column_text(statement,6);
        
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
        
        [self drawPlanArea:context
                   nPoints:numPoints
                    nLoops:numLoops
                   partLen:polyPartLen
                    points:llpoints
                 withColor:UIColor.redColor.CGColor];
    }
    
    SQLOK(sqlite3_finalize(statement), "displayParcels");
    [pd close];
}
- (void)fillPlanArea:(CGContextRef)context
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

- (void)drawPlanArea:(CGContextRef)context
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

-(void)displayPlanLine:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
{
    
        NSString *query,*querys;
        sqlite3_stmt *statement;
        DPOINT BasePt;
        int numPoints,numLoops;
        LPSTR symName;
        PropertyData * pd = [[PropertyData alloc]init];
        
        CloseTRANS2(&_pTranLLtoView);
        CloseTRANS2(&_pTranViewtoLL);
        
        _pTranLLtoView = STRANBoundsToBounds(platlonBounds, pvbounds);
        
        [pd open];
        
        switch (CRAPI.sharedInstance.project)
        {
            case PROJECT_METROGIS:
                query = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,SYMBOLNAME FROM PLAN_LINE,PLAN_LINE_index WHERE PLAN_LINE.id=PLAN_LINE_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                         platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
                querys = [NSString stringWithFormat:@"SELECT BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,USECODE,id FROM LANDUSE"];
        }
        
        SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "prepareDisplayLandUse");
        
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            BasePt.x = sqlite3_column_double(statement,0);
            BasePt.y = sqlite3_column_double(statement,1);
            numPoints = sqlite3_column_int(statement,2);
            numLoops = sqlite3_column_int(statement,3);
            int *polyPartLen = (int *)sqlite3_column_blob(statement,4);
            int nBlobBytes = sqlite3_column_bytes(statement,4);
            LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
            nBlobBytes = sqlite3_column_bytes(statement,5);
            LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
            symName = (LPSTR)sqlite3_column_text(statement,6);
            
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
                     withColor:UIColor.blackColor.CGColor];
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
{
    CGContextSetLineWidth(context, 2);
    
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
        
        //CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
        
        if (!CGContextIsPathEmpty(context))
        {
            CGContextSetStrokeColorWithColor(context,color);
            CGContextDrawPath(context, kCGPathStroke);
        }
    }
}

-(void)displayPlanPoint:(CGContextRef)context
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds
{
    NSString *query,*querys;
    sqlite3_stmt *statement;
    DPOINT BasePt;
    int numPoints,numLoops;
    LPSTR symName;
    PropertyData * pd = [[PropertyData alloc]init];
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANBoundsToBounds(platlonBounds, pvbounds);
    
    [pd open];
    
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT PointX,PointY,SYMBOLNAME FROM PLAN_POINT,PLAN_POINT_index WHERE PLAN_POINT.id=PLAN_POINT_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
    }
    
    SQLOK(sqlite3_prepare_v2(pd.database, query.UTF8String, -1, &statement, 0), "prepareDisplayLandUse");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        symName = (LPSTR)sqlite3_column_text(statement,2);
        
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
    CGRect pointRect = CGRectMake(pPoint->x, pPoint->y, 5, 5);
    
    CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
    
}

@end
