//  PlatImageView.m
//  GMMobile

#import "PlatImageView.h"
#import "SewerData.h"

#define MAX_PROFILE_AREAS 8

@interface PlatImageView ()

@property (nonatomic) LPTRANDATA pTranLatlonToImage, pTranImageToLatlon;
@property (nonatomic) LPTRANDATA pTranFrameToImage, pTranImageToFrame;
@property (nonatomic, copy) NSString *platType, *platName;
@property (nonatomic) int numProfileAreas;

@end

@implementation PlatImageView
{
    DPOINT _imageCorners[4];
    DPOINT _virtualImageCorners[4];
    DPOINT _imageCornersWorld[4];
    DPOINT _virtualImageCornersWorld[4];
    NSInteger _numProfileAreaPoints[MAX_PROFILE_AREAS];
    LPDPOINT _profileAreaPoints[MAX_PROFILE_AREAS];
}

+ (PlatImageView *)platImageViewWithDelegate:(id)delegate
                                    andFrame:(CGRect)frame
{
    PlatImageView *platView = [[PlatImageView alloc] init];
    
    platView.frame = frame;
    platView.contentMode = UIViewContentModeScaleAspectFit;
    platView.userInteractionEnabled = YES;
    [platView addGesturesToView];
    
    NSString *imagePath = CRAPI.sharedInstance.currentPlatImagePath;
    platView.platType = CRAPI.sharedInstance.currentPlatType;
    
    platView.platType = @"SAN";
    imagePath = [NSBundle.mainBundle pathForResource:@"S-N-54"
                                              ofType:@"jpg"];
    
    platView.platType = @"SAN";
    imagePath = [NSBundle.mainBundle pathForResource:@"S-55S-2"
                                              ofType:@"jpg"];

    platView.platType = @"STORM";
    imagePath = [NSBundle.mainBundle pathForResource:@"SD-30A-10"
                                              ofType:@"jpg"];
   
    platView.image = [UIImage imageWithContentsOfFile:imagePath];
    platView.platName = imagePath.lastPathComponent.stringByDeletingPathExtension;
    platView.delegate = delegate;
    [platView getPlatTransformation];
    return platView;
}

- (void)dealloc
{
    CloseTRANS2(&_pTranImageToLatlon);
    CloseTRANS2(&_pTranLatlonToImage);
    CloseTRANS2(&_pTranFrameToImage);
    CloseTRANS2(&_pTranImageToFrame);
    
    for (int i = 0; i < _numProfileAreas; i++)
        free(_profileAreaPoints[i]);
    
    _numProfileAreas = 0;
    
    NSLog(@"Sewer Database dealloc");
}

- (void)setPlatID:(int)refno andType:(int)platType
{
    NSString *type = @"STORM";
    if (platType == PLAT_TYPE_SANITARY)
        type = @"SAN";
    
    sqlite3_stmt *statement;
    SewerData *sd = [[SewerData alloc] init];
    [sd open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PLAT_NAME FROM %@_PLAT WHERE id = %i;",
                       type,refno];
    
    SQLOKswr(sqlite3_prepare_v2(sd.database, query.UTF8String, -1, &statement, 0), "setPlatID");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR platname = (LPSTR)sqlite3_column_text(statement, 0);
        _platName = [NSString stringWithUTF8String:platname];
        _platType = type;
    }
    
    SQLOKswr(sqlite3_finalize(statement), "setPlatID");
    [sd close];
    [self getPlatTransformation];
    [self setNeedsDisplay];
}

- (DPOINT)latLonToImage:(LLPOINT)latLonPoint
{
    DPOINT dptIn, dptOut;
    dptIn.x = latLonPoint.lon;
    dptIn.y = latLonPoint.lat;
    dptOut = TranDPOINT(&dptIn, _pTranLatlonToImage);
    return dptOut;
}

- (LLPOINT)imageToLatLon:(DPOINT)imagePoint
{
    LLPOINT llPt;
    DPOINT dptOut;
    dptOut = TranDPOINT(&imagePoint, _pTranImageToLatlon);
    llPt.lon = dptOut.x;
    llPt.lat = dptOut.y;
    return llPt;
}

- (DPOINT)frameToImage:(DPOINT)framePoint
{
    DPOINT imagePoint = TranDPOINT(&framePoint, _pTranFrameToImage);
    return imagePoint;
}

