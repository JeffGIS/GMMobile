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
@property ItemProcessingPassTypes passID;

-(void)displayLayers:(CGContextRef)context
   displayCharacteristics:(DisplayCharacteristics *)dc
                llCorners:(CORNERPOINTS *) latlonCornerPoints
                 LLBounds:(MNMXCORD *)platlonBounds
               viewBounds:(MNMXCORD *)pvbounds
                   themes:(Themes*)themes
              pointInArea:(PointInArea *)pia;
- (NSString *)pickPDFPlat:(LLPOINT *)pt
                platRefno:(int *)platRef;
- (int)pickLayers:(LLPOINT*)point highlightList:(NSMutableArray*)hlist;

@end
