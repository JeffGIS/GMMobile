//
//  NVCrimeListDelegate.m
//  NVMobile
//
//  Created by Jeff Smith on 4/5/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import "NVCrimeListDelegate.h"
#import "CrimeList.h"
#import "MapViewController.h"
#import "CCodeLibrary/NVTabBarEdit.h"

@interface NVCrimeListDelegate ()

@property CrimeList *crimeList;

@end

@implementation NVCrimeListDelegate

- (BOOL) openList
{
    BOOL rtn = FALSE;
    
    _crimeList = CrimeList.new;
    if (_crimeList)
    {
        [_crimeList open];
        rtn = TRUE;
    }
    return rtn;
}

- (void) closeList
{
    [_crimeList close:TRUE];
    _crimeList = nil;
}
- (NSInteger)numRowsInSpreadsheet
{
    return (_crimeList.availableCrimeFields.count - 1);
}

- (NSInteger)numColumnsInSpreadsheet
{
    return _crimeList.getControlNumbers.count;
}

- (NSString *)headerTextForRow:(NSUInteger)row
{
    CrimeList *crimelist = _crimeList;
    NSArray *list = crimelist.availableCrimeFields;
    
    if (row < list.count)
    {
        CrimeFieldType ifield = [list[row] integerValue];
        NSString *fieldName = [crimelist crimeFieldName:ifield];
        
        return [fieldName stringByReplacingOccurrencesOfString:@" ("
                                                    withString:@"\n("];
    }
    
    else
        return [NSString stringWithFormat:@"Row %lu", (unsigned long)row];
}

- (NSString *)headerTextForColumn:(NSUInteger)column
{
    CrimeList *proplist = _crimeList;
    NSArray *list = proplist.getControlNumbers;
    
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
    CrimeList *proplist = _crimeList;
    NSArray *list = proplist.getControlNumbers;
    PropFieldType type = (PFT_PIN + row - 1);
    
    if (column <= list.count && row < proplist.availableCrimeFields.count)
    {
        NSInteger propNum = [list[column - 1] integerValue];
        
        
        return [proplist getFieldValue:propNum
                                  type:type];
    }
   else
        return @"";
}

- (NSString *)titleTextForSpreadsheet
{
    return CrimeList.getCurrentCrimeListName;
    
}

- (void)spreadsheetDidEditTitleText:(NSString *)titleText
{
    if (![titleText isEqualToString:CrimeList.getCurrentCrimeListName])
        [CrimeList renameCurrentCrimeList:titleText];
}

- (void)spreadsheetDidEditColumnHeaderText:(NSString *)text
                                   atIndex:(NSInteger)index
{
    
}

- (void)spreadsheetDidEditRowHeaderText:(NSString *)text
                                atIndex:(NSInteger)index
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
    [_crimeList close:YES];
    NSArray * rtn = [CrimeList getCrimeLists];
    [_crimeList open];
    return rtn;
}

- (void)spreadsheetDidSetCurrentList:(NSString *)file
{
    [_crimeList close:YES];
    [CrimeList setCurrentCrimeList:file];
    [_crimeList open];
}

- (void)spreadsheetDidDeleteCurrentList
{
    [_crimeList close:YES];
    [CrimeList deleteCurrentCrimeList];
    [_crimeList open];
}

- (void)spreadsheetDidCreateList
{
    [_crimeList close:YES];
    [CrimeList createNewCrimeList];
    [_crimeList open];
}

- (void)spreadsheetDidMapItForRow:(NSInteger)row
                           column:(NSInteger)column
                 tabBarController:(UITabBarController *)tabBarController
{
    CrimeList *proplist = [[CrimeList alloc] init];
    
    LLPOINT llpoint = [proplist getCrimeLatLon:column];
    
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
    return CrimeListFieldDescription(row);
}

- (BOOL)spreadsheetCanEditRowHeaderText:(NSInteger)row
{
    BOOL rtn = NO;
    NSArray *list = _crimeList.availableCrimeFields;
    
    if (row < list.count)
    {
        CrimeFieldType ifield = [list[row] integerValue];
    
        switch (ifield)
        {
            case CFT_SearchString1:
            case CFT_SearchString2:
                rtn = YES;
                break;
            default:
                break;
                
        }
    }
    return rtn;
}
-(void) spreadsheetDidEditRowHeaderText:(NSString *)text atIndex:(NSInteger)row
{
    
}
- (BOOL)spreadsheetSortOnRow:(NSInteger)row
{
    BOOL rtn = YES;
    NSArray *list = _crimeList.availableCrimeFields;
    
    if (row < list.count)
    {
        CrimeFieldType ifield = [list[row] integerValue];
        
        switch (ifield)
        {
            case CFT_SearchString1:
            case CFT_SearchString2:
                rtn = NO;
                break;
            default:
                break;
                
        }
    }
    return rtn;
}

@end
