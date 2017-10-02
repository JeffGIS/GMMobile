//  NVSpreadsheetDelegate.m
//  NVMobile

#import "NVSpreadsheetDelegate.h"
#import "PropertyList.h"
#import "Destinations.h"
#import "MapViewController.h"
#import "CCodeLibrary/NVTabBarEdit.h"

@interface NVSpreadsheetDelegate ()

@property PropertyList *propList;

@end

@implementation NVSpreadsheetDelegate

- (SpreadsheetTypes)getSpreadSheetType
{
    return SST_PropertyList;
}

- (BOOL)openList
{
    BOOL rtn = FALSE;
    
    _propList = PropertyList.new;
    if (_propList)
    {
        [_propList open];
        rtn = TRUE;
    }
    return rtn;
}

- (NSString *)currentListName
{
    return [PropertyList getCurrentPropertyListName];
}
- (void) closeList
{
    [_propList close:TRUE];
    _propList = nil;
}
- (NSInteger)numRowsInSpreadsheet
{
    return (_propList.availablePropertyFields.count - 1);
}

- (NSInteger)numColumnsInSpreadsheet
{
    return _propList.getPropertyNumbers.count + 4;
}

- (void)deleteRows:(NSArray *)arrayOfRows
{
    
}

- (NSString *)headerTextForRow:(NSUInteger)row
{
    PropertyList *proplist = _propList;
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
    PropertyList *proplist = _propList;
    NSArray *list = proplist.getPropertyNumbers;
    
    if (column <= list.count)
    {
        NSInteger propNum = [list[column - 1] integerValue];
        
        return [proplist getFieldValue:propNum
                                  type:PFT_UserID];
    }
    
    else if (column == (list.count + 1))
        return @"Total";
    
    else if (column == (list.count + 2))
        return @"Average";
    
    else if (column == (list.count + 3))
        return @"Minimum";
    
    else if (column == (list.count + 4))
        return @"Maximum";
    
    else
        return @"";
}

- (NSString *)textForColumn:(NSUInteger)column
                        row:(NSUInteger)row
{
    PropertyList *proplist = _propList;
    NSArray *list = proplist.getPropertyNumbers;
    PropFieldType type = (PFT_PIN + row - 1);
   
    if (column <= list.count && row < proplist.availablePropertyFields.count)
    {
        NSInteger propNum = [list[column - 1] integerValue];
        
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
    else if (column == list.count+1 && row < proplist.availablePropertyFields.count)
    {
        return [proplist getFieldTotal:type];
    }
    else if (column == list.count+2 && row < proplist.availablePropertyFields.count)
    {
        return [proplist getFieldAverage:type];
    }
    else
        return @"";
}

- (void)spreadsheetDidEditTitleText:(NSString *)titleText
{
    if (![titleText isEqualToString:PropertyList.getCurrentPropertyListName])
        [PropertyList renameCurrentPropertyList:titleText];
}

- (void)spreadsheetDidEditColumnHeaderText:(NSString *)text
                                   atIndex:(NSInteger)index
{
    [_propList updatePropertyUserID:(index + 1) userID:text];
}

- (void)spreadsheetDidEditRowHeaderText:(NSString *)text
                                atIndex:(NSInteger)row
{
    
}

- (BOOL)spreadsheetCanEditRowHeaderTextAtIndex:(NSInteger)index
{
    return YES;
}

- (BOOL)spreadsheetCanEditColumnHeaderTextAtIndex:(NSInteger)index
{
    return YES;
}

- (NSArray *)spreadsheetDidGetLists
{
    [_propList close:YES];
    NSArray * rtn = [PropertyList getPropertyLists];
    [_propList open];
    return rtn;
}

- (void)spreadsheetDidSetCurrentList:(NSString *)file
{
    [_propList close:YES];
    [PropertyList setCurrentPropertyList:file];
    [_propList open];
}

- (void)spreadsheetDidDeleteCurrentList
{
    [_propList close:YES];
    [PropertyList deleteCurrentPropertyList];
    [_propList open];
}

- (void)spreadsheetDidCreateList
{
    [_propList close:YES];
    [PropertyList createNewPropertyList];
    [_propList open];
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

- (NSString *)filePathForHelpFile
{
    return nil;
}

- (void)copyRows:(NSArray *)arrayOfRows
          toList:(NSString *)listName
{
    
}

@end
