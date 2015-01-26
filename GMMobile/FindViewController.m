//  FindViewController.m
//  GMMobile

#import "FindViewController.h"

@interface FindViewController ()

@end

@implementation FindViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    self.navigationController.view.alpha = 1.0;
    self.navigationController.view.opaque = YES;
    
    [self setupButton:_pidButton];
    [self setupButton:_addressButton];
    [self setupButton:_taxpayerButton];
    [self setupButton:_intersectionButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupButton:(UIButton *)button
{
    button.layer.cornerRadius = 10.0;
    button.layer.borderColor = UserDefaults.defaults.green.CGColor;
    button.layer.borderWidth = 4.0;
}

- (IBAction)findPID:(id)sender
{
    
}

- (IBAction)findAddress:(id)sender
{
    
}

- (IBAction)findTaxpayer:(id)sender
{
    
}

- (IBAction)findIntersection:(id)sender
{
    
}

@end