//  VectorView.m
//  GMMobile

extern int keepProcessing;

#import "VectorView.h"
#import "BoundaryData.h"
#import "PlanimetricData.h"
#import "PropertyData.h"
#import "SewerData.h"
#import "PipeTrace.h"

@interface VectorView ()

@property (nonatomic) LPBYTE bitmapData;
@property (nonatomic) CGColorSpaceRef colorSpace;
@property (nonatomic) CGContextRef vectorViewContext, context;
@property (nonatomic) NSInteger width, height;
@property (nonatomic) dispatch_queue_t vectorQueue;
@property (nonatomic) CGRect rect;

@end

@implementation VectorView

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = UIColor.clearColor;
        _vectorQueue = dispatch_queue_create("vectorQueue", NULL);
    }
    
    return self;
}

/*- (void)freeResources
{
    return;
    if (_bitmapData)
        free (_bitmapData);
    _bitmapData = nil;
    
    if (_context)
        CGContextRelease(_context);
    _context = nil;
    if (_colorSpace)
        CGColorSpaceRelease(_colorSpace);
    _colorSpace = nil;

}
- (void)dealloc
{
    [self freeResources];
}

CGContextRef createBitmapContext(CGRect rect,int pixelsWide, int pixelsHigh,CGColorSpaceRef colorSpace, void **bmData)
{
    CGContextRef context = NULL;
    void *bitmapData = NULL;
    int bitmapByteCount, bitmapBytesPerRow;
    
    bitmapBytesPerRow = pixelsWide*4;
    bitmapByteCount = (bitmapBytesPerRow *pixelsHigh);
    
    bitmapData = malloc(bitmapByteCount);

    if (bitmapData)
    {
        memset (bitmapData,0xff,bitmapByteCount);
        context = CGBitmapContextCreate(bitmapData,
                                        pixelsWide,
                                        pixelsHigh,
                                        8, //bits per component
                                        bitmapBytesPerRow,
                                        colorSpace,(CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        if (!context)
        {
            free (bitmapData);
            bitmapData = nil;
        }
//        else
//            CGContextClearRect(context,rect);
    }
    
    *bmData = bitmapData;
    return context;
}
*/

- (void) setRegion:(GMSVisibleRegion)region
{
    _latlonCornerPoints.nearLeft.x = region.nearLeft.longitude;
    _latlonCornerPoints.nearLeft.y = region.nearLeft.latitude;
    _latlonCornerPoints.farLeft.x = region.farLeft.longitude;
    _latlonCornerPoints.farLeft.y = region.farLeft.latitude;
    _latlonCornerPoints.farRight.x = region.farRight.longitude;
    _latlonCornerPoints.farRight.y = region.farRight.latitude;
    _latlonCornerPoints.nearRight.x = region.nearRight.longitude;
    _latlonCornerPoints.nearRight.y = region.nearRight.latitude;

    _latlonBounds = CornerPointBounds (&_latlonCornerPoints);
}

