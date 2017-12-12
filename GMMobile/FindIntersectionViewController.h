//  FindIntersectionViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"

@class FindIntersectionViewController;

@protocol FindIntersectionViewControllerDelegate <NSObject>

- (void)findIntersectionViewController:(FindIntersectionViewController *)findIntersection
                 didSelectIntersection:(NSString *)intersection;

@end

@interface FindIntersectionViewController : UIViewController <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) id <FindIntersectionViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *street1Label;
@property (weak, nonatomic) IBOutlet UILabel *street2Label;
@property (weak, nonatomic) IBOutlet UITextField *street1TF;
@property (weak, nonatomic) IBOutlet UITextField *street2TF;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
