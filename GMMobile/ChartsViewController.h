//  ChartsViewController.h
//  NVMobile

@import UIKit;

typedef NS_ENUM(NSInteger, ChartsViewType)
{
    ChartsViewTypeDefault,
    ChartsViewTypePropReport,
    ChartsViewTypeCensusDataPie,
    ChartsViewTypeCensusDataLine,
};

@interface ChartsViewController : UIViewController

@property (nonatomic, copy) NSArray *propHistoryArray;
@property (nonatomic) NSString *geoid;

+ (instancetype)chartViewWithType:(ChartsViewType)type;

@end
