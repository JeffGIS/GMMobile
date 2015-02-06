//  WebKitViewController.m
//  GMMobile

#import "WebKitViewController.h"

@interface WebKitViewController ()

@property (nonatomic, copy) NSString *PID;
@property (nonatomic) WKWebView *webView;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) UIInterfaceOrientation *orientation;

@end

@implementation WebKitViewController

- (id)initWithPID:(NSString *)PID
{
    self = [super init];
    
    if (self)
    {
        _PID = PID;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    [self setupWebView];
    [self setupBackButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupWebView
{
    CGRect wvFrame = CGRectMake(self.view.frame.origin.x, 48.0,
                                self.view.frame.size.width,
                                self.view.frame.size.height);
    
    _webView = [[WKWebView alloc] initWithFrame:wvFrame];
    [self.view addSubview:_webView];
    _webView.allowsBackForwardNavigationGestures = YES;
    
    NSURL *url = [NSURL URLWithString:
                  [NSString stringWithFormat:
                   @"http://www16.co.hennepin.mn.us/pins/pidresult.jsp?pid=%@", _PID]];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:urlRequest];
}

- (void)setupBackButton
{
    _backButton = [[UIButton alloc] initWithFrame:CGRectMake(16.0, 16.0, 120.0, 32.0)];
    _backButton.titleLabel.font = [UIFont boldSystemFontOfSize:28.0];
    
    [_backButton setTitle:@"< Return"
                 forState:UIControlStateNormal];
    
    [_backButton setTitleColor:UserDefaults.defaults.appleBlue
                      forState:UIControlStateNormal];
    
    [_backButton addTarget:self
                    action:@selector(goBack:)
          forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_backButton];
}

- (void)goBack:(UIButton *)button
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    CGRect wvFrame = CGRectMake(self.view.frame.origin.x, 48.0,
                                self.view.frame.size.height,
                                self.view.frame.size.width);
    
    _webView.frame = wvFrame;
}

@end