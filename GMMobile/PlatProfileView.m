//  PlatProfileView.m
//  GMMobile

#import "PlatProfileView.h"

@interface PlatProfileView ()

@property (nonatomic) CGImageRef imageRef;
@property (nonatomic) NSInteger profileX, profileMinY, profileMaxY;
@property (nonatomic) CGRect imageRect;
@property (nonatomic) CGFloat scale;
@property (nonatomic) NSInteger imageWidth, imageHeight;

@end

@implementation PlatProfileView

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

- (void)zoomImage:(UIImage *)image
              atX:(NSInteger)imageX
         fromMinY:(NSInteger)minY
           toMaxY:(NSInteger)maxY
{
    _imageWidth = (NSInteger)CGImageGetWidth(image.CGImage);
    _imageHeight = (NSInteger)CGImageGetHeight(image.CGImage);
    
    _imageRef = CGImageRetain(image.CGImage);
    _profileX = imageX;
    _profileMinY = minY;
    _profileMaxY = maxY;
    CGFloat scale = ((maxY - minY) / self.frame.size.height);
    _imageRect.origin.x = (imageX - (scale * (self.frame.size.width / 2.0)));
    _imageRect.origin.y = (_imageHeight - maxY);
    _imageRect.size.width = (self.frame.size.width * scale);
    _imageRect.size.height = (self.frame.size.height * scale);
    _scale = scale;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect) || CGRectIsInfinite(rect))
        return;
    
    if (!_imageRef)
        return;
    
    CGImageRef image2 = CGImageCreateWithImageInRect(_imageRef, _imageRect);
    CGContextSaveGState(context);
    
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -rect.size.height);
    //NSInteger imageWidth = (int)CGImageGetWidth(image2);
    //NSInteger imageHeight = (int)CGImageGetHeight(image2);
   
    CGContextDrawImage(context, rect, image2);
    CGImageRelease(_imageRef);
    CGImageRelease (image2);
    CGContextRestoreGState(context);
    _imageRef = NULL;
}

@end