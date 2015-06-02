//  SettingOptionsViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "UploadViewController.h"

@interface SettingOptionsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVTextAlertDelegate,NVLargeAlertViewDelegate,UploadViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end