- (DPOINT)imageToFrame:(DPOINT)imagePoint
{
    DPOINT framePoint = TranDPOINT(&imagePoint, _pTranImageToFrame);
    return framePoint;
}

- (CLLocationCoordinate2D)imageToCLLocationCoordinate2D:(DPOINT)imagePoint
{
    CLLocationCoordinate2D llPt;
    DPOINT dptOut;
    dptOut = TranDPOINT(&imagePoint, _pTranImageToLatlon);
    llPt.longitude = dptOut.x;
    llPt.latitude = dptOut.y;
    return llPt;
}

- (CGRect) frameRectToVirtualImageRect:(CGRect)frameRect bounds:(CGRect)bnd
{
    CGRect imageRect;
    MNMXCORD screenBounds;
    MNMXCORD imageBounds;
    DPOINT frameCorners[4];
    float rsq;
    
    frameCorners[0].x = frameCorners[1].x = frameRect.origin.x;
    frameCorners[1].y = frameCorners[2].y = frameRect.origin.y;
    frameCorners[2].x = frameCorners[3].x = frameRect.origin.x + frameRect.size.width;
    frameCorners[0].y = frameCorners[3].y = frameRect.origin.y + frameRect.size.height;
    LPTRANDATA pTran = STRANPoints(frameCorners, _virtualImageCorners, 4, 1, &rsq);
    
    screenBounds.xmn = bnd.origin.x;
    screenBounds.ymn = bnd.origin.y;
    screenBounds.xmx = screenBounds.xmn + bnd.size.width;
    screenBounds.ymx = screenBounds.ymn + bnd.size.height;
    TranMNMXCORD(&screenBounds, &imageBounds,pTran);
    CloseTRANS2(&pTran);
    
    imageRect = CGRectMake(imageBounds.xmn,imageBounds.ymn, imageBounds.xmx - imageBounds.xmn, imageBounds.ymx - imageBounds.ymn);
    return imageRect;
}
- (CGFloat)zoomForMapBounds:(CGRect)frameRect
                    bearing:(CGFloat *)bearing
                     target:(CLLocationCoordinate2D *)target
                mapViewSize:(CGSize)size
                       minYpt:(DPOINT *)minYpt
                       maxYpt:(DPOINT *)maxYpt
{
    CGRect bnd = self.bounds;
    CGRect imageRect = [self frameRectToVirtualImageRect:frameRect bounds:bnd];
    GMSVisibleRegion region = [self imageRectToMapRegion:imageRect];
    _mapViewSize = size;
    CGFloat minY, maxY;
    
    CLLocationCoordinate2D center;
    
    CGFloat zoom = [self zoomForVisibleRegion:region
                                       target:&center];
    
    DPOINT ptImage1, ptImage2;
    DPOINT ptLev201, ptLev202;
    
    ptImage1.x = ptImage2.x = imageRect.origin.x + imageRect.size.width/2;
    ptImage1.y = imageRect.origin.y - imageRect.size.height/2;
    ptImage2.y = imageRect.origin.y + imageRect.size.height/2;
    ptLev201 = TranDPOINT(&ptImage1, _pTranImageToLatlon);
    ptLev202 = TranDPOINT(&ptImage2, _pTranImageToLatlon);
    CGFloat az = getazd(&ptLev201, &ptLev202);
    CGFloat trueBearing = (LTWOPI(HALFPI - az) * DEGRAD);
    *bearing = ((roundf(trueBearing / 5.0)) * 5.0);
    *target = center;

    if ([self getYValueRangeForProfileAtX:ptImage1.x
                                     minY:&minY
                                     maxY:&maxY])
    {
        ptImage1.y = minY;
        ptImage2.x = ptImage1.x;
        ptImage2.y = maxY;
        *minYpt = ptImage1;
        *maxYpt = ptImage2;
    }
    
    return zoom;
}

- (CGFloat)zoomForVisibleRegion:(GMSVisibleRegion)region
                         target:(CLLocationCoordinate2D *)target
{
    CLLocation *farLeft = [[CLLocation alloc] initWithLatitude:region.farLeft.latitude
                                                     longitude:region.farLeft.longitude];
    
    CLLocation *nearRight = [[CLLocation alloc] initWithLatitude:region.nearRight.latitude
                                                       longitude:region.nearRight.longitude];
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(((farLeft.coordinate.latitude + nearRight.coordinate.latitude) / 2.0),
                                                               ((farLeft.coordinate.longitude + nearRight.coordinate.longitude) / 2.0));
    
    *target = center;
    
    CLLocationDistance diagonalDist = [farLeft distanceFromLocation:nearRight];
    
    NSInteger pixDist = sqrt((_mapViewSize.height * _mapViewSize.height) +
                             (_mapViewSize.width * _mapViewSize.width));
    
    CGFloat zoom = [GMSCameraPosition zoomAtCoordinate:center
                                             forMeters:diagonalDist
                                             perPoints:pixDist];
    
    return zoom;
}

