//
//  PlatView.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 2/16/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "PlatView.h"

@implementation PlatView

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGImageRef image;
    
 /*   if (_displayData && _zoom >= CRAPI.sharedInstance.parcelsVisibleAtZoom)
    {
        PropertyData *pd = [[PropertyData alloc] init];
        _viewBounds.xmn = self.bounds.origin.x;
        _viewBounds.xmx = (self.bounds.origin.x + self.bounds.size.width);
        _viewBounds.ymn = (self.bounds.origin.y + self.bounds.size.height);
        _viewBounds.ymx = self.bounds.origin.y;
        
        [pd displayParcels:context
                  LLBounds:&_latlonBounds
                viewBounds:&_viewBounds];
        
        [pd displayParcelText:context
                     LLBounds:&_latlonBounds
                   viewBounds:&_viewBounds];
    }*/
    CGContextDrawImage(context, rect, image);
    
}


@end
