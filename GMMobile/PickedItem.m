//
//  PickedItem.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 3/9/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "PickedItem.h"

@implementation PickedItem

+(PickedItem *) nearestPickedItem:(NSMutableArray*)highlightList
{
    if (!highlightList.count)
        return nil;
    PickedItem * pi = (PickedItem*)highlightList[0];
    int mini = 0;
    double mind = pi.distance;
    
    for (int i=1;i<highlightList.count;i++)
    {
        pi = (PickedItem*)highlightList[i];
        if (pi.distance < mind)
        {
            mind = pi.distance;
            mini = i;
        }
    }
    pi = (PickedItem*)highlightList[mini];
    return pi;
}


@end
