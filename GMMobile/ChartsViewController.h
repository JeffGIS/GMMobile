//  ChartsViewController.h
//  NVMobile

@import UIKit;
#import "CCodeLibrary/NVColor.h"

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
@property CLLocationCoordinate2D toDestination, fromDestination;
@property (nonatomic) NSString *areaType;
@property (nonatomic) NSString *geoid;

+ (instancetype)routingChartFromDestination:(CLLocationCoordinate2D)fromDestination
                              toDestination:(CLLocationCoordinate2D)toDestination
                                      color:(NVColor *)color;

+ (instancetype)chartViewWithType:(ChartsViewType)type;

@end
