//  ThemeLegendMapOverlay.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "ThemeLegend.h"

@interface ThemeLegendMapOverlay : UIView

+ (ThemeLegendMapOverlay *)drawLegend:(ThemeLegend *)legend
                               inView:(UIView *)view;

@end