//  FindBoundariesViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "CCodeLibrary/NVUnitPickerTextAlert.h"
#import "PropertyData.h"

@class FindBoundariesViewController;

@protocol FindBoundsViewControllerDelegate <NSObject>

- (void)findBoundsViewController:(FindBoundariesViewController *)findBounds
                 didSelectBounds:(NSString *)bounds
                            type:(NSString *)type
                           refno:(int)refno;

@optional
- (void)findBoundsViewController:(FindBoundariesViewController *)findPropOwner
          didSelectMultipleProps:(NSArray <PropertyRecord *> *)multipleProps;

@end

@interface FindBoundariesViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,NVUnitPickerTextAlertDelegate>

@property (weak, nonatomic) id <FindBoundsViewControllerDelegate> delegate;
@property (nonatomic, copy) NSArray *otherAreas;

@end
