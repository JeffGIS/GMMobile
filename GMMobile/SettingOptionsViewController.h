//  SettingOptionsViewController.h
//  GMMobile

@import UIKit;
#import "UploadViewController.h"
#import "CCodeLibrary/NVAlertView.h"
@import StoreKit;
#import "CCodeLibrary/NVContactPicker.h"
#import "CCodeLibrary/FTPDataPush.h"

@interface SettingOptionsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVTextAlertDelegate,NVAlertViewDelegate,UploadViewControllerDelegate,SKProductsRequestDelegate,SKPaymentTransactionObserver,FTPDataPushDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end