//  NVPageController.m
//  GMMobile

#import "NVPageController.h"
#import "ConfigurationControl.h"

@interface NVPageController ()  <UIPageViewControllerDataSource,UIPageViewControllerDelegate>

@property (nonatomic) NSMutableArray *pages;
@property (nonatomic) UIPageControl *pageControl;
@property (nonatomic) NSArray *legends;
@property (nonatomic) NSArray *pageViewArrangementArray;

@end

@implementation NVPageController

+ (instancetype)pageControllerWithArrangementArray:(NSArray *)arrangementArray
{
    if (!arrangementArray)
        return nil;
    
    NVPageController *nvpc = NVPageController.new;
    nvpc.pageViewArrangementArray = arrangementArray;
    return nvpc;
}

- (id)init
{
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                  options:nil];

    return self;
}

- (BOOL)prefersStatusBarHidden
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return YES;
    
    else
        return NO;
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
    int index = 0;
    
    if (!_pages.count)
        _pages = NSMutableArray.array;
    
    NVPageViewArrangement rootPVArr = [(NSNumber *)_pageViewArrangementArray[0] integerValue];
    NSUInteger numLegends = [self numPagesFromArrangement:rootPVArr];
    
    NVPageView *rootPV = [NVPageView pageViewWithNumLegends:numLegends
                                              startingIndex:0
                                                pageControl:_pageControl
                                            pageArrangement:rootPVArr];
    
    index += numLegends;
    
    [_pages addObject:rootPV];
    
    for (int i = 1; i < _pageViewArrangementArray.count; i++)
    {
        NVPageViewArrangement pvArr = [(NSNumber *)_pageViewArrangementArray[i] integerValue];
        NSUInteger numLegends = [self numPagesFromArrangement:pvArr];
        
        NVPageView *pv = [NVPageView pageViewWithNumLegends:numLegends
                                              startingIndex:index
                                                pageControl:_pageControl
                                            pageArrangement:pvArr];
        
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
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [_pageControl.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                  constant:12.0].active = YES;
    }
    
    else
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

- (NSUInteger)numPagesFromArrangement:(NVPageViewArrangement)arrangement
{
    NSUInteger numPages = 0;
    
    switch (arrangement)
    {
        case NVPageViewArrangementFit1:
            numPages = 1;
            break;
            
        case NVPageViewArrangementFit2:
        case NVPageViewArrangementFit2Columns2:
            numPages = 2;
            break;
            
        case NVPageViewArrangementFit3:
        case NVPageViewArrangementFit3Columns2:
        case NVPageViewArrangementFit3Columns3:
            numPages = 3;
            break;
            
        case NVPageViewArrangementFit4:
        case NVPageViewArrangementFit4Columns2:
        case NVPageViewArrangementFit4Columns3:
        case NVPageViewArrangementFit4Columns4:
            numPages = 4;
            break;
            
        case NVPageViewArrangementFit5:
        case NVPageViewArrangementFit5Columns2:
        case NVPageViewArrangementFit5Columns3:
        case NVPageViewArrangementFit5Columns4:
        case NVPageViewArrangementFit5Columns5:
            numPages = 5;
            break;
            
        case NVPageViewArrangementFit6:
        case NVPageViewArrangementFit6Columns2:
        case NVPageViewArrangementFit6Columns3:
        case NVPageViewArrangementFit6Columns4:
        case NVPageViewArrangementFit6Columns5:
        case NVPageViewArrangementFit6Columns6:
            numPages = 6;
            break;
            
        default:
            break;
    }
    
    return numPages;
}

@end