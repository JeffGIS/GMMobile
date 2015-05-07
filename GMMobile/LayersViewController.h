//  LayersViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"

@interface LayersViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end