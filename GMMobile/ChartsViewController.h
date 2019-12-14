//  ChartsViewController.h
//  NVMobile

@import UIKit;
#import "CCodeLibrary/NVColor.h"
#import "CCodeLibrary/TimeLine.h"
#import "CCodeLibrary/NVDateRange.h"
#import "CCodeLibrary/NVSpreadsheetVC.h"

#define MAX_QUERIES 50

typedef NS_ENUM(NSInteger, ChartsViewType)
{
    ChartsViewTypeDefault,
    ChartsViewTypePropReport,
    ChartsViewTypeSalesHistory,
    ChartsViewTypeCensusDataPie,
    ChartsViewTypeCensusDataBar,
    ChartsViewTypeCensusDataLine,
    ChartsViewTypeRouting,
    ChartsViewTypeTimeLine,
};

@interface ChartsViewController : UIViewController

@property (nonatomic, copy) NSArray *propHistoryArray;
@property (nonatomic, copy) NSArray *salesHistoryArray;
@property CLLocationCoordinate2D toDestination, fromDestination;
@property (nonatomic, copy) NSString *areaType, *geoid;
@property int startTime, endTime, interval;
@property TimeArraySpan span;
@property (nonatomic, copy) NSArray<TimeLine *> *timeLineArray;
@property (nonatomic, weak) NVSpreadsheetVC *currentSpreadsheet;

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
