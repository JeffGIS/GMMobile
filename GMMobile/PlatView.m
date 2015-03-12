//  PlatView.m
//  GMMobile

#import "PlatView.h"
#import "SewerData.h"
#import <GoogleMaps/GoogleMaps.h>

#define TESTMODE YES

@interface PlatView ()

@property (nonatomic) CGImageRef image;
@property NSString * platType;
@property NSString * platName;
@property int imageWidth;
@property int imageHeight;
@property CGFloat imageFactor;
@property CGFloat currentScale;
@property CGRect imageRect;
@property LPTRANDATA pTranImageToLatlon;
@property LPTRANDATA pTranLatlonToImage;


@end

@implementation PlatView

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.opaque = YES;
        self.currentScale = 1;
        self.backgroundColor = UIColor.clearColor;
    }
    
    return self;
}

-(void)dealloc
{
    CGImageRelease(_image);
    CloseTRANS2 (&_pTranImageToLatlon);
    CloseTRANS2 (&_pTranLatlonToImage);
    NSLog(@"Sewer Database dealloc");
}

- (DPOINT) latLonToImage:(LLPOINT)latLonPoint
{
    DPOINT dptIn,dptOut;
    
    dptIn.x = latLonPoint.lon;
    dptIn.y = latLonPoint.lat;
    
    dptOut = TranDPOINT(&dptIn, _pTranLatlonToImage);
    return dptOut;
}
- (LLPOINT) imageToLatLon:(DPOINT)imagePoint
{
    LLPOINT llPt;
    DPOINT dptOut;
    
    dptOut = TranDPOINT(&imagePoint, _pTranImageToLatlon);
    llPt.lon = dptOut.x;
    llPt.lat = dptOut.y;
    
    return llPt;
}

-(CLLocationCoordinate2D)imageToCLLocationCoordinate2D:(DPOINT)imagePoint
{
    CLLocationCoordinate2D llPt;
    DPOINT dptOut;
    
    dptOut = TranDPOINT(&imagePoint, _pTranImageToLatlon);
    llPt.longitude = dptOut.x;
    llPt.latitude = dptOut.y;
    
    return llPt;
}

- (GMSCoordinateBounds*) imageRectToMapBounds:(CGRect)imageRect bearing:(CGFloat*)bearing
{
    GMSVisibleRegion region = [self imageRectToMapRegion:imageRect];
    GMSCoordinateBounds* gbounds = [[GMSCoordinateBounds alloc]initWithRegion:region];
    DPOINT ptImage1, ptImage2;
    DPOINT ptWorld1, ptWorld2;
    CGFloat az;
    
    ptImage1.x = ptImage2.x = imageRect.size.width;
    ptImage1.y = 0;
    ptImage2.y = imageRect.size.height;
    ptWorld1 = TranDPOINT (&ptImage1,_pTranImageToLatlon);
    ptWorld2 = TranDPOINT (&ptImage2,_pTranImageToLatlon);
    az = getazd(&ptWorld1,&ptWorld2);
    *bearing = LTWOPI (HALFPI - az)*DEGRAD;
    return gbounds;
}

- (GMSVisibleRegion) imageRectToMapRegion:(CGRect)imageRect
{
    GMSVisibleRegion region;
    DPOINT ptIn, ptOut;
    
    ptIn.x = imageRect.origin.x;
    ptIn.y = imageRect.origin.y;
    ptOut = TranDPOINT(&ptIn,_pTranImageToLatlon);
    region.nearLeft.longitude = ptOut.x;
    region.nearLeft.latitude = ptOut.y;
    
    ptIn.y = imageRect.origin.y + imageRect.size.height;
    ptOut = TranDPOINT(&ptIn,_pTranImageToLatlon);
    region.farLeft.longitude = ptOut.x;
    region.farLeft.latitude = ptOut.y;
    
    ptIn.x = imageRect.origin.x + imageRect.size.width;
    ptOut = TranDPOINT(&ptIn,_pTranImageToLatlon);
    region.farRight.longitude = ptOut.x;
    region.farRight.latitude = ptOut.y;
    
    ptIn.y = imageRect.origin.y - imageRect.size.height;
    ptOut = TranDPOINT(&ptIn,_pTranImageToLatlon);
    region.nearRight.longitude = ptOut.x;
    region.nearRight.latitude = ptOut.y;
    
    return region;
}

- (BOOL)getPlatTransformation
{
    double imagex[32], imagey[32], worldx[32], worldy[32];
    float rsq;
    int npt = 0;
    CloseTRANS2 (&_pTranImageToLatlon);
    CloseTRANS2 (&_pTranLatlonToImage);
    SewerData * sd = [[SewerData alloc]init];
    
    [sd open];
    NSString * query = [NSString stringWithFormat:@"SELECT IMAGEX,IMAGEY,WORLDX,WORLDY FROM %@_PLAT_CPT WHERE PLAT_NAME = '%@';",_platType,_platName];
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
    return FALSE;
}

