//  AppDelegate.m
//  GMMobile

int keepProcessing = 1;

#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import "CCodeLibrary/NVDateRange.h"

@implementation AppDelegate

+ (AppDelegate *)sharedAppDelegate
{
    return (AppDelegate *)UIApplication.sharedApplication.delegate;
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *defaultFTP = @"gssidata.com";
    
    [UserDefaults.defaults saveString:defaultFTP
                               forKey:@"CurrentFtp"];
    
    [UserDefaults.defaults saveString:defaultFTP
                               forKey:@"DefaultFtp"];
    
    UITextField *lagFreeField = [[UITextField alloc] init];
    [self.window addSubview:lagFreeField];
    [lagFreeField becomeFirstResponder];
    [lagFreeField resignFirstResponder];
    [lagFreeField removeFromSuperview];
    
    CRAPI.sharedInstance.project = PROJECT_METROGIS;
    CRAPI.sharedInstance.showParcelBoundary = YES;
    CRAPI.sharedInstance.parcelShadingOption = 0;
    [GMSServices provideAPIKey:@"AIzaSyBHsmI7nwgf4vt0jiCI11dzRs5dAlqQ3es"];
    
    CRAPI.sharedInstance.currentPlatType = @"storm";
    
    CRAPI.sharedInstance.currentPlatImagePath = [NSBundle.mainBundle pathForResource:@"SD-30A-10"
                                                                              ofType:@"jpg"];
    
    [UserDefaults.defaults disableWebKitDiskImageCache];
    CRAPI.sharedInstance.defaultColors = UserDefaults.defaults.defaultColors;
    CRAPI.sharedInstance.currentGeoid = 2743000;
    CRAPI.sharedInstance.resetPropList = NO;
    CRAPI.sharedInstance.resetDestinations = NO;
    CRAPI.sharedInstance.clearSpreadsheet = NO;
    
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
    
    return YES;
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
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
}

- (void)didStartNetworking
{
    self.networkingCount += 1;
    UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
}

- (void)didStopNetworking
{
    self.networkingCount -= 1;
    UIApplication.sharedApplication.networkActivityIndicatorVisible = (self.networkingCount != 0);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSString *sourceApp = [SharedDefaults.defaults stringForKey:@"SourceApplication"];
    
    CRAPI.sharedInstance.setToAlleyWalls = NO;
    
    if ([sourceApp isEqualToString:@""])
        sourceApp = @"User";
    
    else if ([sourceApp isEqualToString:@"AlleyWallInventory"])
        CRAPI.sharedInstance.setToAlleyWalls = YES;
    
    CRAPI.sharedInstance.sourceApp = sourceApp;
    
    [SharedDefaults.defaults saveString:@""
                                 forKey:@"SourceApplication"];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"didBecomeActive"
                                                      object:nil
                                                    userInfo:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

@end