//  PlatImageView.m
//  GMMobile

#import "PlatImageView.h"

@implementation PlatImageView

+ (PlatImageView *)platImageViewWithImage:(UIImage *)image
                                 delegate:(id)delegate
{
    PlatImageView *platView = [[PlatImageView alloc] init];
    platView.image = image;
    platView.contentMode = UIViewContentModeScaleAspectFit;
    platView.userInteractionEnabled = YES;
    return platView;
}

@end