//  NVSpreadsheetDelegate.m
//  NVMobile

#import "NVSpreadsheetDelegate.h"
#import "PropertyList.h"
#import "Destinations.h"
#import "MapViewController.h"
#import "CCodeLibrary/NVTabBarEdit.h"

@implementation NVSpreadsheetDelegate

- (NSInteger)numRowsInSpreadsheet
{
    return (PropertyList.new.availablePropertyFields.count - 1);
}

- (NSInteger)numColumnsInSpreadsheet
{
    return PropertyList.new.getPropertyNumbers.count;
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

- (NSString *)titleTextForSpreadsheet
{
    return PropertyList.getCurrentPropertyListName;
}

- (void)spreadsheetDidEditTitleText:(NSString *)titleText
{
    if (![titleText isEqualToString:PropertyList.getCurrentPropertyListName])
        [PropertyList renameCurrentPropertyList:titleText];
}

- (void)spreadsheetDidEditColumnHeaderText:(NSString *)text
                                   atIndex:(NSInteger)index
{
    [PropertyList.new updatePropertyUserID:(index + 1)
                                    userID:text];
}

- (NSArray *)spreadsheetDidGetLists
{
    return [PropertyList getPropertyLists];
}

- (void)spreadsheetDidSetCurrentList:(NSString *)file
{
    [PropertyList setCurrentPropertyList:file];
}

- (void)spreadsheetDidDeleteCurrentList
{
    [PropertyList deleteCurrentPropertyList];
}

- (void)spreadsheetDidCreateList
{
    [PropertyList createNewPropertyList];
}

- (void)spreadsheetDidMapItForRow:(NSInteger)row
                           column:(NSInteger)column
                 tabBarController:(UITabBarController *)tabBarController
{
    PropertyList *proplist = [[PropertyList alloc] init];
    
    LLPOINT llpoint = [proplist getPropertyLatLon:column];
    
    [proplist setZoomValues:column
                     forRow:row];
    
    CLLocationCoordinate2D ssCoords = CLLocationCoordinate2DMake(llpoint.lat, llpoint.lon);
    NSUInteger index = 0;
    
    MapViewController *mapVC = (MapViewController *)[NVTabBarEdit viewControllerWithID:@"MapVC"
                                                                    inTabBarController:tabBarController
                                                                                 index:&index];
    
    if (mapVC)
    {
        mapVC.fromSpreadsheet = YES;
        mapVC.spreadsheetCoords = ssCoords;
    }
    
    tabBarController.selectedIndex = index;
}

- (NSString *)propFieldDescriptionFilePathAtRow:(NSInteger)row
{
    return propertyListFieldDescription(row);
}

@end
