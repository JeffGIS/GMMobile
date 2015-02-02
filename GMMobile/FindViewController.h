//  FindViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import "FindPIDViewController.h"
#import "FindAddressViewController.h"

@interface FindViewController : UIViewController <FindPIDViewControllerDelegate,FindAddressViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *pidButton;
@property (weak, nonatomic) IBOutlet UIButton *addressButton;
@property (weak, nonatomic) IBOutlet UIButton *taxpayerButton;
@property (weak, nonatomic) IBOutlet UIButton *intersectionButton;
@property (nonatomic) FindPIDViewController *findPID;

@end