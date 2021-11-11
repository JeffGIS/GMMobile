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
#import "HuntingDataDisplay.h"
#import "ConfigurationControl.h"
#import "NVMetroSettings.h"
#import "Themes.h"
#import "MinnesotaGame.h"
#import "CCodeLibrary/NVDateRange.h"
#import "CCodeLibrary/SidewalkData.h"



@interface VectorView ()

@property (nonatomic) LPBYTE bitmapData;
@property (nonatomic) CGColorSpaceRef colorSpace;
@property (nonatomic) CGContextRef vectorViewContext, context;
@property (nonatomic) NSInteger width, height;
@property (nonatomic) CGRect rect;
@property (nonatomic) int haveVectorLayer;
@property BoundaryData *bd;
@end

@implementation VectorView
- (void) setHaveVectorLayer:(int)vectorLayer
{
    _haveVectorLayer = vectorLayer;
}
- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = UIColor.clearColor;
    }
    NSLog (@"VectorView init");
     return self;
}
- (void)dealloc
{
    if (_vectorLayer)
    {
        CGLayerRelease(_vectorLayer);
        NSLog (@"VectorView dealloc");
        NSLog (@"Vector layer released");
    }
    [self freeResources];
}


- (void)freeResources
{
    if (_bitmapData)
        free (_bitmapData);
    _bitmapData = nil;
    
//    if (_context)
//        CGContextRelease(_context);
    _context = nil;
    if (_colorSpace)
        CGColorSpaceRelease(_colorSpace);
    _colorSpace = nil;

}
/*CGContextRef createBitmapContext(CGRect rect,int pixelsWide, int pixelsHigh,CGColorSpaceRef colorSpace, void **bmData)
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
}*/


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
        (CRAPI.sharedInstance.maskBoundsForBounds && CRAPI.sharedInstance.maskTransparency > 0.99) &&
        !CRAPI.sharedInstance.selectBoundaryFromMapType)
    {
        BoundaryData *boundData = [[BoundaryData alloc] init];
        MNMXCORD bounds = [boundData getBoundaryAreaBounds:
                           CRAPI.sharedInstance.currentOverallBoundaryRefno
                                                    ofType:CRAPI.sharedInstance.currentOverallBoundaryType];
        if (bounds.xmn)
        {
            _latlonBounds.xmn = max (_latlonBounds.xmn,bounds.xmn);
            _latlonBounds.ymn = max (_latlonBounds.ymn,bounds.ymn);
            _latlonBounds.xmx = min (_latlonBounds.xmx,bounds.xmx);
            _latlonBounds.ymx = min (_latlonBounds.ymx,bounds.ymx);
        }
        _pia = [[PointInArea alloc] init];
        _pia.maxDimension = 1024;
        
        LPDPOINT pPoints = [boundData getPolygonPointsForBoundary:CRAPI.sharedInstance.currentOverallBoundaryRefno
                                                           ofType:CRAPI.sharedInstance.currentOverallBoundaryType
                                                        numPoints:&numPoints
                                                         numLoops:&numLoops
                                                      polyPartLen:&polyPartLen];

        if (pPoints)
        {
            [_pia loadArea:(int)numPoints
              numLoops:(int)numLoops
           polyPartLen:polyPartLen
                points:pPoints
         boundaryWidth:5];
        }
        else
            _pia = nil;
        if (pPoints)
            free (pPoints);
        //[FileLister listFilesInDirectory:@"SHARED"
        //                        outputTo:@""];
   }

}
void checkLLBounds (MNMXCORD * bounds)
{
   static BOOL stop = FALSE;
   if (stop && bounds->ymn < 45 && bounds->ymx > 45)
        ii=1;
   return;
}
- (BOOL) keepGoing
{
    if (!_displayID)
        return YES;
    if (CRAPI.sharedInstance.keepProcessing == _displayID)
        return TRUE;
    //checkLLBounds(&_latlonBounds);
    return FALSE;
}

- (void) vectorViewToPDF
{
    CGRect bnds = CGRectMake(0, 0, 612, 792);
    _pdf = NSMutableData.data;
    UIGraphicsBeginPDFContextToData(_pdf, bnds, NULL);
    UIGraphicsBeginPDFPage();//WithInfo(bnds,nil);
    _vectorViewContext = UIGraphicsGetCurrentContext();
    int scale = 1;
    _displayID = 0;
    [self processVectorView:bnds
                      scale:scale];
}

