//
//  CrimeList.h
//  NVMobile
//
//  Created by Jeff Smith on 4/5/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"

typedef NS_ENUM(NSInteger, CrimeFieldType)
{
    CFT_ControlNum,
    CFT_CASENO,
    CFT_UCR,
    CFT_OffenseCodes,
    CFT_FromTime,
    CFT_ToTime,
    CFT_Address,
    CFT_NumSuspects,
    CFT_SearchString1,
    CFT_SearchString2,
    CFT_HEIGHT,
    CFT_SCORE,
    CFT_LatLon,
    CFT_END
};

@class CrimeList;

@protocol CrimeListDelegate <NSObject>

- (void)CrimeList:(CrimeList *)crimeList
        returnsValue:(NSString *)value
   forControlNumber:(NSInteger)controlNum
        andFieldType:(CrimeFieldType)type
          withStatus:(long)status;

@end

@interface CrimeList : NSObject <GSSiPopoverViewDelegate>
@property (nonatomic, weak) id <CrimeListDelegate> delegate;

@property NSString* crimeListDir;
@property (nonatomic) GSSiPopoverView *popover;
@property int crimeListVersion;

+ (NSArray *) getCrimeLists;
+ (NSString*) getCurrentCrimeListName;
+ (BOOL) renameCurrentCrimeList:(NSString *)newName;
+ (BOOL) deleteCurrentCrimeList;
+ (BOOL) setCurrentCrimeList:(NSString *)crimeList;
+ (NSString *) createNewCrimeList;

- (BOOL)open;
- (void)close:(BOOL)opened;
- (void)startTransaction;
- (void)commitTransaction;

- (NSArray *)getControlNumbers;
- (NSArray *)availableCrimeFields;
- (NSString *)crimeFieldName:(CrimeFieldType)fieldType;

- (void) getCrimeFieldValueOfType:(CrimeFieldType)type
                   forControlNumber:(NSInteger)controlNum;

- (LLPOINT)getCrimeLatLon:(NSInteger)controlNum;

- (NSString *) getFieldValue:(NSInteger)controlNum
                        type:(CrimeFieldType)fieldType;
- (void)setZoomValues:(NSInteger)controlNum forRow:(NSInteger)row;
+ (void) deleteControlNum:(NSInteger)controlNum;
NSString* CrimeListFieldDescription (NSInteger fieldNumber);
- (BOOL)addIncidentToCrimeList:(int)controlNum;

@end
