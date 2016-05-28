//  AppDelegate.h
//  GMMobile

@import CoreLocation;
#import "CCodeLibrary/GeoMasterServer.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate,GeoMasterServerDelegate>

+ (AppDelegate *)sharedAppDelegate;
- (void)didStartNetworking;
- (void)didStopNetworking;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) CLLocationManager *locationManager;

- (void)scheduleLocationTracking;
- (void)stopLocationTracking;

@end