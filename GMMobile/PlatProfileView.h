//  PlatProfileView.h
//  GMMobile

#import <UIKit/UIKit.h>

@interface PlatProfileView : UIView

@property UIImage * image;

-(void)zoomImage:(UIImage *)image
             atX:(NSInteger)imageX
        fromMinY:(NSInteger)minY
          toMaxY:(NSInteger)maxY;

@end