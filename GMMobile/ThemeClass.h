//
//  ThemeClass.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/2/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThemeClass : NSObject

@property NSString* title;
@property double count;
@property int numItems;
@property double pctOfTotal;
@property double symbolWidth;
@property UIColor * color;

+ (ThemeClass*) createWithTitle:(NSString*)title;

@end
