//  CrimeOptions1.h
//  GMMobile

#import <UIKit/UIKit.h>

@interface CrimeOptions1 : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *deptView;

@end