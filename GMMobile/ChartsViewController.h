//  ChartsViewController.h
//  NVMobile

@import UIKit;

typedef NS_ENUM(NSInteger, ChartsViewType)
{
    ChartsViewTypeDefault,
    ChartsViewTypePropReport,
    ChartsViewTypeCensusData,
};

@interface ChartsViewController : UIViewController

@property (nonatomic, copy) NSArray *propHistoryArray;

+ (instancetype)chartViewWithType:(ChartsViewType)type;

@end
