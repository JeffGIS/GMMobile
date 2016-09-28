//  FindPropertyOwnerViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"

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

@end

@interface FindPropertyOwnerViewController : UIViewController

@property (weak, nonatomic) id <FindPropOwnerViewControllerDelegate> delegate;

+ (NSArray *)limitToOptions;

@end
