//  FindAddressViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"

@class FindAddressViewController;

@protocol FindAddressViewControllerDelegate <NSObject>

- (void)findAddressViewController:(FindAddressViewController *)findAddress
                 didSelectAddress:(NSString *)address
                              PID:(NSString *)PID;

@end

@interface FindAddressViewController : UIViewController <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) id <FindAddressViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *houseLabel;
@property (weak, nonatomic) IBOutlet UILabel *streetLabel;
@property (weak, nonatomic) IBOutlet UITextField *houseTF;
@property (weak, nonatomic) IBOutlet UITextField *streetTF;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end