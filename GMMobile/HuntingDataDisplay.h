//
//  HuntingDataDisplay.h
//  NVMobile
//
//  Created by Jeff Smith on 11/23/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "ConfigurationControl.h"
#import "CCodeLibrary/SymbolDictionary.h"
#import "HuntingData.h"
#import "Themes.h"

@interface HuntingDataDisplay : NSObject

@property int processingID;
@property int zoom;
@property ItemProcessingPassTypes passID;

-(void)displayLayers:(CGContextRef)context
displayCharacteristics:(DisplayCharacteristics *)dc
           llCorners:(CORNERPOINTS *) latlonCornerPoints
            LLBounds:(MNMXCORD *)platlonBounds
          viewBounds:(MNMXCORD *)pvbounds
              themes:(Themes*)themes
         pointInArea:(PointInArea *)pia;

+(CGColorRef) WMAColor;
+(CGColorRef) WPAColor;
+(CGColorRef) NWRColor;
+(CGColorRef) FSAColor;
+(CGColorRef) WalkInColor;
+(CGColorRef) LAKESColor;

@end
