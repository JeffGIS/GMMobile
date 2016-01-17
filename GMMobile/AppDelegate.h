//  AppDelegate.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
@import CoreLocation;

@interface AppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate>

+ (AppDelegate *)sharedAppDelegate;
- (void)didStartNetworking;
- (void)didStopNetworking;

@property (strong, nonatomic) UIWindow *window;
@property NSInteger networkingCount;
@property (nonatomic) CLLocationManager *locationManager;

@end