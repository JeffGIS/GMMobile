//
//  PickedItem.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 3/9/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

typedef NS_ENUM(NSInteger, PickItemTypes) {
    PTPid,
    PTStormSewerLine,
    PTStormSewerPoint,
    PTStormSewerPlat
};

@interface PickedItem : NSObject
@property int itemType;
@property int refno;
@property double distance;
@property NSString * identifier;
@property DPOINT pickedPoint;

+(PickedItem *) nearestPickedItem:(NSMutableArray*)highlightList;

@end
