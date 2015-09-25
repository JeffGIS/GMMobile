//  SpreadsheetViewController.m
//  GMMobile

#import "SpreadsheetViewController.h"
#import "CCodeLibrary/SpreadsheetView.h"

@interface SpreadsheetViewController ()

@property (nonatomic) SpreadsheetView *spreadsheetView;

@end

@implementation SpreadsheetViewController

- (void)viewDidLoad
{
    CGFloat statusBarHeight = [self statusBarHeight:self.interfaceOrientation];
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    
    CGRect ssFrame = CGRectMake(0.0, statusBarHeight, self.view.frame.size.width,
                                self.view.frame.size.height - statusBarHeight - tabBarHeight);
    
    _spreadsheetView = [SpreadsheetView spreadsheetViewWithRows:40
                                                        columns:12
                                                           view:self.view
                                                          frame:ssFrame
                                                   returnHidden:YES];
    
    [self.view addSubview:_spreadsheetView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (CGFloat)statusBarHeight:(UIInterfaceOrientation)orientation
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if (orientation == UIDeviceOrientationLandscapeLeft ||
            orientation == UIDeviceOrientationLandscapeRight)
        {
            return 0.0;
        }
    }
    
    return 20.0;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
duration:(NSTimeInterval)duration
{
    if (_spreadsheetView)
    {
        [_spreadsheetView willRotateWithDuration:duration
                                    tabBarHeight:self.tabBarController.tabBar.frame.size.height];
    }
}

@end