//  LayerOverridesViewController.m
//  GMMobile

#import "LayerOverridesViewController.h"

@interface LayerOverridesViewController ()

@end

@implementation LayerOverridesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (UIButton *button in self.view.subviews)
    {
        if ([button isKindOfClass:UIButton.class] &&
            button != _returnButton && button != _cascadeButton)
        {
            [self setupButton:button];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupButton:(UIButton *)button
{
    button.layer.borderColor = UIColor.darkGrayColor.CGColor;
    button.layer.borderWidth = 1.0;
    
    [button setTitleColor:UserDefaults.defaults.appleBlue
                 forState:UIControlStateHighlighted];
    
    if (button == _AOffColor || button == _AOnColor)
    {
        button.titleLabel.layer.shadowColor = UIColor.blackColor.CGColor;
        button.titleLabel.layer.shadowOpacity = 1.0;
        button.titleLabel.layer.shadowRadius = 6.0;
        button.titleLabel.layer.shadowOffset = CGSizeZero;
        
        [button setTitleColor:UIColor.whiteColor
                     forState:UIControlStateNormal];
    }
}

- (IBAction)AOnColorSwitch:(id)sender
{
    
}

- (IBAction)AOnTransSwitch:(id)sender
{
    
}
- (IBAction)AOnWidthSwitch:(id)sender
{
    
}

- (IBAction)AOnFontSwitch:(id)sender
{
    
}

- (IBAction)AOnShadowSwitch:(id)sender
{
    
}

- (IBAction)AOffColorSwitch:(id)sender
{
    
}

- (IBAction)AOffTransSwitch:(id)sender
{
    
}

- (IBAction)AOffWidthSwitch:(id)sender
{
    
}

- (IBAction)AOffFontSwitch:(id)sender
{
    
}

- (IBAction)AOffShadowSwitch:(id)sender
{
    
}

- (IBAction)AOnColor:(UIButton *)sender
{
    NVColorWheel *colorWheel = [NVColorWheel showColorWheelWithView:self.view
                                                         startColor:sender.backgroundColor
                                                           delegate:self
                                                             tabBar:self.tabBarController.tabBar
                                                                tag:[self indexOfButton:sender]];
#pragma unused(colorWheel)
}

- (IBAction)AOnTrans:(id)sender
{
    
}

- (IBAction)AOnWidth:(id)sender
{
    
}

- (IBAction)AOnFont:(id)sender
{
    
}

- (IBAction)AOnShadow:(id)sender
{
    
}

- (IBAction)AOffColor:(UIButton *)sender
{
    NVColorWheel *colorWheel = [NVColorWheel showColorWheelWithView:self.view
                                                         startColor:sender.backgroundColor
                                                           delegate:self
                                                             tabBar:self.tabBarController.tabBar
                                                                tag:[self indexOfButton:sender]];
#pragma unused(colorWheel)
}

- (IBAction)AOffTrans:(id)sender
{
    
}

- (IBAction)AOffWidth:(id)sender
{
    
}

- (IBAction)AOffFont:(id)sender
{
    
}

- (IBAction)AOffShadow:(id)sender
{
    
}

- (IBAction)returnButton:(id)sender
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    for (NVColorWheel *colorWheel in self.view.subviews)
    {
        if ([colorWheel isKindOfClass:NVColorWheel.class])
        {
            [colorWheel willRotateWithDuration:duration
                        toInterfaceOrientation:toInterfaceOrientation];
        }
    }
}

- (NSInteger)indexOfButton:(UIButton *)subview
{
    return [self.view.subviews indexOfObject:subview];
}

- (UIButton *)buttonAtIndex:(NSInteger)tag
{
    return [self.view.subviews objectAtIndex:tag];
}

- (void)colorWheel:(NVColorWheel *)colorWheel
    didReturnColor:(UIColor *)color
         colorName:(NSString *)colorName
    forViewWithTag:(NSInteger)tag
{
    UIButton *button = [self buttonAtIndex:tag];
    button.backgroundColor = color;
    
    [button setTitle:colorName
            forState:UIControlStateNormal];
    
    [colorWheel hideColorWheel:YES];
}

- (void)colorWheelDidCancel:(NVColorWheel *)colorWheel
{
    [colorWheel hideColorWheel:YES];
}

- (IBAction)cascadeButton:(id)sender {
}
@end