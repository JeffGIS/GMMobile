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
    ShapeFileDisplay *sfd;
    NSString *fileName;
    NSString *shapeFile;
    
    if (CRAPI.sharedInstance.showPlats)
    {
        fileName = @"PDFBOUNDS.shp";
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
    else
    {
        dc.pointSymbol = CircleSym;

        if ([ConfigurationControl.sharedInstance layer:HCLayerSewers
                                         visibleAtZoom:_zoom
                                               andPass:_passID])
        {
            fileName = @"swGravityMain.shp";
            dc.elementType = StormMain;
            dc.penColor = UIColor.greenColor;
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
            
            fileName = @"swPressurePipe.shp";
            dc.elementType = StormPressurePipe;
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
            
            fileName = @"swManhole.shp";
            dc.elementType = StormManhole;
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
            
            fileName = @"ssGravityMain.shp";
            dc.elementType = SanitaryMain;
            dc.penColor = UIColor.blueColor;
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
            fileName = @"ssPressurizedMain.shp";
            dc.elementType = SanitaryPressurizedMain;
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
            fileName = @"ssManhole.shp";
            dc.elementType = SanitaryManhole;
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
        if ([ConfigurationControl.sharedInstance layer:HCLayerMapleGroveWater
                                         visibleAtZoom:_zoom
                                               andPass:_passID])
        {
            fileName = @"wMain.shp";
            dc.elementType = WaterMain;
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
            
            fileName = @"wHydrant.shp";
            dc.elementType = Hydrant;
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
            fileName = @"wMeter.shp";
            dc.elementType = WaterMeter;
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
        if ([ConfigurationControl.sharedInstance layer:HCLayerMapleGroveFiber
                                         visibleAtZoom:_zoom
                                               andPass:_passID])
        {
            fileName = @"MG_FiberLines.shp";
            dc.elementType = FiberLines;
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
            fileName = @"MG_FiberPoints.shp";
            dc.elementType = FiberPoints;
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
}
- (NSString *)pickPDFPlat:(LLPOINT *)pt
                platRefno:(int *)platRef
{
    int ref = 0;
    NSString * platID = @"";
    NSString *documentsDirectory = UserDefaults.defaults.sharedFilePath;
    NSString *outputDirectory = [NSString stringWithFormat:@"%@/MapleGrove", documentsDirectory];
    ShapeFileDisplay *sfd;
    NSString *fileName;
    NSString *shapeFile;
    NSMutableArray *hltList = [NSMutableArray new];
    
    if (CRAPI.sharedInstance.showPlats)
    {
        fileName = @"PDFBOUNDS.shp";
        shapeFile = [NSString stringWithFormat:@"%@/%@", outputDirectory,fileName];
        sfd = [ShapeFileDisplay createWithFile:shapeFile.UTF8String];
        if (sfd)
        {
            sfd.processingID = _processingID;
            hltList = [sfd pickPDFPlat:pt];
        }
    }
    if (hltList.count > 0)
    {
        PickedItem *pi = hltList[0];
        ref = (int)pi.refno;
        platID = pi.identifier;
    }
    *platRef = ref;
    return platID;
}


@end
