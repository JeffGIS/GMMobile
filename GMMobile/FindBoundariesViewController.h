//  FindBoundariesViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "CCodeLibrary/NVUnitPickerTextAlert.h"

@class FindBoundariesViewController;

@protocol FindBoundsViewControllerDelegate <NSObject>

- (void)findBoundsViewController:(FindBoundariesViewController *)findBounds
                 didSelectBounds:(NSString *)bounds
                            type:(NSString *)type
                           refno:(int)refno;

@end

@interface FindBoundariesViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVUnitPickerTextAlertDelegate>

@property (weak, nonatomic) id <FindBoundsViewControllerDelegate> delegate;

@end