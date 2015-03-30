//  LayersViewController.m
//  GMMobile

#import "LayersViewController.h"

@interface LayersViewController ()

@end

@implementation LayersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _parcelZoomStepper.stepValue = 1.0;
    _parcelZoomStepper.minimumValue = 12.0;
    _parcelZoomStepper.maximumValue = 20.0;
    _parcelZoomStepper.continuous = NO;
    _parcelZoomStepper.value = CRAPI.sharedInstance.parcelsVisibleAtZoom;
    
    _sewerZoomStepper.stepValue = 1.0;
    _sewerZoomStepper.minimumValue = 12.0;
    _sewerZoomStepper.maximumValue = 20.0;
    _sewerZoomStepper.continuous = NO;
    _sewerZoomStepper.value = CRAPI.sharedInstance.parcelsVisibleAtZoom;
    
    _parcelZoomLabel.text = [NSString stringWithFormat:@"Show Parcels at Zoom Level %i",
                             (int)CRAPI.sharedInstance.parcelsVisibleAtZoom];
    
    _sewerZoomLabel.text = [NSString stringWithFormat:@"Show Sewer at Zoom Level %i",
                            (int)CRAPI.sharedInstance.sewerVisibleAtZoom];

    if (CRAPI.sharedInstance.parcelShadingOption > 3)
    {
        _parcelShadingOption2.selectedSegmentIndex = CRAPI.sharedInstance.parcelShadingOption-4;
        _parcelShadingOption.selectedSegmentIndex = -1;
    }
    else
    {
        _parcelShadingOption.selectedSegmentIndex = CRAPI.sharedInstance.parcelShadingOption;
        _parcelShadingOption2.selectedSegmentIndex = -1;
    }
    
    _parcelBoundaryLines.selectedSegmentIndex = CRAPI.sharedInstance.showParcelBoundary;
    [self setParcelLines];
    }

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)setParcelZoom:(id)sender
{
    CRAPI.sharedInstance.parcelsVisibleAtZoom = _parcelZoomStepper.value;
    
    if (CRAPI.sharedInstance.parcelsVisibleAtZoom > 19)
        _parcelZoomLabel.text = [NSString stringWithFormat:@"Never Show Parcels"];
    
    else
        _parcelZoomLabel.text = [NSString stringWithFormat:@"Show Parcels at Zoom Level %i",
                             (int)CRAPI.sharedInstance.parcelsVisibleAtZoom];
}

- (IBAction)setGMTileZoom:(id)sender
{
    CRAPI.sharedInstance.GMTilesVisible = !CRAPI.sharedInstance.GMTilesVisible;
}

- (IBAction)setSewerZoom:(id)sender
{
    CRAPI.sharedInstance.sewerVisibleAtZoom = _sewerZoomStepper.value;
    
    _sewerZoomLabel.text = [NSString stringWithFormat:@"Show Sewer at Zoom Level %i",
                            (int)CRAPI.sharedInstance.sewerVisibleAtZoom];
    
}

- (IBAction)displayTileInfo:(id)sender
{
    CRAPI.sharedInstance.showTileInfo = !CRAPI.sharedInstance.showTileInfo;
}

-(void)setParcelLines
{
    if (CRAPI.sharedInstance.parcelShadingOption)
        _parcelBoundaryLines.enabled = YES;
    
    else
    {
        _parcelBoundaryLines.selectedSegmentIndex = 1;
        _parcelBoundaryLines.enabled = NO;
        CRAPI.sharedInstance.showParcelBoundary = YES;
    }
}

- (IBAction)parcelShadingOption:(id)sender
{
    CRAPI.sharedInstance.parcelShadingOption = (int)_parcelShadingOption.selectedSegmentIndex;
    _parcelShadingOption2.selectedSegmentIndex = -1;
    [self setParcelLines];
}

- (IBAction)parcelShadingOption2:(id)sender
{
    _parcelShadingOption.selectedSegmentIndex = -1;
    CRAPI.sharedInstance.parcelShadingOption = (int)_parcelShadingOption2.selectedSegmentIndex+4;
    [self setParcelLines];
}

- (IBAction)parcelTextOption:(id)sender
{
    CRAPI.sharedInstance.parcelTextOption = (int)_parcelTextOption.selectedSegmentIndex;
    _parcelTextOption2.selectedSegmentIndex = -1;
    [self setParcelLines];
}

- (IBAction)parcelTextOption2:(id)sender
{
    _parcelTextOption.selectedSegmentIndex = -1;
    CRAPI.sharedInstance.parcelTextOption = (int)_parcelTextOption2.selectedSegmentIndex+4;
    [self setParcelLines];
}

- (IBAction)parcelBoundaryLines:(id)sender
{
    CRAPI.sharedInstance.showParcelBoundary = !CRAPI.sharedInstance.showParcelBoundary;
}

- (IBAction)showSpreadsheetView:(id)sender
{
    SpreadsheetView *spreadsheetView = [SpreadsheetView spreadsheetViewWithRows:24
                                                                        columns:8
                                                                           view:self.view];
    
    [self.view addSubview:spreadsheetView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    for (SpreadsheetView *spreadsheetView in self.view.subviews)
    {
        if ([spreadsheetView isKindOfClass:SpreadsheetView.class])
        {
            [spreadsheetView willRotateWithDuration:duration
                                       tabBarHeight:self.tabBarController.tabBar.frame.size.height];
        }
            
    }
}

@end