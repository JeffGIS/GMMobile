//  NVPanoramaVC.m
//  NVMobile

#import "NVPanoramaVC.h"
#import "CCodeLibrary/UserDefaults.h"
@import GoogleMaps;

@interface NVPanoramaVC () <GMSPanoramaViewDelegate>

@property (nonatomic, weak) id<NVPanoramaVCDelegate> delegate;
@property (nonatomic) GMSMarker *marker;
@property (nonatomic) GMSPanoramaView *panView;
@property CLLocationCoordinate2D pickedCoord, atCoord, lookingAtCoord;

@end

@implementation NVPanoramaVC

+ (BOOL)presentPanoramaInController:(UIViewController *)controller
                     lookingAtCoord:(CLLocationCoordinate2D)lookingAtCoord
                           delegate:(id<NVPanoramaVCDelegate>)delegate
{
    return [NVPanoramaVC presentPanoramaInController:controller
                                             atCoord:lookingAtCoord
                                      lookingAtCoord:lookingAtCoord
                                            delegate:delegate];
}

+ (BOOL)presentPanoramaInController:(UIViewController *)controller
                            atCoord:(CLLocationCoordinate2D)atCoord
                     lookingAtCoord:(CLLocationCoordinate2D)lookingAtCoord
                           delegate:(id<NVPanoramaVCDelegate>)delegate
{
    if (!delegate || !controller)
    {
        NSLog(@"NVPanoramaVC ERROR: Cannot set delegate or controller to nil.");
        return NO;
    }
    
    if (![delegate respondsToSelector:@selector(panoramaVC:didReturnWithCoord:)])
    {
        NSLog(@"NVPanoramaVC ERROR: Delegate must respond to all selectors in protocol.");
        return NO;
    }
    
    NVPanoramaVC *nvpvc = NVPanoramaVC.new;
    nvpvc.delegate = delegate;
    nvpvc.atCoord = atCoord;
    nvpvc.lookingAtCoord = lookingAtCoord;
    nvpvc.pickedCoord = CLLocationCoordinate2DMake(0.0, 0.0);
    nvpvc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [controller presentViewController:nvpvc animated:YES completion:nil];
    
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _panView = GMSPanoramaView.new;
    _panView.translatesAutoresizingMaskIntoConstraints = NO;
    _panView.delegate = self;
    
    [self.view addSubview:_panView];
    [_panView constrainToView:self.view leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    
    UIButton *dismissPan = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissPan.translatesAutoresizingMaskIntoConstraints = NO;
    dismissPan.backgroundColor = UIColor.clearColor;
    dismissPan.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        dismissPan.titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
    
    else
        dismissPan.titleLabel.font = [UIFont boldSystemFontOfSize:44.0];
    
    dismissPan.titleLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    dismissPan.titleLabel.layer.shadowOpacity = 1.0;
    dismissPan.titleLabel.layer.shadowRadius = 2.0;
    dismissPan.titleLabel.layer.shadowOffset = CGSizeZero;
    [dismissPan setTitle:@"< Return" forState:UIControlStateNormal];
    [dismissPan setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [dismissPan setTitleColor:UIColor.lightGrayColor forState:UIControlStateHighlighted];
    
    [self.view addSubview:dismissPan];
    [dismissPan constrainLeadingToAnchor:self.view.leadingAnchor constant:10.0];
    [dismissPan constrainTopToAnchor:self.view.topAnchor];
    
    [dismissPan addTarget:self
                   action:@selector(dismissPanTapped)
         forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_panView moveNearCoordinate:_atCoord radius:100];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)dismissPanTapped
{
    [_delegate panoramaVC:self didReturnWithCoord:_pickedCoord];
}

- (void)panoramaView:(GMSPanoramaView *)view
   didMoveToPanorama:(GMSPanorama *)panorama
      nearCoordinate:(CLLocationCoordinate2D)coordinate
{
    CLLocationDirection heading = getHeading(panorama.coordinate, _lookingAtCoord);
    
    view.camera = [GMSPanoramaCamera cameraWithHeading:heading
                                                 pitch:0.0
                                                  zoom:1.0
                                                   FOV:90.0];
    
    _marker = [GMSMarker markerWithPosition:_lookingAtCoord];
    _marker.panoramaView = view;
}

- (void)panoramaView:(GMSPanoramaView *)view
               error:(NSError *)error
onMoveNearCoordinate:(CLLocationCoordinate2D)coordinate
{
    [NVAlertView showLargeAlertViewinView:self.view
                                 delegate:self
                                    title:@"Street View is not yet available for this location."
                          buttonTextArray:@[@"OK"]
                         destructiveIndex:0];
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    [_delegate panoramaVC:self didReturnWithCoord:_pickedCoord];
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
