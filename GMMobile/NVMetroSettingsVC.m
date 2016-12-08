//  NVMetroSettingsVC.m
//  NVMobile

#import "NVMetroSettingsVC.h"
#import "CCodeLibrary/UserDefaults.h"

@interface NVMetroSettingsVC ()

@end

@implementation NVMetroSettingsVC

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    
    CGFloat margin = 20.0;
    UIView *topView = UIView.new;
    topView.translatesAutoresizingMaskIntoConstraints = NO;
    topView.backgroundColor = UserDefaults.defaults.appleGray;
    topView.layer.cornerRadius = 10.0;
    
    [self.view addSubview:topView];
    [topView constrainTopToAnchor:self.view.topAnchor constant:margin];
    [topView constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [topView constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    
    UIView *bottomView = UIView.new;
    bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    bottomView.backgroundColor = UserDefaults.defaults.appleGray;
    bottomView.layer.cornerRadius = 10.0;
    
    [self.view addSubview:bottomView];
    [bottomView constrainTopToAnchor:topView.bottomAnchor constant:margin];
    [bottomView constrainLeadingToAnchor:self.view.leadingAnchor constant:margin];
    [bottomView constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    [bottomView constrainBottomToAnchor:self.view.bottomAnchor constant:-margin];
    [bottomView constrainHeightToAnchor:topView.heightAnchor multiplier:0.5];
    
    for (int i = 1; i < 9; i++)
    {
        UIView *view = UIView.new;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.layer.borderColor = UIColor.darkGrayColor.CGColor;
        view.layer.borderWidth = 1.0;
        view.tag = i;
        
        if (i < 7)
        {
            [topView addSubview:view];
            [view constrainLeadingToAnchor:topView.leadingAnchor];
            [view constrainTrailingToAnchor:topView.trailingAnchor];
        }
        
        else
        {
            [bottomView addSubview:view];
            [view constrainLeadingToAnchor:bottomView.leadingAnchor];
            [view constrainTrailingToAnchor:bottomView.trailingAnchor];
        }
        
        switch (i)
        {
            case 1:
                [view constrainTopToAnchor:topView.topAnchor];
                break;
                
            case 2:
            case 3:
            case 4:
            case 5:
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-1].heightAnchor];
                break;
                
            case 6:
                [view constrainTopToAnchor:[topView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[topView viewWithTag:i-1].heightAnchor];
                [view constrainBottomToAnchor:topView.bottomAnchor];
                break;
                
            case 7:
                [view constrainTopToAnchor:bottomView.topAnchor];
                break;
                
            case 8:
                [view constrainTopToAnchor:[bottomView viewWithTag:i-1].bottomAnchor];
                [view constrainHeightToAnchor:[bottomView viewWithTag:i-1].heightAnchor];
                [view constrainBottomToAnchor:bottomView.bottomAnchor];
                break;
                
            default:
                break;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
