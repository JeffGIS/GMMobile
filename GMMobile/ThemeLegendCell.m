//
//  ThemeLegendCell.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/4/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import "ThemeLegendCell.h"

@implementation ThemeLegendCell

+ (ThemeLegendCell*) createWithLabel:(NSString*)label
{
    ThemeLegendCell *class = [[ThemeLegendCell alloc]init];
    class.label = label;
    return class;
}

-(id) copyWithZone: (NSZone *) zone
{
    ThemeLegendCell *another = [[ThemeLegendCell allocWithZone: zone] init];
    
    another.count = _count;
    another.symbolWidth = _symbolWidth;
    another.symbolColor = [[UIColor alloc]initWithCGColor:_symbolColor.CGColor];
    another.label = [NSString stringWithString:_label];
    return  another;
}

@end
