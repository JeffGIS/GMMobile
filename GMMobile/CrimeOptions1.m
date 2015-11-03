//  CrimeOptions1.m
//  GMMobile

#import "CrimeOptions1.h"
#import "CCodeLibrary/UserDefaults.h"

@implementation CrimeOptions1

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.green;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end