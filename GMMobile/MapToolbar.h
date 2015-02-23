//  MapToolbar.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@class MapToolbar;

@protocol MapToolbarDelegate <NSObject>

- (void)mapToolbarDidSelectUserLocation;
- (void)mapToolbarDidSelectZoomExtent;
- (void)mapToolbarDidSelectMapType:(NSInteger)mapType;
- (void)mapToolbarDidSelectSplitScreenSetting:(NSInteger)setting;
- (void)mapToolbarDidSelectAnnotationOption:(BOOL)option;

@end

@interface MapToolbar : UIView

@property (nonatomic, weak) id <MapToolbarDelegate> delegate;

- (id)initWithView:(UIView *)view;

@end