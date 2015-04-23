//  AppDelegate.m
//  GMMobile

int keepProcessing = 1;

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
    CRAPI.sharedInstance.showParcelBoundary = YES;
    CRAPI.sharedInstance.parcelShadingOption = 0;
    [GMSServices provideAPIKey:@"AIzaSyBHsmI7nwgf4vt0jiCI11dzRs5dAlqQ3es"];
    
    CRAPI.sharedInstance.currentPlatType = @"storm";
    
    CRAPI.sharedInstance.currentPlatImagePath = [NSBundle.mainBundle pathForResource:@"SD-30A-10"
                                                                              ofType:@"jpg"];
    
    [UserDefaults.defaults disableWebKitDiskImageCache];
    
    NSLog(@"Shared File Path: %@", CRAPI.sharedInstance.sharedFilePath);

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
    NSString *sourceApp = [SharedDefaults.defaults stringForKey:@"SourceApplication"];
    
    if ([sourceApp isEqualToString:@""])
        sourceApp = @"User";
    
    NSLog(@"GMMobile opened by %@", sourceApp);
    
    [SharedDefaults.defaults saveString:@""
                                 forKey:@"SourceApplication"];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

@end