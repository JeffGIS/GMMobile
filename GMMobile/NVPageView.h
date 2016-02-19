//  NVPageView.h
//  GMMobile

@import UIKit;

typedef NS_ENUM(NSInteger, NVPageViewArrangement)
{
    NVPageViewArrangementDefault,
    NVPageViewArrangementFit1,
    NVPageViewArrangementFit2,
    NVPageViewArrangementFit2Columns2,
    NVPageViewArrangementFit3,
    NVPageViewArrangementFit3Columns2,
    NVPageViewArrangementFit3Columns3,
    NVPageViewArrangementFit4,
    NVPageViewArrangementFit4Columns2,
    NVPageViewArrangementFit4Columns3,
    NVPageViewArrangementFit4Columns4,
    NVPageViewArrangementFit5,
    NVPageViewArrangementFit5Columns2,
    NVPageViewArrangementFit5Columns3,
    NVPageViewArrangementFit5Columns4,
    NVPageViewArrangementFit5Columns5,
    NVPageViewArrangementFit6,
    NVPageViewArrangementFit6Columns2,
    NVPageViewArrangementFit6Columns3,
    NVPageViewArrangementFit6Columns4,
    NVPageViewArrangementFit6Columns5,
    NVPageViewArrangementFit6Columns6,
};

@interface NVPageView : UIViewController

+ (instancetype)pageViewWithNumLegends:(NSUInteger)numLegends
                         startingIndex:(NSUInteger)startingIndex
                       pageArrangement:(NVPageViewArrangement)pageArrangement
                            controller:(UIPageViewController *)controller;

@end