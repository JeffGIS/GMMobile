//  ChartsViewController.h
//  NVMobile

@import UIKit;

typedef NS_ENUM(NSInteger, ChartsViewType)
{
    ChartsViewTypeDefault,
    ChartsViewTypePropReport,
    ChartsViewTypeCensusDataPie,
    ChartsViewTypeCensusDataBar,
    ChartsViewTypeCensusDataLine,
    ChartsViewTypeRouting,
};

@interface ChartsViewController : UIViewController

@property (nonatomic, copy) NSArray *propHistoryArray;
@property (nonatomic) NSString *areaType;
@property (nonatomic) NSString *geoid;

+ (instancetype)routingChartFromDestination:(CLLocationCoordinate2D)fromDestination
                              toDestination:(CLLocationCoordinate2D)toDestination;

+ (instancetype)chartViewWithType:(ChartsViewType)type;

@end
