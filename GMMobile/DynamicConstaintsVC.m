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
    
    UIButton *returnButton = [[UIButton alloc] initWithFrame:CGRectMake(20.0, 20.0, 240.0, 60.0)];
    returnButton.backgroundColor = UIColor.whiteColor;
    returnButton.titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
    
    [returnButton setTitle:@"< Return"
                  forState:UIControlStateNormal];
    
    [returnButton setTitleColor:UIColor.blackColor
                       forState:UIControlStateNormal];
    
    [returnButton setTitleColor:UIColor.grayColor
                       forState:UIControlStateHighlighted];
    
    [returnButton addTarget:self
                     action:@selector(returnButtonTapped:)
           forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:returnButton];
    
    UIView *v1 = [[UIView alloc] initWithFrame:CGRectMake(20.0, 100.0, (self.view.frame.size.width - 40.0),
                                                          ((self.view.frame.size.height - 140.0) / 2.0))];
    
    v1.backgroundColor = UIColor.redColor;
    [self.view addSubview:v1];
    
    UIView *v2 = [[UIView alloc] initWithFrame:CGRectMake(20.0, (120.0 + ((self.view.frame.size.height - 140.0) / 2.0)),
                                                          (self.view.frame.size.width - 40.0),
                                                          ((self.view.frame.size.height - 140.0) / 2.0))];
    
    v2.backgroundColor = UIColor.greenColor;
    [self.view addSubview:v2];
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