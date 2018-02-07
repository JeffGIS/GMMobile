//  NVPanoramaView.h
//  NVMobile

@import GoogleMaps;

@class NVPanoramaView;

@protocol NVPanoramaViewDelegate <NSObject>

- (void)panoramaView:(NVPanoramaView *)panoramaView
  didReturnWithCoord:(CLLocationCoordinate2D)coordinate;

@end

@interface NVPanoramaView : GMSPanoramaView

+ (BOOL)showPanoramaAtCoord:(CLLocationCoordinate2D)coords
                     inView:(UIView *)view
                   delegate:(id)delegate
                     tabBar:(UITabBar *)tabBar;

+ (BOOL)showPanoramaAtCoord:(CLLocationCoordinate2D)coord
             lookingAtCoord:(CLLocationCoordinate2D)lookAtcoord
                     inView:(UIView *)view
                   delegate:(id)delegate
                     tabBar:(UITabBar *)tabBar;

- (void)hide:(BOOL)animated;

@end
