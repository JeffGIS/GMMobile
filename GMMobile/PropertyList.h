//  PropertyList.h
//  GMMobile

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "GetSlowValues.h"

typedef NS_ENUM(NSInteger, ValueTypes)
{
    VTInteger,
    VTDouble,
    VTLLPoint,
    VTString,
};
typedef NS_ENUM(NSInteger, PropFieldType)
{
    PFT_LatLon,
    PFT_UserID,
    PFT_PIN,
    PFT_Address,
    PFT_Owner,
    PFT_TaxPayer,
    PFT_Links,
    PFT_ACRES,
    PFT_EMV_TOTAL,
    PFT_EMV_BUILDING,
    PFT_EMV_LAND,
    PFT_EMV_LAND_PER_ACRE,
    PFT_TOTAL_TAX,
    PFT_SPEC_ASSESSMENT,
    PFT_Stability5yr_block,
    PFT_Stability5yr_blockgroup,
    PFT_Stability15yr_block,
    PFT_Stability15yr_blockgroup,
    PFT_Stability5yr_qtrMile,
    PFT_Stability5yr_halfMile,
    PFT_Stability5yr_Mile,
    PFT_Stability15yr_qtrMile,
    PFT_Stability15yr_halfMile,
    PFT_Stability15yr_Mile,
    PFT_DistanceToDestinations,
    PFT_TimeToDestinations,
    PFT_PctHomestead_block,
    PFT_PctHomestead_blockgroup,
    PFT_PctHomeOwn_block,
    PFT_PctHomeOwn_blockgroup,
    PFT_MedianAgePop_block,
    PFT_MedianAgePop_blockgroup,
    PFT_MedianBuiltYear_block,
    PFT_MedianBuiltYear_blockgroup,
    PFT_MedianAgeChildren_block,
    PFT_MedianAgeAdults_block,
    PFT_PctChildren_block,
    PFT_PctChildren_blockgroup,
    PFT_MedianAgeChildren_blockgroup,
    PFT_MedianAgeAdults_blockgroup,
    PFT_PctSenior_block,
    PFT_PctSenior_blockgroup,
    PFT_RankEMV_block,
    PFT_RankEMV_blockgroup,
    PFT_PctOpenSpace_qtrMile,
    PFT_PctOpenSpace_halfMile,
    PFT_PctOpenSpace_Mile,
    PFT_PctIndustrial_qtrMile,
    PFT_PctIndustrial_halfMile,
    PFT_PctIndustrial_Mile,
    PFT_PctResidential_qtrMile,
    PFT_PctResidential_halfMile,
    PFT_PctResidential_Mile,
    PFT_PctCommercial_qtrMile,
    PFT_PctCommercial_halfMile,
    PFT_PctCommercial_Mile,
    PFT_END
};
typedef NS_ENUM(NSInteger, PropBaseType)
{
    PBT_Residential,
    PBT_Commercial,
    PBT_Industrial,
    PBT_Stability,
    PBT_OpenSpace,
};

@class PropertyList;

@protocol PropertyListDelegate <NSObject>

- (void)PropertyList:(PropertyList *)propList
        returnsValue:(NSString *)value
   forPropertyNumber:(NSInteger)propNum
        andFieldType:(PropFieldType)type
          withStatus:(long)status;

@end

@interface PropertyList : NSObject <GetSlowValuesDelegate,GSSiPopoverViewDelegate>
@property (nonatomic, weak) id <PropertyListDelegate> delegate;
@property NSString* propListDir;
@property (nonatomic) GSSiPopoverView *popover;
@property int propVersion;

+ (NSArray *) getPropertyLists;
+ (NSString*) getCurrentPropertyListName;
+ (BOOL) renameCurrentPropertyList:(NSString *)newName;
+ (BOOL) deleteCurrentPropertyList;
+ (BOOL) setCurrentPropertyList:(NSString *)propList;
+ (void) createNewPropertyList;

- (BOOL)open;
- (void)close:(BOOL)opened;

- (BOOL)addParcelToPropertyList:(NSString *)PID
                        popover:(GSSiPopoverView*)popover;

- (NSArray *)getPropertyNumbers;
- (NSArray *)availablePropertyFields;
- (NSString *)propertyFieldName:(PropFieldType)fieldType;

- (void) getPropertyFieldValueOfType:(PropFieldType)type
                   forPropertyNumber:(NSInteger)propNum;

- (void)updatePropertyUserID:(NSInteger)propNum
                      userID:(NSString *)userID;

- (LLPOINT)getPropertyLatLon:(NSInteger)propNum;

- (NSString *) getFieldValue:(NSInteger)propNum
                        type:(PropFieldType)fieldType;
- (void)setZoomValues:(NSInteger)propNum forRow:(NSInteger)row;
+ (PropBaseType)getBaseTypeForField:(PropFieldType) field;
+ (void) deleteProperty:(NSInteger)propNum;
NSString* propertyListFieldDescription (NSInteger fieldNumber);
- (NSString *) getFieldAverage:(PropFieldType)fieldType;
- (NSString *) getFieldTotal:(PropFieldType)fieldType;

@end
