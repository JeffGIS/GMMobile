//  VectorView.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "MapViewController.h"
@import GoogleMaps;

typedef NS_ENUM(NSInteger, DisplayDataOptions)
{
    DISPLAY_DATA_OPTION_NODISPLAY,
    DISPLAY_DATA_OPTION_DISPLAY,
    DISPLAY_DATA_OPTION_HIGHLIGHT,
    DISPLAY_DATA_OPTION_UNHIGHLIGHT,
    NumDisplayDataOptions
};

@class VectorView;

@protocol VectorViewDelegate <NSObject>

- (void)vectorViewDidComplete:(VectorView*)vectorView
                      pdfData:(NSData *)pdfData
                    reDisplay:(BOOL)reDisplay;

@end

@interface VectorView : UIView

@property (nonatomic, weak) id <VectorViewDelegate> delegate;

@property DisplayDataOptions displayDataOption;
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
@property GMSMapView * mapView;
@property UIImage *backgroundImage;
@property (weak)MapViewController *mvc;



- (void) setRegion:(GMSVisibleRegion)region;
- (void) vectorViewToPDF;

@end
