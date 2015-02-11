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
    [self setupButton:_pidButton];
    [self setupButton:_addressButton];
    [self setupButton:_taxpayerButton];
    [self setupButton:_intersectionButton];
    [self setupButton:_boundariesButton];
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
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowFindPID"])
    {
        FindPIDViewController *findPID = segue.destinationViewController;
        findPID.delegate = self;
    }
    
    else if ([segue.identifier isEqualToString:@"ShowFindAddress"])
    {
        FindAddressViewController *findAddress = segue.destinationViewController;
        findAddress.delegate = self;
    }
    
    else if ([segue.identifier isEqualToString:@"ShowFindPropertyOwner"])
    {
        FindAddressViewController *findPropOwner = segue.destinationViewController;
        findPropOwner.delegate = self;
    }
    
    else if ([segue.identifier isEqualToString:@"ShowFindIntersection"])
    {
        FindAddressViewController *findInt = segue.destinationViewController;
        findInt.delegate = self;
    }
    
    else if ([segue.identifier isEqualToString:@"ShowFindBoundaries"])
    {
        FindBoundariesViewController *findBounds = segue.destinationViewController;
        findBounds.delegate = self;
    }
}

- (void)findPIDViewController:(FindPIDViewController *)findPID
                 didSelectPID:(NSString *)PID
{
    [findPID dismissViewControllerAnimated:YES
                                completion:nil];
    
    CRAPI.sharedInstance.GMMSetting = GMMSettingPID;
    CRAPI.sharedInstance.currentPID = PID;
    self.tabBarController.selectedIndex = 0;
}

- (void)findAddressViewController:(FindAddressViewController *)findAddress
                 didSelectAddress:(NSString *)address
                              PID:(NSString *)PID
{
    [findAddress dismissViewControllerAnimated:YES
                                    completion:nil];
    
    CRAPI.sharedInstance.GMMSetting = GMMSettingAddress;
    CRAPI.sharedInstance.currentPID = PID;
    CRAPI.sharedInstance.currentAddress = address;
    self.tabBarController.selectedIndex = 0;
}

- (void)findIntersectionViewController:(FindIntersectionViewController *)findIntersection
                 didSelectIntersection:(NSString *)intersection
{
    [findIntersection dismissViewControllerAnimated:YES
                                         completion:nil];
}

- (void)findPropOwnerViewController:(FindPropertyOwnerViewController *)findPropOwner
                 didSelectPropOwner:(NSString *)propOwner
                                PID:(NSString *)PID
{
    [findPropOwner dismissViewControllerAnimated:YES
                                      completion:nil];
    
    CRAPI.sharedInstance.GMMSetting = GMMSettingPropOwner;
    CRAPI.sharedInstance.currentPID = PID;
    CRAPI.sharedInstance.currentPropOwner = propOwner;
    self.tabBarController.selectedIndex = 0;
}

@end