//  NVPageController.m
//  GMMobile

#import "NVPageController.h"
#import "NVPageView.h"
#import "ConfigurationControl.h"

@interface NVPageController ()  <UIPageViewControllerDataSource,UIPageViewControllerDelegate>

@property (nonatomic) NSMutableArray *pages;
@property (nonatomic) UIPageControl *pageControl;
@property (nonatomic) NSArray *legends;

@end

@implementation NVPageController

- (id)init
{
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                  options:nil];

    return self;
}

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
    _legends = ConfigurationControl.sharedInstance.legendList;
    
    if (!_pages.count)
        _pages = NSMutableArray.array;
    
    NVPageView *rootPV = [NVPageView pageViewWithNumLegends:MIN(_legends.count, 3)
                                              startingIndex:0
                                                pageControl:_pageControl];
    
    [_pages addObject:rootPV];
    
    for (int i = 3; i < _legends.count; i += 3)
    {
        NVPageView *pv = [NVPageView pageViewWithNumLegends:MIN((_legends.count - i), 3)
                                              startingIndex:(NSUInteger)i
                                                pageControl:_pageControl];
        
        [_pages addObject:pv];
    }
    
    _pageControl = UIPageControl.new;
    _pageControl.numberOfPages = _pages.count;
    _pageControl.currentPage = 0;
    _pageControl.userInteractionEnabled = NO;
    _pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    _pageControl.hidesForSinglePage = YES;
    [self.view addSubview:_pageControl];
    
    [_pageControl.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [_pageControl.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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

- (void)addViewController:(UIViewController *)viewController
{
    _pages = NSMutableArray.array;
    [_pages addObject:viewController];
}

@end