//  DestinationsViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "CCodeLibrary/NVTextAlert.h"

@interface DestinationsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVTextAlertDelegate>

@property (weak, nonatomic) IBOutlet UITableView *topTableView;
@property (weak, nonatomic) IBOutlet UITableView *bottomTableView;

@end