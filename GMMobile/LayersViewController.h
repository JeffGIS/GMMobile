//  LayersViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface LayersViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *parcelZoomLabel;
@property (weak, nonatomic) IBOutlet UILabel *sewerZoomLabel;
@property (weak, nonatomic) IBOutlet UIStepper *parcelZoomStepper;
@property (weak, nonatomic) IBOutlet UIStepper *sewerZoomStepper;
@property (weak, nonatomic) IBOutlet UISegmentedControl *parcelShadingOption;
- (IBAction)displayTileInfo:(id)sender;
- (IBAction)parcelShadingOption:(id)sender;
- (IBAction)parcelShadingOption2:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *parcelShadingOption2;
- (IBAction)parcelBoundaryLines:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *parcelBoundaryLines;
@property (weak, nonatomic) IBOutlet UISegmentedControl *basemapSC;

@end