- (GMSVisibleRegion)imageRectToMapRegion:(CGRect)imageRect
{
    GMSVisibleRegion region;
    DPOINT frameCornersImage[4];
    DPOINT frameCornersWorld[4];
    
    frameCornersImage[0].x = imageRect.origin.x;
    frameCornersImage[0].y = imageRect.origin.y + imageRect.size.height;
    frameCornersImage[1].x = imageRect.origin.x;
    frameCornersImage[1].y = imageRect.origin.y;
    frameCornersImage[2].x = imageRect.origin.x + imageRect.size.width;
    frameCornersImage[2].y = imageRect.origin.y;
    frameCornersImage[3].x = imageRect.origin.x + imageRect.size.width;
    frameCornersImage[3].y = imageRect.origin.y + imageRect.size.height;

    TranPoints(frameCornersImage, frameCornersWorld, 4, _pTranImageToLatlon);
    
    for (int i = 0; i < 4; i++)
    {
        PixelXYToLatLongd(frameCornersWorld[i].x, frameCornersWorld[i].y, 20,
                          &frameCornersWorld[i].y, &frameCornersWorld[i].x);
    }
    
    region.nearLeft.longitude = frameCornersWorld[0].x;
    region.nearLeft.latitude = frameCornersWorld[0].y;
    region.farLeft.longitude = frameCornersWorld[1].x;
    region.farLeft.latitude = frameCornersWorld[1].y;
    region.farRight.longitude = frameCornersWorld[2].x;
    region.farRight.latitude = frameCornersWorld[2].y;
    region.nearRight.longitude = frameCornersWorld[3].x;
    region.nearRight.latitude = frameCornersWorld[3].y;
    
    return region;
}

