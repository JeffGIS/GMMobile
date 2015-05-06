//  SettingOptionsViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "CCodeLibrary/NVTextAlert.h"
#import "CCodeLibrary/NVLargeAlertView.h"

@interface SettingOptionsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVTextAlertDelegate,NVLargeAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end