//  MarkerButton.m
//  GMMobile

#import "MarkerButton.h"

@implementation MarkerButton

+ (MarkerButton *)markerWithPosition:(CLLocationCoordinate2D)position
                                view:(UIView *)view
                                 map:(GMSMapView *)map
                     statusBarHeight:(CGFloat)statusBarHeight
                            delegate:(id)delegate
{
    MarkerButton *marker = [[MarkerButton alloc] init];
    
    CGFloat size = 38.0;
    
    marker.frame = CGRectMake(0.0, 0.0, size, size);
    marker.position = position;
    marker.delegate = delegate;
        
    CGPoint target = [map.projection pointForCoordinate:position];
    
    marker.center = CGPointMake(target.x, ((target.y + statusBarHeight) - (marker.frame.size.height / 2.0)));
    [view addSubview:marker];
    
    [marker setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"marker"
                                                                                    ofType:@"png"]]
            forState:UIControlStateNormal];
    
    [marker addTarget:marker
               action:@selector(markerButtonTapped:)
     forControlEvents:UIControlEventTouchUpInside];
    
    return marker;
}

- (void)markerButtonTapped:(MarkerButton *)marker
{
    if (_delegate)
        [_delegate markerButtonWasTapped:self];
}

@end