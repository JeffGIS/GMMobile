//  NVPanoramaView.m
//  NVMobile

#import "NVPanoramaView.h"
#import "CCodeLibrary/UserDefaults.h"
#import "CCodeLibrary/NVAlertView.h"
#import "CCodeLibrary/CRAPI.h"

@interface NVPanoramaView () <GMSPanoramaViewDelegate,NVAlertViewDelegate>

@property (nonatomic, weak) id <NVPanoramaViewDelegate> viewDelegate;
@property (nonatomic) GMSMarker *marker;
@property CLLocationCoordinate2D pickedCoord;

@end

@implementation NVPanoramaView

+ (BOOL)showPanoramaAtCoord:(CLLocationCoordinate2D)coord
                     inView:(UIView *)view
                   delegate:(id)delegate
                     tabBar:(UITabBar *)tabBar
{
    if (!delegate || !view)
    {
        NSLog(@"NVPanoramaView ERROR:Cannot set delegate or view to nil");
        return NO;
    }
    
    if (![delegate respondsToSelector:@selector(panoramaView:didReturnWithCoord:)])
    {
        NSLog(@"NVPanoramaView ERROR:Delegate must respond to all selectors in protocol");
        return NO;
    }
    
    NVPanoramaView *panView = NVPanoramaView.new;
    panView.delegate = panView;
    panView.viewDelegate = delegate;
    panView.translatesAutoresizingMaskIntoConstraints = NO;
    panView.alpha = 0.0;
    panView.pickedCoord = CLLocationCoordinate2DMake(0.0, 0.0);
    
    [view addSubview:panView];
    [panView constrainToView:view leading:0.0 trailing:0.0 top:0.0 bottom:tabBar.frame.size.height];
    [panView moveNearCoordinate:coord];
    
    UIButton *dismissPan = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissPan.translatesAutoresizingMaskIntoConstraints = NO;
    dismissPan.backgroundColor = UIColor.clearColor;
    dismissPan.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        dismissPan.titleLabel.font = [UIFont boldSystemFontOfSize:28.0];
    
    else
        dismissPan.titleLabel.font = [UIFont boldSystemFontOfSize:40.0];
    
    dismissPan.titleLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    dismissPan.titleLabel.layer.shadowOpacity = 1.0;
    dismissPan.titleLabel.layer.shadowRadius = 3.0;
    dismissPan.titleLabel.layer.shadowOffset = CGSizeZero;
    [dismissPan setTitle:@"< Return" forState:UIControlStateNormal];
    [dismissPan setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [dismissPan setTitleColor:UIColor.lightGrayColor forState:UIControlStateHighlighted];
    
    [panView addSubview:dismissPan];
    [dismissPan constrainLeadingToAnchor:panView.leadingAnchor constant:20.0];
    [dismissPan constrainTopToAnchor:panView.topAnchor constant:20.0];
    [dismissPan addTarget:panView action:@selector(dismissPanTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [UIView animateWithDuration:0.25 animations:^{
        panView.alpha = 1.0;
    }];
    
    return YES;
}

- (void)dismissPanTapped:(UIButton *)button
{
    [_viewDelegate panoramaView:self didReturnWithCoord:_pickedCoord];
}

- (void)hide:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             [self removeFromSuperview];
                         }];
    }
    
    else
        [self removeFromSuperview];
}

- (void)panoramaView:(GMSPanoramaView *)view
   didMoveToPanorama:(GMSPanorama *)panorama
      nearCoordinate:(CLLocationCoordinate2D)coordinate
{
    CLLocationDirection heading = getHeading(panorama.coordinate, coordinate);
    
    view.camera = [GMSPanoramaCamera cameraWithHeading:heading
                                                 pitch:0.0
                                                  zoom:1.0
                                                   FOV:90.0];
}

- (void)panoramaView:(GMSPanoramaView *)view
               error:(NSError *)error
onMoveNearCoordinate:(CLLocationCoordinate2D)coordinate
{
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self
                                                      delegate:self
                                                         title:@"Street View is not yet available for this location."
                                               buttonTextArray:@[@"OK"]
                                              destructiveIndex:0];
#pragma unused(alert)
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    [_viewDelegate panoramaView:self didReturnWithCoord:_pickedCoord];
}

- (void)panoramaView:(GMSPanoramaView *)panoramaView
              didTap:(CGPoint)point
{
    GMSOrientation ofp = [panoramaView orientationForPoint:point];
    double heading = ofp.heading;
    double pitch = ofp.pitch;
    double distanceInFeet = 0.0;
    
    if (pitch < 0.0)
    {
        pitch = -pitch;
        pitch *= DEGtoRAD;
        distanceInFeet = (9.25 / tan(pitch));
        _pickedCoord = locationWithBearing(heading, distanceInFeet, panoramaView.panorama.coordinate);
        _marker.panoramaView = nil;
        _marker = [GMSMarker markerWithPosition:_pickedCoord];
        _marker.panoramaView = panoramaView;
    }
}

@end
