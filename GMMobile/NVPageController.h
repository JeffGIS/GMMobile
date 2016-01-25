//  NVPageController.h
//  GMMobile

@import UIKit;
#import "NVPageView.h"

@interface NVPageController : UIPageViewController

+ (instancetype)pageControllerWithArrangementArray:(NSArray *)arrangementArray;

- (void)addViewController:(UIViewController *)viewController;

@end