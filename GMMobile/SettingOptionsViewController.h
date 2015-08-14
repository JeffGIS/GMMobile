//  SettingOptionsViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "UploadViewController.h"
#import "CCodeLibrary/NVAlertView.h"

@interface SettingOptionsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVTextAlertDelegate,NVAlertViewDelegate,UploadViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end