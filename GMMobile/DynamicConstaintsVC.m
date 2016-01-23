//  DynamicConstaintsVC.m
//  GMMobile

#import "DynamicConstaintsVC.h"
#import "CCodeLibrary/UserDefaults.h"

@interface DynamicConstaintsVC ()

@end

@implementation DynamicConstaintsVC

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UserDefaults.defaults.appleBlue;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    returnButton.titleLabel.font = [UIFont boldSystemFontOfSize:36.0];
    returnButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [returnButton setTitle:@"< Return"
                  forState:UIControlStateNormal];
    
    [returnButton setTitleColor:UIColor.whiteColor
                       forState:UIControlStateNormal];
    
    [returnButton setTitleColor:UIColor.lightGrayColor
                       forState:UIControlStateHighlighted];
    
    [returnButton addTarget:self
                     action:@selector(returnButtonTapped:)
           forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:returnButton];
    
    UIView *v1 = UIView.new;
    v1.backgroundColor = UIColor.redColor;
    v1.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:v1];
    
    UIView *v2 = UIView.new;
    v2.backgroundColor = UIColor.greenColor;
    v2.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:v2];
    
    UIView *v3 = UIView.new;
    v3.backgroundColor = UIColor.yellowColor;
    v3.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:v3];
    
    UIView *v4 = UIView.new;
    v4.backgroundColor = UIColor.magentaColor;
    v4.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:v4];
    
    [returnButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                               constant:20.0].active = YES;
    
    [returnButton.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                           constant:20.0].active = YES;

    [v1.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                     constant:20.0].active = YES;
    
    [v1.trailingAnchor constraintEqualToAnchor:self.view.centerXAnchor
                                      constant:-10.0].active = YES;
    
    [v1.topAnchor constraintEqualToAnchor:returnButton.bottomAnchor
                                 constant:20.0].active = YES;
    
    [v1.bottomAnchor constraintEqualToAnchor:self.view.centerYAnchor
                                    constant:((returnButton.frame.size.height / 2.0) + 30.0)].active = YES;
    
    [v2.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                     constant:20.0].active = YES;
    
    [v2.trailingAnchor constraintEqualToAnchor:self.view.centerXAnchor
                                      constant:-10.0].active = YES;
    
    [v2.topAnchor constraintEqualToAnchor:self.view.centerYAnchor
                                 constant:((returnButton.frame.size.height / 2.0) + 50.0)].active = YES;
    
    [v2.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                    constant:-20.0].active = YES;
    
    [v3.leadingAnchor constraintEqualToAnchor:self.view.centerXAnchor
                                     constant:10.0].active = YES;
    
    [v3.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                      constant:-20.0].active = YES;
    
    [v3.topAnchor constraintEqualToAnchor:returnButton.bottomAnchor
                                 constant:20.0].active = YES;
    
    [v3.bottomAnchor constraintEqualToAnchor:self.view.centerYAnchor
                                    constant:((returnButton.frame.size.height / 2.0) + 30.0)].active = YES;
    
    [v4.leadingAnchor constraintEqualToAnchor:self.view.centerXAnchor
                                     constant:10.0].active = YES;
    
    [v4.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                      constant:-20.0].active = YES;
    
    [v4.topAnchor constraintEqualToAnchor:self.view.centerYAnchor
                                 constant:((returnButton.frame.size.height / 2.0) + 50.0)].active = YES;
    
    [v4.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                    constant:-20.0].active = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)returnButtonTapped:(UIButton *)button
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end