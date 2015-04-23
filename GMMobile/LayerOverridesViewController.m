//  LayerOverridesViewController.m
//  GMMobile

#import "LayerOverridesViewController.h"

@interface LayerOverridesViewController ()

@property (nonatomic) CGFloat offTrans, onTrans;

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
    
    _offTrans = 50;
    _onTrans = 100.0;
    
    [_AOnTrans setTitle:[NSString stringWithFormat:@"%.0f%%", _onTrans]
               forState:UIControlStateNormal];
    
    [_AOffTrans setTitle:[NSString stringWithFormat:@"%.0f%%", _offTrans]
               forState:UIControlStateNormal];
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

- (IBAction)AOnTrans:(UIButton *)sender
{
    NVSliderView *sliderView = [NVSliderView showSliderWithView:self.view
                                                     startValue:_onTrans
                                                       minValue:0.0
                                                       maxValue:100.0
                                                       delegate:self
                                                         tabBar:self.tabBarController.tabBar
                                                            tag:[self indexOfButton:sender]];
#pragma unused(sliderView)
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

- (IBAction)AOffTrans:(UIButton *)sender
{
    NVSliderView *sliderView = [NVSliderView showSliderWithView:self.view
                                                     startValue:_offTrans
                                                       minValue:0.0
                                                       maxValue:100.0
                                                       delegate:self
                                                         tabBar:self.tabBarController.tabBar
                                                            tag:[self indexOfButton:sender]];
#pragma unused(sliderView)
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

- (IBAction)cascadeButton:(id)sender
{
    
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

- (NSInteger)indexOfButton:(UIButton *)button
{
    return [self.view.subviews indexOfObject:button];
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

- (void)sliderView:(NVSliderView *)sliderView
        didReturnValue:(CGFloat)value
        forViewWithTag:(NSInteger)tag
{
    if ([self buttonAtIndex:tag] == _AOnTrans)
    {
        _onTrans = value;
        
        [_AOnTrans setTitle:[NSString stringWithFormat:@"%.0f%%", _onTrans]
                   forState:UIControlStateNormal];
    }
    
    else if ([self buttonAtIndex:tag] == _AOffTrans)
    {
        _offTrans = value;
        
        [_AOffTrans setTitle:[NSString stringWithFormat:@"%.0f%%", _offTrans]
                    forState:UIControlStateNormal];
    }
    
    [sliderView hideSliderView:YES];
}

- (void)sliderViewDidCancel:(NVSliderView *)sliderView
{
    [sliderView hideSliderView:YES];
}

@end