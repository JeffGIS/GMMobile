//  PlatImageView.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import <GoogleMaps/GoogleMaps.h>

@interface PlatImageView : UIImageView

+ (PlatImageView *)platImageViewWithImage:(UIImage *)image
                                 delegate:(id)delegate;

@end