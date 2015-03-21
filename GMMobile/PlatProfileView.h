//
//  PlatProfileView.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 3/20/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlatProfileView : UIView

@property UIImage * image;

-(void)zoomImage:(UIImage*)image atX:(int)imageX fromMinY:(int)minY toMaxY:(int)maxY;

@end
