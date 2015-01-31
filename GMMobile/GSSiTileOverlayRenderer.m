//  GSSiTileOverlayRenderer.m
//  GMMobile

#import "GSSiTileOverlayRenderer.h"

@implementation GSSiTileOverlayRenderer

-(void)drawMapRect:(MKMapRect)mapRect
         zoomScale:(MKZoomScale)zoomScale
         inContext:(CGContextRef)context
{
    [super drawMapRect:mapRect
             zoomScale:zoomScale
             inContext:context];
    
    //this is where we query the tiles table to add custom drawing
    

 /*   CGRect rect = [self rectForMapRect:mapRect];
    
    MKTileOverlayPath path;
    MKTileOverlay *tileOverlay = (MKTileOverlay *)self.overlay;
    path.x = (mapRect.origin.x * (zoomScale / tileOverlay.tileSize.width));
    path.y = (mapRect.origin.y * (zoomScale / tileOverlay.tileSize.width));
    path.z = (log2(zoomScale) + 20);
    
    CGContextSetStrokeColorWithColor(context, UIColor.blueColor.CGColor);
    CGContextSetLineWidth(context, 1.0 / zoomScale);
    CGContextStrokeRect(context, rect);
    
    UIGraphicsPushContext(context);
    NSString *text = [NSString stringWithFormat:@"X=%ld\nY=%ld\nZ=%ld",
                      (long)path.x,(long)path.y,(long)path.z];
    
    [text drawInRect:rect
      withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:(20.0 / zoomScale)],
                       NSForegroundColorAttributeName:UIColor.blueColor}];
    
    UIGraphicsPopContext();*/

}

@end