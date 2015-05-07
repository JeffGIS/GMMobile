//  SettingOptionsViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "CCodeLibrary/NVTextAlert.h"
#import "CCodeLibrary/NVLargeAlertView.h"
#import "UploadViewController.h"

@interface SettingOptionsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVTextAlertDelegate,NVLargeAlertViewDelegate,UploadViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end