- (void)drawRect:(CGRect)rect
{
    _pdf = nil;
    NSInteger fromDate = 0, toDate = 0;
    [NVDateRange getCurrentFromDate:&fromDate toDate:&toDate];
    CRAPI.sharedInstance.fromDate = fromDate;
    CRAPI.sharedInstance.toDate = toDate;
    
    if (CRAPI.sharedInstance.keepProcessing < 0)
        return;
    if (_displayID < 0)
        return;
  
    int printFactor = 1;
    int scale = UIScreen.mainScreen.scale*printFactor;
    _vectorViewContext = UIGraphicsGetCurrentContext();
    if (!_vectorViewContext || CRAPI.sharedInstance.keepProcessing < 0)
        return;
    if (self.haveVectorLayer)
    {
        //UIGraphicsEndPDFContext();
        //CGContextDrawLayerAtPoint(_vectorViewContext, CGPointMake(0, 0), _vectorLayer);
        if ([self keepGoing])
        {
            CGContextScaleCTM(_vectorViewContext,1,-1);
            CGContextTranslateCTM(_vectorViewContext, 0, -rect.size.height);
            CGContextDrawLayerInRect(_vectorViewContext, rect, _vectorLayer);
        }
        //CGLayerRelease(_vectorLayer);
        self.haveVectorLayer = NO;
        if (self.delegate)
            [self.delegate vectorViewDidComplete:self
                                         pdfData:nil
                                       reDisplay:_redisplay];
        return;
    }
    if (CRAPI.sharedInstance.keepProcessing > 0)
        CRAPI.sharedInstance.keepProcessing++;
    
    _displayID = CRAPI.sharedInstance.keepProcessing;
    
    CGRect bnds = self.bounds;
    [self processVectorView:bnds
                      scale:scale];
}

