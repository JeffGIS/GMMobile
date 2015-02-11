//  FindPropertyOwnerViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@class FindPropertyOwnerViewController;

@protocol FindPropOwnerViewControllerDelegate <NSObject>

- (void)findPropOwnerViewController:(FindPropertyOwnerViewController *)findPropOwner
                 didSelectPropOwner:(NSString *)propOwner
                                PID:(NSString *)PID;

@end

@interface FindPropertyOwnerViewController : UIViewController <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) id <FindPropOwnerViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITextField *propOwnerTF;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end