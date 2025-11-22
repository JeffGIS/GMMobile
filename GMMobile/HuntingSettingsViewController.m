//
//  HuntingSettingsViewController.m
//  NVMobile
//
//  Created by Jeff Smith on 9/23/25.
//  Copyright © 2025 GSSi. All rights reserved.
//

#import "HuntingSettingsViewController.h"

@interface HuntingSettingsViewController ()

@end

@implementation HuntingSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CGRect frame = _autoVehicleLocationSwitch.frame;
    frame = _autoTrackingSwitch.frame;
    [_displayMotionSwitch setOn:CRAPI.sharedInstance.displayMotion];
    return;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)autoTrackingChanged:(id)sender {
    UISwitch *autoTrackingSwitch = sender;
    TrackLocationManager *locationManager = [CRAPI.sharedInstance getLocationManager];
    if (autoTrackingSwitch.on)
    {
        [locationManager startMotionActivityMonitoring];
    }
    else
    {
        [locationManager pauseMotionActivityMonitoring];
    }
}

- (IBAction)autoVehicleLocationChanged:(id)sender {
    UISwitch *autoVehicleLocationSwitch = sender;
    TrackLocationManager *locationManager = [CRAPI.sharedInstance getLocationManager];
    if (autoVehicleLocationSwitch.on)
    {
        [locationManager startMotionActivityMonitoring];
    }
    else
    {
        [locationManager pauseMotionActivityMonitoring];
    }
}
- (IBAction)displayMotionChanged:(id)sender {
    UISwitch *displayMotionSwitch = sender;
    CRAPI.sharedInstance.displayMotion = displayMotionSwitch.on;
}

@end
