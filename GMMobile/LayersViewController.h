//  LayersViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface LayersViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *parcelZoomLabel;
@property (weak, nonatomic) IBOutlet UILabel *sewerZoomLabel;
@property (weak, nonatomic) IBOutlet UIStepper *parcelZoomStepper;
@property (weak, nonatomic) IBOutlet UIStepper *sewerZoomStepper;
@property (weak, nonatomic) IBOutlet UISegmentedControl *parcelShadingOption;
@property (weak, nonatomic) IBOutlet UISegmentedControl *parcelShadingOption2;
@property (weak, nonatomic) IBOutlet UISegmentedControl *parcelTextOption;
@property (weak, nonatomic) IBOutlet UISegmentedControl *parcelTextOption2;
@property (weak, nonatomic) IBOutlet UISegmentedControl *parcelBoundaryLines;

- (IBAction)displayTileInfo:(id)sender;
- (IBAction)parcelShadingOption:(id)sender;
- (IBAction)parcelShadingOption2:(id)sender;
- (IBAction)parcelTextOption:(id)sender;
- (IBAction)parcelTextOption2:(id)sender;
- (IBAction)parcelBoundaryLines:(id)sender;

@end