- (BOOL)getPlatTransformation
{
    NSString *query;
    sqlite3_stmt *statement;
    double imagex[32], imagey[32], worldx[32], worldy[32];
    float rsq;
    int npt = 0;
    
    CloseTRANS2(&_pTranImageToLatlon);
    CloseTRANS2(&_pTranLatlonToImage);
    SewerData *sd = [[SewerData alloc] init];
    [sd open];
    
    query = [NSString stringWithFormat:@"SELECT IMAGEX,IMAGEY,WORLDX,WORLDY FROM %@_PLAT_CPT WHERE PLAT_NAME = '%@';",
                       _platType, _platName];
    
    
    SQLOKswr(sqlite3_prepare_v2(sd.database, query.UTF8String, -1, &statement, 0), "");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        imagex[npt] = sqlite3_column_double(statement, 0);
        imagey[npt] = sqlite3_column_double(statement, 1);
        //imagey[npt] = self.image.size.height - imagey[npt];
        worldx[npt] = sqlite3_column_double(statement, 2);
        worldy[npt++] = sqlite3_column_double(statement, 3);
    }
    
    _pTranImageToLatlon = STRAN2(0, imagex, imagey, worldx, worldy, npt,2, &rsq);
    _pTranLatlonToImage = STRAN2(0, worldx, worldy, imagex, imagey, npt,2, &rsq);
    
    SQLOKswr(sqlite3_finalize(statement), "pickPLAT");
    _imageCorners[0].x = _imageCorners[0].y = 0;
    _imageCorners[1].x = 0;
    _imageCorners[1].y = self.image.size.height;
    _imageCorners[2].x = self.image.size.width;
    _imageCorners[2].y = self.image.size.height;
    _imageCorners[3].x = self.image.size.width;
    _imageCorners[3].y = 0;
    TranPoints (_imageCorners,_imageCornersWorld,4,_pTranImageToLatlon);
    DPOINT imageCornersFrame[4];
    CGFloat midx = self.frame.origin.x + self.frame.size.width / 2;
    CGFloat midy = self.frame.origin.y + self.frame.size.height / 2;
    CGFloat scale = min (self.frame.size.height/self.image.size.height,self.frame.size.width/self.image.size.width)/2;
    imageCornersFrame[0].x = imageCornersFrame[1].x = midx - self.image.size.width * scale;
    imageCornersFrame[0].y = imageCornersFrame[3].y = midy + self.image.size.height * scale;
    imageCornersFrame[2].x = imageCornersFrame[3].x = midx + self.image.size.width * scale;
    imageCornersFrame[1].y = imageCornersFrame[2].y = midy - self.image.size.height * scale;
    CloseTRANS2(&_pTranFrameToImage);
    CloseTRANS2(&_pTranImageToFrame);
    _pTranFrameToImage = STRANPoints(imageCornersFrame, _imageCorners, 4, 1, 0);
    _pTranImageToFrame = STRANPoints(_imageCorners, imageCornersFrame, 4, 1, 0);
    DPOINT frameCorners[4];
    frameCorners[0].x = frameCorners[1].x = frameCorners[1].y = frameCorners[2].y = 0;
    frameCorners[2].x = frameCorners[3].x = self.frame.size.width;
    frameCorners[0].y = frameCorners[3].y = self.frame.size.height;
    TranPoints(frameCorners, _virtualImageCorners, 4, _pTranFrameToImage);
    
    for (int i = 0; i < _numProfileAreas; i++)
        free (_profileAreaPoints[i]);

    _numProfileAreas = 0;
    
    query = [NSString stringWithFormat:@"SELECT PLAT_NAME, BasePointX, BasePointY,NumPoints,NumLoops, Points FROM %@_PROFILE_PLT WHERE PLAT_NAME >= '%@' AND PLAT_NAME < '%@~';",
                       _platType, _platName,_platName];
    SQLOKswr(sqlite3_prepare_v2(sd.database, query.UTF8String, -1, &statement, 0), "");
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        DPOINT BasePt;
        LPDPOINT llpoints;
        LPSTR platName = (LPSTR)sqlite3_column_text(statement,0);
        BasePt.x = sqlite3_column_double(statement,1);
        BasePt.y = sqlite3_column_double(statement,2);
        _numProfileAreaPoints[_numProfileAreas] = sqlite3_column_int(statement,3);
        int nLoops = sqlite3_column_int(statement,4);
        double cFactor = COORDINATE_FACTOR;
        
        if (nLoops < 0)
            cFactor /= 1000;
        
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,5);
        _profileAreaPoints[_numProfileAreas] = malloc(abs(_numProfileAreaPoints[_numProfileAreas]) * sizeof(DPOINT) + 4);
        llpoints = _profileAreaPoints[_numProfileAreas];
        
        if (_numProfileAreaPoints[_numProfileAreas] < 0)
        {
            _numProfileAreaPoints[_numProfileAreas] = -_numProfileAreaPoints[_numProfileAreas];
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < _numProfileAreaPoints[_numProfileAreas]; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / cFactor);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / cFactor);
            }
        }
        
        else for (int i = 0; i < _numProfileAreaPoints[_numProfileAreas]; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / cFactor);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / cFactor);
        }
        
        _numProfileAreas++;
    }
    
    SQLOKswr(sqlite3_finalize(statement), "");
    [sd close];
    return YES;
}

- (BOOL)getYValueRangeForProfileAtX:(CGFloat)x
                               minY:(CGFloat *)pMinY
                               maxY:(CGFloat *)pMaxY
{
    BOOL rtn = NO;
    
    CGFloat y, minY = DBL_MAX, maxY = DBL_MIN;
    
    for (int area = 0; area < _numProfileAreas; area++)
    {
        LPDPOINT areaPoints = _profileAreaPoints[area];
        
        for (int i = 0; i < _numProfileAreaPoints[area]; i++)
        {
            int i2 = i + 1;
            
            if (i2 == _numProfileAreaPoints[area])
                i2 = 0;
            
//            DPOINT pt = areaPoints[i];
//            DPOINT pt2 = areaPoints[i2];
            
            if ((areaPoints[i].x <= x && areaPoints[i2].x >= x) ||
                (areaPoints[i2].x <= x && areaPoints[i].x >= x))
            {
                y = areaPoints[i].y + (areaPoints[i2].y - areaPoints[i].y) *
                (x  - areaPoints[i].x) / (areaPoints[i2].x - areaPoints[i].x);
                
                minY = min(y, minY);
                maxY = max(y, maxY);
                rtn = YES;
            }
        }
    }
    
    *pMinY = minY;
    *pMaxY = maxY;
    return rtn;
}

