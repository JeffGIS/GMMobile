//  AppDelegate.m
//  GMMobile


#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import "CCodeLibrary/NVDateRange.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/SharedDefaults.h"
#import "CCodeLibrary/CRAPI.h"

@interface AppDelegate ()

@property UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic) NSTimer *locationTimer;
@property (nonatomic) GeoMasterServer *GMServer;
@property (nonatomic) CLLocation *currentLocation;
@property BOOL skipMethodCall;

@end

@implementation AppDelegate

+ (AppDelegate *)sharedAppDelegate
{
    return (AppDelegate *)UIApplication.sharedApplication.delegate;
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *defaultFTP = @"gssiserver3.com";
    
    [UserDefaults.defaults saveString:defaultFTP
                               forKey:@"CurrentFtp"];
    
    [UserDefaults.defaults saveString:defaultFTP
                               forKey:@"DefaultFtp"];
    
    UITextField *lagFreeField = [[UITextField alloc] init];
    [self.window addSubview:lagFreeField];
    [lagFreeField becomeFirstResponder];
    [lagFreeField resignFirstResponder];
    [lagFreeField removeFromSuperview];
    
    CRAPI.sharedInstance.currentModule = GMMOBILE_MODULE;
    CRAPI.sharedInstance.project = PROJECT_METROGIS;
    CRAPI.sharedInstance.showParcelBoundary = YES;
    CRAPI.sharedInstance.parcelShadingOption = 0;
    CRAPI.sharedInstance.currentPlatType = @"storm";
    [GMSServices provideAPIKey:@"AIzaSyBHsmI7nwgf4vt0jiCI11dzRs5dAlqQ3es"];
    
    CRAPI.sharedInstance.defaultColors = UserDefaults.defaults.defaultColors;
    CRAPI.sharedInstance.currentGeoid = 2743000;
    CRAPI.sharedInstance.resetPropList = NO;
    CRAPI.sharedInstance.resetDestinations = NO;
    
    NSInteger fromDate = 0, toDate = 0;
    
    [NVDateRange getLastYearFromDate:&fromDate
                              toDate:&toDate];
    
    CRAPI.sharedInstance.fromDate = fromDate;
    CRAPI.sharedInstance.toDate = toDate;
    
    UIUserNotificationType nTypes =
    UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *nSettings = [UIUserNotificationSettings settingsForTypes:nTypes
                                                                              categories:nil];
    
    [UIApplication.sharedApplication registerUserNotificationSettings:nSettings];
    [UIApplication.sharedApplication registerForRemoteNotifications];
    
    CRAPI.sharedInstance.showPolylineForBounds = ![UserDefaults.defaults boolForKey:@"ShowPolylineForBounds"];
    CRAPI.sharedInstance.maskBoundsForBounds = ![UserDefaults.defaults boolForKey:@"MaskBoundsForBounds"];
    CRAPI.sharedInstance.offsetForBounds = [UserDefaults.defaults stringForKey:@"OffsetForBounds"];
    CRAPI.sharedInstance.offsetForBoundsInMeters = (int)[UserDefaults.defaults integerForKey:@"OffsetForBoundsInMeters"];
    CRAPI.sharedInstance.mapPropList = ![UserDefaults.defaults boolForKey:@"MapPropList"];
    CRAPI.sharedInstance.mapIndividualDest = ![UserDefaults.defaults boolForKey:@"MapIndividualDest"];
    CRAPI.sharedInstance.mapGroupDest = ![UserDefaults.defaults boolForKey:@"MapGroupDest"];
    
    if (!CRAPI.sharedInstance.offsetForBounds)
        CRAPI.sharedInstance.offsetForBounds = @"0 feet";
    
    if (!CRAPI.sharedInstance.offsetForBoundsInMeters)
        CRAPI.sharedInstance.offsetForBoundsInMeters = 0;
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.activityType = CLActivityTypeAutomotiveNavigation;
    
    if ([_locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)])
        _locationManager.allowsBackgroundLocationUpdates = YES;
    
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [_locationManager requestAlwaysAuthorization];
    
    if ([UserDefaults.defaults boolForKey:@"TrackLocation"])
        [self scheduleLocationTracking];
    
    return YES;
}

- (void)scheduleLocationTracking
{
    _backgroundTaskIdentifier = [UIApplication.sharedApplication beginBackgroundTaskWithExpirationHandler:^{
        [UIApplication.sharedApplication endBackgroundTask:_backgroundTaskIdentifier];
    }];
    
    _locationTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                      target:self
                                                    selector:@selector(checkUserLocation:)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)stopLocationTracking
{
    [UIApplication.sharedApplication endBackgroundTask:_backgroundTaskIdentifier];
    [_locationTimer invalidate];
}

