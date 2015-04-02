//  VectorView.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import <GoogleMaps/GoogleMaps.h>
#import "PickedItem.h"

#define DISPLAY_DATA_OPTION_NODISPLAY   0
#define DISPLAY_DATA_OPTION_DISPLAY     1
#define DISPLAY_DATA_OPTION_HIGHLIGHT   2
#define DISPLAY_DATA_OPTION_UNHIGHLIGHT 3

@class VectorView;

@protocol VectorViewDelegate <NSObject>

- (void)vectorViewDidComplete:(VectorView*)vectorView;

@end

@interface VectorView : UIView

@property (nonatomic, weak) id <VectorViewDelegate> delegate;

@property int displayDataOption;
@property int displayID;
@property PickedItem * pickedItem;
@property int ivv;
@property int zoom;
@property CORNERPOINTS latlonCornerPoints;
@property MNMXCORD latlonBounds;
@property MNMXCORD viewBounds;

- (void) setRegion:(GMSVisibleRegion)region;

@end