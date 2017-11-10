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

- (id)init
{
    self = [super init];
    
    if (self)
    {
        arc4random_uniform(100);
        self.gameDuration = 15;
        self.delayBetweenItems = 2;
        self.totalItems = 4 * 4;
        self.maxDistance = 450;
    }
    
    return self;
}

- (void) createHeaderLabel
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       CGRect rect = _parentView.frame;
                       rect.origin.x += 5;
                       rect.origin.y += 5;
                       rect.size.height = 90;
                       rect.size.width -= 10;
                       UILabel *label = [[UILabel alloc] initWithFrame:rect];
                       label.backgroundColor = [UIColor blueColor];
                       label.textAlignment = NSTextAlignmentCenter;
                       label.textColor = [UIColor whiteColor];
                       label.numberOfLines = 0;
                       label.lineBreakMode = UILineBreakModeWordWrap;
                       label.font = [UIFont boldSystemFontOfSize:32.0];
                       label.text = @"Locate Lake Minnetonka";
                       [_parentView addSubview:label];
                       [_parentView bringSubviewToFront:label];
                       _headerLabel = label;
                   });
}

- (void) createTimerLabel
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       CGRect rect = _parentView.frame;
                       rect.origin.x += rect.size.width * 0.65;
                       rect.origin.y += 95 * 1.25;
                       rect.size.height = 90 * 1.5;
                       rect.size.width *= 0.3;
                       UILabel *label = [[UILabel alloc] initWithFrame:rect];
                       label.backgroundColor = [UIColor yellowColor];
                       label.textAlignment = NSTextAlignmentCenter;
                       label.textColor = [UIColor blackColor];
                       label.numberOfLines = 0;
                       label.lineBreakMode = UILineBreakModeWordWrap;
                       label.font = [UIFont boldSystemFontOfSize:32.0];
                       label.text = @"Seconds Remaining\n200";
                       [_parentView addSubview:label];
                       [_parentView bringSubviewToFront:label];
                       _timerLabel = label;
                   });
}

- (void) createDistanceLabel
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       CGRect rect = _parentView.frame;
                       rect.origin.x = rect.origin.x + rect.size.width * 0.7;
                       rect.origin.y = rect.origin.y + rect.size.height /  2;
                       rect.size.height = 90;
                       rect.size.width *= 0.3;
                       rect.size.width -= 5;
                       UILabel *label = [[UILabel alloc] initWithFrame:rect];
                       label.backgroundColor = [UIColor yellowColor];
                       label.textAlignment = NSTextAlignmentCenter;
                       label.textColor = [UIColor blackColor];
                       label.numberOfLines = 0;
                       label.lineBreakMode = UILineBreakModeWordWrap;
                       label.font = [UIFont boldSystemFontOfSize:32.0];
                       label.text = @"";
                       [_parentView addSubview:label];
                       [_parentView bringSubviewToFront:label];
                       _distanceLabel = label;
                   });
}

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
    if (!_headerLabel)
        [self createHeaderLabel];
    if (!_distanceLabel)
        [self createDistanceLabel];
    if (!_timerLabel)
        [self createTimerLabel];
    if (!_attempts++)
    {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           
                           _timer = [NSTimer scheduledTimerWithTimeInterval:3
                                                                     target:self
                                                                   selector:@selector(nextItem:)
                                                                   userInfo:nil
                                                                    repeats:NO];
                           
                       });
        return;
    }
    if (_attempts > 5)
        return;
    if (pt.lat < 0)
        return;
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
    if (!pPoints)
        return;
    BOOL inArea = POINT_IN_AREAD(BasePt, numPoints, pPoints, 1, 0, 0, 0);
    
    if (inArea)
        minDist = 0;
    for (int i = 0;i < numPoints; i++)
    {
        double d = ArcDistance(BasePt, pPoints[i]);
        minDist = min (d, minDist);
        pPoints[i] = TranDPOINTP(&pPoints[i], _pTranLLtoView);
    }
    
    _distance = max (0,minDist / METERS_PER_MILE);
    [self hideViews];
    [self bringViewsToFront];
    if (_attempts > 4 || _distance < 1)
    {
        _totDistance += _distance;
        _itemsCompleted++;
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
                           
        _timer = [NSTimer scheduledTimerWithTimeInterval:_delayBetweenItems
                                                  target:self
                                                selector:@selector(nextItem:)
                                                userInfo:nil
                                                 repeats:NO];

                       });
   }
 }

