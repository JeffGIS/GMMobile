 //  VectorView.m
//  GMMobile

#import "VectorView.h"
#import "BoundaryData.h"
#import "PlanimetricData.h"
#import "PropertyData.h"
#import "BoundaryData.h"
#import "PipeTrace.h"
#import "CrimeDataDisplay.h"
#import "UserLayerDisplay.h"
#import "ConfigurationControl.h"
#import "NVMetroSettings.h"
#import "Themes.h"
#import "CCodeLibrary/NVDateRange.h"

#define METERS_PER_MILE 1609.344

@interface VectorView ()

@property (nonatomic) LPBYTE bitmapData;
@property (nonatomic) CGColorSpaceRef colorSpace;
@property (nonatomic) CGContextRef vectorViewContext, context;
@property (nonatomic) NSInteger width, height;
@property (nonatomic) dispatch_queue_t vectorQueue;
@property (nonatomic) CGRect rect;
@property BOOL haveVectorLayer;
@property BoundaryData *bd;
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
    NSLog (@"VectorView alloc");
    return self;
}
- (void)dealloc
{
    if (_vectorLayer)
    {
        CGLayerRelease(_vectorLayer);
        NSLog (@"Vector layer released");
    }
    NSLog (@"Vector viewDealloc");
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
    int numPoints, numLoops;
    LPINT polyPartLen;
    
    _latlonCornerPoints = CornerPointsFromRegion (region);
    _latlonBounds = CornerPointBounds (&_latlonCornerPoints);
    CRAPI.sharedInstance.lastViewBounds = _latlonBounds;
    CRAPI.sharedInstance.lastDisplayBounds = _latlonBounds;
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet)
    {
        
    }
    else if (CRAPI.sharedInstance.currentOverallBoundaryRefno &&
        CRAPI.sharedInstance.maskBoundsForBounds &&
        !CRAPI.sharedInstance.selectBoundaryFromMapType)
    {
        BoundaryData *boundData = [[BoundaryData alloc] init];
        MNMXCORD bounds = [boundData getBoundaryAreaBounds:
                           CRAPI.sharedInstance.currentOverallBoundaryRefno
                                                    ofType:@"BOUNDARY"];
        _latlonBounds.xmn = max (_latlonBounds.xmn,bounds.xmn);
        _latlonBounds.ymn = max (_latlonBounds.ymn,bounds.ymn);
        _latlonBounds.xmx = min (_latlonBounds.xmx,bounds.xmx);
        _latlonBounds.ymx = min (_latlonBounds.ymx,bounds.ymx);
        _pia = [[PointInArea alloc] init];
        _pia.maxDimension = 1024;
        
        LPDPOINT pPoints = [boundData getPolygonPointsForBoundary:CRAPI.sharedInstance.currentOverallBoundaryRefno
                                                        numPoints:&numPoints
                                                         numLoops:&numLoops
                                                      polyPartLen:&polyPartLen];

        [_pia loadArea:(int)numPoints
              numLoops:(int)numLoops
           polyPartLen:polyPartLen
                points:pPoints
         boundaryWidth:5];
        //[FileLister listFilesInDirectory:@"SHARED"
        //                        outputTo:@""];
   }

}
- (BOOL) keepGoing
{
    if (!self.displayID)
        return YES;
    BOOL rtn = CRAPI.sharedInstance.keepProcessing == self.displayID;
    return rtn;
}
- (void)drawRect:(CGRect)rect
{
    NSInteger fromDate = 0, toDate = 0;
    [NVDateRange getCurrentFromDate:&fromDate toDate:&toDate];
    CRAPI.sharedInstance.fromDate = fromDate;
    CRAPI.sharedInstance.toDate = toDate;
    
    if (CRAPI.sharedInstance.keepProcessing < 0)
        return;
    
    int scale = UIScreen.mainScreen.scale;
    _vectorViewContext = UIGraphicsGetCurrentContext();
    if (!_vectorViewContext || CRAPI.sharedInstance.keepProcessing < 0)
        return;
    if (_haveVectorLayer)
    {
        UIGraphicsEndPDFContext();
        //CGContextDrawLayerAtPoint(_vectorViewContext, CGPointMake(0, 0), _vectorLayer);
        if ([self keepGoing])
        {
            CGContextScaleCTM(_vectorViewContext,1,-1);
            CGContextTranslateCTM(_vectorViewContext, 0, -rect.size.height);
            CGContextDrawLayerInRect(_vectorViewContext, rect, _vectorLayer);
        }
        //CGLayerRelease(_vectorLayer);
        _haveVectorLayer = NO;
        if (self.delegate)
            [self.delegate vectorViewDidComplete:self
             reDisplay:_redisplay];
        return;
    }
    if (CRAPI.sharedInstance.keepProcessing > 0)
        CRAPI.sharedInstance.keepProcessing++;
    
    self.displayID = CRAPI.sharedInstance.keepProcessing;
    
    CGRect bnds = self.bounds;
    _viewBounds.xmn = (self.bounds.origin.x * scale);
    _viewBounds.xmx = ((self.bounds.origin.x + self.bounds.size.width) * scale);
    _viewBounds.ymx = ((self.bounds.origin.y + self.bounds.size.height) * scale);
    _viewBounds.ymn = (self.bounds.origin.y * scale);
    {
        
            CGSize size = CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);
            if (_displayDataOption != DISPLAY_DATA_OPTION_HIGHLIGHT || !_vectorLayer)
            {
                if (_vectorLayer)
                {
                    CGLayerRelease(_vectorLayer);
                    NSLog (@"Vector layer released");
                }
                _vectorLayer = CGLayerCreateWithContext(_vectorViewContext, size, NULL);
                NSLog (@"Vector layer created");

            }
            else
                _context = CGLayerGetContext(_vectorLayer);

            dispatch_async(_vectorQueue,
                           ^{
                               DisplayCharacteristics *dc = [[DisplayCharacteristics alloc]init];
                               _colorSpace = CGColorSpaceCreateDeviceRGB();
                               _width = self.bounds.size.width * scale;
                               _height = self.bounds.size.height * scale;
                               _rect = CGRectMake(0, 0, _width, _height);
                               //_context = createBitmapContext (_rect,_width,_height,_colorSpace,&bmData);
                               //_bitmapData = bmData;
                               _context = CGLayerGetContext(_vectorLayer);
                              /* NSMutableData *pdf = NSMutableData.data;
                               UIGraphicsBeginPDFContextToData(pdf, CGRectZero, NULL);
                               UIGraphicsBeginPDFPage();
                               _context = UIGraphicsGetCurrentContext();*/
                               if ([self keepGoing] && CRAPI.sharedInstance.showPlats)
                               {
                                   if (ConfigurationControl.sharedInstance.currentApp == HCConfigSewers)
                                   {
                                       SewerData *sd = [[SewerData alloc] init];
                                       sd.processingID = CRAPI.sharedInstance.keepProcessing;
                                       sd.zoom = _zoom;
                                       
                                       [sd displayPlats:_context
                                                   type:@"STORM"
                                              llCorners:&_latlonCornerPoints
                                               LLBounds:&_latlonBounds
                                             viewBounds:&_viewBounds];
                                   }
                                   else if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove)
                                   {
                                       UserLayerDisplay *ud = [[UserLayerDisplay alloc] init];
                                       ud.processingID = CRAPI.sharedInstance.keepProcessing;
                                       ud.zoom = _zoom;
                                       if ([self keepGoing])
                                       {
                                           [ud displayLayers:_context
                                      displayCharacteristics:dc
                                                   llCorners:&_latlonCornerPoints
                                                    LLBounds:&_latlonBounds
                                                  viewBounds:&_viewBounds
                                                      themes:nil
                                                 pointInArea:_pia];
                                       }
                                   }
                               }
                               
                               else if ([self doNVMetroDisplay:dc])
                               {
                                   
                               }
                               
                               else
                               {
                                   Themes * themes = [[Themes alloc]init];
                                   themes.displayID = CRAPI.sharedInstance.keepProcessing;
                                   
                                   [themes setAppThemes];
                                   switch (_displayDataOption)
                                   {
                                       case DISPLAY_DATA_OPTION_DISPLAY:
                                       {
                                           if (CRAPI.sharedInstance.selectBoundaryFromMapType)
                                           {
                                               BoundaryData *bd = [[BoundaryData alloc] init];
                                               bd.processingID = CRAPI.sharedInstance.keepProcessing;
                                               bd.zoom = _zoom;
                                               
                                               [bd display:_context
                                                  areaType:CRAPI.sharedInstance.selectBoundaryFromMapType
                                              pointInAreas:nil
                                                 llCorners:&_latlonCornerPoints
                                                  LLBounds:&_latlonBounds
                                                viewBounds:&_viewBounds];
                                               
                                               [bd displayText:_context
                                                          from:TFOSelectBoundary
                                                      areaType:CRAPI.sharedInstance.selectBoundaryFromMapType
                                                     textOptions:NVMetroSettings.sharedInstance.currentTextOption
                                                  pointInAreas:nil
                                                     llCorners:&_latlonCornerPoints
                                                      LLBounds:&_latlonBounds
                                                    viewBounds:&_viewBounds];

                                           }
                                           else
                                           {
                                               int passID = [themes themesNeedDataPass:CRAPI.sharedInstance.keepProcessing];
                                               while (passID < DonePass)
                                               {
                                                   if (passID == DataPass)
                                                       [themes themesBeginDataPass:CRAPI.sharedInstance.keepProcessing];
                                                   else if (passID == DisplayPass)
                                                       [themes themesBeginDisplayPass:CRAPI.sharedInstance.keepProcessing];
                                                   if ([self keepGoing] &&
                                                       [ConfigurationControl.sharedInstance layer:HCLayerParcels
                                                                                    visibleAtZoom:_zoom
                                                                                          andPass:passID])
                                                   {
                                                       PropertyData *pd = [[PropertyData alloc] init];
                                                       
                                                       pd.processingID = CRAPI.sharedInstance.keepProcessing;
                                                       
                                                       [pd displayParcels:_context
                                                                llCorners:&_latlonCornerPoints
                                                                 LLBounds:&_latlonBounds
                                                               viewBounds:&_viewBounds
                                                                   themes:nil];
                                                       
                                                       [pd displayParcelText:_context
                                                                   llCorners:&_latlonCornerPoints
                                                                    LLBounds:&_latlonBounds
                                                                  viewBounds:&_viewBounds];
                                                   }
                                                   if ([self keepGoing] &&
                                                       [ConfigurationControl.sharedInstance layer:HCLayerPlanimetric
                                                                                    visibleAtZoom:_zoom
                                                                                          andPass:passID])
                                                   {
                                                       PlanimetricData *pd = [[PlanimetricData alloc] init];
                                                       pd.processingID = CRAPI.sharedInstance.keepProcessing;
                                                       pd.zoom = _zoom;
                                                       
                                                       if ([self keepGoing])
                                                           [pd displayPlanArea:_context
                                                                     llCorners:&_latlonCornerPoints
                                                                      LLBounds:&_latlonBounds
                                                                    viewBounds:&_viewBounds];
                                                       
                                                       if ([self keepGoing])
                                                           [pd displayPlanLine:_context
                                                                     llCorners:&_latlonCornerPoints
                                                                      LLBounds:&_latlonBounds
                                                                    viewBounds:&_viewBounds];
                                                       
                                                       if ([self keepGoing])
                                                           [pd displayPlanPoint:_context
                                                                      llCorners:&_latlonCornerPoints
                                                                       LLBounds:&_latlonBounds
                                                                     viewBounds:&_viewBounds];
                                                   }
                                                   
                                                   
                                                   if ([self keepGoing] &&
                                                       [ConfigurationControl.sharedInstance layer:HCLayerAlleys
                                                                                    visibleAtZoom:_zoom
                                                                                          andPass:passID])
                                                   {
                                                       PlanimetricData *pd = [[PlanimetricData alloc] init];
                                                       pd.processingID = CRAPI.sharedInstance.keepProcessing;
                                                       pd.zoom = _zoom;
                                                       
                                                       if ([self keepGoing])
                                                           [pd displayAlleyLine:_context
                                                                      llCorners:&_latlonCornerPoints
                                                                       LLBounds:&_latlonBounds
                                                                     viewBounds:&_viewBounds];
                                                       
                                                       if ([self keepGoing])
                                                           [pd displayWallPoint:_context
                                                                      llCorners:&_latlonCornerPoints
                                                                       LLBounds:&_latlonBounds
                                                                     viewBounds:&_viewBounds];
                                                   }
                                                   if ([self keepGoing] &&
                                                       [ConfigurationControl.sharedInstance layer:HCLayerCurbRamps
                                                                                    visibleAtZoom:_zoom
                                                                                          andPass:passID])
                                                   {
                                                       PlanimetricData *pd = [[PlanimetricData alloc] init];
                                                       pd.processingID = CRAPI.sharedInstance.keepProcessing;
                                                       pd.zoom = _zoom;
                                                       
                                                       if ([self keepGoing])
                                                       {
                                                           [pd displayCurRampIntersectionPoint:_context
                                                                        displayCharacteristics:dc
                                                                                     llCorners:&_latlonCornerPoints
                                                                                      LLBounds:&_latlonBounds
                                                                                    viewBounds:&_viewBounds
                                                                                        themes:themes];
                                                       }
                                                   }
                                                   if ([self keepGoing] &&
                                                       [ConfigurationControl.sharedInstance layer:HCLayerCrimes
                                                                                    visibleAtZoom:_zoom
                                                                                          andPass:passID])
                                                   {
                                                       CrimeDataDisplay *cd = [[CrimeDataDisplay alloc] init];
                                                       cd.processingID = CRAPI.sharedInstance.keepProcessing;
                                                       cd.zoom = _zoom;
                                                       cd.mode = CRAPI.sharedInstance.crimeMode;
                                                       cd.choroplethTarget = CRAPI.sharedInstance.crimeTarget;
                                                       cd.choroplethAdjustValue = ConfigurationControl.sharedInstance.adjustCrimeOption;
                                                       cd.choroplethAdjustArea = ConfigurationControl.sharedInstance.adjustCrimeArea;
                                                       if ([self keepGoing])
                                                       {
                                                           [cd displayCrimePoints:_context
                                                           displayCharacteristics:dc
                                                                        llCorners:&_latlonCornerPoints
                                                                         LLBounds:&_latlonBounds
                                                                       viewBounds:&_viewBounds
                                                                           themes:themes
                                                                      pointInArea:_pia
                                                                             pass:_pass];
                                                           if (!_pass && [self keepGoing])
                                                               _redisplay = YES;
                                                           else
                                                               _redisplay = NO;
                                                       }
                                                   }
                                                   if ([self keepGoing] &&
                                                       [ConfigurationControl.sharedInstance layer:HCLayerSewers
                                                                                    visibleAtZoom:_zoom
                                                                                          andPass:passID])
                                                   {
                                                       SewerData *sd = [[SewerData alloc] init];
                                                       sd.processingID = CRAPI.sharedInstance.keepProcessing;
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
                                                   if ([self keepGoing] &&
                                                       ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove)
                                                   {
                                                       UserLayerDisplay *ud = [[UserLayerDisplay alloc] init];
                                                       ud.processingID = CRAPI.sharedInstance.keepProcessing;
                                                       ud.zoom = _zoom;
                                                       ud.passID = passID;
                                                       if ([self keepGoing])
                                                       {
                                                           [ud displayLayers:_context
                                                      displayCharacteristics:dc
                                                                   llCorners:&_latlonCornerPoints
                                                                    LLBounds:&_latlonBounds
                                                                  viewBounds:&_viewBounds
                                                                      themes:themes
                                                                 pointInArea:_pia];
                                                       }
                                                   }
                                                   
                                                   
                                                  /* if ([self keepGoing])
                                                   {
                                                        BoundaryData *bd = [[BoundaryData alloc] init];
                                                        bd.processingID = CRAPI.sharedInstance.keepProcessing;
                                                        bd.zoom = _zoom;
                                                        [bd displayLandUse:_context
                                                        llCorners:&_latlonCornerPoints
                                                        LLBounds:&_latlonBounds
                                                        viewBounds:&_viewBounds];
                                                    }
                                                    
                                                    if ([self keepGoing])
                                                    {
                                                    BoundaryData *bd = [[BoundaryData alloc] init];
                                                    bd.processingID = CRAPI.sharedInstance.keepProcessing;
                                                    bd.zoom = _zoom;
                                                    [bd displayCensusAreas:_context
                                                    type:@"TRACT"
                                                    llCorners:&_latlonCornerPoints
                                                    LLBounds:&_latlonBounds
                                                    viewBounds:&_viewBounds];
                                                    }*/
                                                   
                                                   if ([self keepGoing] && CRAPI.sharedInstance.currentOverallBoundaryRefno &&
                                                       (CRAPI.sharedInstance.showPolylineForBounds ||
                                                        CRAPI.sharedInstance.maskBoundsForBounds))
                                                   {
                                                       BoundaryData *bd = [[BoundaryData alloc] init];
                                                       
                                                       [bd displayBoundary:CRAPI.sharedInstance.currentOverallBoundaryRefno
                                                                    ofType:@"BOUNDARY"
                                                                    asMask:CRAPI.sharedInstance.maskBoundsForBounds
                                                                 inContext:_context
                                                                 llCorners:&_latlonCornerPoints
                                                                  LLBounds:&_latlonBounds
                                                                viewBounds:&_viewBounds];
                                                   }
                                                   
                                                   if ([self keepGoing] && passID == DisplayPass &&
                                                       [ConfigurationControl.sharedInstance layerInConfig:HCLayerSewers])
                                                   {
                                                       PipeTrace *pt = [[PipeTrace alloc] init];
                                                       pt.processingID = CRAPI.sharedInstance.keepProcessing;
                                                       
                                                       [pt displayPipeTrace:_context
                                                                  llCorners:&_latlonCornerPoints
                                                                   LLBounds:&_latlonBounds
                                                                 viewBounds:&_viewBounds];
                                                   }
                                                   if (passID == DataPass)
                                                       [themes themesEndDataPass:CRAPI.sharedInstance.keepProcessing];
                                                   else if (passID == DisplayPass)
                                                       [themes themesEndDisplayPass:CRAPI.sharedInstance.keepProcessing];
                                                   passID++;
                                               }
                                           }
                                       }
                                           break;
                                           
                                       case DISPLAY_DATA_OPTION_HIGHLIGHT:
                                       {
                                           switch (_pickedItem.itemType)
                                           {
                                               case StormMain:
                                               {
                                                   SewerData *sd = [[SewerData alloc] init];
                                                   sd.processingID = CRAPI.sharedInstance.keepProcessing;
                                                   sd.zoom = _zoom;
                                                   
                                                   [sd highlightStormLine:_context
                                                                    refno:(int)_pickedItem.refno
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
                                              
                                               default:
                                                   break;
                                           }
                                      }
                                           break;
                                   }
                               }
                               if ([self keepGoing])
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
                                   NSLog (@"Vector layer released");
                                   _vectorLayer = 0;
                                   _haveVectorLayer = NO;
                                   if (self.delegate)
                                       [self.delegate vectorViewDidComplete:self
                                                                  reDisplay:NO];
                               }
                               
                               //[self freeResources];
                               NSLog (@"Vector view complete");
                           });
    }
}
-(void)   displayMapit:(CGContextRef)context
displayCharacteristics:(DisplayCharacteristics *)dc
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
                themes:(Themes*)themes
           pointInArea:(PointInArea *)pia
{
    
    if ([self keepGoing])
    {
        BoundaryData *bd = [[BoundaryData alloc] init];
        bd.processingID = self.displayID;
        bd.zoom = _zoom;
        [bd displayLandUse:_context
                 llCorners:&_latlonCornerPoints
                  LLBounds:&_latlonBounds
                viewBounds:&_viewBounds
    displayCharacteristics:dc
                    themes:themes
               pointInArea:pia];

    }

}

