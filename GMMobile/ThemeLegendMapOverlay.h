//  ThemeLegendMapOverlay.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "ThemeLegend.h"

@class ThemeLegendMapOverlay;

@protocol ThemeLegendMapOverlayDelegate <NSObject>

- (void)themeLegendDidChangeStatus;

@end

@interface ThemeLegendMapOverlay : UIView <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) id <ThemeLegendMapOverlayDelegate> delegate;
@property (nonatomic) ThemeLegend *legend;

+ (ThemeLegendMapOverlay *)drawLegend:(ThemeLegend *)legend
                              withTag:(NSInteger)tag
                             delegate:(id)delegate
                               inView:(UIView *)view
                             atOrigin:(CGPoint)origin
                               tabBar:(UITabBar *)tabBar;

@end