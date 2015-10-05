//  DestinationsViewController.h
//  GMMobile

#import <UIKit/UIKit.h>

@interface DestinationsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end