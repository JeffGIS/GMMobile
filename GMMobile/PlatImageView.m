//  PlatImageView.m
//  GMMobile

#import "PlatImageView.h"
#import "SewerData.h"

@interface PlatImageView ()

@property (nonatomic) LPTRANDATA pTranImageToLatlon;
@property (nonatomic) LPTRANDATA pTranLatlonToImage;
@property (nonatomic, copy) NSString *platType;
@property (nonatomic, copy) NSString *platName;

@end

@implementation PlatImageView
{
    DPOINT _imageCornersWorld[4];
}

+ (PlatImageView *)platImageViewWithImagePath:(NSString *)imagePath
                                     delegate:(id)delegate;
{
    imagePath = [NSBundle.mainBundle pathForResource:@"S-N-54"
                                              ofType:@"jpg"];
    
    //imagePath = [NSBundle.mainBundle pathForResource:@"S-55S-2"
                                              //ofType:@"jpg"];

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

- (GMSCoordinateBounds *)imageRectToMapBounds:(CGRect)imageRect
                                      bearing:(CGFloat *)bearing
{
    GMSVisibleRegion region = [self imageRectToMapRegion:imageRect];
    GMSCoordinateBounds *gbounds = [[GMSCoordinateBounds alloc] initWithRegion:region];
    DPOINT ptImage1, ptImage2;
    DPOINT ptWorld1, ptWorld2;
    CGFloat az;
    
    ptImage1.x = ptImage2.x = imageRect.size.width/2;
    ptImage1.y = 0;
    ptImage2.y = imageRect.size.height;
    ptWorld1 = TranDPOINT(&ptImage1, _pTranImageToLatlon);
    ptWorld2 = TranDPOINT(&ptImage2, _pTranImageToLatlon);
    az = getazd(&ptWorld1, &ptWorld2);
    *bearing = LTWOPI(HALFPI - az) * DEGRAD;
    return gbounds;
}

- (GMSVisibleRegion)imageRectToMapRegion:(CGRect)imageRect
{
    GMSVisibleRegion region;
    DPOINT ptIn, ptOut;
    DPOINT framePoints[4], framePointsWorld[4];
    DPOINT imageCorners[4];
    
    imageCorners[0].x = imageRect.origin.x;
    imageCorners[0].y = imageRect.origin.y;
    imageCorners[1].x = imageRect.origin.x;
    imageCorners[1].y = imageRect.origin.y + imageRect.size.height;
    imageCorners[2].x = imageRect.origin.x + imageRect.size.width;
    imageCorners[2].y = imageRect.origin.y + imageRect.size.height;
    imageCorners[3].x = imageRect.origin.x + imageRect.size.width;
    imageCorners[2].y = imageRect.origin.y;

    LPTRANDATA pTran = STRANPoints (&imageCorners, &_imageCornersWorld,4,0);

    framePoints[0].x = framePoints[0].y = 0;
    framePoints[1].x = 0;
    framePoints[1].y = self.superview.frame.size.height;
    framePoints[2].x = self.superview.frame.size.width;
    framePoints[2].y = self.superview.frame.size.height;
    framePoints[3].x = self.superview.frame.size.width;
    framePoints[3].y = 0;
    TranPoints(framePoints, framePointsWorld, 4, pTran);
    CloseTRANS2(&pTran);
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
        worldx[npt] = sqlite3_column_double(statement, 2);
        worldy[npt++] = sqlite3_column_double(statement, 3);
    }
    
    _pTranImageToLatlon = STRAN2(0, imagex, imagey, worldx, worldy, npt, &rsq);
    _pTranLatlonToImage = STRAN2(0, worldx, worldy, imagex, imagey, npt, &rsq);
    
    SQLOKswr(sqlite3_finalize(statement), "pickPLAT");
    [sd close];
    imageCorners[0].x = imageCorners[0].y = 0;
    imageCorners[1].x = 0;
    imageCorners[1].y = self.image.size.height;
    imageCorners[2].x = self.image.size.width;
    imageCorners[2].y = self.image.size.height;
    imageCorners[3].x = self.image.size.width;
    imageCorners[2].y = 0;
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
            
            GMSCoordinateBounds *bounds = [self imageRectToMapBounds:self.frame
                                                             bearing:&pBearing];
            
            [_delegate platViewDidTransBounds:bounds
                                  withBearing:pBearing];
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
        if (pinchGesture.state == UIGestureRecognizerStateBegan)
        {
            if (_delegate)
                [_delegate platViewDidBeginTrans];
        }
        
        CGFloat currentScale = [[pinchGesture.view.layer valueForKeyPath:@"transform.scale.x"] floatValue];
        
        CGFloat minScale = 0.25;
        CGFloat maxScale = 10.0;
        CGFloat zoomSpeed = 0.5;
        
        CGFloat deltaScale = pinchGesture.scale;
        deltaScale = (((deltaScale - 1.0) * zoomSpeed) + 1.0);
        deltaScale = MIN(deltaScale, (maxScale / currentScale));
        deltaScale = MAX(deltaScale, (minScale / currentScale));
        
        CGAffineTransform transformation = CGAffineTransformScale(pinchGesture.view.transform, deltaScale, deltaScale);
        pinchGesture.view.transform = transformation;
        pinchGesture.scale = 1.0;
        
        if (_delegate)
        {
            CGFloat pBearing;
            
            GMSCoordinateBounds *bounds = [self imageRectToMapBounds:self.frame
                                                             bearing:&pBearing];
            
            [_delegate platViewDidTransBounds:bounds
                                  withBearing:pBearing];
        }
    }
}

@end