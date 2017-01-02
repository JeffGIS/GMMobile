//  FindViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "FindPIDViewController.h"
#import "FindAddressViewController.h"
#import "FindIntersectionViewController.h"
#import "FindPropertyOwnerViewController.h"
#import "FindBoundariesViewController.h"

@interface FindViewController : UIViewController <FindPIDViewControllerDelegate,FindAddressViewControllerDelegate,FindIntersectionViewControllerDelegate,FindPropOwnerViewControllerDelegate,FindBoundsViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *pidButton;
@property (weak, nonatomic) IBOutlet UIButton *addressButton;
@property (weak, nonatomic) IBOutlet UIButton *taxpayerButton;
@property (weak, nonatomic) IBOutlet UIButton *intersectionButton;
@property (weak, nonatomic) IBOutlet UIButton *boundariesButton;
@property (nonatomic) FindPIDViewController *findPID;

@end
