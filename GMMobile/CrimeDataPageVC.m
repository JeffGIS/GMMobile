//  CrimeDataPageVC.m
//  GMMobile

#import "CrimeDataPageVC.h"
#import "CrimeOptions1.h"
#import "CrimeOptions2.h"

@interface CrimeDataPageVC ()

@property (nonatomic) NSArray *pages;
@property (nonatomic) UIPageControl *pageControl;

@end

@implementation CrimeDataPageVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupPages];
    self.dataSource = self;
    self.delegate = self;
    self.view.backgroundColor = UIColor.blackColor;
    
    [self setViewControllers:@[_pages[0]]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:YES
                  completion:nil];
}

- (void)setupPages
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:NSBundle.mainBundle];
    
    UIViewController *cdovc = [storyboard instantiateViewControllerWithIdentifier:@"CrimeDataOptionsVC"];
    CrimeOptions1 *co1 = [storyboard instantiateViewControllerWithIdentifier:@"CrimeOptions1"];
    UIViewController *co2 = [storyboard instantiateViewControllerWithIdentifier:@"CrimeOptions2"];
    
    _pages = @[cdovc, co1, co2];
    
    _pageControl = [[UIPageControl alloc] init];
    
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    
    _pageControl.frame = CGRectMake(0.0, (self.view.frame.size.height - tabBarHeight - 20.0),
                                    self.view.frame.size.width, 20.0);
    
    _pageControl.numberOfPages = _pages.count;
    _pageControl.currentPage = 0;
    [self.view addSubview:_pageControl];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger index = [_pages indexOfObject:viewController];
    NSParameterAssert(index != NSNotFound);
    
    if (index >= (_pages.count - 1))
        return nil;
    
    return _pages[index + 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger index = [_pages indexOfObject:viewController];
    NSParameterAssert(index != NSNotFound);
    
    if (index <= 0)
        return nil;
    
    return _pages[index - 1];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        _pageControl.frame = CGRectMake(0.0, (self.view.frame.size.width - tabBarHeight - 20.0),
                                        self.view.frame.size.width, 20.0);
    }];
}

- (void)pageViewController:(UIPageViewController *)pvc
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    if (finished && completed)
    {
        NSInteger currentPage = [_pages indexOfObject:pvc.viewControllers[0]];
        _pageControl.currentPage = currentPage;
    }
}

@end