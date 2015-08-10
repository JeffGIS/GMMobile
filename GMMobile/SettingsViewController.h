//  SettingsViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import <MessageUI/MessageUI.h>
#import "ConfigurationControl.h"
#import "CCodeLibrary/NVAlertView.h"

#define DLSTATUS_USER_CANCELLED 1
#define DLSTATUS_FTP_FAILED 2

@class SettingsViewController;

@protocol SettingsViewControllerDelegate <NSObject>

- (void) SettingsViewControllerSuccess;
- (void) SettingsViewControllerFailed:(int)status;

@end


@interface SettingsViewController : UIViewController <FTPDataPullDelegate,GSSiPopoverViewDelegate,NVAlertViewDelegate,MFMailComposeViewControllerDelegate,GSSiBumpDetectorDelegate,NVHeadingViewControllerDelegate,NVVideoHeadingViewControllerDelegate>
@property (nonatomic, weak) id <SettingsViewControllerDelegate> delegate;
@property (nonatomic) GSSiPopoverView *popover;
@property id saveDelegate;
@property BOOL fromDataLoader;

- (void) initFromDataLoader:(GSSiPopoverView*)popover;

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
- (IBAction)loadAlleyWall:(id)sender;
- (IBAction)loadCurbRamps:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *databaseSize;

@property int nComplete, nFailed;
@property NSCondition *condition;
@property BOOL keepGoing;
@property (nonatomic) NSTimer *timer;

@end