//
//  ThemeLegendCell.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/4/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThemeLegendCell : NSObject
@property int count;
@property float symbolWidth;
@property UIColor * symbolColor;
@property NSString * label;

+ (ThemeLegendCell*) createWithLabel:(NSString*)label;


@end
