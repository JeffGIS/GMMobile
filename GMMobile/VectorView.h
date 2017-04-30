//  VectorView.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import <GoogleMaps/GoogleMaps.h>

#define DISPLAY_DATA_OPTION_NODISPLAY   0
#define DISPLAY_DATA_OPTION_DISPLAY     1
#define DISPLAY_DATA_OPTION_HIGHLIGHT   2
#define DISPLAY_DATA_OPTION_UNHIGHLIGHT 3

@class VectorView;

@protocol VectorViewDelegate <NSObject>

- (void)vectorViewDidComplete:(VectorView*)vectorView
                      pdfData:(NSData *)pdfData
                    reDisplay:(BOOL)reDisplay;

@end

@interface VectorView : UIView

@property (nonatomic, weak) id <VectorViewDelegate> delegate;

@property int displayDataOption;
@property int displayID;
@property PickedItem * pickedItem;
@property int ivv;
@property CGFloat zoom;
@property CORNERPOINTS latlonCornerPoints;
@property MNMXCORD latlonBounds;
@property MNMXCORD viewBounds;
@property CGLayerRef vectorLayer;
@property PointInArea *pia;
@property int pass;
@property BOOL redisplay;
@property NSMutableData * pdf;


- (void) setRegion:(GMSVisibleRegion)region;
- (void) vectorViewToPDF;

@end
