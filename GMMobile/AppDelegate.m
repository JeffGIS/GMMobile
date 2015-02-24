//  AppDelegate.m
//  GMMobile

int keepProcessing=1;

#import "AppDelegate.h"

@interface AppDelegate ()

@property CLLocationManager *locationManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *defaultFTP = @"gssidata.com";
    
    [UserDefaults.defaults saveString:defaultFTP
                               forKey:@"CurrentFtp"];
    
    [UserDefaults.defaults saveString:defaultFTP
                               forKey:@"DefaultFtp"];
    
    _locationManager = [[CLLocationManager alloc] init];
    
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [_locationManager requestWhenInUseAuthorization];
    
    UITextField *lagFreeField = [[UITextField alloc] init];
    [self.window addSubview:lagFreeField];
    [lagFreeField becomeFirstResponder];
    [lagFreeField resignFirstResponder];
    [lagFreeField removeFromSuperview];
    
    CRAPI.sharedInstance.project = PROJECT_METROGIS;
    CRAPI.sharedInstance.GMTilesVisible = YES;
    CRAPI.sharedInstance.showParcelBoundary = YES;
    CRAPI.sharedInstance.parcelsVisibleAtZoom = 16;
    CRAPI.sharedInstance.sewerVisibleAtZoom = 17;
    CRAPI.sharedInstance.parcelShadingOption = 0;
    //CRAPI.sharedInstance.basemap = BasemapSettingApple;

    return YES;
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

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

@end