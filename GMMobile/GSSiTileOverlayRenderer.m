//  GSSiTileOverlayRenderer.m
//  GMMobile

#import "GSSiTileOverlayRenderer.h"
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@implementation GSSiTileOverlayRenderer

-(void)drawMapRect:(MKMapRect)mapRect
         zoomScale:(MKZoomScale)zoomScale
         inContext:(CGContextRef)context
{
    [super drawMapRect:mapRect
             zoomScale:zoomScale
             inContext:context];

    if (CRAPI.sharedInstance.showTileInfo)
    {
        CGRect rect = [self rectForMapRect:mapRect];
        
        MKTileOverlayPath path;
        MKTileOverlay *tileOverlay = (MKTileOverlay *)self.overlay;
        path.x = (mapRect.origin.x * (zoomScale / tileOverlay.tileSize.width));
        path.y = (mapRect.origin.y * (zoomScale / tileOverlay.tileSize.width));
        path.z = (log2(zoomScale) + 20);
        
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor.CGColor);
        CGContextSetLineWidth(context, 13.0 / zoomScale);
        CGContextStrokeRect(context, rect);
        CGContextSetStrokeColorWithColor(context, UIColor.yellowColor.CGColor);
        CGContextSetLineWidth(context, 7.0 / zoomScale);
        CGContextStrokeRect(context, rect);
        
        UIGraphicsPushContext(context);
        NSString *text = [NSString stringWithFormat:@"X=%ld\nY=%ld\nZ=%ld",
                          (long)path.x,(long)path.y,(long)path.z];
        
        [text drawInRect:rect
          withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:(40.0 / zoomScale)],
                           NSForegroundColorAttributeName:UIColor.blackColor}];
        [text drawInRect:rect
          withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:(40.0 / zoomScale)],
                           NSForegroundColorAttributeName:UIColor.yellowColor}];
        
        UIGraphicsPopContext();
    }
}

@end