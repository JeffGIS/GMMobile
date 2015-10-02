//  PropertyList.h
//  GMMobile

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"

typedef NS_ENUM(NSInteger, PropFieldType)
{
    PFT_LatLon,
    PFT_ID,
    PFT_Address,
    PFT_PctOpenSpace_halfMile,
    PFT_PctOpenSpace_Mile,
    PFT_PctIndustrial_halfMile,
    PFT_PctIndustrial_Mile,
    PFT_Stability5yr_block,
    PFT_Stability5yr_blockgroup,
    PFT_Stability15yr_block,
    PFT_Stability15yr_blockgroup,
    PFT_Stability_halfMile,
    PFT_TimeToDestinations,
    PFT_PctHomestead_block,
    PFT_MedianAge_block,
    PFT_MedianAge_blockgroup,
    PFT_Children_block,
    PFT_MedianAgeChildren_block,
    PFT_MedianAgeAdults_block,
    PFT_Seniors_block,
    PFT_END
};

@class PropertyList;

@protocol PropertyListDelegate <NSObject>

- (void)PropertyList:(PropertyList *)propList
        returnsValue:(NSString *)value
   forPropertyNumber:(NSInteger)propNum
        andFieldType:(PropFieldType)type
          withStatus:(long)status;

@end

@interface PropertyList : NSObject
@property (nonatomic, weak) id <PropertyListDelegate> delegate;

- (BOOL)addParcelToPropertyList:(NSString *)PID;

- (NSArray*) getPropertyNumbers;
- (NSArray*)availablePropertyFields;
- (NSString*) propertyFieldName:(PropFieldType)fieldType;
- (void) getPropertyFieldValueOfType:(PropFieldType)type
                       forPropertyNumber:(NSInteger)propNum;

@end