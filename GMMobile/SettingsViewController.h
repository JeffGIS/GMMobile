//  SettingsViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import <MessageUI/MessageUI.h>
#import "ConfigurationControl.h"
#import "CCodeLibrary/NVAlertView.h"
#import "CCodeLibrary/CompressDecompress.h"

#define DLSTATUS_USER_CANCELLED 1
#define DLSTATUS_FTP_FAILED 2

@class SettingsViewController;

@protocol SettingsViewControllerDelegate <NSObject>

- (void) SettingsViewControllerSuccess;
- (void) SettingsViewControllerFailed:(int)status;

@end


@interface SettingsViewController : UIViewController <FTPDataPullDelegate,FTPDataPushDelegate,FTPDirectoryCreateDelegate,GSSiPopoverViewDelegate,NVAlertViewDelegate,GSSiBumpDetectorDelegate,NVHeadingViewControllerDelegate,NVVideoHeadingViewControllerDelegate,MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) id <SettingsViewControllerDelegate> delegate;
@property (nonatomic) GSSiPopoverView *popover;
@property id saveDelegate;
@property BOOL fromDataLoader;
@property FTPDirectoryCreate * ftpdc;
- (void) initFromDataLoader:(GSSiPopoverView*)popover;

@property int nComplete, nFailed;
@property NSCondition *condition;
@property BOOL keepGoing;
@property (nonatomic) NSTimer *timer;

- (IBAction)uploadDatabases:(id)sender;
- (IBAction)outputFile:(id)sender;
- (IBAction)loadAreas:(id)sender;
- (IBAction)loadCrimeData:(id)sender;
- (IBAction)loadMapleGrove:(id)sender;
- (IBAction)loadPlan:(id)sender;
- (IBAction)loadAlleyWall:(id)sender;
- (IBAction)loadCurbRamps:(id)sender;
- (IBAction)loadSewer:(id)sender;
- (IBAction)loadCensus:(id)sender;
- (IBAction)loadParcels:(id)sender;
- (IBAction)loadDatabase:(id)sender;
- (IBAction)uploadDirectory:(id)sender;
- (IBAction)loadNVMetro:(id)sender;
@end