//  ThemeLegendMapOverlay.h
//  GMMobile

@import UIKit;
#import "CCodeLibrary/NVAlertView.h"
#import "ThemeLegend.h"
#import "CCodeLibrary/NVColorSet.h"

@class ThemeLegendMapOverlay;

@protocol ThemeLegendMapOverlayDelegate <NSObject>

- (void)themeLegendDidChangeStatus:(BOOL)refreshVectorView;
- (void)themeLegendWasDraggedOffRightSide;
- (void)themeLegendWasDraggedOffLeftSide;

- (void)randomColorsSelectedWithOption:(NVColorOption)option
                        forThemeLegend:(ThemeLegendMapOverlay *)legend;

@end

@interface ThemeLegendMapOverlay : UIView <UITableViewDataSource,UITableViewDelegate,NVAlertViewDelegate,UIGestureRecognizerDelegate>

@property (weak, nonatomic) id <ThemeLegendMapOverlayDelegate> delegate;
@property (nonatomic) ThemeLegend *legend;
@property BOOL isExpanded;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) CGFloat rowHeight, width;
@property NSUInteger currentColorPalette;

+ (ThemeLegendMapOverlay *)drawLegend:(ThemeLegend *)legend
                              withTag:(NSInteger)tag
                             delegate:(id)delegate
                               inView:(UIView *)view
                             atOrigin:(CGPoint)origin
                               tabBar:(UITabBar *)tabBar;

- (void)displayRandomColorAlertInView:(UIView *)view;

@end