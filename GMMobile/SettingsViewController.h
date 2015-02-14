//  SettingsViewController.h
//  GMMobile
#import <MessageUI/MessageUI.h>

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface SettingsViewController : UIViewController <FTPDataPullDelegate,GSSiPopoverViewDelegate,UIAlertViewDelegate,MFMailComposeViewControllerDelegate>

- (IBAction)loadDatabase:(id)sender;
- (IBAction)preloadTiles:(id)sender;
- (IBAction)loadParcels:(id)sender;
- (IBAction)deleteDatabase:(id)sender;
- (IBAction)showEmail:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *databaseSize;

@property (atomic) int nComplete;
@property (atomic) int nFailed;
@property NSCondition *condition;
@property (atomic) BOOL keepGoing;

@end