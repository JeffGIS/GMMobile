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
    
    viewBounds.xmn = 0;
    viewBounds.ymn = 0;
    viewBounds.xmx = width;
    viewBounds.ymx = height;
    CORNERPOINTS latlonCornerPoints = CornerPointsFromPointAndDist (latlon,dist);
    latlonBounds = CornerPointBounds (&latlonCornerPoints);
    
    Themes * themes = [[Themes alloc]init];
    themes.displayID = CRAPI.sharedInstance.keepProcessing;
    ConfigurationControl.sharedInstance.currentApp = HCConfigFromSpreadsheet;
    [themes setAppThemes];
    
    [self        displayMapit:context
       displayCharacteristics:dc
                    llCorners:&latlonCornerPoints
                     LLBounds:&latlonBounds
                   viewBounds:&viewBounds
                       themes:themes
                  pointInArea:nil];
    
    BoundaryData *bd = [[BoundaryData alloc] init];
    
    if (ConfigurationControl.sharedInstance.MapitBoundaryOpt == MAPIT_CIRCULAR)
    {
        [bd displayCircularBoundaryAt:ConfigurationControl.sharedInstance.MapitTargetCenterPoint
                           withRadius:ConfigurationControl.sharedInstance.MapitCirularBoundaryRadiusInMiles*METERS_PER_MILE
                               asMask:1
                            inContext:context
                            llCorners:&latlonCornerPoints
                             LLBounds:&latlonBounds
                           viewBounds:&viewBounds];
        
    }
    else
    {
        [bd displayBoundary:ConfigurationControl.sharedInstance.MapitBoundaryRefno
                     ofType:ConfigurationControl.sharedInstance.MapitBoundaryType
                     asMask:1
                  inContext:context
                  llCorners:&latlonCornerPoints
                   LLBounds:&latlonBounds
                 viewBounds:&viewBounds];
        
    }
    NSString * file = CRAPI.sharedInstance.extractFile;
    {
        LPBYTE pbuf = bmData;
        int ii;
        for (int i=0;i<4*width*height;i++)
        {
            if (pbuf[i])
                ii=pbuf[i];
        }
    }
    if (context)
        CGContextRelease(context);
    BOOL rtn = WriteBitmapDataToFile ((LPSTR)file.UTF8String,width, height, colorSpace, bmData);
    if (rtn)
        NSLog(@"Image written");
    CGColorSpaceRelease(colorSpace);
    if (bmData)
        free (bmData);
    UIImage *image = [UIImage imageWithContentsOfFile:file];
    UIImageWriteToSavedPhotosAlbum(image,
                                   nil,
                                   nil,
                                   nil);

    /*UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    NSData * pngData = UIImagePNGRepresentation(image);
    [pngData writeToFile:CRAPI.sharedInstance.extractFile atomically:YES];*/
  
}

-(void)   displayMapit:(CGContextRef)context
displayCharacteristics:(DisplayCharacteristics *)dc
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvBounds
                themes:(Themes*)themes
           pointInArea:(PointInArea *)pia
{
    
        BoundaryData *bd = [[BoundaryData alloc] init];
        [bd displayLandUse:context
                 llCorners:latlonCornerPoints
                  LLBounds:platlonBounds
                viewBounds:pvBounds
    displayCharacteristics:dc
                    themes:themes
               pointInArea:pia];
        
    
}


//[PropertyList getRadiusForField:ifield];
@end
