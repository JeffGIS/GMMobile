//  PlatImageView.m
//  GMMobile

#import "PlatImageView.h"
#import "SewerData.h"

@interface PlatImageView ()

@property (nonatomic) LPTRANDATA pTranImageToLatlon;
@property (nonatomic) LPTRANDATA pTranLatlonToImage;
@property (nonatomic, copy) NSString *platType;
@property (nonatomic, copy) NSString *platName;
@property (nonatomic) CGPoint lastPoint;

@end

@implementation PlatImageView
{
    DPOINT _imageCornersWorld[4];
}

+ (PlatImageView *)platImageViewWithImagePath:(NSString *)imagePath
                                     delegate:(id)delegate
{
    
    
    imagePath = [NSBundle.mainBundle pathForResource:@"S-N-54"
                                              ofType:@"jpg"];
    
    imagePath = [NSBundle.mainBundle pathForResource:@"S-55S-2"
                                              ofType:@"jpg"];
    PlatImageView *platView = [[PlatImageView alloc] init];
    platView.image = [UIImage imageWithContentsOfFile:imagePath];
    platView.platName = imagePath.lastPathComponent.stringByDeletingPathExtension;
    platView.platType = @"SAN";
    platView.delegate = delegate;
    [platView getPlatTransformation];
    return platView;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.userInteractionEnabled = YES;
        [self addGesturesToView];
    }
    
    return self;
}

