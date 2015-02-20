//
//  PlanimetricData.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 2/19/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <sqlite3.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface PlanimetricData : NSObject
-(void)displayPlanArea:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;
-(void)displayPlanLine:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;
-(void)displayPlanPoint:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

@end
