//
//  HuntingSettingsViewController.h
//  NVMobile
//
//  Created by Jeff Smith on 9/23/25.
//  Copyright © 2025 GSSi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCodeLibrary/CRAPI.h"

NS_ASSUME_NONNULL_BEGIN

@interface HuntingSettingsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISwitch *autoVehicleLocationSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *autoTrackingSwitch;
- (IBAction)autoVehicleLocationChanged:(id)sender;
- (IBAction)autoTrackingChanged:(id)sender;

@end

NS_ASSUME_NONNULL_END
