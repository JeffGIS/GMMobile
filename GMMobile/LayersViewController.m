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
    _parcelZoomStepper.maximumValue = 19.0;
    _parcelZoomStepper.continuous = NO;
    _parcelZoomStepper.value = CRAPI.sharedInstance.parcelsVisibleAtZoom;
    
    _parcelZoomLabel.text = [NSString stringWithFormat:@"Show Parcels at Zoom Level %i",
                             (int)CRAPI.sharedInstance.parcelsVisibleAtZoom];
    
    _sewerZoomLabel.text = [NSString stringWithFormat:@"Show Sewer at Zoom Level %i",
                            (int)CRAPI.sharedInstance.sewerVisibleAtZoom];
    
    _parcelShadingOption.selectedSegmentIndex = CRAPI.sharedInstance.parcelShadingOption;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)setParcelZoom:(id)sender
{
    CRAPI.sharedInstance.parcelsVisibleAtZoom = _parcelZoomStepper.value;
    
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

- (IBAction)setParcelShading:(id)sender
{
    CRAPI.sharedInstance.parcelShadingOption = (int)_parcelShadingOption.selectedSegmentIndex;
}

@end