//
//  HuntingDataDisplay.m
//  NVMobile
//
//  Created by Jeff Smith on 11/23/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import "HuntingDataDisplay.h"
#import "ShapeFileDisplay.h"

@implementation HuntingDataDisplay


-(void)  displayLayers:(CGContextRef)context
displayCharacteristics:(DisplayCharacteristics *)dc
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds
                themes:(Themes*)themes
           pointInArea:(PointInArea *)pia
{
    NSString *documentsDirectory = UserDefaults.defaults.sharedFilePath;
    NSString *outputDirectory = [NSString stringWithFormat:@"%@/Hunting", documentsDirectory];
    ShapeFileDisplay *sfd;
    NSString *fileName;
    NSString *shapeFile;
    
    //if (CRAPI.sharedInstance.showPlats)
    {
        fileName = @"Carlton_County.shp";
        dc.elementType = PDFBounds;
        shapeFile = [NSString stringWithFormat:@"%@/%@", outputDirectory,fileName];
        sfd = [ShapeFileDisplay createWithFile:shapeFile.UTF8String];
        if (sfd)
        {
            sfd.zoom = _zoom;
            sfd.processingID = _processingID;
            [sfd display:context
  displayCharacteristics:dc
               llCorners:latlonCornerPoints
                LLBounds:platlonBounds
              viewBounds:pvbounds
                  themes:themes
             pointInArea:pia];
        }
    }

}
@end
