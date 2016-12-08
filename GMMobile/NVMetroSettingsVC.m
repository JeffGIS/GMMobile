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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
