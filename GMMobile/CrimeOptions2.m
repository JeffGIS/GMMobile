//  CrimeOptions2.m
//  GMMobile

#import "CrimeOptions2.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ConfigurationControl.h"

@implementation CrimeOptions2

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *legends = ConfigurationControl.sharedInstance.legendList.copy;
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end