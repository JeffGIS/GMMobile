//  SettingsViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface SettingsViewController : UIViewController <FTPDataPullDelegate,GSSiPopoverViewDelegate>

- (IBAction)loadDatabase:(id)sender;
- (IBAction)preloadTiles:(id)sender;

@end