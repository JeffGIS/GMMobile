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

static int groupCount[4]={87,500,84,193};

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.delayBetweenItems = 2.0;
        self.maxDistance = 450;
        self.numPerGroup = 5;
        self.numChoicesPerItem = 4;
        self.numGroups = 4;
        self.totalItems = self.numPerGroup * self.numGroups;
        _groupNames = @[@"Counties",@"Cities",@"State Parks",@"Lakes"];
        _groupName = @[@"County",@"City",@"State Park",@"Lake"];
        self.gameDuration = 60 * self.numGroups;
        CRAPI.sharedInstance.maskTransparency = 0;
        CRAPI.sharedInstance.boundaryBorderWidth = 3;
    }
    
    return self;
}

- (void) createHeaderLabel
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       CGRect rect = _parentView.frame;
                       rect.origin.x += 86;
                       rect.origin.y += 20;
                       rect.size.height = 90;
                       rect.size.width -= 86*2;
                       UILabel *label = [[UILabel alloc] initWithFrame:rect];
                       label.backgroundColor = [UIColor clearColor];
                       label.textAlignment = NSTextAlignmentCenter;
                       label.textColor = [UIColor brownColor];
                       label.numberOfLines = 0;
                       label.lineBreakMode = NSLineBreakByWordWrapping;
                       label.font = [UIFont systemFontOfSize:36.0];
                      // label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];

                       label.text = @"Pick a County to Start";
                       [_parentView addSubview:label];
                       [_parentView bringSubviewToFront:label];
                       _headerLabel = label;
                   });
}

- (void) createTimerLabel
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       NSString * hourglassFile = [NSBundle.mainBundle pathForResource:@"hourglass1"
                                                                       ofType:@"png"];

                       CGRect rect = _parentView.frame;
                       rect.origin.x = rect.origin.x + rect.size.width - 86;
                       rect.origin.y = 20;
                       rect.size.height = 161;
                       rect.size.width = 86;
                       UIImageView *hourglass = [[UIImageView alloc]initWithFrame:rect];
                       NSMutableArray *imageArray = NSMutableArray.new;
                       [imageArray addObject:[UIImage imageWithContentsOfFile:hourglassFile]];
                       hourglassFile = [NSBundle.mainBundle pathForResource:@"hourglass2"
                                                                     ofType:@"png"];
                       [imageArray addObject:[UIImage imageWithContentsOfFile:hourglassFile]];
                       hourglassFile = [NSBundle.mainBundle pathForResource:@"hourglass3"
                                                                     ofType:@"png"];
                       [imageArray addObject:[UIImage imageWithContentsOfFile:hourglassFile]];
                       hourglassFile = [NSBundle.mainBundle pathForResource:@"hourglass4"
                                                                     ofType:@"png"];
                       [imageArray addObject:[UIImage imageWithContentsOfFile:hourglassFile]];
                       hourglass.animationImages = imageArray;
                       rect.origin.y += rect.size.height;
                       rect.size.height = 40;
                       UILabel *label = [[UILabel alloc] initWithFrame:rect];
                       label.backgroundColor = [UIColor clearColor];
                       label.textAlignment = NSTextAlignmentCenter;
                       label.textColor = [UIColor blackColor];
                       label.numberOfLines = 0;
                       label.font = [UIFont boldSystemFontOfSize:28.0];
                       label.font = [UIFont monospacedDigitSystemFontOfSize:28 weight:UIFontWeightBlack];
                       label.text = @"";
                       [_parentView addSubview:label];
                       [_parentView bringSubviewToFront:label];
                       [_parentView addSubview:hourglass];
                       [_parentView bringSubviewToFront:hourglass];
                       _timerLabel = label;
                       _hourglassImage = hourglass;
                   });
}