- (void)drawRect:(CGRect)rect
{
    _vectorViewContext = UIGraphicsGetCurrentContext();
    
    if (!_vectorViewContext || !keepProcessing)
        return;
    
    keepProcessing++;
    
    self.displayID = keepProcessing;
    
    if (_displayData)
    {
        dispatch_async(_vectorQueue,
        ^{
            int scale = UIScreen.mainScreen.scale;
            _colorSpace = CGColorSpaceCreateDeviceRGB();
            _width = self.bounds.size.width * scale;
            _height = self.bounds.size.height * scale;
            _rect = CGRectMake(0, 0, _width, _height);
            //_context = createBitmapContext (_rect,_width,_height,_colorSpace,&bmData);
            //_bitmapData = bmData;
            CGSize size = CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);
            CGLayerRef vectorLayer = CGLayerCreateWithContext(_vectorViewContext, size, NULL);
            _context = CGLayerGetContext(vectorLayer);
            _viewBounds.xmn = (self.bounds.origin.x * scale);
            _viewBounds.xmx = ((self.bounds.origin.x + self.bounds.size.width) * scale);
            _viewBounds.ymx = ((self.bounds.origin.y + self.bounds.size.height) * scale);
            _viewBounds.ymn = (self.bounds.origin.y * scale);
            
            if (keepProcessing == self.displayID && CRAPI.sharedInstance.showPlats)
            {
                SewerData *sd = [[SewerData alloc] init];
                sd.processingID = keepProcessing;
                sd.zoom = _zoom;
                
                [sd displayPlats:_context
                            type:@"STORM"
                       llCorners:&_latlonCornerPoints
                        LLBounds:&_latlonBounds
                      viewBounds:&_viewBounds];
            }
            
            else
            {
                if (keepProcessing == self.displayID && _zoom >= CRAPI.sharedInstance.parcelsVisibleAtZoom)
                {
                    PropertyData *pd = [[PropertyData alloc] init];
                    
                    pd.processingID = keepProcessing;
                    
                    [pd displayParcels:_context
                             llCorners:&_latlonCornerPoints
                              LLBounds:&_latlonBounds
                            viewBounds:&_viewBounds];
                    
                    [pd displayParcelText:_context
                                llCorners:&_latlonCornerPoints
                                 LLBounds:&_latlonBounds
                               viewBounds:&_viewBounds];
                }
                
                if (keepProcessing == self.displayID && CRAPI.sharedInstance.currentOverallBoundaryRefno)
                {
                    BoundaryData *bd = [[BoundaryData alloc] init];
                    
                    [bd displayBoundary:CRAPI.sharedInstance.currentOverallBoundaryRefno
                              inContext:_context
                              llCorners:&_latlonCornerPoints
                              LLBounds:&_latlonBounds
                             viewBounds:&_viewBounds];
                }
                
                /*if (CRAPI.sharedInstance.currentOverallBoundaryRefno)
                {
                    BoundaryData *bd = [[BoundaryData alloc]init];
                    [bd displayLandUse:context
                               LLBounds:&_latlonBounds
                             viewBounds:&_viewBounds];
                }*/
                
         /*       if (_zoom > CRAPI.sharedInstance.sewerVisibleAtZoom)
                {
                    PlanimetricData *pd = [[PlanimetricData alloc] init];
                    pd.processingID = keepProcessing;
                    
                    [pd displayPlanArea:_context
                               LLBounds:&_latlonBounds
                             viewBounds:&_viewBounds];
                    
                    [pd displayPlanLine:_context
                               LLBounds:&_latlonBounds
                             viewBounds:&_viewBounds];
                    
                    [pd displayPlanPoint:_context
                                LLBounds:&_latlonBounds
                              viewBounds:&_viewBounds];
                    
                    [pd displayWallPoint:_context
                                LLBounds:&_latlonBounds
                              viewBounds:&_viewBounds];
                }*/
                
                if (keepProcessing == self.displayID && _zoom >= CRAPI.sharedInstance.sewerVisibleAtZoom)
                {
                    SewerData *sd = [[SewerData alloc] init];
                    sd.processingID = keepProcessing;
                    sd.zoom = _zoom;
                    
                    [sd displayStormLine:_context
                                    pass:LINE_PASS
                               llCorners:&_latlonCornerPoints
                               LLBounds:&_latlonBounds
                             viewBounds:&_viewBounds];
                    
                    [sd displayStormPoint:_context
                                llCorners:&_latlonCornerPoints
                                LLBounds:&_latlonBounds
                              viewBounds:&_viewBounds];
                    
                    [sd displayStormLine:_context
                                    pass:TEXT_PASS
                               llCorners:&_latlonCornerPoints
                                LLBounds:&_latlonBounds
                              viewBounds:&_viewBounds];
                    
                }
            }
            
            if (keepProcessing == self.displayID)
            {
                PipeTrace *pt = [[PipeTrace alloc] init];
                pt.processingID = keepProcessing;
                
                [pt displayPipeTrace:_context
                           llCorners:&_latlonCornerPoints
                            LLBounds:&_latlonBounds
                          viewBounds:&_viewBounds];
            }
            
            if (keepProcessing == self.displayID)
            {
                CGContextDrawLayerAtPoint(_vectorViewContext, CGPointMake(0, 0), vectorLayer);
                /*UIGraphicsBeginImageContext(size);
                _context = UIGraphicsGetCurrentContext();
                CGContextDrawLayerAtPoint(_context, CGPointMake(0, 0), vectorLayer);
                UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
                NSData * pngData = UIImagePNGRepresentation(image);
                [pngData writeToFile:CRAPI.sharedInstance.extractFile atomically:YES];*/
                
                if (self.delegate)
                    [self.delegate vectorViewDidComplete];
            }
            
            CGLayerRelease(vectorLayer);
            //[self freeResources];
            NSLog (@"Vector view complete");
        });
    }
}

@end