- (void)checkUserLocation:(NSTimer *)timer
{
    [_locationManager requestLocation];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    _currentLocation = (CLLocation *)locations.lastObject;
    
    if (!_skipMethodCall)
    {
        [self performSelector:@selector(sendLocationToServer)
                   withObject:nil
                   afterDelay:0.5];
        
        _skipMethodCall = YES;
    }
}

- (void)sendLocationToServer
{
    _GMServer = GeoMasterServer.open;
    _GMServer.delegate = self;
    [_GMServer initCommunication:5.0];
    _skipMethodCall = NO;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"locationManager ERROR:%@", error.localizedDescription);
}

- (void)GMServerDidOpen:(GeoMasterServer *)server
{
    NSString *msg = [NSString stringWithFormat:@"$MACRO([%%DL]macros\\GetUserLocations.txt,%@,%@,%i,%i,%i,%i,%i,%i)\r\n",
                     vendorUUIDString(), UIDevice.currentDevice.name, (int)round(_currentLocation.coordinate.latitude * 100000),
                     (int)round(_currentLocation.coordinate.longitude * 100000), (int)round(_currentLocation.timestamp.timeIntervalSince1970),
                     (int)round(_currentLocation.horizontalAccuracy), (int)round(_currentLocation.course), (int)round(_currentLocation.speed)];
    
    if (msg)
        [_GMServer sendMessage:msg];
    
    NSLog(@"GMServer Query: %@", msg);
}

- (void)GMServer:(GeoMasterServer *)server
didReceiveMessage:(NSString *)message
      withStatus:(long)status
{
    NSLog(@"Location update: %@", message);
    [_GMServer closeServer];
}

- (void)GMServer:(GeoMasterServer *)server
 didReceiveError:(NSString *)error
      withStatus:(long)status
{
    NSLog(@"Location update ERROR: %@", error);
    [_GMServer closeServer];
    
}

- (void)application:(UIApplication *)app
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    const char *data = devToken.bytes;
    NSMutableString *token = NSMutableString.string;
    
    for (int i = 0; i < devToken.length; i++)
        [token appendFormat:@"%02.2hhX", data[i]];
    
    NSString *deviceToken = token.copy;
    NSLog(@"Token for Push Notifications:%@", deviceToken);
    
    NSString *previousDeviceToken = [UserDefaults.defaults stringForKey:@"DeviceToken"];
    
    if (![deviceToken isEqualToString:previousDeviceToken])
    {
        //this is where we send the device token to our notification server(s)
        
        [UserDefaults.defaults saveString:deviceToken
                                   forKey:@"DeviceToken"];
    }
}

- (void)application:(UIApplication *)app
didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    NSLog(@"Remote Notification Registration ERROR:%@", err);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [UserDefaults.defaults saveBool:!CRAPI.sharedInstance.showPolylineForBounds
                             forKey:@"ShowPolylineForBounds"];
    
    [UserDefaults.defaults saveBool:!CRAPI.sharedInstance.maskBoundsForBounds
                             forKey:@"MaskBoundsForBounds"];
    
    [UserDefaults.defaults saveString:CRAPI.sharedInstance.offsetForBounds
                               forKey:@"OffsetForBounds"];
    
    [UserDefaults.defaults saveInteger:CRAPI.sharedInstance.offsetForBoundsInMeters
                                forKey:@"OffsetForBoundsInMeters"];
    
    NSLog(@"%d", CRAPI.sharedInstance.mapPropList);
    
    [UserDefaults.defaults saveBool:!CRAPI.sharedInstance.mapPropList
                             forKey:@"MapPropList"];
    
    [UserDefaults.defaults saveBool:!CRAPI.sharedInstance.mapIndividualDest
                             forKey:@"MapIndividualDest"];
    
    [UserDefaults.defaults saveBool:!CRAPI.sharedInstance.mapGroupDest
                             forKey:@"MapGroupDest"];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"didResignActive"
                                                      object:nil
                                                    userInfo:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSString *sourceApp = [SharedDefaults.defaults stringForKey:@"SourceApplication"];
    
    CRAPI.sharedInstance.setToAlleyWalls = NO;
    
    if ([sourceApp isEqualToString:@""])
        sourceApp = @"User";
    
    else if ([sourceApp isEqualToString:@"NVAlleyWalls"])
        CRAPI.sharedInstance.setToAlleyWalls = YES;
    
    CRAPI.sharedInstance.sourceApp = sourceApp;
    
    [SharedDefaults.defaults saveString:@""
                                 forKey:@"SourceApplication"];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"didBecomeActive"
                                                      object:nil
                                                    userInfo:nil];
    
    CRAPI.sharedInstance.becameActive = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

@end