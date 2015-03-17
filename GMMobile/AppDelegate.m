//  AppDelegate.m
//  GMMobile

int keepProcessing=1;

#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>

@implementation AppDelegate

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
    CRAPI.sharedInstance.GMTilesVisible = NO;
    CRAPI.sharedInstance.showParcelBoundary = YES;
    CRAPI.sharedInstance.parcelsVisibleAtZoom = 16;
    CRAPI.sharedInstance.sewerVisibleAtZoom = 17;
    CRAPI.sharedInstance.parcelShadingOption = 0;
    [GMSServices provideAPIKey:@"AIzaSyBHsmI7nwgf4vt0jiCI11dzRs5dAlqQ3es"];
    
    CRAPI.sharedInstance.currentPlatType = @"STORM";
    
    CRAPI.sharedInstance.currentPlatImagePath = [NSBundle.mainBundle pathForResource:@"SD-30A-10"
                                                                              ofType:@"jpg"];
    
    CRAPI.sharedInstance.currentPlatType = @"SAN";
    
    CRAPI.sharedInstance.currentPlatImagePath = [NSBundle.mainBundle pathForResource:@"S-2A-10"
                                                                              ofType:@"jpg"];
    
    CRAPI.sharedInstance.currentPlatImagePath = [NSBundle.mainBundle pathForResource:@"S-N-54"
                                                                              ofType:@"jpg"];
    
    CRAPI.sharedInstance.currentPlatImagePath = [NSBundle.mainBundle pathForResource:@"S-55S-2"
                                                                              ofType:@"jpg"];

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