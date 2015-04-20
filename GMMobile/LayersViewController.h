//  LayersViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

typedef NS_ENUM(NSInteger, GMLayerSetting)
{
    GMLayerSettingOn,
    GMLayerSettingOff,
    GMLayerSettingAuto,
};

#define DEFAULT_ZOOM_LEVEL 12

@interface LayersViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end