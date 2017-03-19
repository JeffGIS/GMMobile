//
//  ThemeClass.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/2/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import "ThemeClass.h"

@implementation ThemeClass

+ (ThemeClass *)createWithTitle:(NSString *)title
{
    ThemeClass *class = [[ThemeClass alloc] init];
    class.title = title;
    class.size = 1;
    return class;
}

- (void)setStatus:(int)status
{
    int ii;
    _status = status;
    if ([_title containsString:@"Burglary"])
        ii=status;
}

@end
