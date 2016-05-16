//  SettingOptionsViewController.h
//  GMMobile

@import UIKit;
#import "CCodeLibrary/NVAlertView.h"
#import "CCodeLibrary/NVContactPicker.h"
#import "CCodeLibrary/FTPDataPush.h"
#import "CCodeLibrary/NVTextAlert.h"

@interface SettingOptionsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVTextAlertDelegate,NVAlertViewDelegate,FTPDataPushDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end