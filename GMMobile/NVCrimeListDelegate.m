//  NVCrimeListDelegate.m
//  NVMobile

#import "NVCrimeListDelegate.h"
#import "CrimeList.h"
#import "MapViewController.h"
#import "CCodeLibrary/NVTabBarEdit.h"
#import "ChartsViewController.h"

@interface NVCrimeListDelegate ()

@property (nonatomic) CrimeList *crimeList;

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

- (void)closeList
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
    
    else
        return @"";
}

- (void)deleteRows:(NSArray *)arrayOfRows
{
    CrimeList *crimelist = _crimeList;
    NSArray *list = crimelist.getControlNumbers;
    //BOOL opened = [crimelist open];
    [crimelist startTransaction];
    for (NSNumber * rownum in arrayOfRows)
    {
        int row = (int)rownum.integerValue - 1;
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

- (void)copyRows:(NSArray *)arrayOfRows
          toList:(NSString *)listName
{
    CrimeList *crimelist = _crimeList;
    NSArray *list = crimelist.getControlNumbers;
    NSMutableArray *cnumToCopyList = NSMutableArray.new;
    for (NSNumber * rownum in arrayOfRows)
    {
        int row = (int)rownum.integerValue - 1;
        if (row < list.count)
        {
            NSNumber *cnum = list[row];
            [cnumToCopyList addObject:cnum];
        }
    }
    crimelist = nil;
    [self closeList];
    if (!listName)
        [CrimeList createNewCrimeList];
    else
        [CrimeList setCurrentCrimeList:listName];
    [self openList];
    
    
    int count = 1;
    BOOL opened = [_crimeList open];
    [_crimeList startTransaction];
    for (NSNumber * num in cnumToCopyList)
    {
        [_crimeList addIncidentToCrimeList:(int)num.integerValue];
        count++;
    }
    [_crimeList commitTransaction];
    [_crimeList close:opened];
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
    if (CRAPI.sharedInstance.mapCrimeList)
        CRAPI.sharedInstance.mapCrimeList = file;

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

- (NSArray *)getSearchStrings
{
    BOOL closeList = NO;
    
    if (!_crimeList)
    {
        if ([self openList])
            closeList = YES;
    }
    
    NSMutableArray *array = NSMutableArray.array;
    
    for (CrimeFieldType ifield = CFT_SearchString1;ifield <= CFT_SearchString3;ifield++)
    {
        NSString *sstring = [_crimeList getSearchString:ifield];
        
        [array addObject:sstring];
    }
    
    if (closeList)
        [self closeList];
    
    return array.copy;
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

- (void)getTimeLine:(NVSpreadsheetVC *)parentController
{
    NSMutableArray<TimeLine *> *array = NSMutableArray.array;
    CrimeList *crimelist = _crimeList;
    BOOL opened = crimelist.open;
    NSArray *list = crimelist.getControlNumbers;
    
    for (NSNumber *num in list)
    {
        int cnum = (int)num.integerValue;
        
        NSString *time = [crimelist getFieldValue:cnum type:CFT_FromTime raw:YES];
        TimeLine *tl = TimeLine.new;
        tl.time = (int)time.integerValue;
        tl.value = 1+[NSCalendar.currentCalendar component:NSCalendarUnitHour fromDate:[NSDate dateWithTimeIntervalSince1970:time.integerValue]];
        tl.refno = cnum;
        [array addObject:tl];
    }
    TimeLine *tl = TimeLine.new;
    tl.time = NSDate.date.timeIntervalSince1970;
    tl.value = 0.1;
    tl.refno = -1;
    [array addObject:tl];
    
    [crimelist close:opened];
    
    ChartsViewController *chartsVC = [ChartsViewController chartViewWithType:ChartsViewTypeTimeLine];
    chartsVC.timeLineArray = array.copy;
    chartsVC.currentSpreadsheet = parentController;
    [parentController presentViewController:chartsVC animated:YES completion:nil];
}

- (SpreadsheetAction)actionForTapOnRowHeader
{
    return SSA_SortRows;
}

- (SpreadsheetAction)actionForTwoTouchLongPressOnRowHeader
{
    return SSA_None;
}

- (SpreadsheetAction)actionForOneTouchLongPressOnColumnHeader
{
    return SSA_MultiSelect;
}

- (SpreadsheetAction)actionForTwoTouchLongPressOnColumnHeader
{
    return SSA_None;
}

- (NSString *)filePathForHelpFile
{
    return nil;
}

- (void)spreadsheetDidZoomForRow:(NSInteger)row column:(NSInteger)column from:(NVSpreadsheetVC *)fromVC tabBarController:(UITabBarController *)tabBarController { 
    return;
}


- (void)spreadsheetDidZoomForRow:(NSInteger)row
                          column:(NSInteger)column
                tabBarController:(UITabBarController *)tabBarController
{
    //no implmentation for NVCrime spreadsheet.
}

@end
