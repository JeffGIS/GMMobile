//
//  CreateBatchCrimeMaps.m
//  NVMobile
//
//  Created by Jeff Smith on 10/15/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import "CreateBatchCrimeMaps.h"
#import "CrimeDataDisplay.h"
#import "BoundaryData.h"

@implementation CreateBatchCrimeMaps
- (void)createImages:(NSString *)batchName
                     popover:(GSSiPopoverView*)popover

{
    DisplayCharacteristics *dc = DisplayCharacteristics.new;
    void *bmData = NULL;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int width = 1024*1;
    int height = 1024*4;
    CGContextRef context = createBitmapContext(width, height, colorSpace, &bmData);
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetShouldAntialias(context, YES);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    CGRect colorRect;
    colorRect.origin.x = 0;
    colorRect.origin.y = 0;
    colorRect.size.width = width;
    colorRect.size.height = height;
    UIColor *white = [UIColor whiteColor];
    CGContextSetFillColorWithColor(context,[white CGColor]);
    CGContextFillRect (context,colorRect);

    
    MNMXCORD viewBounds;
    
    viewBounds.xmn = 0;
    viewBounds.ymn = 0;
    viewBounds.xmx = width;
    viewBounds.ymx = height;
    
    NSString * tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/BatchCrimeMaps"];
    Themes * themes = [[Themes alloc]init];
    themes.displayID = 0;
    HardCodedConfigs saveConfig = ConfigurationControl.sharedInstance.currentApp;
    ConfigurationControl.sharedInstance.currentApp = HCConfigCrimes;
    [themes setAppThemes:tempDirectory
            outputFactor:1];

    long long refno = 51144;//[BoundaryData getBoundaryAreaRefnoForType:@"CITY" andName:@"Minneapolis"];
    BoundaryData * bd = BoundaryData.new;
    MNMXCORD areaBounds = [bd getBoundaryAreaBounds:refno
                                   ofType:@"BOUNDARY"];
    CORNERPOINTS latlonCornerPoints = CornerPointsFromLLBoundsAndView (&areaBounds,&viewBounds);
    MNMXCORD latlonBounds = CornerPointBounds (&latlonCornerPoints);
    CrimeDataDisplay *cd = [[CrimeDataDisplay alloc] init];
    cd.processingID = 0;
    cd.zoom = 0;
    cd.mode = PINMAP;
    cd.choroplethTarget = CRAPI.sharedInstance.crimeTarget;
    cd.choroplethAdjustValue = ConfigurationControl.sharedInstance.adjustCrimeOption;
    cd.choroplethAdjustArea = ConfigurationControl.sharedInstance.adjustCrimeArea;
    int passID = [themes themesNeedDataPass:0];
    while (passID < DonePass)
    {
        if (passID == DataPass)
            [themes themesBeginDataPass:0];
        else if (passID == DisplayPass)
            [themes themesBeginDisplayPass:0];
        [cd displayCrimePoints:context
        displayCharacteristics:dc
                     llCorners:&latlonCornerPoints
                      LLBounds:&latlonBounds
                    viewBounds:MNMXCORD_view(&viewBounds)
                        themes:themes
                   pointInArea:nil
                          pass:passID++];
    }
    if (CRAPI.sharedInstance.currentOverallBoundaryRefno &&
        (CRAPI.sharedInstance.showPolylineForBounds ||
         CRAPI.sharedInstance.maskBoundsForBounds))
    {
        BoundaryData *bd = [[BoundaryData alloc] init];
        
        [bd displayBoundary:CRAPI.sharedInstance.currentOverallBoundaryRefno
                     ofType:@"BOUNDARY"
                     asMask:CRAPI.sharedInstance.maskBoundsForBounds
                  inContext:context
                  llCorners:&latlonCornerPoints
                   LLBounds:&latlonBounds
                 viewBounds:&viewBounds];
    }
    [themes themesEndDisplayPass:0];
    if (context)
        CGContextRelease(context);
    NSString * file = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.bmp"];
    BOOL rtn = WriteBitmapDataToFile ((LPSTR)file.UTF8String,width, height, colorSpace, bmData);

    long long fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:file
                                                                        error:nil].fileSize;
    UIImage *image = [UIImage imageWithContentsOfFile:file];
    file = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.png"];
    [UIImagePNGRepresentation(image) writeToFile:file atomically:YES];
    
    fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:file
                                                               error:nil].fileSize;
    
    CGColorSpaceRelease(colorSpace);
    if (bmData)
        free (bmData);
    ConfigurationControl.sharedInstance.currentApp = saveConfig;
    for (Theme *thm in themes.themeList)
    {
        [thm.legend writeThemeLegendToFile];
    }
    
   // uploadToCloud(file, YES);

}

@end
