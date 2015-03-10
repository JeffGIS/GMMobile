//  PickedItem.m
//  GMMobile

#import "PickedItem.h"

@implementation PickedItem

+ (PickedItem *)nearestPickedItem:(NSMutableArray *)highlightList
{
    if (!highlightList.count)
        return nil;
    
    PickedItem * pi = (PickedItem *)highlightList[0];
    int mini = 0;
    double mind = pi.distance;
    
    for (int i = 1; i < highlightList.count; i++)
    {
        pi = (PickedItem *)highlightList[i];
        
        if (pi.distance < mind)
        {
            mind = pi.distance;
            mini = i;
        }
    }
    
    pi = (PickedItem *)highlightList[mini];
    return pi;
}

@end