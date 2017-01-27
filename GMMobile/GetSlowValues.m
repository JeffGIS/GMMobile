//
//  GetSlowValues.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/3/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import "GetSlowValues.h"
#import "Destinations.h"
#import "PropertyData.h"
#import "BoundaryData.h"
#import "CCodeLibrary/PercentInArea.h"


@implementation SlowValues
@end

@implementation GetSlowValues
- (void)computeSlowValues:(int)propNum
                     dbid:(int)dbid
                  popover:(GSSiPopoverView*)popover
                aroundLatLon:(LLPOINT)latlon
                      totEMV:(int)totEMV
                     useDesc:(LPSTR) usedescIN
{
    SlowValues * slowVals = [[SlowValues alloc]init];
    _popover = popover;
    _popover.title = @"Computing Values From Map";
    [self computeValuesFromMap:slowVals dbid:propNum popover:popover aroundLatLon:latlon totEMV:totEMV useDesc:usedescIN];
    
    //add routes from property to destinations
    Destinations *dests = [[Destinations alloc]init];
    [dests addRoutesForProperty:propNum];
    
    if (_delegate)
        [_delegate getSlowValuesDidComplete:propNum values:slowVals];

}
- (void)computeValuesFromMap:(SlowValues *)values
                        dbid:(int)dbid
                     popover:(GSSiPopoverView*)popover
                aroundLatLon:(LLPOINT)latlon
                      totEMV:(int)totEMV
                     useDesc:(LPSTR) usedescIN
{
    return;
    Themes * themes = [[Themes alloc]init];
    void *bmData = NULL;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int width = 1024;
    int height = 1024;
    CGContextRef context = createBitmapContext(width, height, colorSpace, &bmData);
    DisplayCharacteristics *dc = DisplayCharacteristics.new;
    MNMXCORD latlonBounds;
    MNMXCORD viewBounds;
    double OneMile = 5280 * MFT;
    double dist = OneMile / 2;
    
    CORNERPOINTS latlonCornerPoints = CornerPointsFromPointAndDist (latlon,dist);
    latlonBounds = CornerPointBounds (&latlonCornerPoints);
    
    BoundaryData *bd = [[BoundaryData alloc] init];
    [bd displayLandUse:context
             llCorners:&latlonCornerPoints
              LLBounds:&latlonBounds
            viewBounds:&viewBounds
displayCharacteristics:dc
                themes:themes
           pointInArea:nil];

}

/*UIGraphicsBeginImageContext(size);
 _context = UIGraphicsGetCurrentContext();
 CGContextDrawLayerAtPoint(_context, CGPointMake(0, 0), vectorLayer);
 UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
 NSData * pngData = UIImagePNGRepresentation(image);
 [pngData writeToFile:CRAPI.sharedInstance.extractFile atomically:YES];*/

@end
