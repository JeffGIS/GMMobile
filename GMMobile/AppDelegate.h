//  AppDelegate.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

+ (AppDelegate *)sharedAppDelegate;
- (void)didStartNetworking;
- (void)didStopNetworking;

@property (strong, nonatomic) UIWindow *window;
@property NSInteger networkingCount;

@end