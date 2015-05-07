//  AppDelegate.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "MapToolbar.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
+ (AppDelegate *)sharedAppDelegate;
- (void)didStartNetworking;
- (void)didStopNetworking;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MapToolbar *mapToolbar;
@property NSInteger networkingCount;
@end