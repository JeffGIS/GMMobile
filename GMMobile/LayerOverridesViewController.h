//
//  LayerOverridesViewController.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/23/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <UIKit/UIKit.h>

//switches
@interface LayerOverridesViewController : UIViewController
- (IBAction)AOnColorSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *AOnColorSwitch;
- (IBAction)AOnTransSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *AOnTransSwitch;
- (IBAction)AOnWidthSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *AOnFontSwitch;
- (IBAction)AOnFontSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *AOnWidthSwitch;
- (IBAction)AOnShadowSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *AOnShadowSwitch;

- (IBAction)AOffColorSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *AOffColorSwitch;
- (IBAction)AOffTransSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *AOffTransSwitch;
- (IBAction)AOffWidthSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *AOffWidthSwitch;
- (IBAction)AOffFontSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *AOffFontSwitch;
- (IBAction)AOffShadowSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *AOffShadowSwitch;


//buttons
- (IBAction)AOffColor:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AOffColor;
- (IBAction)AOffTrans:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AOffTrans;
- (IBAction)AOffWidth:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AOffWidth;
- (IBAction)AOffFont:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AOffFont;
- (IBAction)AOffShadow:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AOffShadow;
- (IBAction)AOnColor:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AOnColor;
- (IBAction)AOnTrans:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AOnTrans;
- (IBAction)AOnWidth:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AOnWidth;
- (IBAction)AOnFont:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AOnFont;
- (IBAction)AOnShadow:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AOnShadow;
- (IBAction)returnButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;
@end
