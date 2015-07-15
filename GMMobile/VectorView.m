 //  VectorView.m
//  GMMobile

extern int keepProcessing;

#import "VectorView.h"
#import "BoundaryData.h"
#import "PlanimetricData.h"
#import "PropertyData.h"
#import "SewerData.h"
#import "PipeTrace.h"
#import "ConfigurationControl.h"

@interface VectorView ()

@property (nonatomic) LPBYTE bitmapData;
@property (nonatomic) CGColorSpaceRef colorSpace;
@property (nonatomic) CGContextRef vectorViewContext, context;
@property (nonatomic) NSInteger width, height;
@property (nonatomic) dispatch_queue_t vectorQueue;
@property (nonatomic) CGRect rect;
@property BOOL haveVectorLayer;

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
- (void)dealloc
{
    if (_vectorLayer)
        CGLayerRelease(_vectorLayer);

    //[self freeResources];
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
    int scale = UIScreen.mainScreen.scale;
    _vectorViewContext = UIGraphicsGetCurrentContext();
    if (!_vectorViewContext || !keepProcessing)
        return;
    if (_haveVectorLayer)
    {
        //CGContextDrawLayerAtPoint(_vectorViewContext, CGPointMake(0, 0), _vectorLayer);
        if (keepProcessing == self.displayID)
        {
            CGContextScaleCTM(_vectorViewContext,1,-1);
            CGContextTranslateCTM(_vectorViewContext, 0, -rect.size.height);
            CGContextDrawLayerInRect(_vectorViewContext, rect, _vectorLayer);
        }
        //CGLayerRelease(_vectorLayer);
        _haveVectorLayer = NO;
        if (self.delegate)
            [self.delegate vectorViewDidComplete:self];
        return;
    }
    keepProcessing++;
    
    self.displayID = keepProcessing;
    
    _viewBounds.xmn = (self.bounds.origin.x * scale);
    _viewBounds.xmx = ((self.bounds.origin.x + self.bounds.size.width) * scale);
    _viewBounds.ymx = ((self.bounds.origin.y + self.bounds.size.height) * scale);
    _viewBounds.ymn = (self.bounds.origin.y * scale);
    {
        
            CGSize size = CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);
            if (_displayDataOption != DISPLAY_DATA_OPTION_HIGHLIGHT || !_vectorLayer)
                _vectorLayer = CGLayerCreateWithContext(_vectorViewContext, size, NULL);
            else
                _context = CGLayerGetContext(_vectorLayer);

            dispatch_async(_vectorQueue,
                           ^{
                               _colorSpace = CGColorSpaceCreateDeviceRGB();
                               _width = self.bounds.size.width * scale;
                               _height = self.bounds.size.height * scale;
                               _rect = CGRectMake(0, 0, _width, _height);
                               //_context = createBitmapContext (_rect,_width,_height,_colorSpace,&bmData);
                               //_bitmapData = bmData;
                               _context = CGLayerGetContext(_vectorLayer);
                               
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
                                   switch (_displayDataOption)
                                   {
                                       case DISPLAY_DATA_OPTION_DISPLAY:
                                       {
                                           if (keepProcessing == self.displayID &&
                                               [ConfigurationControl.sharedInstance layer:HCLayerParcels                                                                            visibleAtZoom:_zoom])
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
                                           
                                           /* if (keepProcessing == self.displayID && CRAPI.sharedInstance.currentOverallBoundaryRefno)
                                            {
                                            BoundaryData *bd = [[BoundaryData alloc]init];
                                            bd.processingID = keepProcessing;
                                            [bd displayLandUse:_context
                                            llCorners:&_latlonCornerPoints
                                            LLBounds:&_latlonBounds
                                            viewBounds:&_viewBounds];
                                            }*/
                                            
                                           if (keepProcessing == self.displayID &&
                                               [ConfigurationControl.sharedInstance layer:HCLayerPlanimetric
                                                                            visibleAtZoom:_zoom])
                                            {
                                                PlanimetricData *pd = [[PlanimetricData alloc] init];
                                                pd.processingID = keepProcessing;
                                                pd.zoom = _zoom;
                                               
                                                if (keepProcessing == self.displayID)
                                                    [pd displayPlanArea:_context
                                                              llCorners:&_latlonCornerPoints
                                                               LLBounds:&_latlonBounds
                                                             viewBounds:&_viewBounds];
                                                
                                                if (keepProcessing == self.displayID)
                                                    [pd displayPlanLine:_context
                                                              llCorners:&_latlonCornerPoints
                                                               LLBounds:&_latlonBounds
                                                             viewBounds:&_viewBounds];
                                                
                                                if (keepProcessing == self.displayID)
                                                    [pd displayPlanPoint:_context
                                                               llCorners:&_latlonCornerPoints
                                                                LLBounds:&_latlonBounds
                                                              viewBounds:&_viewBounds];
                                            }
                                           
                                           
                                           if (keepProcessing == self.displayID &&
                                               [ConfigurationControl.sharedInstance layer:HCLayerAlleys
                                                                            visibleAtZoom:_zoom])
                                           {
                                               PlanimetricData *pd = [[PlanimetricData alloc] init];
                                               pd.processingID = keepProcessing;
                                               pd.zoom = _zoom;

                                               if (keepProcessing == self.displayID)
                                                   [pd displayAlleyLine:_context
                                                              llCorners:&_latlonCornerPoints
                                                               LLBounds:&_latlonBounds
                                                             viewBounds:&_viewBounds];
                                               
                                               if (keepProcessing == self.displayID)
                                                   [pd displayWallPoint:_context
                                                              llCorners:&_latlonCornerPoints
                                                               LLBounds:&_latlonBounds
                                                             viewBounds:&_viewBounds];
                                           }
                                           if (keepProcessing == self.displayID &&
                                               [ConfigurationControl.sharedInstance layer:HCLayerCurbRamps
                                                                            visibleAtZoom:_zoom])
                                           {
                                               PlanimetricData *pd = [[PlanimetricData alloc] init];
                                               pd.processingID = keepProcessing;
                                               pd.zoom = _zoom;
                                               
                                               if (keepProcessing == self.displayID)
                                               {
                                                   [pd displayCurRampIntersectionPoint:_context
                                                                             llCorners:&_latlonCornerPoints
                                                                              LLBounds:&_latlonBounds
                                                                            viewBounds:&_viewBounds];
                                               }
                                           }
                                           if (keepProcessing == self.displayID &&
                                               [ConfigurationControl.sharedInstance layer:HCLayerSewers
                                                                            visibleAtZoom:_zoom])
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
                                           
                                           if (keepProcessing == self.displayID &&
                                               [ConfigurationControl.sharedInstance layerInConfig:HCLayerSewers])
                                           {
                                               PipeTrace *pt = [[PipeTrace alloc] init];
                                               pt.processingID = keepProcessing;
                                               
                                               [pt displayPipeTrace:_context
                                                          llCorners:&_latlonCornerPoints
                                                           LLBounds:&_latlonBounds
                                                         viewBounds:&_viewBounds];
                                           }
                                       }
                                           break;
                                       case DISPLAY_DATA_OPTION_HIGHLIGHT:
                                       {
                                           switch (_pickedItem.itemType)
                                           {
                                               case PTStormSewerLine:
                                               {
                                                   SewerData *sd = [[SewerData alloc] init];
                                                   sd.processingID = keepProcessing;
                                                   sd.zoom = _zoom;
                                                   
                                                   [sd highlightStormLine:_context
                                                                    refno:_pickedItem.refno
                                                                llCorners:&_latlonCornerPoints
                                                                 LLBounds:&_latlonBounds
                                                               viewBounds:&_viewBounds];
                                                   
                                                  /* [sd displayStormLine:_context
                                                                   pass:LINE_PASS
                                                              llCorners:&_latlonCornerPoints
                                                               LLBounds:&_latlonBounds
                                                             viewBounds:&_viewBounds];*/
                                               }
                                                   
                                                   break;
                                                   
                                           }
                                      }
                                           break;
                               
                                   }
                               }
                               if (keepProcessing == self.displayID)
                               {
                                   _haveVectorLayer = YES;
                                   dispatch_async(dispatch_get_main_queue(),
                                                  ^{
                                                      [self setNeedsDisplay];
                                                  });
                                   /*UIGraphicsBeginImageContext(size);
                                    _context = UIGraphicsGetCurrentContext();
                                    CGContextDrawLayerAtPoint(_context, CGPointMake(0, 0), vectorLayer);
                                    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
                                    NSData * pngData = UIImagePNGRepresentation(image);
                                    [pngData writeToFile:CRAPI.sharedInstance.extractFile atomically:YES];*/
                                   
                               }
                               else
                               {
                                   CGLayerRelease(_vectorLayer);
                                   _vectorLayer = 0;
                                   _haveVectorLayer = NO;
                                   if (self.delegate)
                                       [self.delegate vectorViewDidComplete:self];
                               }
                               
                               //[self freeResources];
                               NSLog (@"Vector view complete");
                           });
        
    }
}

@end