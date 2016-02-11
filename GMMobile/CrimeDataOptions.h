//  CrimeDataOptions.h
//  GMMobile

@import UIKit;
#import "CCodeLibrary/NVDateRange.h"

typedef NS_ENUM(NSInteger, NVMapModeType)
{
    NVMapModeTypePIN,
    NVMapModeTypeHotspot,
    NVMapModeTypeChoropleth,
};

@interface CrimeDataOptions : UIViewController <UITableViewDataSource,UITableViewDelegate,NVDateRangeDelegate>

@end