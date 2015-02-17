//
//  BoundaryData.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 2/17/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <sqlite3.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface BoundaryData : NSObject
-(void)displayBoundary:(int)refno
             inContext:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

@end
