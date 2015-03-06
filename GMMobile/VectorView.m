//  VectorView.m
//  GMMobile

extern int keepProcessing;

#import "VectorView.h"
#import "BoundaryData.h"
#import "PlanimetricData.h"
#import "PropertyData.h"
#import "SewerData.h"

@implementation VectorView
{
    LPBYTE _bitmapData;
    CGColorSpaceRef _colorSpace;
    CGContextRef _vectorViewContext;
    CGContextRef _context;
    int _width, _height;
    dispatch_queue_t _vectorQueue;
    CGRect _rect;
}

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

- (void)drawRect:(CGRect)rect
{
    _vectorViewContext = UIGraphicsGetCurrentContext();
    
    if (!_vectorViewContext || !keepProcessing)
        return;
    
    keepProcessing++;
    
    self.displayID = keepProcessing;
    
    if (_displayData)
    {
        //void *bmData;
        //[self freeResources];
        
        //if (_context)
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
        
        if (_zoom >= CRAPI.sharedInstance.parcelsVisibleAtZoom)
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            pd.processingID = keepProcessing;
            
            [pd displayParcels:_context
                      LLBounds:&_latlonBounds
                    viewBounds:&_viewBounds];
            
            [pd displayParcelText:_context
                         LLBounds:&_latlonBounds
                       viewBounds:&_viewBounds];
        }
        
        if (CRAPI.sharedInstance.currentOverallBoundaryRefno)
        {
            BoundaryData *bd = [[BoundaryData alloc] init];
            
            [bd displayBoundary:CRAPI.sharedInstance.currentOverallBoundaryRefno
                      inContext:_context
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
        if (_zoom > CRAPI.sharedInstance.sewerVisibleAtZoom)
        {
            SewerData *sd = [[SewerData alloc] init];
            sd.processingID = keepProcessing;
            sd.zoom = _zoom;
            
            [sd displayStormLine:_context
                            pass:LINE_PASS
                       LLBounds:&_latlonBounds
                     viewBounds:&_viewBounds];
            
            [sd displayStormPoint:_context
                        LLBounds:&_latlonBounds
                      viewBounds:&_viewBounds];
            
            [sd displayStormLine:_context
                            pass:TEXT_PASS
                        LLBounds:&_latlonBounds
                      viewBounds:&_viewBounds];
            
            /*[sd displayPlats:_context
                        type:@"SAN"
                    LLBounds:&_latlonBounds
                  viewBounds:&_viewBounds];*/
        }
        if (self.displayData && keepProcessing == self.displayID)
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
}

@end