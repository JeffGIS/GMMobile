//  FindPropertyOwnerViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "PropertyData.h"
#import "BoundaryData.h"

@class FindPropertyOwnerViewController;

@protocol FindPropOwnerViewControllerDelegate <NSObject>

- (void)findPropOwnerViewController:(FindPropertyOwnerViewController *)findPropOwner
                 didSelectPropOwner:(NSString *)propOwner
                                PID:(NSString *)PID;

- (void)findPropOwnerViewController:(FindPropertyOwnerViewController *)findPropOwner
             didSelectMultipleProps:(NSArray <PropertyRecord *> *)multipleProps;

@end

@interface FindPropertyOwnerViewController : UIViewController <PropertyDataDelegate>

@property (weak, nonatomic) id <FindPropOwnerViewControllerDelegate> delegate;

+ (NSArray *)limitToOptions;

@end
