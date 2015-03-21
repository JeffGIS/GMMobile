//
//  PlatProfileView.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 3/20/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "PlatProfileView.h"

@implementation PlatProfileView
{
    CGImageRef _imageRef;
    int _profileX, _profileMinY, _profileMaxY;
    CGRect _imageRect;
    CGFloat _scale;
    int _imageWidth, _imageHeight;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = UIColor.clearColor;
    }
    
    return self;
}

-(void)zoomImage:(UIImage*)image atX:(int)imageX fromMinY:(int)minY toMaxY:(int)maxY
{
    _imageWidth = (int)CGImageGetWidth(image.CGImage);
    _imageHeight = (int)CGImageGetHeight(image.CGImage);
    
    _imageRef = CGImageRetain(image.CGImage);
    _profileX = imageX;
    _profileMinY = minY;
    _profileMaxY = maxY;
    CGFloat scale = (maxY - minY) / self.frame.size.height;
    _imageRect.origin.x = imageX - scale * (self.frame.size.width / 2);
    _imageRect.origin.y = _imageHeight - maxY;
    _imageRect.size.width = self.frame.size.width * scale;
    _imageRect.size.height = self.frame.size.height * scale;
    _scale = scale;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect) || CGRectIsInfinite(rect))
        return;
    
    if (!_imageRef)
        return;
    CGImageRef image2 = CGImageCreateWithImageInRect(_imageRef, _imageRect);
    CGContextSaveGState(context);
    
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -rect.size.height);
    int imageWidth = (int)CGImageGetWidth(image2);
    int imageHeight = (int)CGImageGetHeight(image2);
   
    CGContextDrawImage(context, rect, image2);
    CGImageRelease(_imageRef);
    CGImageRelease (image2);
    CGContextRestoreGState(context);
    _imageRef = NULL;
}


@end
