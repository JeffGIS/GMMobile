//  NVSpreadsheetDelegate.m
//  NVMobile

#import "NVSpreadsheetDelegate.h"
#import "PropertyList.h"
#import "Destinations.h"

@implementation NVSpreadsheetDelegate

- (NSInteger)numRowsInSpreadsheet
{
    return MAX((PropertyList.new.availablePropertyFields.count - 1), 16);
}

- (NSInteger)numColumnsInSpreadsheet
{
    return MAX(PropertyList.new.getPropertyNumbers.count, 16);
}

- (NSString *)headerTextForRow:(NSUInteger)row
{
    PropertyList *proplist = PropertyList.new;
    NSArray *list = proplist.availablePropertyFields;
    
    if (row < list.count)
    {
        PropFieldType ifield = [list[row] integerValue];
        NSString *fieldName = [proplist propertyFieldName:ifield];
        
        return [fieldName stringByReplacingOccurrencesOfString:@" ("
                                                    withString:@"\n("];
    }
    
    else
        return [NSString stringWithFormat:@"Row %lu", (unsigned long)row];
}

- (NSString *)headerTextForColumn:(NSUInteger)column
{
    PropertyList *proplist = PropertyList.new;
    NSArray *list = proplist.getPropertyNumbers;
    
    if (column <= list.count)
    {
        NSInteger propNum = [list[column - 1] integerValue];
        
        return [proplist getFieldValue:propNum
                                  type:PFT_UserID];
    }
    
    else
        return [NSString stringWithFormat:@"Property %lu", (unsigned long)column];
}

- (NSString *)textForColumn:(NSUInteger)column
                        row:(NSUInteger)row
{
    PropertyList *proplist = PropertyList.new;
    NSArray *list = proplist.getPropertyNumbers;
    
    if (column <= list.count && row < proplist.availablePropertyFields.count)
    {
        NSInteger propNum = [list[column - 1] integerValue];
        PropFieldType type = (PFT_PIN + row - 1);
        
        if (type == PFT_TimeToDestinations)
        {
            Destinations *dest = Destinations.new;
            
            CGFloat val = [dest totalValueForProperty:propNum
                                               ofType:type];
            
            return [NSString stringWithFormat:@"%.1f", (val / 60.0)];
        }
        
        else if (type == PFT_DistanceToDestinations)
        {
            Destinations *dest = Destinations.new;
            
            CGFloat val = [dest totalValueForProperty:propNum
                                               ofType:type];
            
            return [NSString stringWithFormat:@"%.1f", val];
        }
        
        return [proplist getFieldValue:propNum
                                  type:type];
    }
    
    else
        return @"";
}

@end
