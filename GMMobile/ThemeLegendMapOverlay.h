//  ThemeLegendMapOverlay.h
//  GMMobile

@import UIKit;
#import "CCodeLibrary/NVAlertView.h"
#import "ThemeLegend.h"
#import "CCodeLibrary/NVColorSet.h"

typedef NS_ENUM(NSInteger, ThemeLegendTitleOptions)
{
    TLTCancel,
    TLTSwitchMode,
    TLTOverlay,
    TLTBarChartOnly,
    TLTApplyExistingColors,
    TLTSelectColors,
    TLTTitles,
    TLTZoomToMax,
    TLTCount
};


@class ThemeLegendMapOverlay;

@protocol ThemeLegendMapOverlayDelegate <NSObject>

- (void)themeLegendDidChangeStatus:(BOOL)refreshVectorView;
- (void)themeLegendWasDraggedOffRightSide;
- (void)themeLegendWasDraggedOffLeftSide;
- (CGFloat)statusBarHeight:(UIInterfaceOrientation)orientation;
- (BOOL)themeLegendIsOffMap;

@optional
- (void)clearVectorView;
//- (void)themeLegendDidWantMinimize;
- (void)themeLegendWillExpand;
- (void)themeLegendDidShrink;
- (void)updateRightArrowVisibility:(BOOL)hidden;
- (void)updateLeftArrowVisibility:(BOOL)hidden;

- (void)randomColorsSelectedWithOption:(NVColorOption)option
                        forThemeLegend:(ThemeLegendMapOverlay *)legend;

- (void)zoomToBounds:(MNMXCORD)bounds;
@end

@interface ThemeLegendMapOverlay : UIView

@property (nonatomic) ThemeLegend *legend;
@property BOOL isExpanded;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) CGFloat rowHeight, width, headerHeight;
@property NSUInteger currentColorPalette;
@property (nonatomic) UIImageView *moveRightView, *moveLeftView;
@property CGFloat dragMargin;

+ (CGFloat)rowHeight;
+ (CGFloat)width;
+ (UIFont *)headerFont;

+ (ThemeLegendMapOverlay *)drawLegend:(ThemeLegend *)legend
                              withTag:(NSInteger)tag
                             delegate:(id)delegate
                               inView:(UIView *)view
                             atOrigin:(CGPoint)origin
                          hideButtons:(BOOL)hideButtons;

- (void)displayRandomColorAlertInView:(UIView *)view;
- (void)disableSelect;
- (void)disableMultipleSelect;

@end