- (BOOL) doNVMetroDisplay:(DisplayCharacteristics *)dc
{
    if (ConfigurationControl.sharedInstance.currentApp != HCConfigMetroProp &&
        ConfigurationControl.sharedInstance.currentApp != HCConfigFromSpreadsheet &&
        ConfigurationControl.sharedInstance.currentApp != HCConfigFromSpreadsheet)
        return FALSE;
    if (CRAPI.sharedInstance.selectBoundaryFromMapType)
        return FALSE;
    
    Themes * themes = [[Themes alloc]init];
    themes.displayID = CRAPI.sharedInstance.keepProcessing;
    [themes setAppThemes];
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigFromSlowValues)
    {
        [self        displayMapit:_context
           displayCharacteristics:dc
                        llCorners:&_latlonCornerPoints
                         LLBounds:&_latlonBounds
                       viewBounds:&_viewBounds
                           themes:themes
                      pointInArea:_pia];
        
        BoundaryData *bd = [[BoundaryData alloc] init];
        
        if (ConfigurationControl.sharedInstance.MapitBoundaryOpt == MAPIT_CIRCULAR)
        {
            [bd displayCircularBoundaryAt:ConfigurationControl.sharedInstance.MapitTargetCenterPoint
                               withRadius:ConfigurationControl.sharedInstance.MapitCirularBoundaryRadiusInMiles*METERS_PER_MILE
                                lineWidth:0
                                   asMask:1
                                inContext:_context
                                llCorners:&_latlonCornerPoints
                                 LLBounds:&_latlonBounds
                               viewBounds:&_viewBounds];
            
        }
        else
        {
            [bd displayBoundary:ConfigurationControl.sharedInstance.MapitBoundaryRefno
                         ofType:ConfigurationControl.sharedInstance.MapitBoundaryType
                         asMask:1
                      inContext:_context
                      llCorners:&_latlonCornerPoints
                       LLBounds:&_latlonBounds
                     viewBounds:&_viewBounds];
        }
        
    }
   
    else switch (_displayDataOption)
    {
        case DISPLAY_DATA_OPTION_DISPLAY:
        {
            ItemProcessingPassTypes passID = [themes themesNeedDataPass:CRAPI.sharedInstance.keepProcessing];
            while (passID < DonePass)
            {
                if (passID == DataPass)
                    [themes themesBeginDataPass:CRAPI.sharedInstance.keepProcessing];
                else if (passID == DisplayPass)
                    [themes themesBeginDisplayPass:CRAPI.sharedInstance.keepProcessing];
                
                if ([self keepGoing])
                    switch (NVMetroSettings.sharedInstance.currentFeature)
                {
                    case CPFLandUse:
                    {
                        BoundaryData *bd = [[BoundaryData alloc] init];
                        bd.processingID = CRAPI.sharedInstance.keepProcessing;
                        bd.zoom = _zoom;
                        bd.numPass = 2;
                        [bd displayLandUse:_context
                                 llCorners:&_latlonCornerPoints
                                  LLBounds:&_latlonBounds
                                viewBounds:&_viewBounds
                    displayCharacteristics:dc
                                    themes:themes
                               pointInArea:_pia];
                        
                        
                    }
                        break;
                        
                    case CPFParcels:
                    case CPFParcels_IND:
                    case CPFParcels_AG:
                    case CPFParcels_RES:
                    case CPFParcels_COM:
                    case CPFBlocks:
                    case CPFBlockGroups:
                    case CPFBlockGroups_ACS:
                    case CPFTracts:
                    {
                        NSString *CenType = @"PARCEL";
                        if (NVMetroSettings.sharedInstance.currentFeature == CPFBlocks)
                            CenType = @"BLOCK";
                        if (NVMetroSettings.sharedInstance.currentFeature == CPFBlockGroups)
                            CenType = @"BLOCKGROUP";
                        if (NVMetroSettings.sharedInstance.currentFeature == CPFBlockGroups_ACS)
                            CenType = @"BLOCKGROUP_ACS";
                        if (NVMetroSettings.sharedInstance.currentFeature == CPFTracts)
                            CenType = @"TRACT";
                        if (passID == DataPass || !_bd)
                        {
                            _bd = BoundaryData.new;
                            _bd.numPass = 1;
                            if ([NVMetroSettings.sharedInstance currentValueFields].length > 0)
                                _bd.numPass++;
                            if (NVMetroSettings.sharedInstance.currentTextOption.numTextFields > 0)
                                _bd.numPass++;
                            [_bd open];
                        }
                        _bd.pass = passID;
                        _bd.processingID = CRAPI.sharedInstance.keepProcessing;
                        _bd.zoom = _zoom;
                        [_bd displayCensusAreas:_context
                                          type:CenType
                        displayCharacteristics:dc
                                     llCorners:&_latlonCornerPoints
                                      LLBounds:&_latlonBounds
                                    viewBounds:&_viewBounds
                                        themes:themes
                                    pointInArea:_pia];
                        if (passID == DisplayPass &&
                            NVMetroSettings.sharedInstance.currentTextOption.numTextFields > 0)
                        {
                            [_bd displayText:_context
                                        from:TFONVMetroDisplay
                                   areaType:CenType
                                textOptions:NVMetroSettings.sharedInstance.currentTextOption
                               pointInAreas:nil
                                  llCorners:&_latlonCornerPoints
                                   LLBounds:&_latlonBounds
                                 viewBounds:&_viewBounds];
                            
                            [_bd close:YES];
                            _bd = nil;
                        }
                    }
                        break;
                    default:
                        break;
                }
                
                if (passID == DataPass)
                    [themes themesEndDataPass:CRAPI.sharedInstance.keepProcessing];
                else if (passID == DisplayPass)
                {
                    [themes themesEndDisplayPass:CRAPI.sharedInstance.keepProcessing];
                    if ([self keepGoing] && CRAPI.sharedInstance.currentOverallBoundaryRefno &&
                        (CRAPI.sharedInstance.showPolylineForBounds ||
                         CRAPI.sharedInstance.maskBoundsForBounds))
                    {
                        BoundaryData *bd = [[BoundaryData alloc] init];
                        
                        [bd displayBoundary:CRAPI.sharedInstance.currentOverallBoundaryRefno
                                     ofType:@"BOUNDARY"
                                     asMask:CRAPI.sharedInstance.maskBoundsForBounds
                                  inContext:_context
                                  llCorners:&_latlonCornerPoints
                                   LLBounds:&_latlonBounds
                                 viewBounds:&_viewBounds];
                    }
                    

                }
                passID++;
            }
        }
            break;
            
    }
    return TRUE;
}
@end
