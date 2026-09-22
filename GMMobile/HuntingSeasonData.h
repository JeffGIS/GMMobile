//
//  HuntingSeasonData.h
//  NVMobile
//
//  Created by Jeff Smith on 10/6/25.
//  Copyright © 2025 GSSi. All rights reserved.
//

#ifndef HuntingSeasonData_h
#define HuntingSeasonData_h

typedef NS_ENUM(NSInteger, SpeciesType)
{
    Deer,
    Duck,
    Turkey,
    Grouse,
    Pheasant,
    Rabbit,
};

#import <Foundation/Foundation.h>
#import "CCodeLibrary/SQLiteLib.h"
#import "CCodeLibrary/CCodeLibrary.h"
#import "CCodeLibrary/WeatherData.h"

@interface BoundaryAreaData : NSObject

@property NSString *name;
@property int refno;

@end

@interface HuntingSeasonData : NSObject
@property sqlite3nv *database;
@property (atomic) BOOL isOpen;
@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *path;
@property NSInteger fileSize;
@property (nonatomic) int datasetVersion;
@property (nonatomic) SpeciesType *CurrentSpecies;
@property (nonatomic) long startHuntingDate, endHuntingDate;
@property (nonatomic) long startHuntingTime, endHuntingTime;
@property (nonatomic) NSString * label, *line1, *line2;


- (BOOL)open;
- (void)close:(BOOL)opened;
- (void)startTransaction;
- (void)commitTransaction;
- (BOOL)executeCmd:(char *)cmd;

- (void)updateInfo:(WeatherRecord *)weatherData;
- (void)setLabel:(UILabel *)label;

- (NSMutableArray *)getSeasonTypes;
- (NSMutableArray *)getSeasonDataForType:(NSString *)type;


@end
#endif /* HuntingSeasonData_h */