- (void)addGesturesToView
{
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handlePanGesture:)];
    
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(handlePinchGesture:)];
    
    pinchGesture.delegate = self;
    [self addGestureRecognizer:pinchGesture];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(handleLongPressGesture:)];
    
    longPressGesture.delegate = self;
    [self addGestureRecognizer:longPressGesture];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture
{
    CGPoint point = [panGesture translationInView:panGesture.view];
    
    CGAffineTransform translate = CGAffineTransformTranslate(panGesture.view.transform,
                                                             point.x, point.y);
    
    panGesture.view.transform = translate;
    
    [panGesture setTranslation:CGPointZero
                        inView:panGesture.view];
    
    if (_delegate)
    {
        CGFloat pBearing;
        CLLocationCoordinate2D pTarget;
        DPOINT minYpt, maxYpt;
        
        CGFloat pZoom = [self zoomForMapBounds:self.frame
                                       bearing:&pBearing
                                        target:&pTarget
                                   mapViewSize:_mapViewSize
                                        minYpt:&minYpt
                                        maxYpt:&maxYpt];
        
        [_delegate platViewDidZoom:pZoom
                       withBearing:pBearing
                            target:pTarget
                            minYpt:minYpt
                            maxYpt:maxYpt
                      gestureState:panGesture.state];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGesture
{
    CGPoint locationInView = [pinchGesture locationInView:pinchGesture.view];
    
    CGPoint anchor = CGPointMake((locationInView.x / _originalSize.width),
                                 (locationInView.y / _originalSize.height));
    
    [self setAnchorPoint:anchor
                 forView:pinchGesture.view];
    
    CGFloat currentScale = [[pinchGesture.view.layer valueForKeyPath:@"transform.scale"] floatValue];
    
    const CGFloat kMinScale = 0.5;
    const CGFloat kMaxScale = 50.0;
    
    CGFloat newScale = pinchGesture.scale;
    newScale = MIN(newScale, (kMaxScale / currentScale));
    newScale = MAX(newScale, (kMinScale / currentScale));
    
    CGAffineTransform scale = CGAffineTransformScale(pinchGesture.view.transform, newScale, newScale);
    pinchGesture.view.transform = scale;
    pinchGesture.scale = 1.0;
    
    if (_delegate)
    {
        CGFloat pBearing;
        CLLocationCoordinate2D pTarget;
        DPOINT minYpt, maxYpt;
        CGFloat pZoom = [self zoomForMapBounds:self.frame
                                       bearing:&pBearing
                                        target:&pTarget
                                   mapViewSize:_mapViewSize
                                        minYpt:&minYpt
                                        maxYpt:&maxYpt];
        
        [_delegate platViewDidZoom:pZoom
                       withBearing:pBearing
                            target:pTarget
                            minYpt:minYpt
                            maxYpt:maxYpt
                      gestureState:pinchGesture.state];
    }
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)longPressGesture
{
    if (longPressGesture.state == UIGestureRecognizerStateBegan)
        for (UIGestureRecognizer *gestures in self.gestureRecognizers)
            {
                if ([gestures isKindOfClass:UIPanGestureRecognizer.class] ||
                    [gestures isKindOfClass:UIPinchGestureRecognizer.class])
                {
                    gestures.enabled = NO;
                }
            }
    
    else if (longPressGesture.state == UIGestureRecognizerStateEnded)
    {
        for (UIGestureRecognizer *gestures in self.gestureRecognizers)
            gestures.enabled = YES;
    }

    CGFloat xPoint = [longPressGesture locationInView:self].x;
    
    if (_delegate)
    {
        DPOINT framePt;
        
        framePt.x = xPoint;
        framePt.y = 100;
        DPOINT imagePt = [self frameToImage:framePt];
        [_delegate platViewDidLongPressAtFrameXPosition:xPoint
                                 andImageXPosition:imagePt.x
                                      gestureState:longPressGesture.state];
    }
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
               forView:(UIView *)view
{
    CGPoint oldOrigin = view.frame.origin;
    view.layer.anchorPoint = anchorPoint;
    CGPoint newOrigin = view.frame.origin;
    
    CGPoint transition;
    transition.x = (newOrigin.x - oldOrigin.x);
    transition.y = (newOrigin.y - oldOrigin.y);
    
    view.center = CGPointMake((view.center.x - transition.x),
                              (view.center.y - transition.y));
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end