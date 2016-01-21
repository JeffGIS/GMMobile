//
//  ShapeFileDisplay.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/20/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "NVShapeFileLibrary/shapefil.h"
#import "SymbolDictionary.h"
#import "Themes.h"

@interface ShapeFileDisplay : NSObject

@property SHPHandle hSHP;
@property DBFHandle hDBF;


+ (ShapeFileDisplay *)createWithFile:(char*)shapeFile;
-(void)  display:(CGContextRef)context
displayCharacteristics:(DisplayCharacteristics *)dc
       llCorners:(CORNERPOINTS *) latlonCornerPoints
        LLBounds:(MNMXCORD *)platlonBounds
      viewBounds:(MNMXCORD *)pvbounds
          themes:(Themes*)themes
     pointInArea:(PointInArea *)pia;

@end
