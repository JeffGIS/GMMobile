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
    CFT_LatLon,
    CFT_UserID,
};

@class CrimeList;

@protocol CrimeListDelegate <NSObject>

- (void)CrimeList:(CrimeList *)propList
        returnsValue:(NSString *)value
   forCrimeNumber:(NSInteger)propNum
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
+ (BOOL) setCurrentCrimeList:(NSString *)propList;
+ (void) createNewCrimeList;

- (BOOL)open;
- (void)close:(BOOL)opened;
- (void)startTransaction;
- (void)commitTransaction;

- (NSArray *)getCrimeNumbers;
- (NSArray *)availableCrimeFields;
- (NSString *)crimeFieldName:(CrimeFieldType)fieldType;

- (void) getCrimeFieldValueOfType:(CrimeFieldType)type
                   forCrimeNumber:(NSInteger)propNum;

- (void)updateCrimeUserID:(NSInteger)propNum
                      userID:(NSString *)userID;

- (LLPOINT)getCrimeLatLon:(NSInteger)propNum;

- (NSString *) getFieldValue:(NSInteger)propNum
                        type:(CrimeFieldType)fieldType;
- (void)setZoomValues:(NSInteger)crimeNum forRow:(NSInteger)row;
+ (void) deleteCrime:(NSInteger)propNum;
NSString* CrimeListFieldDescription (NSInteger fieldNumber);

@end
