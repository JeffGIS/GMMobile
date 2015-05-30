//  SettingsViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import <MessageUI/MessageUI.h>

#define GET_PROPERTY 1
#define GET_TILES 2
#define GET_PARCELS 3
#define GET_AREAS 4
#define GET_SEWER 5
#define GET_PLAN 6
#define GET_CENSUS 7
#define GET_ALLEYWALL 8

@class SettingsViewController;

@protocol SettingsViewControllerDelegate <NSObject>

- (void) SettingsViewControllerSuccess;
- (void) SettingsViewControllerFailed:(int)status;

@end


@interface SettingsViewController : UIViewController <FTPDataPullDelegate,GSSiPopoverViewDelegate,GSSiAlertDelegate,MFMailComposeViewControllerDelegate,GSSiBumpDetectorDelegate,NVHeadingViewControllerDelegate,NVVideoHeadingViewControllerDelegate>
@property (nonatomic, weak) id <SettingsViewControllerDelegate> delegate;
@property (nonatomic) GSSiPopoverView *popover;
@property id saveDelegate;
@property BOOL fromDataLoader;

- (void) initFromDataLoader:(GSSiPopoverView*)popover
                forDatabase:(int)db;

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

@property (weak, nonatomic) IBOutlet UILabel *databaseSize;

@property int nComplete, nFailed;
@property NSCondition *condition;
@property BOOL keepGoing;
@property (nonatomic) NSTimer *timer;

@end