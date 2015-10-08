//  DestinationsViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "CCodeLibrary/NVTextAlert.h"
#import "CCodeLibrary/NVDestinationOptions.h"

@interface DestinationsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVTextAlertDelegate,NVDestinationOptionsDelegate>

@property (weak, nonatomic) IBOutlet UITableView *topTableView;
@property (weak, nonatomic) IBOutlet UITableView *bottomTableView;

@end