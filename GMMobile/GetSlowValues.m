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

@interface GetSlowValues ()
@property BoundaryData * bd;
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
    [self computeValuesFromMap:slowVals
                          dbid:propNum
                       popover:popover
                  aroundLatLon:latlon
                        totEMV:totEMV
                       useDesc:usedescIN];
    
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
    CGContextSetAllowsAntialiasing(context, NO);
    CGContextSetShouldAntialias(context, NO);

    DisplayCharacteristics *dc = DisplayCharacteristics.new;
    MNMXCORD latlonBounds;
    MNMXCORD viewBounds;
    double OneMile = 5280 * FTM;
    double radius = OneMile / 2;
    
    viewBounds.xmn = 0;
    viewBounds.ymn = height;
    viewBounds.xmx = width;
    viewBounds.ymx = 0;
    CORNERPOINTS latlonCornerPoints = CornerPointsFromLatLonAndDist (latlon,radius);
    latlonBounds = CornerPointBounds (&latlonCornerPoints);
    
    Themes * themes = [[Themes alloc]init];
    themes.displayID = CRAPI.sharedInstance.keepProcessing;
    ConfigurationControl.sharedInstance.currentApp = HCConfigFromSlowValues;
    [themes setAppThemes];

    Theme * theme = themes.themeList[0];
    COLORREF_RGB4 *wantColors;
    int *colorCounts;
    
//    _maxColors = [self getColorsFromTheme:theme colors:&wantColors];
    _maxColors =  getColorsFromTheme2(context,theme,width,height,bmData,&wantColors);

    colorCounts = calloc ((_maxColors+1),sizeof(int));
    
    dc.width = 0;
    _bd = [[BoundaryData alloc] init];
    
    [self        displayMapit:context
                    baseLayer:MBL_LandUse
       displayCharacteristics:dc
                    llCorners:&latlonCornerPoints
                     LLBounds:&latlonBounds
                   viewBounds:&viewBounds
                       themes:themes
                  pointInArea:nil];
    
    
    {
        [_bd displayCircularBoundaryAt:latlon
                           withRadius:radius
                            lineWidth:0
                               asMask:1
                            inContext:context
                            llCorners:&latlonCornerPoints
                             LLBounds:&latlonBounds
                           viewBounds:&viewBounds];
        
    }
/*    else
    {
        [bd displayBoundary:ConfigurationControl.sharedInstance.MapitBoundaryRefno
                     ofType:ConfigurationControl.sharedInstance.MapitBoundaryType
                     asMask:1
                  inContext:context
                  llCorners:&latlonCornerPoints
                   LLBounds:&latlonBounds
                 viewBounds:&viewBounds];
        
    }*/
    
    COLORREF_RGB4 * pColor = (COLORREF_RGB4*)bmData;
    for (int irow = 0;irow < height;irow++)
        for (int icol = 0;icol < width;icol++)
        {
            [self countColors:pColor++
            wantColors:wantColors
             counts:colorCounts];
        }
    double totPct=0;
    for (int i=0;i<_maxColors;i++)
    {
        int c = colorCounts[i];
        double pct = (double)(c * 100)/(width*height);
        totPct += pct;
    }
    if (context)
        CGContextRelease(context);
/*     NSString * file = CRAPI.sharedInstance.extractFile;
    BOOL rtn = WriteBitmapDataToFile ((LPSTR)file.UTF8String,width, height, colorSpace, bmData);
    if (rtn)
        NSLog(@"Image written");
    UIImage *image = [UIImage imageWithContentsOfFile:file];
    UIImageWriteToSavedPhotosAlbum(image,
                                   nil,
                                   nil,
                                   nil);
*/
    CGColorSpaceRelease(colorSpace);
    if (bmData)
        free (bmData);
}

- (int) getColorsFromTheme:(Theme*)theme
                    colors:(COLORREF_RGB4**)pclrs
{
    int nColors = theme.numClasses;
    COLORREF_RGB4 * pColors = malloc ((nColors+1)*sizeof(COLORREF_RGB4));
    ThemeLegend * legend = theme.legend;
    for (int i=0;i<nColors;i++)
    {
        CGFloat R,G,B,Alpha;
        ThemeLegendCell *cell = legend.cells[i];
        UIColor *color = cell.symbolColor;
        [color getRed:&R green:&G blue:&B alpha:&Alpha];
        pColors[i].cRed = R*255;
        pColors[i].cGreen = G*255;
        pColors[i].cBlue = B*255;
        pColors[i].cIntensity = Alpha*255;
        
    }
    *pclrs = pColors;
    
    return nColors;
}