- (void) createDistanceLabel
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       CGRect rect = _parentView.frame;
                       rect.origin.x = rect.origin.x + rect.size.width * 0.68;
                       rect.origin.y = rect.origin.y + rect.size.height* 0.7;
                       rect.size.height = 90;
                       rect.size.width *= 0.3;
                       rect.size.width -= 5;
                       UILabel *label = [[UILabel alloc] initWithFrame:rect];
                       label.backgroundColor = [UIColor clearColor];
                       label.textAlignment = NSTextAlignmentCenter;
                       label.textColor = [UIColor blackColor];
                       label.numberOfLines = 0;
                       label.lineBreakMode = NSLineBreakByWordWrapping;
                       label.font = [UIFont systemFontOfSize:32.0];
                       label.text = @"";
                       [_parentView addSubview:label];
                       [_parentView bringSubviewToFront:label];
                       _distanceLabel = label;
                       rect = _parentView.frame;
                       rect.origin.x = rect.origin.x + rect.size.width * 0.68;
                       rect.origin.y = rect.origin.y + rect.size.height* 0.52;
                       rect.size.height = 90*2;
                       rect.size.width = (rect.size.height * 420)/340.0;
                       UIImageView *happySad = [[UIImageView alloc]initWithFrame:rect];
                       happySad.layer.borderColor = [UIColor brownColor].CGColor;
                       happySad.layer.borderWidth = 5;
                       _happySadImage = happySad;
                       [_parentView addSubview:_happySadImage];
                       [_parentView bringSubviewToFront:_happySadImage];
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
                           
                           _timer = [NSTimer scheduledTimerWithTimeInterval:_delayBetweenItems
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
    CGColorRef pointColor = UIColor.redColor.CGColor;
    CGColorRef starColor = UIColor.orangeColor.CGColor;
    CGColorRef blackColor = UIColor.blackColor.CGColor;
    [self setTrans:latlonCornerPoints viewBounds:pvbounds];
    
    BasePt.x = pt.lon;
    BasePt.y = pt.lat;
    DPOINT viewPoint = TranDPOINTP(&BasePt, _pTranLLtoView);
    [SymbolDictionary drawPointWithSymbol:context
                                       at:&viewPoint
                              usingSymbol:CircleSym
                                     Size:20*UIScreen.mainScreen.scale
                                fillColor:pointColor
                                lineColor:blackColor
                                lineWidth:1*UIScreen.mainScreen.scale];

    BoundaryData * bd = BoundaryData.new;
    int numPoints, numLoops;
    LPINT polyPartLen;

    double minDist = DBL_MAX;
    
    LPDPOINT pPoints = [bd getPolygonPointsForGameBoundary:_refno
                                                   inTable:_areaType
                                                 numPoints:&numPoints
                                                  numLoops:&numLoops
                                               polyPartLen:&polyPartLen];
    if (!pPoints)
        return;
    BOOL inArea = POINT_IN_AREAD(BasePt, numPoints, pPoints, 1, 0, 0, 0);
    
    if (inArea)
    {
        minDist = 0;
        _minPoint = _bestGuessPoint = BasePt;
    }
    for (int i = 0;i < numPoints; i++)
    {
        double d = ArcDistance(BasePt, pPoints[i]);
        if (d < minDist)
        {
            minDist = d;
            _minPoint = pPoints[i];
        }
        pPoints[i] = TranDPOINTP(&pPoints[i], _pTranLLtoView);
    }
    
    _distance = max (0,minDist / METERS_PER_MILE);
    if (_distance < _bestGuess)
    {
        _bestGuessPoint = BasePt;
        _bestGuess = _distance;
    }
    [self hideViews];
    [self loadHappySadImage:_distance];

    [self bringViewsToFront:NO];
    if (_attempts > 4 || _distance < 1)
    {
        _totDistance += _bestGuess;
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
        DPOINT viewPoint = TranDPOINTP(&_minPoint, _pTranLLtoView);
        [SymbolDictionary drawPointWithSymbol:context
                                           at:&viewPoint
                                  usingSymbol:Star2Sym
                                         Size:50*UIScreen.mainScreen.scale
                                    fillColor:starColor
                                    lineColor:blackColor
                                    lineWidth:1*UIScreen.mainScreen.scale];
        viewPoint = TranDPOINTP(&_bestGuessPoint, _pTranLLtoView);
        [SymbolDictionary drawPointWithSymbol:context
                                           at:&viewPoint
                                  usingSymbol:CircleSym
                                         Size:20*UIScreen.mainScreen.scale
                                    fillColor:blackColor
                                    lineColor:blackColor
                                    lineWidth:1*UIScreen.mainScreen.scale];

        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           
        _timer = [NSTimer scheduledTimerWithTimeInterval:_delayBetweenItems
                                                  target:self
                                                selector:@selector(nextItem:)
                                                userInfo:nil
                                                 repeats:NO];

                       });
   }
   if (pPoints)
       free (pPoints);
 }