- (void) displayGameTimer:(NSTimer *)timer
{
    int timeRemaining = _endTime - [NSDate timeIntervalSinceReferenceDate];
    if (timeRemaining > 0)
    {
        _timerLabel.text = [NSString stringWithFormat:@"Seconds Remaining\n%i",timeRemaining];
        [self bringViewsToFront];
     }
    else
    {
        [timer invalidate];
        _wantViews = NO;
        _gameTimer = nil;
        [self hideViews];
        if (_timer)
        {
            [_timer invalidate];
            _timer = nil;
        }
        [_poTableView hide:YES];
        _popoverView = [[GSSiPopoverView alloc] initWithView:_mvc.view];
        _popoverView.delegate = self;
        _popoverView.progressView.hidden = YES;
        _popoverView.progressLabel.hidden = YES;
        _popoverView.cancelButtonTitle = @" Start Next Game ";
        [_popoverView showAfter:0.1
                      withTitle:[NSString stringWithFormat:@"Done\nItems Completed:%i\nScore:%i",_itemsCompleted,_totDistance+(_totalItems - _itemsCompleted)*_maxDistance]];
    }
}
-(void) bringViewsToFront
{
    if (!_wantViews)
        return;
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       if (_distance >= 0)
                           _distanceLabel.text = [NSString stringWithFormat:@"%.0f miles",_distance];
                       else
                           _distanceLabel.text = @"";
                       [_headerLabel setHidden:NO];
                       [_distanceLabel setHidden:NO];
                       [_timerLabel setHidden:NO];
                       [_parentView bringSubviewToFront:_headerLabel];
                       [_parentView bringSubviewToFront:_distanceLabel];
                       [_parentView bringSubviewToFront:_timerLabel];
                   });

}
-(void) hideViews
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [_headerLabel setHidden:YES];
                       [_distanceLabel setHidden:YES];
                       [_timerLabel setHidden:YES];
                   });

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
    _choices=@[@"Lake1",@"Lake2"];
    [self hideViews];
    _wantViews = NO;
    LLPOINT p = {-1,-1};
    CRAPI.sharedInstance.lastPickPoint = p;
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       _poTableView = [NVPopoverTableView showPopoverTableViewInView:_parentView
                                                             delegate:self
                                                                title:@"Choose One\nof the\nFollowing Cities"
                                                            textArray:_choices
                                                        includeCancel:NO];
                   });
    
    return FALSE;
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    _refno = 1084;

    if (index)
        _refno = 1060;
    _attempts = 1;
    _distance = -1;
    _wantViews = YES;
    _headerLabel.text = [NSString stringWithFormat:@"Lake %i",index+1];
    _distanceLabel.text = @"Start";
    [self bringViewsToFront];
    if (!_gameTimer)
    {
        _totDistance = 0;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           _itemsCompleted = 0;
                           
                           _endTime = [NSDate timeIntervalSinceReferenceDate] + _gameDuration;
                           
                           _gameTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                         target:self
                                                                       selector:@selector(displayGameTimer:)
                                                                       userInfo:nil
                                                                        repeats:YES];
                           
                       });
        
    }

    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [popoverTableView hide:YES];

                       _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                 target:self.mvc
                                                               selector:@selector(extentZoom2:)
                                                               userInfo:nil
                                                                repeats:NO];
                       
                   });

}
- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    [popoverView hide];
    [self nextItem:nil];
}
@end
