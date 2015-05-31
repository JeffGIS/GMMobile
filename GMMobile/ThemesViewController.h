//  ThemesViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "NVDataLoader.h"

@interface ThemesViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVDataLoaderDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property GSSiPopoverView* popover;
@property int selectedApp;
@property NSIndexPath * selectedIndexPath;
@end