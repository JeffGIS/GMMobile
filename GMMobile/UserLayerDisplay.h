//
//  UserLayerDisplay.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/20/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "ConfigurationControl.h"
#import "CCodeLibrary/SymbolDictionary.h"
#import "Themes.h"

@interface UserLayerDisplay : NSObject
@property int processingID;
@property int zoom;

-(void)displayLayers:(CGContextRef)context
   displayCharacteristics:(DisplayCharacteristics *)dc
                llCorners:(CORNERPOINTS *) latlonCornerPoints
                 LLBounds:(MNMXCORD *)platlonBounds
               viewBounds:(MNMXCORD *)pvbounds
                   themes:(Themes*)themes
              pointInArea:(PointInArea *)pia;


@end