- (CGImageRef)getImage
{
    CGRect rect = self.bounds;
    NSString *imagePath;
    if (!_image)
    {
        if (TESTMODE)
        {
            imagePath = [NSBundle.mainBundle pathForResource:@"S-2A-10"
                                                                ofType:@"jpg"];
            
            UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
            _image = CGImageRetain(img.CGImage);
        }
        
        else
        {
            imagePath = CRAPI.sharedInstance.currentPlatImagePath;
            UIImage *img;
            img = [UIImage imageWithContentsOfFile:imagePath];
            _image = CGImageRetain(img.CGImage);
        }
        _platName = [[imagePath lastPathComponent]stringByDeletingPathExtension];
        _platType = @"SAN";
        [self getPlatTransformation];
        _imageWidth = (int)CGImageGetWidth(_image);
        _imageHeight = (int)CGImageGetHeight(_image);
        if (rect.size.height / _imageHeight  < rect.size.width / _imageWidth)
            _imageFactor = rect.size.height / _imageHeight;
        else
            _imageFactor = rect.size.width / _imageWidth;
        _imageFactor *= _currentScale;
        CGFloat midx=rect.size.width/2, midy=rect.size.height/2;
        _imageRect.size.height = _imageHeight;
        _imageRect.size.width = _imageWidth;
        _imageRect.origin.x = midx/_imageFactor - _imageRect.size.width/2;
        _imageRect.origin.y = -(midy/_imageFactor + _imageRect.size.height/2);
    }
    
    return _image;
}

CGRect scaleRect (CGRect rect,CGFloat scale)
{
    CGRect outRect;
    
    outRect = rect;
    outRect.size.height *= scale;
    outRect.size.width *= scale;
    
    return outRect;
}
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect) || CGRectIsInfinite(rect))
        return;
    
    if (!_image)
        [self getImage];
    
    if (!_image)
        return;
    
    CGContextSaveGState(context);
    [self addGesturesToView];
    
    //self.transform = CGAffineTransformMakeRotation(M_PI);
    CGContextScaleCTM(context, 1, -1);
    //CGContextRotateCTM(context, M_PI);
    //imageRect.origin = CGPointMake(8.0, 8.0);
    //imageRect.size = CGSizeMake(64.0, 64.0);
    
    CGContextScaleCTM(context,_imageFactor*1,_imageFactor*1);
    //CGContextTranslateCTM(context, 0, 2000);
    //imageRect.origin.y = 0;
    // Note: The images are actually drawn upside down because Quartz image drawing expects
    // the coordinate system to have the origin in the lower-left corner, but a UIView
    // puts the origin in the upper-left corner. For the sake of brevity (and because
    // it likely would go unnoticed for the image used) this is not addressed here.
    // For the demonstration of PDF drawing however, it is addressed, as it would definately
    // be noticed, and one method of addressing it is shown there.
    
    // Draw the image in the upper left corner (0,0) with size 64x64
    //CGRect drawRect = scaleRect (_imageRect,_currentScale);
    CGContextDrawImage(context, _imageRect, _image);
    CGFloat bearing;
    GMSCoordinateBounds* bounds = [self imageRectToMapBounds:_imageRect bearing:&bearing];
    if (_delegate)
        [_delegate platViewDidZoom:bounds withBearing:bearing];
/*
    // Tile the same image across the bottom of the view
    // CGContextDrawTiledImage() will fill the entire clipping area with the image, so to avoid
    // filling the entire view, we'll clip the view to the rect below. This rect extends
    // past the region of the view, but since the view's rectangle has already been applied as a clip
    // to our drawing area, it will be intersected with this rect to form the final clipping area
    CGContextClipToRect(context, CGRectMake(0.0, 80.0, self.bounds.size.width, self.bounds.size.height));
    
    // The origin of the image rect works similarly to the phase parameter for SetLineDash and
    // SetPatternPhase and specifies where in the coordinate system the "first" image is drawn.
    // The size (previously set to 64x64) specifies the size the image is scaled to before being tiled.
    imageRect.origin = CGPointMake(32.0, 112.0);
    CGContextDrawTiledImage(context, imageRect, self.image);
    // Highlight the "first" image from the DrawTiledImage call.
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 0.5);
    CGContextFillRect(context, imageRect);
    // And stroke the clipped area
    CGContextSetLineWidth(context, 3.0);
    CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
    CGContextStrokeRect(context, CGContextGetClipBoundingBox(context));
 */
    CGImageRelease(_image);
    CGContextRestoreGState(context);
    _image = NULL;
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
        [self setNeedsDisplay];
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
            [_delegate platViewDidTranslate:translation];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGesture
{
    if (pinchGesture.state == UIGestureRecognizerStateEnded)
    {
        _currentScale = [[pinchGesture.view.layer valueForKeyPath:@"transform.scale.x"] floatValue];
        if (_delegate)
            [_delegate platViewDidEndTrans];
        [self setNeedsDisplay];
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
            [_delegate platViewDidTransformScale:deltaScale];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end