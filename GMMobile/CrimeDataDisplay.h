//
//  CrimeDataDisplay.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/3/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "ConfigurationControl.h"
#import "CCodeLibrary/SymbolDictionary.h"
#import "CCodeLibrary/DispersePoint.h"
#import "Themes.h"
#import "MapViewController.h"
@import GoogleMaps;

@interface CrimeDataDisplay : NSObject <GSSiPopoverViewDelegate>

@property CrimeMapMode mode;
@property int numPass;
@property int saveFromDate;
@property NSString * choroplethTarget;
@property AdjustCrimeOptions choroplethAdjustValue;
@property NSString * choroplethAdjustArea;
@property LPTRANDATA pTranLLtoView;
@property LPTRANDATA pTranViewtoLL;
@property int *processingID;
@property id <GSSiPopoverViewDelegate> savePOdelegate;
@property CGFloat zoom;
@property int minUCR, maxUCR;
@property GMSMapView * mapView;
@property UIImage * backgroundImage;
@property (weak)MapViewController *mvc;
@property BOOL popoverDisplayed;
-(void)displayCrimePoints:(CGContextRef)context
          contextIsBitmap:(BOOL)isBitmap
   displayCharacteristics:(DisplayCharacteristics *)dc
                llCorners:(CORNERPOINTS *) latlonCornerPoints
                 LLBounds:(MNMXCORD *)platlonBounds
               viewBounds:(MNMXCORD *)pvbounds
                   themes:(Themes*)themes
              pointInArea:(PointInArea *)pia
                     pass:(int)pass;


@end
