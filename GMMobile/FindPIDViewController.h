//  FindPIDViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"

@class FindPIDViewController;

@protocol FindPIDViewControllerDelegate <NSObject>

- (void)findPIDViewController:(FindPIDViewController *)findPID
                 didSelectPID:(NSString *)PID;

@end

@interface FindPIDViewController : UIViewController <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) id <FindPIDViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *pidEntry;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