int getColorsFromTheme2(CGContextRef context,Theme* theme,int width,int height,void *bmData,COLORREF_RGB4** pclrs)
{
    COLORREF_RGB4 * pColor = (COLORREF_RGB4 *)bmData;
    CGRect colorRect;
    colorRect.origin.x = 0;
    colorRect.origin.y = 0;
    colorRect.size.width = width;
    colorRect.size.height = height;

    int nColors = theme.numClasses;
    COLORREF_RGB4 * pColors = malloc ((nColors+1)*sizeof(COLORREF_RGB4));
    ThemeLegend * legend = theme.legend;
    for (int i=0;i<nColors;i++)
    {
        CGFloat R,G,B,Alpha;
        ThemeLegendCell *cell = legend.cells[i];
        UIColor *color = cell.symbolColor;
        CGColorRef colorRef =[color CGColor];
        CGContextSetFillColorWithColor(context,colorRef);
        CGContextFillRect (context,colorRect);
        [color getRed:&R green:&G blue:&B alpha:&Alpha];
        pColors[i].cRed = pColor->cRed;
        pColors[i].cGreen = pColor->cGreen;
        pColors[i].cBlue = pColor->cBlue;
        pColors[i].cIntensity = pColor->cIntensity;
        
    }
    *pclrs = pColors;
    
    return nColors;
}

- (void) countColors:(COLORREF_RGB4*)color
          wantColors:(COLORREF_RGB4*)wantColors
              counts:(LPINT)colorCounts
{
    int r = color->cRed;
    int g = color->cGreen;
    int b = color->cBlue;
    int a;
    if (g != 255)
    {
        for (int j = 0;j<_maxColors;j++)
        {
            r = wantColors[j].cRed;
            g = wantColors[j].cGreen;
            b = wantColors[j].cBlue;
            a = wantColors[j].cIntensity;
        }
    }
    for (int i=0;i<_maxColors;i++)
    {
        if (*(LPINT)color == *(LPINT)&wantColors[i])
        {
            colorCounts[i]++;
            return;
        }
        if (color->cRed == wantColors[i].cRed &&
            color->cGreen == wantColors[i].cGreen &&
            color->cBlue == wantColors[i].cBlue)
        {
            colorCounts[i]++;
            return;
        }
    }
    colorCounts[_maxColors]++;
    return;
}
- (BOOL) createColorByIDTable
{
    BOOL rtn = FALSE;
    
    NSString * cmd = @"DROP TABLE IF EXISTS COLORBYID;CREATE TEMP TABLE COLORBYID (ID INTEGER PRIMARY KEY,SOURCEKEY CHAR(32));";
    rtn = [_bd executeCmd:(LPSTR)cmd.UTF8String];
    [_bd startTransaction];
    return rtn;
}

-(void)   displayMapit:(CGContextRef)context
             baseLayer:(MapitBaseLayer)baseLayer
displayCharacteristics:(DisplayCharacteristics *)dc
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvBounds
                themes:(Themes*)themes
           pointInArea:(PointInArea *)pia
{
    
    switch (baseLayer)
    {
        case MBL_LandUse:
        {
            [_bd displayLandUse:context
                     llCorners:latlonCornerPoints
                      LLBounds:platlonBounds
                    viewBounds:pvBounds
        displayCharacteristics:dc
                        themes:themes
                   pointInArea:pia];
        }
            break;
            
        case MBL_CensusTracts:
        {
            [_bd displayCensusAreas:context
                              type:@"TRACTS"
            displayCharacteristics:dc
                     llCorners:latlonCornerPoints
                      LLBounds:platlonBounds
                    viewBounds:pvBounds
                        themes:themes
                   pointInArea:pia];
        }
            break;
            
    }
}


//[PropertyList getRadiusForField:ifield];
@end
