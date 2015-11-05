//  CrimeOptions2.m
//  GMMobile

#import "CrimeOptions2.h"
#import "CCodeLibrary/UserDefaults.h"

@implementation CrimeOptions2

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.brownColor;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end