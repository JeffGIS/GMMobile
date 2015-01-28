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

- (void)prepareForSegue:(UIStoryboardSegue *)segue
sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showFindPID"])
    {
        FindPIDViewController *findPID = segue.destinationViewController;
        findPID.delegate = self;
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

@end