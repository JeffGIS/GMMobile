//  FindViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface FindViewController : UIViewController
{
    
}

@property (weak, nonatomic) IBOutlet UIButton *pidButton;
@property (weak, nonatomic) IBOutlet UIButton *addressButton;
@property (weak, nonatomic) IBOutlet UIButton *taxpayerButton;
@property (weak, nonatomic) IBOutlet UIButton *intersectionButton;


- (IBAction)findPID:(id)sender;
- (IBAction)findAddress:(id)sender;
- (IBAction)findTaxpayer:(id)sender;
- (IBAction)findIntersection:(id)sender;

@end