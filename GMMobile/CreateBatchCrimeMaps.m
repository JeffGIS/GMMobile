//  CreateBatchCrimeMaps.m
//  NVMobile

#import "CreateBatchCrimeMaps.h"
#import "BoundaryData.h"

static int pageWidthFactor = 1;

@implementation CreateBatchCrimeMaps

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.backgroundCrimeQueue = dispatch_queue_create("backgroundCrimeQueue", NULL);
    }
    NSLog (@"VectorView init");
    return self;
}

- (void)createImages:(NSString *)batchName
             popover:(GSSiPopoverView *)popover
{
    _popover = popover;
    DisplayCharacteristics *dc = DisplayCharacteristics.new;
    void *bmData = NULL;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int width = 1600*2;
    int height = 3200*2;
    int numPages = 2;
    MNMXCORD viewBounds;
    _pdfFile = [NSString stringWithFormat:@"%@/sample%i.pdf",NSTemporaryDirectory(),pageWidthFactor];
    _pageArray = NSMutableArray.array;
    
    _popover.hideAtCancel = YES;
    _popover.delegate = self;
    _popover.title = [NSString stringWithFormat:@"Creating Background Maps"];
    [_popover show];
    
    viewBounds.xmn = 0;
    viewBounds.ymn = 0;
    viewBounds.xmx = width;
    viewBounds.ymx = height;
    
    Themes *themes = Themes.new;
    themes.displayID = 0;
    HardCodedConfigs saveConfig = ConfigurationControl.sharedInstance.currentApp;
    ConfigurationControl.sharedInstance.currentApp = HCConfigCrimes;
    
    long long refno = 51144;//[BoundaryData getBoundaryAreaRefnoForType:@"CITY" andName:@"Minneapolis"];
    BoundaryData *bd = BoundaryData.new;
    MNMXCORD areaBounds = [bd getBoundaryAreaBounds:refno
                                             ofType:@"BOUNDARY"];
    CORNERPOINTS latlonCornerPoints = CornerPointsFromLLBoundsAndView (&areaBounds,&viewBounds);
    MNMXCORD latlonBounds = CornerPointBounds (&latlonCornerPoints);
    dispatch_async(_backgroundCrimeQueue, ^{
        for (int pageNumber = 0;pageNumber < numPages;pageNumber++)
        {
            double progress = (double)pageNumber / numPages;
            
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               [_popover setTitle:[NSString stringWithFormat:@"Processing Page %i",pageNumber+1]];
                               [_popover updateProgress:progress];
                               
                           });
            
            NSString * tempDirectory = [NSString stringWithFormat:@"%@/BatchCrimeMaps/page%i",NSTemporaryDirectory(),pageNumber];
            [themes setAppThemes:tempDirectory outputFactor:0.6*pageWidthFactor];
            
            CGContextRef context = createBitmapContext(width, height, colorSpace, &bmData);
            CGContextSetAllowsAntialiasing(context, YES);
            CGContextSetShouldAntialias(context, YES);
            CGContextTranslateCTM(context, 0, height);
            CGContextScaleCTM(context, 1, -1);
            CGRect colorRect;
            colorRect.origin.x = 0;
            colorRect.origin.y = 0;
            colorRect.size.width = width;
            colorRect.size.height = height;
            UIColor *white = [UIColor whiteColor];
            CGContextSetFillColorWithColor(context,[white CGColor]);
            CGContextFillRect (context,colorRect);
            
            _cd = [[CrimeDataDisplay alloc] init];
            _cd.processingID = 0;
            _cd.zoom = 0;
            _cd.mode = PINMAP;
            if (pageNumber)
                _cd.mode = HOTSPOT;
            _cd.choroplethTarget = CRAPI.sharedInstance.crimeTarget;
            _cd.choroplethAdjustValue = ConfigurationControl.sharedInstance.adjustCrimeOption;
            _cd.choroplethAdjustArea = ConfigurationControl.sharedInstance.adjustCrimeArea;
            int passID = [themes themesNeedDataPass:0];
            
            while (passID < DonePass)
            {
                if (passID == DataPass)
                    [themes themesBeginDataPass:0];
                
                else if (passID == DisplayPass)
                    [themes themesBeginDisplayPass:0];
                
                [_cd displayCrimePoints:context
                 displayCharacteristics:dc
                              llCorners:&latlonCornerPoints
                               LLBounds:&latlonBounds
                             viewBounds:MNMXCORD_view(&viewBounds)
                                 themes:themes
                            pointInArea:nil
                                   pass:passID++];
            }
            
            if (CRAPI.sharedInstance.currentOverallBoundaryRefno &&
                (CRAPI.sharedInstance.showPolylineForBounds ||
                 CRAPI.sharedInstance.maskBoundsForBounds))
            {
                BoundaryData *bd = [[BoundaryData alloc] init];
                
                [bd displayBoundary:CRAPI.sharedInstance.currentOverallBoundaryRefno
                             ofType:@"BOUNDARY"
                             asMask:CRAPI.sharedInstance.maskBoundsForBounds
                          inContext:context
                          llCorners:&latlonCornerPoints
                           LLBounds:&latlonBounds
                         viewBounds:&viewBounds];
            }
            [themes themesEndDisplayPass:0];
            if (context)
                CGContextRelease(context);
            NSString *file = [NSString stringWithFormat:@"%@/map_%i.gmp", NSTemporaryDirectory(),pageNumber];
            BOOL rtn = WriteBitmapDataToFile((LPSTR)file.UTF8String,width, height, colorSpace, bmData);
            
            long long fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:file
                                                                                error:nil].fileSize;
           /* UIImage *image = [UIImage imageWithContentsOfFile:file];
            file = [NSString stringWithFormat:@"%@/map_%i.png", NSTemporaryDirectory(),pageNumber];
            [UIImagePNGRepresentation(image) writeToFile:file atomically:YES];
            
            fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:file
                                                                      error:nil].fileSize;
            */
            CGColorSpaceRelease(colorSpace);
            if (bmData)
                free (bmData);
            ConfigurationControl.sharedInstance.currentApp = saveConfig;
            PDFPage *page = PDFPage.new;
            page.pageWidth = 2550;//8.5 inches X 300 DPI
            page.pageHeight = 3300;//11 inches X 300 DPI
            PDFPageImage *mainImage = PDFPageImage.new;
            mainImage.imageFile = file;
            double mainImageWidth = 0.6;
            double imageFactor = (mainImageWidth * height) / width;
            mainImage.imageLocation = CGRectMake(60.0*pageWidthFactor, 60.0*pageWidthFactor, mainImageWidth*page.pageWidth, page.pageWidth*imageFactor);
            [page.PDFPageImages addObject:mainImage];
            
            int x = 1950;
            int y = 90*pageWidthFactor;
            
            for (Theme *thm in themes.themeList)
            {
                PDFPageImage *image = PDFPageImage.new;
                CGSize size = [thm.legend writeThemeLegendToFile];
                image.imageLocation = CGRectMake(x*pageWidthFactor, y*pageWidthFactor, size.width, size.height);
                y+= (size.height + 10*pageWidthFactor);
                image.imageFile = thm.legend.outputFile;
                [page.PDFPageImages addObject:image];
            }
            
            PDFPageTextBlock *tb = PDFPageTextBlock.new;
            tb.text = @"Violent Crime Pin Map\nCity of Minneapolis";
            if (pageNumber)
                tb.text = @"Violent Crime Hotspot Map\nCity of Minneapolis";
            tb.textColor = UIColor.blueColor;
            tb.textLocation = CGRectMake(15.0*pageWidthFactor, 15.0*pageWidthFactor, page.pageWidth, 90.0*pageWidthFactor*2);
            tb.font = [UIFont boldSystemFontOfSize:72.0*pageWidthFactor];
            [page.PDFPageTextBlocks addObject:tb];
            [_pageArray addObject:page];
        }
        if (!_cd.processingID)
        {
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               [_popover setTitle:@"Creating PDF File"];
                               [_popover updateProgress:1];
                           });
            [PDFCreator writePDFtoFile:_pdfFile fromPageArray:_pageArray];
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                         target:self
                                                                       selector:@selector(createPDF:)
                                                                       userInfo:nil
                                                                        repeats:NO];
                           });
        }
    });
}

- (void)createPDF:(NSTimer*)timer
{
    [timer invalidate];
    [_popover hide];
    pageWidthFactor++;
    uploadToCloud(_pdfFile, YES);
    
}

- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    _cd.processingID = 1;
}

@end
