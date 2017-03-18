//  ChartsViewController.h
//  NVMobile

@import UIKit;
#import "CCodeLibrary/NVColor.h"
#import "CCodeLibrary/NVDateRange.h"

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
@property (nonatomic, copy) NSString *areaType, *geoid;
@property int startTime, endTime, interval;
@property TimeArraySpan span;

/*
 * startTime & endTime are 24 hour format (hhmm)
 * endTime must be greater than startTime at least by interval
 * interval is in minutes
 */
+ (instancetype)routingChartFromDestination:(CLLocationCoordinate2D)fromDestination
                              toDestination:(CLLocationCoordinate2D)toDestination
                                  startTime:(int)startTime
                                    endTime:(int)endTime
                                       span:(TimeArraySpan)span
                                   interval:(int)interval
                                      color:(NVColor *)color;

+ (instancetype)chartViewWithType:(ChartsViewType)type;

@end
