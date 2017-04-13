//  NVCrimeListDelegate.m
//  NVMobile

#import "NVCrimeListDelegate.h"
#import "CrimeList.h"
#import "MapViewController.h"
#import "CCodeLibrary/NVTabBarEdit.h"
#import "ChartsViewController.h"

@interface NVCrimeListDelegate ()

@property CrimeList *crimeList;

@end

@implementation NVCrimeListDelegate

- (SpreadsheetTypes)getSpreadSheetType
{
    return SST_CrimeList;
}

- (NSString *)currentListName
{
    return CrimeList.getCurrentCrimeListName;
}

- (BOOL)openList
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
    CrimeList *crimelist = _crimeList;
    NSArray *list = crimelist.getControlNumbers;
    
    if (column <= list.count)
    {
        NSInteger controlNum = [list[column - 1] integerValue];
        
        return [crimelist getFieldValue:controlNum
                                    type:CFT_CASENO
                                     raw:NO];
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

- (void)deleteRows:(NSArray *)arrayOfRows
{
    CrimeList *crimelist = _crimeList;
    NSArray *list = crimelist.getControlNumbers;
    BOOL opened = [crimelist open];
    [crimelist startTransaction];
    for (NSNumber * rownum in arrayOfRows)
    {
        int row = (int)rownum.integerValue;
        if (row < list.count)
        {
            NSNumber *cnum = list[row];
            [crimelist deleteControlNumber:(int)cnum.integerValue];
        }
    }
    [crimelist commitTransaction];
    [crimelist close:YES];
    [crimelist open];
}

- (NSString *)textForColumn:(NSUInteger)column
                        row:(NSUInteger)row
{
    CrimeList *crimelist = _crimeList;
    NSArray *list = crimelist.getControlNumbers;
    CrimeFieldType type = (CFT_UCR + row - 1);
    
    if (column <= list.count && row < crimelist.availableCrimeFields.count)
    {
        NSInteger propNum = [list[column - 1] integerValue];
        
        
        return [crimelist getFieldValue:propNum
                                  type:type
                                    raw:NO];
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
    {
        [self closeList];
        [CrimeList renameCurrentCrimeList:titleText];
        [self openList];
    }
}

- (void)spreadsheetDidEditColumnHeaderText:(NSString *)text
                                   atIndex:(NSInteger)index
{
    NSArray *list = _crimeList.availableCrimeFields;
    
    if (index < list.count)
    {
        CrimeFieldType ifield = [list[index] integerValue];
        [_crimeList changeTextForFieldHeader:ifield
                                     newText:text];
    }
}

- (void)spreadsheetDidEditRowHeaderText:(NSString *)text
                                atIndex:(NSInteger)index
{
    NSArray *list = _crimeList.availableCrimeFields;
    
    if (index < list.count)
    {
        CrimeFieldType ifield = [list[index] integerValue];
        [_crimeList changeTextForFieldHeader:ifield newText:text];
    }
}

- (BOOL)spreadsheetCanEditRowHeaderTextAtIndex:(NSInteger)index
{
    BOOL rtn = NO;
    NSArray *list = _crimeList.availableCrimeFields;
    
    if (index < list.count)
    {
        CrimeFieldType ifield = [list[index] integerValue];
        
        switch (ifield)
        {
            case CFT_SearchString1:
            case CFT_SearchString2:
            case CFT_SearchString3:
                rtn = YES;
                break;
            default:
                break;
        }
    }
    
    return rtn;
}

- (NSString *)spreadsheetRowHeaderTextPrefixAtIndex:(NSInteger)index
{
    NSString *prfx = @"SEARCH:";
    return prfx;
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

- (NSString *)spreadsheetGetReportForRow:(NSInteger)row
                            column:(NSInteger)column
{
    NSString * report = nil;
    CrimeList *crimelist = [[CrimeList alloc] init];
    NSArray *list = crimelist.getControlNumbers;
    
    if (column <= list.count && row < crimelist.availableCrimeFields.count)
    {
        NSInteger controlNum = [list[column - 1] integerValue];
        report = [CrimeData reportForControlNumber:controlNum];

    }
    return report;
}
- (void)spreadsheetDidMapItForRow:(NSInteger)row
                           column:(NSInteger)column
                 tabBarController:(UITabBarController *)tabBarController
    {
        CrimeList *crimelist = [[CrimeList alloc] init];
        
    LLPOINT llpoint = [crimelist getCrimeLatLon:column];
    
    [crimelist setZoomValues:column
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

- (BOOL)spreadsheetSortOnRow:(NSInteger)row
{
    BOOL rtn = YES;
    NSArray *list = _crimeList.availableCrimeFields;
    int ascdesc = 1;
    int asc;
    CrimeFieldType currentSortField = [_crimeList getSortField:&asc];

    if (row < list.count)
    {
        CrimeFieldType ifield = [list[row] integerValue];
        if (ifield == currentSortField)
            ascdesc =  !asc;
        switch (ifield)
        {
            case CFT_LatLon:
                rtn = NO;
                break;
            default:
                [_crimeList sortOn:ifield
                         direction:ascdesc];
                break;
                
        }
    }
    return rtn;
}

- (void)getTimeLine:(UIViewController *)parentController
{
    NSMutableArray<TimeLine *> *array = NSMutableArray.array;
    CrimeList *crimelist = _crimeList;
    BOOL opened = [crimelist open];
    NSArray *list = crimelist.getControlNumbers;
    
    for (NSNumber *num in list)
    {
        int cnum = (int)num.integerValue;
        
        NSString *time = [crimelist getFieldValue:cnum
                                             type:CFT_FromTime
                                              raw:YES];
        
        NSString *nsus = [crimelist getFieldValue:cnum
                                             type:CFT_NumSuspects
                                              raw:YES];
        TimeLine *tl = TimeLine.new;
        tl.time = (int)time.integerValue;
        tl.value = nsus.integerValue;
        [array addObject:tl];
    }
    
    [crimelist close:opened];
    
    ChartsViewController *chartsVC = [ChartsViewController chartViewWithType:ChartsViewTypeTimeLine];
    chartsVC.timeLineArray = array.copy;
    [parentController presentViewController:chartsVC animated:YES completion:nil];
}

@end
