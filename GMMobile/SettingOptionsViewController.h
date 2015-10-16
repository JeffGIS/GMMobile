//  SettingOptionsViewController.h
//  GMMobile

@import UIKit;
#import "UploadViewController.h"
#import "CCodeLibrary/NVAlertView.h"
@import StoreKit;
@import Contacts;
@import ContactsUI;

@interface SettingOptionsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVTextAlertDelegate,NVAlertViewDelegate,UploadViewControllerDelegate,SKStoreProductViewControllerDelegate,UINavigationControllerDelegate,CNContactPickerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end