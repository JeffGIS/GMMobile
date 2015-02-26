//  VectorView.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@class VectorView;

@protocol VectorViewDelegate <NSObject>

- (void)vectorViewDidComplete;

@end

@interface VectorView : UIView

@property (nonatomic, weak) id <VectorViewDelegate> delegate;

@property int displayData;
@property int displayID;
@property int zoom;
@property MNMXCORD latlonBounds;
@property MNMXCORD viewBounds;

@end