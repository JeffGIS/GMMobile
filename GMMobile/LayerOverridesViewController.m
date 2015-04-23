//
//  LayerOverridesViewController.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/23/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "LayerOverridesViewController.h"

@interface LayerOverridesViewController ()

@end

@implementation LayerOverridesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)AOnColorSwitch:(id)sender {
}
- (IBAction)AOnTransSwitch:(id)sender {
}
- (IBAction)AOnWidthSwitch:(id)sender {
}
- (IBAction)AOnFontSwitch:(id)sender {
}
- (IBAction)AOnShadowSwitch:(id)sender {
}
- (IBAction)AOffColorSwitch:(id)sender {
}
- (IBAction)AOffTransSwitch:(id)sender {
}
- (IBAction)AOffWidthSwitch:(id)sender {
}
- (IBAction)AOffFontSwitch:(id)sender {
}
- (IBAction)AOffShadowSwitch:(id)sender{
}

- (IBAction)AOnColor:(UIButton*)sender {
/*    NVColorWheel *colorWheel = [NVColorWheel showColorWheelWithView:sender.backgroundColor
                                                           delegate:self
                                                             tabBar:self.tabBarController.tabBar
                                                                tag:cellButton.tag];*/
#pragma unused(colorWheel)
}
- (IBAction)AOnTrans:(id)sender {
}
- (IBAction)AOnWidth:(id)sender {
}
- (IBAction)AOnFont:(id)sender {
}
- (IBAction)AOnShadow:(id)sender {
}
- (IBAction)AOffColor:(id)sender {
}
- (IBAction)AOffTrans:(id)sender {
}
- (IBAction)AOffWidth:(id)sender {
}
- (IBAction)AOffFont:(id)sender {
}
- (IBAction)AOffShadow:(id)sender {
}
- (IBAction)returnButton:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}
@end
