//  ThemeLegendMapOverlay.m
//  GMMobile

#import "ThemeLegendMapOverlay.h"

@implementation ThemeLegendMapOverlay

+ (ThemeLegendMapOverlay *)drawLegend:(ThemeLegend *)legend
                               inView:(UIView *)view
{
    ThemeLegendMapOverlay *tlmo = [[ThemeLegendMapOverlay alloc] init];
    tlmo.frame = CGRectMake(568.0, 312.0, 180.0, 200.0);
    tlmo.backgroundColor = UIColor.whiteColor;
    [view addSubview:tlmo];
    
    return tlmo;
}

@end