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
    BOOL rtn = WriteBitmapDataToFile ((LPSTR)file.UTF8String,width, height, colorSpace, bmData);
    if (rtn)
        NSLog(@"Image written");
    CGColorSpaceRelease(colorSpace);
    if (bmData)
        free (bmData);
    if (context)
        CGContextRelease(context);
    

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
/*UIGraphicsBeginImageContext(size);
 _context = UIGraphicsGetCurrentContext();
 CGContextDrawLayerAtPoint(_context, CGPointMake(0, 0), vectorLayer);
 UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
 NSData * pngData = UIImagePNGRepresentation(image);
 [pngData writeToFile:CRAPI.sharedInstance.extractFile atomically:YES];*/
BOOL WriteBitmapDataToFile (LPSTR file,int pixelsWide, int pixelsHigh, CGColorSpaceRef colorSpace, void *bmData)
{
    BOOL rtn = TRUE;
    BITMAPINFOHEADER bih;
    
    int bitmapByteCount = 0, bitmapBytesPerRow = 0;
    int nc = (int)CGColorSpaceGetNumberOfComponents(colorSpace);
    uint32_t flags = 0;
    if (nc > 1)
    {
        nc++;
        flags = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
        flags = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little;
        flags = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big;
    }
    bitmapBytesPerRow = nc * pixelsWide;
    bitmapByteCount = (bitmapBytesPerRow *pixelsHigh);
    
    bih.biHeight = pixelsHigh;
    bih.biWidth = pixelsWide;
    bih.biBitCount = nc*8;
    bih.biSizeImage = bitmapByteCount;
    bih.biSize = sizeof(BITMAPINFOHEADER);
    int ii = sizeof(BITMAPINFOHEADER);
    ii = sizeof(DWORD);
    ii = sizeof(WORD);
    ii = sizeof(LONG);
    bih.biPlanes = 1;
    bih.biCompression = BI_RGB;
    bih.biXPelsPerMeter = 0;
    bih.biYPelsPerMeter = 0;
    bih.biClrUsed = 0;
    bih.biClrImportant = 0;
    
    COLORREF_RGB rgb;
    rgb.cRed = 0;
    rgb.cGreen = 0;
    rgb.cBlue = 0;
    
    BITMAPFILEHEADER bfh;
    
    bfh.bfType = 0x4D42;
    bfh.bfReserved1 = 0;
    bfh.bfReserved2 = 0;
    bfh.bfOffBits = sizeof(BITMAPFILEHEADER) + bih.biSize;
    bfh.bfSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + bitmapByteCount;
    
    FILE *Fid = fopen(file,"wb");
    if (BigWrite(Fid ,(LPBYTE)&bfh ,sizeof(BITMAPFILEHEADER), -1) != sizeof(BITMAPFILEHEADER))
        rtn = FALSE;
    if (BigWrite(Fid ,(LPBYTE)&bih ,sizeof(BITMAPINFOHEADER), -1) != sizeof(BITMAPINFOHEADER))
        rtn = FALSE;
    if (BigWrite(Fid ,(LPBYTE)bmData ,bitmapByteCount, -1) != bitmapByteCount)
        rtn = FALSE;
    
    fclose (Fid);
    
    return rtn;
}

@end
