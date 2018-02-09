//  NVPanoramaVC.h
//  NVMobile

@import UIKit;

@class NVPanoramaVC;

@protocol NVPanoramaVCDelegate<NSObject>

- (void)panoramaVC:(NVPanoramaVC *)panoramaVC
didReturnWithCoord:(CLLocationCoordinate2D)coordinate;

@end

@interface NVPanoramaVC : UIViewController

+ (BOOL)presentPanoramaInController:(UIViewController *)controller
                     lookingAtCoord:(CLLocationCoordinate2D)lookingAtCoord
                           delegate:(id<NVPanoramaVCDelegate>)delegate;

+ (BOOL)presentPanoramaInController:(UIViewController *)controller
                            atCoord:(CLLocationCoordinate2D)atCoord
                     lookingAtCoord:(CLLocationCoordinate2D)lookingAtCoord
                           delegate:(id<NVPanoramaVCDelegate>)delegate;

@end
