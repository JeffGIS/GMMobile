//  LayersViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface LayersViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVColorWheelDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end