- (void)dealloc
{
    CloseTRANS2(&_pTranImageToLatlon);
    CloseTRANS2(&_pTranLatlonToImage);
    NSLog(@"Sewer Database dealloc");
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

- (CLLocationCoordinate2D)imageToCLLocationCoordinate2D:(DPOINT)imagePoint
{
    CLLocationCoordinate2D llPt;
    DPOINT dptOut;
    dptOut = TranDPOINT(&imagePoint, _pTranImageToLatlon);
    llPt.longitude = dptOut.x;
    llPt.latitude = dptOut.y;
    return llPt;
}

- (CGFloat)zoomForMapBounds:(CGRect)imageRect
                    bearing:(CGFloat *)bearing
                     target:(CLLocationCoordinate2D *)target
                mapViewSize:(CGSize)size
{
    GMSVisibleRegion region = [self imageRectToMapRegion:imageRect];
    _mapViewSize = size;
    
    CLLocationCoordinate2D center;
    
    CGFloat zoom = [self zoomForVisibleRegion:region
                                       target:&center];
    
    DPOINT ptImage1, ptImage2;
    DPOINT ptWorld1, ptWorld2;
    DPOINT ptLev201, ptLev202;
    
    ptImage1.x = ptImage2.x = imageRect.size.width / 2.0;
    ptImage1.y = 0;
    ptImage2.y = imageRect.size.height;
    ptLev201 = TranDPOINT(&ptImage1, _pTranImageToLatlon);
    ptLev202 = TranDPOINT(&ptImage2, _pTranImageToLatlon);
    CGFloat az = getazd(&ptLev201, &ptLev202);
    CGFloat trueBearing = (LTWOPI(HALFPI - az) * DEGRAD);
    *bearing = ((roundf(trueBearing / 5.0)) * 5.0);
    *target = center;
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
    DPOINT ptIn, ptOut;
    DPOINT framePoints[4], framePointsWorld[4];
    DPOINT imageCorners[4];
    
    imageCorners[0].x = imageRect.origin.x;
    imageCorners[0].y = imageRect.origin.y + imageRect.size.height;
    imageCorners[1].x = imageRect.origin.x;
    imageCorners[1].y = imageRect.origin.y;
    imageCorners[2].x = imageRect.origin.x + imageRect.size.width;
    imageCorners[2].y = imageRect.origin.y;
    imageCorners[3].x = imageRect.origin.x + imageRect.size.width;
    imageCorners[3].y = imageRect.origin.y + imageRect.size.height;

    LPTRANDATA pTran = STRANPoints(imageCorners, _imageCornersWorld,4,1,0);

    framePoints[0].x = framePoints[1].y = 0;
    framePoints[1].x = 0;
    framePoints[0].y = self.superview.frame.size.height;
    framePoints[2].x = self.superview.frame.size.width;
    framePoints[3].y = self.superview.frame.size.height;
    framePoints[3].x = self.superview.frame.size.width;
    framePoints[2].y = 0;
    TranPoints(framePoints, framePointsWorld, 4, pTran);
    CloseTRANS2(&pTran);
    for (int i=0;i<4;i++)
        PixelXYToLatLongd(framePointsWorld[i].x, framePointsWorld[i].y, 20, &framePointsWorld[i].y, &framePointsWorld[i].x);
    region.nearLeft.longitude = framePointsWorld[0].x;
    region.nearLeft.latitude = framePointsWorld[0].y;
    region.farLeft.longitude = framePointsWorld[1].x;
    region.farLeft.latitude = framePointsWorld[1].y;
    region.farRight.longitude = framePointsWorld[2].x;
    region.farRight.latitude = framePointsWorld[2].y;
    region.nearRight.longitude = framePointsWorld[3].x;
    region.nearRight.latitude = framePointsWorld[3].y;
    
    /*ptIn.x = imageRect.origin.x;
    ptIn.y = imageRect.origin.y;
    ptOut = TranDPOINT(&ptIn, _pTranImageToLatlon);
    region.nearLeft.longitude = ptOut.x;
    region.nearLeft.latitude = ptOut.y;
    
    ptIn.y = (imageRect.origin.y + imageRect.size.height);
    ptOut = TranDPOINT(&ptIn, _pTranImageToLatlon);
    region.farLeft.longitude = ptOut.x;
    region.farLeft.latitude = ptOut.y;
    
    ptIn.x = (imageRect.origin.x + imageRect.size.width);
    ptOut = TranDPOINT(&ptIn, _pTranImageToLatlon);
    region.farRight.longitude = ptOut.x;
    region.farRight.latitude = ptOut.y;
    
    ptIn.y = (imageRect.origin.y - imageRect.size.height);
    ptOut = TranDPOINT(&ptIn, _pTranImageToLatlon);
    region.nearRight.longitude = ptOut.x;
    region.nearRight.latitude = ptOut.y;*/
    
    return region;
}

- (BOOL)getPlatTransformation
{
    double imagex[32], imagey[32], worldx[32], worldy[32];
    float rsq;
    int npt = 0;
    DPOINT imageCorners[4];
    
    CloseTRANS2(&_pTranImageToLatlon);
    CloseTRANS2(&_pTranLatlonToImage);
    SewerData *sd = [[SewerData alloc] init];
    [sd open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT IMAGEX,IMAGEY,WORLDX,WORLDY FROM %@_PLAT_CPT WHERE PLAT_NAME = '%@';",
                       _platType, _platName];
    
    sqlite3_stmt *statement;
    
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
    [sd close];
    imageCorners[0].x = imageCorners[0].y = 0;
    imageCorners[1].x = 0;
    imageCorners[1].y = self.image.size.height;
    imageCorners[2].x = self.image.size.width;
    imageCorners[2].y = self.image.size.height;
    imageCorners[3].x = self.image.size.width;
    imageCorners[3].y = 0;
    TranPoints (imageCorners,_imageCornersWorld,4,_pTranImageToLatlon);
    return NO;
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
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state == UIGestureRecognizerStateEnded)
    {
        if (_delegate)
            [_delegate platViewDidEndTrans];
    }
    
    else if (panGesture.state == UIGestureRecognizerStateBegan ||
             panGesture.state == UIGestureRecognizerStateChanged)
    {
        if (panGesture.state == UIGestureRecognizerStateBegan)
        {
            if (_delegate)
                [_delegate platViewDidBeginTrans];
        }
        
        CGPoint translation = [panGesture translationInView:panGesture.view.superview];
        
        panGesture.view.center = CGPointMake(panGesture.view.center.x + translation.x,
                                             panGesture.view.center.y + translation.y);
        
        [panGesture setTranslation:CGPointZero
                            inView:self];
        
        if (_delegate)
        {
            CGFloat pBearing;
            CLLocationCoordinate2D pTarget;
            
            CGFloat pZoom = [self zoomForMapBounds:self.frame
                                           bearing:&pBearing
                                            target:&pTarget
                                       mapViewSize:_mapViewSize];
            
            [_delegate platViewDidZoom:pZoom
                           withBearing:pBearing
                                target:pTarget];
        }
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGesture
{
    if (pinchGesture.state == UIGestureRecognizerStateEnded)
    {
        if (_delegate)
            [_delegate platViewDidEndTrans];
    }
    
    else if (pinchGesture.state == UIGestureRecognizerStateBegan ||
             pinchGesture.state == UIGestureRecognizerStateChanged)
    {
        if (pinchGesture.numberOfTouches > 1)
        {
            if (pinchGesture.state == UIGestureRecognizerStateBegan)
            {
                if (_delegate)
                    [_delegate platViewDidBeginTrans];
                
                _lastPoint = [pinchGesture locationInView:self];
            }
            
            CGFloat currentScale = [[pinchGesture.view.layer valueForKeyPath:@"transform.scale.x"] floatValue];
            
            CGFloat minScale = 0.5;
            CGFloat maxScale = 50.0;
            CGFloat zoomSpeed = 1.0;
            
            CGFloat deltaScale = pinchGesture.scale;
            deltaScale = (((deltaScale - 1.0) * zoomSpeed) + 1.0);
            deltaScale = MIN(deltaScale, (maxScale / currentScale));
            deltaScale = MAX(deltaScale, (minScale / currentScale));
            
            CGAffineTransform scale = CGAffineTransformScale(pinchGesture.view.transform, deltaScale, deltaScale);
            pinchGesture.view.transform = scale;
            pinchGesture.scale = 1.0;
            
            CGPoint point = [pinchGesture locationInView:self];
            
            CGAffineTransform translate = CGAffineTransformTranslate(pinchGesture.view.transform,
                                                                     point.x - _lastPoint.x,
                                                                     point.y - _lastPoint.y);
            
            pinchGesture.view.transform = translate;
            _lastPoint = [pinchGesture locationInView:self];
            
            if (_delegate)
            {
                CGFloat pBearing;
                CLLocationCoordinate2D pTarget;
                
                CGFloat pZoom = [self zoomForMapBounds:self.frame
                                               bearing:&pBearing
                                                target:&pTarget
                                           mapViewSize:_mapViewSize];
                
                [_delegate platViewDidZoom:pZoom
                               withBearing:pBearing
                                    target:pTarget];
            }
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end