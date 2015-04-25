//  SettingsViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import <MessageUI/MessageUI.h>

@interface SettingsViewController : UIViewController <FTPDataPullDelegate,GSSiPopoverViewDelegate,GSSiAlertDelegate,MFMailComposeViewControllerDelegate,GSSiBumpDetectorDelegate,NVHeadingViewControllerDelegate,NVVideoHeadingViewControllerDelegate>

- (IBAction)loadDatabase:(id)sender;
- (IBAction)preloadTiles:(id)sender;
- (IBAction)loadParcels:(id)sender;
- (IBAction)deleteDatabase:(id)sender;
- (IBAction)showEmail:(id)sender;
- (IBAction)loadAreas:(id)sender;
- (IBAction)loadSewer:(id)sender;
- (IBAction)loadPlats:(id)sender;
- (IBAction)loadPlan:(id)sender;
- (IBAction)loadCensus:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *databaseSize;

@property (atomic) int nComplete;
@property (atomic) int nFailed;
@property NSCondition *condition;
@property (atomic) BOOL keepGoing;
@property (nonatomic) NSTimer *timer;


@end