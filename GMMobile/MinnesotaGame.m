//
//  MinnesotaGame.m
//  NVMobile
//
//  Created by Jeff Smith on 11/9/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import "MinnesotaGame.h"
#import "BoundaryData.h"

@implementation MinnesotaGame

- (void)dealloc
{
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
}

- (void)setTrans:(CORNERPOINTS *)corners
      viewBounds:(MNMXCORD *)pvbounds
{
    
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    _pTranLLtoView = STRANCornersToBoundsP(corners, pvbounds);
    _pTranViewtoLL = STRANBoundsToCornersP(corners, pvbounds);
}

- (void)displayPickedPoint:(LLPOINT)pt
                 inContext:(CGContextRef)context
               llCorners:(CORNERPOINTS *)latlonCornerPoints
                LLBounds:(MNMXCORD *)platlonBounds
              viewBounds:(MNMXCORD *)pvbounds
{
    if (pt.lat <= 0)
    {
        [self nextItem:nil];
        return;
    }
    _attempts++;
    DPOINT BasePt;
    CGColorRef color = UIColor.redColor.CGColor;
    [self setTrans:latlonCornerPoints viewBounds:pvbounds];
    
    BasePt.x = pt.lon;
    BasePt.y = pt.lat;
    DPOINT viewPoint = TranDPOINTP(&BasePt, _pTranLLtoView);
    [SymbolDictionary drawPointWithSymbol:context
                                       at:&viewPoint
                              usingSymbol:CircleSym
                                     Size:30
                                fillColor:color
                                lineColor:0
                                lineWidth:0];

    BoundaryData * bd = BoundaryData.new;
    int numPoints, numLoops;
    LPINT polyPartLen;

    double minDist = DBL_MAX;
    
    LPDPOINT pPoints = [bd getPolygonPointsForGameBoundary:_refno
                                                   inTable:@"COUNTIES"
                                                 numPoints:&numPoints
                                                  numLoops:&numLoops
                                               polyPartLen:&polyPartLen];
    BOOL inArea = POINT_IN_AREAD(BasePt, numPoints, pPoints, 1, 0, 0, 0);
    
    for (int i = 0;i < numPoints; i++)
    {
        double d = ArcDistance(BasePt, pPoints[i]);
        minDist = min (d, minDist);
        pPoints[i] = TranDPOINTP(&pPoints[i], _pTranLLtoView);
    }

    minDist = minDist / METERS_PER_MILE;
    
    if (_attempts > 2)
    {
        UIColor *boundaryColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        UIColor *fillColor = [UIColor colorWithRed:0 green:0 blue:0.75 alpha:0.5];
        [self drawBoundary:context
                   nPoints:numPoints
                    nLoops:numLoops
                   partLen:polyPartLen
                    points:pPoints
                 withColor:boundaryColor.CGColor
             withFillColor:fillColor.CGColor];
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           
        _timer = [NSTimer scheduledTimerWithTimeInterval:3
                                                  target:self
                                                selector:@selector(nextItem:)
                                                userInfo:nil
                                                 repeats:NO];

                       });

    }
 }

- (void)drawBoundary:(CGContextRef)context
             nPoints:(int)np
              nLoops:(int)nLoops
             partLen:(int *)pPartLen
              points:(LPDPOINT)pPoints
           withColor:(CGColorRef)color
           withFillColor:(CGColorRef)fillColor
{
    CGContextSetLineWidth(context, 5*UIScreen.mainScreen.scale);
    
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
            CGContextSetFillColorWithColor(context,fillColor);
            CGContextDrawPath(context, kCGPathEOFillStroke);
        }
    }
}

- (BOOL) nextItem:(NSTimer *)timer
{
    NSArray *choices = @[@"Lake1", @"Lake2"];
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [NVPopoverTableView showPopoverTableViewInView:_parentView
                                                             delegate:self
                                                                title:@"Choose One\nof the\nFollowing Cities"
                                                            textArray:choices
                                                        includeCancel:NO];
                   });
    
    return FALSE;
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    [popoverTableView hide:YES];
    _refno = 1084;

    if (index)
        _refno = 1060;
    _attempts = 0;
        
}
@end
