//
//  ProximityMapping.h
//  NVMobile
//
//  Created by Jeff Smith on 9/29/23.
//  Copyright © 2023 GSSi. All rights reserved.
//

#ifndef ProximityMapping_h
#define ProximityMapping_h
#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"

@interface CellPointOffsets : NSObject
@property int xoff,yoff;
@property int dst;
@end

@interface ProximityMapping : NSObject<GSSiPopoverViewDelegate>

-(void) CreateCell;
-(int) CreateSurface;

@end
#endif /* ProximityMapping_h */