- (void) displayGameTimer:(NSTimer *)timer
{
    int timeRemaining = _endTime - [NSDate timeIntervalSinceReferenceDate];
    if (timeRemaining > 0)
    {
        int minutes = timeRemaining / 60;
        int seconds = timeRemaining % 60;
        _timerLabel.text = [NSString stringWithFormat:@"%i:%.2i",minutes,seconds];
        [self bringViewsToFront:YES];
     }
    else
    {
        [timer invalidate];
        [_hourglassImage stopAnimating];

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
- (void) loadHappySadImage:(int) distance
{
    static int lasti = 0;
    static int lastd = 0;
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{

    if (distance < 0)
        _happySadImage.image = nil;
    else{
        int idist = 8;
        if (distance > 1)
        {
            idist = distance / 50 + 1;
            idist = 8 - idist;
            if (idist == lasti)
            {
                if (lastd < distance)
                    idist--;
                else
                    idist++;
            }
            idist = max (1,min (7,idist));
            
        }
        NSString *file = [NSBundle.mainBundle pathForResource:[NSString stringWithFormat:@"happy%i",idist]
                                                       ofType:@"png"];
        _happySadImage.image = [UIImage imageWithContentsOfFile:file];
        lasti = idist;
        lastd = distance;
    }
                   });
}
-(void) bringViewsToFront:(BOOL)fromTimer
{
    if (!_wantViews)
        return;
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       if (!fromTimer)
                       {
                           if (_distance > 1)
                           {
                               _distanceLabel.text = [NSString stringWithFormat:@"You missed by\n%.0f miles",_distance];
                           }
                           else if (_distance >= 0)
                           {
                               _distanceLabel.text = @"YOU GOT IT!";
                           }
                           else
                           {
                               _distanceLabel.text = @"";
                           }
                       }
                       [_headerLabel setHidden:NO];
                       [_distanceLabel setHidden:NO];
                       [_timerLabel setHidden:NO];
                       [_hourglassImage setHidden:NO];
                       [_parentView bringSubviewToFront:_headerLabel];
                       [_parentView bringSubviewToFront:_distanceLabel];
                       [_parentView bringSubviewToFront:_timerLabel];
                       [_parentView bringSubviewToFront:_hourglassImage];
                       [_parentView bringSubviewToFront:_happySadImage];
                   });

}
-(void) hideViews
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [_headerLabel setHidden:YES];
                       [_distanceLabel setHidden:YES];
                       [_timerLabel setHidden:YES];
                       //[_hourglassImage setHidden:YES];
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
    CGContextSetLineWidth(context, 2*UIScreen.mainScreen.scale);
    
    if (nLoops < 0)
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
            CGContextDrawPath(context, kCGPathEOFill);
        }
    }
}

