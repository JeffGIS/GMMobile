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
#import "CCodeLibrary/SymbolDictionary.h"
#import "CCodeLibrary/NVColor.h"
#import "Themes.h"

@interface ShapeFileDisplay : NSObject

@property SHPHandle hSHP;
@property DBFHandle hDBF;
@property int processingID;
@property int zoom;
@property CGFloat sizeFactor;
@property CGFloat widthFactor;
@property NSString * fileName;
@property NSString * filePath;
@property NSString * documentsDirectory;
@property sqlite3 *database;
@property DisplayCharacteristics * dc;

+ (ShapeFileDisplay *)createWithFile:(const char*)shapeFile;
-(void)  display:(CGContextRef)context
displayCharacteristics:(DisplayCharacteristics *)dc
       llCorners:(CORNERPOINTS *) latlonCornerPoints
        LLBounds:(MNMXCORD *)platlonBounds
      viewBounds:(MNMXCORD *)pvbounds
          themes:(Themes*)themes
     pointInArea:(PointInArea *)pia;
- (NSMutableArray*)pickPDFPlat:(LLPOINT *)pt;

@end
