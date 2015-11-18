//  ThemeLegendMapOverlay.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "ThemeLegend.h"

@class ThemeLegendMapOverlay;

@protocol ThemeLegendMapOverlayDelegate <NSObject>

- (void)themeLegendDidChangeStatus:(BOOL)refreshVectorView;

@end

@interface ThemeLegendMapOverlay : UIView <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) id <ThemeLegendMapOverlayDelegate> delegate;
@property (nonatomic) ThemeLegend *legend;
@property BOOL isExpanded, selectionMade;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) CGFloat rowHeight;

+ (ThemeLegendMapOverlay *)drawLegend:(ThemeLegend *)legend
                              withTag:(NSInteger)tag
                             delegate:(id)delegate
                               inView:(UIView *)view
                             atOrigin:(CGPoint)origin
                               tabBar:(UITabBar *)tabBar;

@end