//  SettingsViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface SettingsViewController : UIViewController <FTPDataPullDelegate,GSSiPopoverViewDelegate>

- (IBAction)loadDatabase:(id)sender;
- (IBAction)preloadTiles:(id)sender;
- (IBAction)loadParcels:(id)sender;

@property (atomic)  int nComplete;
@property (atomic)  int nFailed;
@property NSCondition *condition;
@property (atomic) BOOL keepGoing;

@end