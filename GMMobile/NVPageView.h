//  NVPageView.h
//  GMMobile

@import UIKit;

@interface NVPageView : UIViewController

+ (instancetype)pageViewWithNumLegends:(NSUInteger)numLegends
                         startingIndex:(NSUInteger)startingIndex
                           pageControl:(UIPageControl *)pageControl;

@end