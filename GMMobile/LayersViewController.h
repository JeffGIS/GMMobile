//  LayersViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface LayersViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *parcelZoomLabel;
@property (weak, nonatomic) IBOutlet UILabel *sewerZoomLabel;
@property (weak, nonatomic) IBOutlet UIStepper *parcelZoomStepper;
@property (weak, nonatomic) IBOutlet UIStepper *sewerZoomStepper;
@property (weak, nonatomic) IBOutlet UISegmentedControl *parcelShadingOption;

@end