//  NVPageController.h
//  GMMobile

@import UIKit;
#import "NVPageView.h"

@interface NVPageController : UIPageViewController

@property BOOL pagingEnabled;

+ (instancetype)pageControllerWithArrangementArray:(NSArray *)arrangementArray;

- (void)addViewController:(UIViewController *)viewController;
- (void)disablePaging;
- (void)enablePaging;

@end
