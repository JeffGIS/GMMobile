//  LayerOverridesViewController.m
//  GMMobile

#import "LayerOverridesViewController.h"

@interface LayerOverridesViewController ()

@end

@implementation LayerOverridesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (UIView *subviews in self.view.subviews)
        subviews.tag = [self.view.subviews indexOfObject:subviews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
                                                                tag:sender.tag];
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
                                                                tag:sender.tag];
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

- (void)colorWheel:(NVColorWheel *)colorWheel
    didReturnColor:(UIColor *)color
         colorName:(NSString *)colorName
    forViewWithTag:(NSInteger)tag
{
    UIButton *subview = [self.view.subviews objectAtIndex:tag];
    subview.backgroundColor = color;
    
    [subview setTitle:colorName
             forState:UIControlStateNormal];
    
    [colorWheel hideColorWheel:YES];
}

- (void)colorWheelDidCancel:(NVColorWheel *)colorWheel
{
    [colorWheel hideColorWheel:YES];
}

@end