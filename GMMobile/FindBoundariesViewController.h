//  FindBoundariesViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@class FindBoundariesViewController;

@protocol FindBoundsViewControllerDelegate <NSObject>

//delegate method goes here

@end

@interface FindBoundariesViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) id <FindBoundsViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *topTableView;
@property (weak, nonatomic) IBOutlet UITableView *bottomTableView;

@end