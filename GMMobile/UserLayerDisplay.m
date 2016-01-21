//
//  UserLayerDisplay.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/20/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import "UserLayerDisplay.h"
#import "ShapeFileDisplay.h"

@implementation UserLayerDisplay

-(void)  displayLayers:(CGContextRef)context
displayCharacteristics:(DisplayCharacteristics *)dc
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
                themes:(Themes*)themes
           pointInArea:(PointInArea *)pia
{
    NSString *documentsDirectory = UserDefaults.defaults.sharedFilePath;
    NSString *outputDirectory = [NSString stringWithFormat:@"%@/MapleGrove", documentsDirectory];
    NSString *fileName = @"wMain.shp";
    NSString *shapeFile = [NSString stringWithFormat:@"%@/%@", outputDirectory,fileName];
    ShapeFileDisplay *sfd = [ShapeFileDisplay createWithFile:shapeFile.UTF8String];
    if (sfd)
    {
        sfd.zoom = _zoom;
        [sfd display:context
displayCharacteristics:dc
           llCorners:latlonCornerPoints
            LLBounds:platlonBounds
          viewBounds:pvbounds
              themes:themes
         pointInArea:pia];
    }
    fileName = @"wHydrant.shp";
    shapeFile = [NSString stringWithFormat:@"%@/%@", outputDirectory,fileName];
    sfd = [ShapeFileDisplay createWithFile:shapeFile.UTF8String];
    if (sfd)
    {
        sfd.zoom = _zoom;
        [sfd display:context
displayCharacteristics:dc
           llCorners:latlonCornerPoints
            LLBounds:platlonBounds
          viewBounds:pvbounds
              themes:themes
         pointInArea:pia];
    }
}


@end