- (void) processVectorView:(CGRect) bounds
                     scale:(int) scale
{
    _viewBounds.xmn = (bounds.origin.x * scale);
    _viewBounds.xmx = ((bounds.origin.x + bounds.size.width) * scale);
    _viewBounds.ymx = ((bounds.origin.y + bounds.size.height) * scale);
    _viewBounds.ymn = (bounds.origin.y * scale);
    {
        CGSize size = CGSizeMake(bounds.size.width * scale, bounds.size.height * scale);
        
        if (_pdf)
            _context = _vectorViewContext;
        
        else if (_displayDataOption != DISPLAY_DATA_OPTION_HIGHLIGHT || !_vectorLayer)
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

        dispatch_async(CRAPI.sharedInstance.vectorQueue, ^{
            DisplayCharacteristics *dc = DisplayCharacteristics.new;
            _colorSpace = CGColorSpaceCreateDeviceRGB();
            _width = bounds.size.width * scale;
            _height = bounds.size.height * scale;
            _rect = CGRectMake(0, 0, _width, _height);
            //_context = createBitmapContext (_rect,_width,_height,_colorSpace,&bmData);
            //_bitmapData = bmData;
            
            if (!_pdf)
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
                    sd.processingID = _displayID;
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
                    ud.processingID = _displayID;
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
            
            else if ([self keepGoing] && [self doNVMetroDisplay:dc])
            {
            }
            
            else
            {
                Themes * themes = [[Themes alloc]init];
                themes.displayID = _displayID;
                
                [themes setAppThemes:nil
                        outputFactor:1];
                switch (_displayDataOption)
                {
                    case DISPLAY_DATA_OPTION_DISPLAY:
                    {
                        if (CRAPI.sharedInstance.selectBoundaryFromMapType)
                        {
                            BoundaryData *bd = [[BoundaryData alloc] init];
                            bd.processingID = _displayID;
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
                            ItemProcessingPassTypes passID = [themes themesNeedDataPass:_displayID];
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
                                    
                                    pd.processingID = _displayID;
                                    
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
                                    pd.processingID = _displayID;
                                    pd.zoom = _zoom;
                                    
                                    if ([self keepGoing])
                                    {
                                        [pd displayPlanArea:_context
                                                  llCorners:&_latlonCornerPoints
                                                   LLBounds:&_latlonBounds
                                                 viewBounds:&_viewBounds];
                                    }
                                    
                                    if ([self keepGoing])
                                    {
                                        [pd displayPlanLine:_context
                                                  llCorners:&_latlonCornerPoints
                                                   LLBounds:&_latlonBounds
                                                 viewBounds:&_viewBounds];
                                    }
                                    
                                    if ([self keepGoing])
                                    {
                                        [pd displayPlanPoint:_context
                                                   llCorners:&_latlonCornerPoints
                                                    LLBounds:&_latlonBounds
                                                  viewBounds:&_viewBounds];
                                    }
                                }
                                
                                if ([self keepGoing] &&
                                    [ConfigurationControl.sharedInstance layer:HCLayerAlleys
                                                                 visibleAtZoom:_zoom
                                                                       andPass:passID])
                                {
                                    PlanimetricData *pd = [[PlanimetricData alloc] init];
                                    pd.processingID = _displayID;
                                    pd.zoom = _zoom;
                                    
                                    if ([self keepGoing])
                                    {
                                        [pd displayAlleyLine:_context
                                                   llCorners:&_latlonCornerPoints
                                                    LLBounds:&_latlonBounds
                                                  viewBounds:&_viewBounds];
                                    }
                                    
                                    if ([self keepGoing])
                                    {
                                        [pd displayWallPoint:_context
                                                   llCorners:&_latlonCornerPoints
                                                    LLBounds:&_latlonBounds
                                                  viewBounds:&_viewBounds];
                                    }
                                }
                                
                                if ([self keepGoing] &&
                                    [ConfigurationControl.sharedInstance layer:HCLayerCurbRamps
                                                                 visibleAtZoom:_zoom
                                                                       andPass:passID])
                                {
                                    PlanimetricData *pd = [[PlanimetricData alloc] init];
                                    pd.processingID = _displayID;
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
                                    cd.processingID = &_displayID;
                                    cd.zoom = _zoom;
                                    cd.mapView = _mapView;
                                    cd.mvc = _mvc;
                                    cd.backgroundImage = _backgroundImage;
                                    cd.mode = CRAPI.sharedInstance.crimeMode;
                                    cd.choroplethTarget = CRAPI.sharedInstance.crimeTarget;
                                    cd.choroplethAdjustValue = ConfigurationControl.sharedInstance.adjustCrimeOption;
                                    cd.choroplethAdjustArea = ConfigurationControl.sharedInstance.adjustCrimeArea;
                                    if ([self keepGoing])
                                    {
                                        [cd displayCrimePoints:_context
                                               contextIsBitmap:FALSE
                                        displayCharacteristics:dc
                                                     llCorners:CORNERPOINTS_view(&_latlonCornerPoints)
                                                      LLBounds:&_latlonBounds
                                                    viewBounds:MNMXCORD_view(&_viewBounds)
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
                                    sd.processingID = _displayID;
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
                                    ud.processingID = _displayID;
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
                                
                                if ([self keepGoing] &&
                                    ConfigurationControl.sharedInstance.currentApp == HCConfigHunting)
                                {
                                    _pia = nil;
                                    HuntingDataDisplay *ud = [[HuntingDataDisplay alloc] init];
                                    ud.processingID = _displayID;
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
                                 bd.processingID = _displayID;
                                 bd.zoom = _zoom;
                                 [bd displayLandUse:_context
                                 llCorners:&_latlonCornerPoints
                                 LLBounds:&_latlonBounds
                                 viewBounds:&_viewBounds];
                                 }
                                 
                                 if ([self keepGoing])
                                 {
                                 BoundaryData *bd = [[BoundaryData alloc] init];
                                 bd.processingID = _displayID;
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
                                                 ofType:CRAPI.sharedInstance.currentOverallBoundaryType
                                                 asMask:CRAPI.sharedInstance.maskTransparency
                                              inContext:_context
                                              llCorners:&_latlonCornerPoints
                                               LLBounds:&_latlonBounds
                                             viewBounds:&_viewBounds];
                                }
                                
                                if ([self keepGoing] && passID == DisplayPass &&
                                    ConfigurationControl.sharedInstance.currentApp == HCConfigMinnesotaGame)
                                {
                                    if (!ConfigurationControl.sharedInstance.mng)
                                        ConfigurationControl.sharedInstance.mng = MinnesotaGame.new;
                                    ConfigurationControl.sharedInstance.mng.parentView = _mvc.view;
                                    ConfigurationControl.sharedInstance.mng.mvc = _mvc;

                                    [ConfigurationControl.sharedInstance.mng displayPickedPoint:CRAPI.sharedInstance.lastPickPoint
                                                  inContext:_context                                               llCorners:&_latlonCornerPoints
                                                   LLBounds:&_latlonBounds
                                                 viewBounds:&_viewBounds];

                                }
                                else if ([self keepGoing] && passID == DisplayPass &&
                                    [ConfigurationControl.sharedInstance layerInConfig:HCLayerSewers])
                                {
                                    PipeTrace *pt = [[PipeTrace alloc] init];
                                    pt.processingID = _displayID;
                                    
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
                                sd.processingID = _displayID;
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
            if (!_displayID)
            {
                UIGraphicsEndPDFContext();
                
                if (self.delegate)
                    [self.delegate vectorViewDidComplete:self
                                                 pdfData:_pdf
                                               reDisplay:_redisplay];
                
            }
            else if ([self keepGoing])
            {
                self.haveVectorLayer = YES;
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
                self.haveVectorLayer = NO;
                if (self.delegate)
                    [self.delegate vectorViewDidComplete:self
                                                 pdfData:nil
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
        bd.processingID = _displayID;
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
    themes.displayID = _displayID;
    [themes setAppThemes:nil
            outputFactor:1];
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
            ItemProcessingPassTypes passID = [themes themesNeedDataPass:_displayID];
            while ([self keepGoing] && passID < DonePass)
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
                        bd.processingID = _displayID;
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
                        _bd.processingID = _displayID;
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
                                     asMask:CRAPI.sharedInstance.maskTransparency
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
