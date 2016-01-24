//
//  CrimeDataDisplay.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/3/15.
//  Copyright © 2015 GSSi. All rights reserved.
//
extern int keepProcessing;

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "ConfigurationControl.h"
#import "SymbolDictionary.h"
#import "Themes.h"

@interface CrimeDataDisplay : NSObject

@property CrimeMapMode mode;
@property NSString * choroplethTarget;
@property LPTRANDATA pTranLLtoView;
@property LPTRANDATA pTranViewtoLL;
@property int processingID;
@property int zoom;
@property int minUCR, maxUCR;

-(void)displayCrimePoints:(CGContextRef)context
   displayCharacteristics:(DisplayCharacteristics *)dc
                llCorners:(CORNERPOINTS *) latlonCornerPoints
                 LLBounds:(MNMXCORD *)platlonBounds
               viewBounds:(MNMXCORD *)pvbounds
                   themes:(Themes*)themes
              pointInArea:(PointInArea *)pia;


@end
