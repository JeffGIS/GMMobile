//  WebKitViewController.m
//  GMMobile

#import "WebKitViewController.h"

@interface WebKitViewController ()

@property (nonatomic, copy) NSString *PID;
@property (nonatomic) WKWebView *webView;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) UIInterfaceOrientation *orientation;
@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) UIView *actIndView;

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
    [self setupActivityIndicatorView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupActivityIndicatorView
{
    _actIndView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 120.0, 120.0)];
    _actIndView.center = self.view.center;
    
    _actIndView.backgroundColor = [UIColor colorWithWhite:0.0
                                                    alpha:0.5];
    
    _actIndView.layer.cornerRadius = 20.0;
    [self.view addSubview:_actIndView];
    
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    _activityIndicator.frame = CGRectMake((_actIndView.frame.size.width / 2.0 - (_activityIndicator.frame.size.width / 2.0)),
                                          (_actIndView.frame.size.height / 2.0 - (_activityIndicator.frame.size.height / 2.0)),
                                          _activityIndicator.frame.size.width,
                                          _activityIndicator.frame.size.height);
    
    [self startIndicator];
}

- (void)setupWebView
{
    CGRect wvFrame = CGRectMake(self.view.frame.origin.x, 48.0,
                                self.view.frame.size.width,
                                self.view.frame.size.height);
    
    NSURL *url = [NSURL URLWithString:
                  [NSString stringWithFormat:
                   @"http://www16.co.hennepin.mn.us/pins/pidresult.jsp?pid=%@", _PID]];
    
    _webView = [[WKWebView alloc] initWithFrame:wvFrame];
    
    _webView.allowsBackForwardNavigationGestures = YES;
    _webView.navigationDelegate = self;
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:urlRequest];
    [self.view addSubview:_webView];
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

- (void)startIndicator
{
    [_actIndView addSubview:_activityIndicator];
    [_activityIndicator startAnimating];
}

- (void)stopIndicator
{
    [_activityIndicator stopAnimating];
    [_actIndView removeFromSuperview];
}

- (void)webView:(WKWebView *)webView
didFinishNavigation:(WKNavigation *)navigation
{
    [self stopIndicator];
}

- (void)webView:(WKWebView *)webView
didFailNavigation:(WKNavigation *)navigation
        withError:(NSError *)error
{
    [self stopIndicator];
    NSLog(@"webView ERROR:%@", error.localizedDescription);
}

@end