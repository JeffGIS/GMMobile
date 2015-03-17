//  PlatImageView.m
//  GMMobile

#import "PlatImageView.h"
#import "SewerData.h"

#define MAX_PROFILE_AREAS 8

@interface PlatImageView ()

@property (nonatomic) LPTRANDATA pTranImageToLatlon;
@property (nonatomic) LPTRANDATA pTranLatlonToImage;
@property (nonatomic) LPTRANDATA pTranFrameToImage;
@property (nonatomic) LPTRANDATA pTranImageToFrame;
@property (nonatomic, copy) NSString *platType;
@property (nonatomic, copy) NSString *platName;

@end

@implementation PlatImageView
{
    DPOINT _imageCorners[4];
    DPOINT _imageCornersWorld[4];
    int _numProfileAreas;
    int _numProfileAreaPoints[MAX_PROFILE_AREAS];
    LPDPOINT _profileAreaPoints[MAX_PROFILE_AREAS];
}

+ (PlatImageView *)platImageViewWithDelegate:(id)delegate
{
    PlatImageView *platView = [[PlatImageView alloc] init];
    NSString *imagePath = CRAPI.sharedInstance.currentPlatImagePath;
    
    platView.image = [UIImage imageWithContentsOfFile:imagePath];
    platView.platType = CRAPI.sharedInstance.currentPlatType;
    platView.platName = imagePath.lastPathComponent.stringByDeletingPathExtension;
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
    CloseTRANS2(&_pTranFrameToImage);
    CloseTRANS2(&_pTranImageToFrame);
    
    for (int i = 0; i < _numProfileAreas; i++)
        free(_profileAreaPoints[i]);
    
    _numProfileAreas = 0;
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

- (CGFloat)zoomForMapBounds:(CGRect)imageRect
                    bearing:(CGFloat *)bearing
                     target:(CLLocationCoordinate2D *)target
                mapViewSize:(CGSize)size
{
    GMSVisibleRegion region = [self imageRectToMapRegion:imageRect];
    _mapViewSize = size;
    CGFloat minY, maxY;
    
    CLLocationCoordinate2D center;
    
    CGFloat zoom = [self zoomForVisibleRegion:region
                                       target:&center];
    
    DPOINT ptImage1, ptImage2;
    DPOINT ptLev201, ptLev202;
    DPOINT ptFrame1, ptFrame2;
    
    ptImage1.x = ptImage2.x = (_imageCorners[0].x + _imageCorners[2].x) / 2;
    ptImage1.y = _imageCorners[0].y;
    ptImage2.y = _imageCorners[2].y;
    ptLev201 = TranDPOINT(&ptImage1, _pTranImageToLatlon);
    ptLev202 = TranDPOINT(&ptImage2, _pTranImageToLatlon);
    CGFloat az = getazd(&ptLev201, &ptLev202);
    CGFloat trueBearing = (LTWOPI(HALFPI - az) * DEGRAD);
    *bearing = ((roundf(trueBearing / 5.0)) * 5.0);
    *target = center;

    ptFrame1.x = self.superview.frame.size.width/2;
    ptFrame1.y = self.superview.frame.size.height;
    ptImage1 = [self frameToImage:ptFrame1];
    
    if ([self getYValueRangeForProfileAtX:ptImage1.x  minY:&minY maxY:&maxY])
    {
        ptImage1.y = minY;
        ptImage2.x = ptImage1.x;
        ptImage2.y = maxY;
        ptFrame1 = [self imageToFrame:ptImage1];
        ptFrame2 = [self imageToFrame:ptImage2];
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
    DPOINT ptIn, ptOut;
    DPOINT framePoints[4], framePointsWorld[4];
    DPOINT imageCornersFrame[4];
    
    imageCornersFrame[0].x = imageRect.origin.x;
    imageCornersFrame[0].y = imageRect.origin.y + imageRect.size.height;
    imageCornersFrame[1].x = imageRect.origin.x;
    imageCornersFrame[1].y = imageRect.origin.y;
    imageCornersFrame[2].x = imageRect.origin.x + imageRect.size.width;
    imageCornersFrame[2].y = imageRect.origin.y;
    imageCornersFrame[3].x = imageRect.origin.x + imageRect.size.width;
    imageCornersFrame[3].y = imageRect.origin.y + imageRect.size.height;

    LPTRANDATA pTranFrameToWorld = STRANPoints(imageCornersFrame, _imageCornersWorld,4,1,0);
    CloseTRANS2(&_pTranFrameToImage);
    CloseTRANS2(&_pTranImageToFrame);
    _pTranFrameToImage = STRANPoints(imageCornersFrame, _imageCorners,4,1,0);
    _pTranImageToFrame = STRANPoints(_imageCorners,imageCornersFrame, 4,1,0);

    framePoints[0].x = framePoints[1].y = 0;
    framePoints[1].x = 0;
    framePoints[0].y = self.superview.frame.size.height;
    framePoints[2].x = self.superview.frame.size.width;
    framePoints[3].y = self.superview.frame.size.height;
    framePoints[3].x = self.superview.frame.size.width;
    framePoints[2].y = 0;
    
    TranPoints(framePoints, framePointsWorld, 4, pTranFrameToWorld);
    CloseTRANS2(&pTranFrameToWorld);
    
    for (int i = 0; i < 4; i++)
    {
        PixelXYToLatLongd(framePointsWorld[i].x, framePointsWorld[i].y, 20,
                          &framePointsWorld[i].y, &framePointsWorld[i].x);
    }
    
    region.nearLeft.longitude = framePointsWorld[0].x;
    region.nearLeft.latitude = framePointsWorld[0].y;
    region.farLeft.longitude = framePointsWorld[1].x;
    region.farLeft.latitude = framePointsWorld[1].y;
    region.farRight.longitude = framePointsWorld[2].x;
    region.farRight.latitude = framePointsWorld[2].y;
    region.nearRight.longitude = framePointsWorld[3].x;
    region.nearRight.latitude = framePointsWorld[3].y;
    
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
    
    for (int i=0;i<_numProfileAreas;i++)
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
        int nBlobBytes = sqlite3_column_bytes(statement,5);
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
            
            DPOINT pt = areaPoints[i];
            DPOINT pt2 = areaPoints[i2];
            
            if ((areaPoints[i].x <= x && areaPoints[i2].x >= x) ||
                (areaPoints[i2].x <= x && areaPoints[i].x >= x))
            {
                y = areaPoints[i].y + (areaPoints[i2].y - areaPoints[i].y) *
                (x  - areaPoints[i].x) / (areaPoints[i].x - areaPoints[i2].x);
                
                minY = min (y,minY);
                maxY = max (y,maxY);
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
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture
{
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateEnded:
            if (_delegate)
                [_delegate platViewDidEndTrans];
            break;
            
        case UIGestureRecognizerStateBegan:
            if (_delegate)
                [_delegate platViewDidBeginTrans];
            
        case UIGestureRecognizerStateChanged:
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
                
                CGFloat pZoom = [self zoomForMapBounds:self.frame
                                               bearing:&pBearing
                                                target:&pTarget
                                           mapViewSize:_mapViewSize];
                
                [_delegate platViewDidZoom:pZoom
                               withBearing:pBearing
                                    target:pTarget];
            }
        }
            
            break;
            
        default:
            break;
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGesture
{
    switch (pinchGesture.state)
    {
        case UIGestureRecognizerStateEnded:
            if (_delegate)
                [_delegate platViewDidEndTrans];
            break;
            
        case UIGestureRecognizerStateBegan:
            if (_delegate)
                [_delegate platViewDidBeginTrans];
            NSLog(@"%f,%f", pinchGesture.view.layer.anchorPoint.x, pinchGesture.view.layer.anchorPoint.y);
            
        case UIGestureRecognizerStateChanged:
        {
            CGPoint locationInView = [pinchGesture locationInView:pinchGesture.view];
            
            CGPoint anchor = CGPointMake((locationInView.x / pinchGesture.view.superview.frame.size.width),
                                         (locationInView.y / pinchGesture.view.superview.frame.size.height));
            
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
                
                CGFloat pZoom = [self zoomForMapBounds:self.frame
                                               bearing:&pBearing
                                                target:&pTarget
                                           mapViewSize:_mapViewSize];
                
                [_delegate platViewDidZoom:pZoom
                               withBearing:pBearing
                                    target:pTarget];
            }
        }
            
            break;
            
        default:
            break;
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