- (int) refnoInGroup:(int)group
               index:(int)index
{
    int ref = -1;
    NSString * fileName = @"";
    switch (group)
    {
        case 0:
            fileName = @"Counties";
            _areaType = @"COUNTIES";
            break;
        case 1:
            fileName = @"TOP500Cities";
            _areaType = @"CITIES";
           break;
        case 2:
            fileName = @"PARKS";
            _areaType = @"PARKS";
            break;
        case 3:
            fileName = @"Top200Lakes";
            _areaType = @"WATERAREA";
            break;
    }
    NSString * file = [NSBundle.mainBundle pathForResource:fileName
                                                      ofType:@"TXT"];
    NSString * fileContents = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    NSArray * fileItems = [fileContents componentsSeparatedByString:@"\n"];
    index++;
    if (index < fileItems.count)
    {
        int inc = 0;
        if (group == 1)
            inc = 1;
        NSString *item = fileItems[index];
        NSArray <NSString*> *txt = [item componentsSeparatedByString:@"\t"];
        if (group == 3)
        {
            ref = (int)txt[1].integerValue;
            _itemDescription = txt[0];
        }
        else
        {
            ref = (int)txt[0+inc].integerValue;
            _itemDescription = txt[1+inc];
        }
    }
    return ref;
}

- (BOOL) inUsedChoices:(int)refno
{
    BOOL rtn = FALSE;
    for (NSNumber * nm in _usedChoices)
    {
        if (nm.integerValue == refno)
            return TRUE;
    }
    NSNumber *nm = [NSNumber numberWithInteger:refno];
    [_usedChoices addObject:nm];
    return rtn;
}

-(NSArray *) nextChoices:(BOOL)newGame
{
    NSMutableArray * choices = NSMutableArray.new;
    if (newGame)
    {
        arc4random_stir ();
        _usedChoices = NSMutableArray.new;
        _itemCount = 0;
    }
    _group = _itemCount++ / _numPerGroup;
    if (_group >= _numGroups)
        return nil;
    _itemType = _groupNames[_group];
    int iChoice = 0;
    while (iChoice < _numChoicesPerItem)
    {
        int refno = [self refnoInGroup:_group
                                 index:arc4random_uniform(groupCount[_group])];
        while ([self inUsedChoices:refno])
        {
            refno = [self refnoInGroup:_group
                                 index:arc4random_uniform(groupCount[_group])];
        }
        NSString * choice = [NSString stringWithFormat:@"%@\x03%i",_itemDescription,refno];
        [choices addObject:choice];
        iChoice++;
    }
    return choices;
}
- (BOOL) nextItem:(NSTimer *)timer
{
    BOOL newGame = TRUE;
    if (_gameTimer)
        newGame = FALSE;
    _choices=[self nextChoices:newGame];
    if (!_choices)
    {
        _endTime = [NSDate timeIntervalSinceReferenceDate];
        return FALSE;
    }
    [self hideViews];
    _wantViews = NO;
    LLPOINT p = {-1,-1};
    CRAPI.sharedInstance.lastPickPoint = p;
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       _poTableView = [NVPopoverTableView showPopoverTableViewInView:_parentView
                                                             delegate:self
                                                                title:[NSString stringWithFormat:@"Choose One\nof the\nFollowing %@",_itemType]
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

    NSString * choice = _choices[index];
    
    NSString * crefno = textAfter(choice, @"\x03");
    NSString * name = textBefore(choice, @"\x03");
    NSString * type = _groupName[_group];
    _refno = (int)crefno.integerValue;
    _attempts = 1;
    _distance = -1;
    [self loadHappySadImage:_distance];

    _bestGuess = 500;
    _wantViews = YES;
    _headerLabel.text = [NSString stringWithFormat:@"Locate %@\n%@",type,name];
    _distanceLabel.text = @"Start";
    [self bringViewsToFront:NO];
    if (!_gameTimer)
    {
        _totDistance = 0;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           _itemsCompleted = 0;
                           
                           _endTime = [NSDate timeIntervalSinceReferenceDate] + _gameDuration;
                           _hourglassImage.animationDuration = _gameDuration;
                           [_hourglassImage startAnimating];
                           [self displayGameTimer:nil];
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
                                                               selector:@selector(vectorViewRefresh)
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
