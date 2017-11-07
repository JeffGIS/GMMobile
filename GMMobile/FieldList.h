//
//  FieldList.h
//  NVMobile
//
//  Created by JEFFREY E SMITH on 11/6/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "PropertyList.h"

@interface FieldListRecord: NSObject
@property PropFieldType type;
@property NSString * name;
@property int sequence;
@property int weight;

@end

@interface FieldList : NSObject

+ (NSArray *) getFieldListRecords;
+ (NSArray *) getFieldLists;
+ (NSString*) getCurrentFieldListName;
+ (void) setWeightFor:(PropFieldType)type
                   to:(int)weight;
+ (int) getSequenceFor:(PropFieldType)type;
+ (void) setSequenceFor:(PropFieldType)type
                   from:(int)fromsequence
                     to:(int)tosequence;
+ (BOOL) renameCurrentFieldList:(NSString *)newName;
+ (BOOL) deleteCurrentFieldList;
+ (BOOL) setCurrentFieldList:(NSString *)propList;
+ (void) createNewFieldList;

- (BOOL)open;
- (void)close:(BOOL)opened;
- (void)startTransaction;
- (void)commitTransaction;
- (BOOL)executeCmd:(char *)cmd;
- (BOOL) createTables;

@end
