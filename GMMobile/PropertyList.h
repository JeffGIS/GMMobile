//  PropertyList.h
//  GMMobile

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "GetSlowValues.h"
#import "PropertyListFields.h"

@class PropertyList;

@protocol PropertyListDelegate <NSObject>

@optional
- (void)PropertyList:(PropertyList *)propList
        returnsValue:(NSString *)value
   forPropertyNumber:(NSInteger)propNum
        andFieldType:(PropFieldType)type
          withStatus:(long)status;

- (void)ParcelAddedToPropertyList:(int)status;

@end

@interface PropertyList : NSObject <GSSiPopoverViewDelegate,GetSlowValuesDelegate,RHWalkScoreDelegate>
@property (nonatomic, weak) id <PropertyListDelegate> delegate;
@property sqlite3nv *database;
@property sqlite3nv *subDatabase;
@property NSString* propListDir;
@property (nonatomic) GSSiPopoverView *popover;
@property int propVersion;
@property int numPropertiesInList;
@property int PropNum;


+ (NSArray *) getPropertyLists;
+ (NSString*) getCurrentPropertyListName;
+ (BOOL) renameCurrentPropertyList:(NSString *)newName;
+ (BOOL) deleteCurrentPropertyList;
+ (BOOL) setCurrentPropertyList:(NSString *)propList;
+ (void) createNewPropertyList;

- (BOOL)open:(BOOL)create;
- (void)close:(BOOL)opened;
- (void)startTransaction;
- (void)commitTransaction;
- (BOOL)executeCmd:(const char *)cmd;
- (BOOL) createTables;

- (BOOL)addParcelToPropertyList:(NSString *)PID
                            popover:(GSSiPopoverView*)popover
                       delegate:(id)delegate
               computeAllValues:(BOOL)computeallvals;

- (BOOL)addParcelsToPropertyList:(NSArray *)PIDList
                         popover:(GSSiPopoverView*)popover
                        delegate:(id)delegate
                 computeAllValues:(BOOL)computeallvals;

- (NSArray *)getPropertyNumbers;
+ (NSArray *)availablePropertyFields;
+ (NSString *)propertyFieldName:(PropFieldType)fieldType;
+ (BOOL)propertyAllowsWeight:(PropFieldType)fieldType;

- (void) getPropertyFieldValueOfType:(PropFieldType)type
                   forPropertyNumber:(NSInteger)propNum;

- (void)updatePropertyUserID:(NSInteger)propNum
                      userID:(NSString *)userID;

- (LLPOINT)getPropertyLatLon:(NSInteger)propNum;

- (NSString *) getFieldValue:(NSInteger)propNum
                        type:(PropFieldType)fieldType;
- (void)setZoomValues:(NSInteger)propNum
           withOption:(NSInteger)option;
+ (MapitBaseLayer)getBaseLayerForField:(PropFieldType)field;
+ (PropBaseType)getBaseTypeForField:(PropFieldType) field;
- (void) deleteProperty:(NSInteger)propNum;
NSString* propertyListFieldDescription (NSInteger fieldNumber);
- (NSString *) getFieldAverage:(PropFieldType)fieldType;
- (NSString *) getFieldTotal:(PropFieldType)fieldType;
- (BOOL)parcelInPropertyList:(NSString *)PIN;
- (NSArray*) getAreaRecords:(NSInteger)propNum;

- (int)getNearestProperty:(LLPOINT *)ll
         distanceInMeters:(double *)dist;

- (NSString *)getVideoDirectory:(int)propNum;
- (BOOL)addVideoClip:(RHClip *)clip;
- (NSArray<RHClip*> *) getVideoClipsForProperty:(int)propNum;
- (NSString *) getPIDforPropnum:(int)propNum;
- (int)nextPropNum;
- (void) addString:(NSString*)value
          withCode:(PropFieldType)code;
- (NSArray*) getPIDS;
@end
