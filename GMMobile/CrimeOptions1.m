//  CrimeOptions1.m
//  GMMobile

#import "CrimeOptions1.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ConfigurationControl.h"

@implementation CrimeOptions1

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog ([NSString stringWithFormat:@"%i legends available",(int)ConfigurationControl.sharedInstance.legendList.count]);
    self.view.backgroundColor = UserDefaults.defaults.green;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end