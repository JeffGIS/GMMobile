//  FindPropertyOwnerViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "PropertyData.h"

typedef NS_ENUM(NSInteger, LimitToOption)
{
    LimitToOptionNoLimit,
    LimitToOptionMapBounds,
    LimitToOptionCurrentCity,
    LimitToOptionCurrentCounty,
};

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
