//  NVSpreadsheetDelegate.m
//  NVMobile

#import "NVSpreadsheetDelegate.h"
#import "PropertyList.h"
#import "FieldList.h"
#import "Destinations.h"
#import "MapViewController.h"
#import "CCodeLibrary/NVTabBarEdit.h"
#import "ChartsViewController.h"

@interface NVSpreadsheetDelegate () <CLLocationManagerDelegate>

@property (nonatomic) PropertyList *propList;
@property (nonatomic, copy) NSArray *fieldList;
@property NVSpreadsheetVC* spreadSheetVC;
@property int locationCount;
@property NSInteger autoSelectedRow;
@property (strong, nullable) CLLocationManager *locationManager;

@end

@implementation NVSpreadsheetDelegate

- (SpreadsheetTypes)getSpreadSheetType
{
    return SST_PropertyList;
}

- (BOOL)getCurrentLocation
{
    if (![CLLocationManager locationServicesEnabled])
        return FALSE;
    _locationCount = 0;
    
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    [_locationManager requestLocation];
    return TRUE;
}
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    CLLocationCoordinate2D currentLocation;
    currentLocation = [locations.firstObject coordinate];
    _locationCount++;
    
    LLPOINT ll;
    ll.lon = currentLocation.longitude;
    ll.lat = currentLocation.latitude;
    double dist;
    int nearProp = [_propList getNearestProperty:&ll
                                distanceInMeters:&dist];
    if (dist < 500)
    {
        NSArray *list = _propList.getPropertyNumbers;
        int iRow = 1;
        for (NSNumber *prop in list)
        {
            if (nearProp == prop.integerValue)
            {
                _autoSelectedRow = iRow;
                [NSTimer scheduledTimerWithTimeInterval:0.1
                                                 target:_spreadSheetVC
                                               selector:@selector(autoSelectRow:)
                                               userInfo:nil
                                                repeats:NO];
            }
            iRow++;
        }        
    }

}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"CLLocationManager ERROR: %@", error.localizedDescription);
}

-(NSInteger) getAutoSelectRow
{
    return _autoSelectedRow;
}

- (BOOL) openList:(NVSpreadsheetVC*)vc
{
    BOOL rtn = FALSE;
    
    _spreadSheetVC = vc;
    _propList = PropertyList.new;
    if (_propList)
    {
        [_propList open];
        _fieldList = [FieldList getFieldListRecords:NO];
        [self getCurrentLocation];
        rtn = TRUE;
    }
    return rtn;
}

- (NSString *)currentListName
{
    return PropertyList.getCurrentPropertyListName;
}

- (void) closeList
{
    [_propList close:TRUE];
    _propList = nil;
}
- (NSInteger)numColumnsInSpreadsheet
{
    return (_fieldList.count-1);
    //return ([PropertyList availablePropertyFields].count - 2);

}
- (void) addPropFromWebsiteToPropList:(NSString *)link
                              popover:(GSSiPopoverView *)popover
{
    NSString * address;
    NSString * houseNum = @"";
    NSString * streetName = @"";
    
    NSRange range;
    range = [link rangeOfString:@"www.edinarealty.com/homes-for-sale/"];
    if (range.length > 0)
    {
        address = [link substringFromIndex:range.location+range.length];
        houseNum = textBefor(address, @"-");
        streetName = textAfter (address,@"-");
        streetName = textBefor(streetName,@"-");
    }
    PropertyData *propData = [[PropertyData alloc] init];
    BOOL opened = [self openList:_spreadSheetVC];
    _locationManager = nil;
    NSArray * addressList = [propData getPIDsMatchingAddress:houseNum.intValue
                                         streetName:streetName];
    for (NSString *addr in addressList)
    {
        NSString *PID = textAfter (addr,@"\t");
        PID = textAfter(PID,@"\t");
        PID = textBefor(PID,@"\t");
        [_propList addParcelToPropertyList:PID popover:popover];
    }
}
- (NSInteger)numRowsInSpreadsheet
{
    return (_propList.getPropertyNumbers.count + 4);
}

- (NSInteger)numSelectableRows
{
    return _propList.getPropertyNumbers.count;
}

- (void)deleteRows:(NSArray *)arrayOfRows
{
    NSArray *list = _propList.getPropertyNumbers;
    BOOL opened = [_propList open];
    [_propList startTransaction];
    
    for (NSNumber *row in arrayOfRows)
    {
        NSNumber *propNum = list[row.integerValue];
        [_propList deleteProperty:(NSInteger)propNum.integerValue];
    }
    
    [_propList commitTransaction];
    [_propList close:opened];
    [self closeList];
    [self openList:_spreadSheetVC];
    return;
}

- (NSString *)headerTextForRow:(NSUInteger)row
{
    NSArray *list = _fieldList;
    
    if (row < list.count)
    {
        FieldListRecord *ifield = list[row];
        NSString *fieldName = ifield.name;
        
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

-(int)autoSelectRow
{
    int rtn = 0;
    
    return rtn;
}

- (UIColor*) backgroundColorForCell:(NSInteger)row
                            column:(NSInteger)column
{
    if (row > _propList.numPropertiesInList)
        return [UIColor colorWithRed:1 green:1 blue:0.85 alpha:1];
    return UIColor.clearColor;
}

- (NSInteger)getPropNumForRow:(NSInteger)row
{
    NSArray *list = _propList.getPropertyNumbers;
    if (row < 0 || row > list.count)
        return -1;
    NSNumber * rtn = list[row-1];
    return rtn.integerValue;
}

- (NSString *)textForColumn:(int)columnIN
                        row:(int)row
{
    NSUInteger column = (int)abs ((int)columnIN);
    PropertyList *proplist = _propList;
    NSArray *list = proplist.getPropertyNumbers;
    NSArray *availablePropertyFields = [PropertyList availablePropertyFields];
    FieldListRecord *flr = nil;
    
    if (row < _fieldList.count)
        flr = _fieldList[row];
    
    PropFieldType type = flr.type;//(PFT_PIN + row - 1);
   
    if (column <= list.count && row < availablePropertyFields.count)
    {
        NSInteger propNum = [list[column - 1] integerValue];
        
        if (type == PFT_TimeToDestinations)
        {
            Destinations *dest = Destinations.new;
            
            CGFloat val = [dest totalValueForProperty:propNum
                                               ofType:type
                                          fromService:@""];

            return [NSString stringWithFormat:@"%.1f", (val / 60.0)];
        }
        if (type == PFT_TimeToDestinationsGoogle)
        {
            Destinations *dest = Destinations.new;
            
            CGFloat val = [dest totalValueForProperty:propNum
                                               ofType:type
                                          fromService:@"GOOGLE"];

            return [NSString stringWithFormat:@"%.1f", (val / 60.0)];
        }

        if (type == PFT_TimeToDestinationsApple)
        {
            Destinations *dest = Destinations.new;
            
            CGFloat val = [dest totalValueForProperty:propNum
                                               ofType:type
                                          fromService:@"Apple"];

            return [NSString stringWithFormat:@"%.1f", (val / 60.0)];
        }
        else if (type == PFT_DistanceToDestinations)
        {
            Destinations *dest = Destinations.new;
            
            CGFloat val = [dest totalValueForProperty:propNum
                                               ofType:type
                                          fromService:@""];
            
            return [NSString stringWithFormat:@"%.1f", val];
        }
        else if (type == PFT_DistanceToDestinationsGoogle)
        {
            Destinations *dest = Destinations.new;
            
            CGFloat val = [dest totalValueForProperty:propNum
                                               ofType:type
                                          fromService:@"GOOGLE"];
            
            return [NSString stringWithFormat:@"%.1f", val];
        }
        else if (type == PFT_DistanceToDestinationsApple)
        {
            Destinations *dest = Destinations.new;
            
            CGFloat val = [dest totalValueForProperty:propNum
                                               ofType:type
                                          fromService:@"Apple"];
            
            return [NSString stringWithFormat:@"%.1f", val];
        }
        else if (type == PFT_ProsAndCons)
        {
            NSArray *clips = [_propList getVideoClipsForProperty:(int)propNum];

            return [NSString stringWithFormat:@"%i Clips",(int)clips.count];
        }
        else if (type == PFT_Links)
        {
            if (columnIN < 0)
            {
                return [proplist getFieldValue:propNum
                                          type:PFT_Address];
            }
            else
                return @"Tap here to view";
        }
        return [proplist getFieldValue:propNum
                                  type:type];
    }
    else if (column == list.count+1 && row < availablePropertyFields.count)
    {
        return [proplist getFieldTotal:type];
    }
    else if (column == list.count+2 && row < availablePropertyFields.count)
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
    NSInteger propNum = [self getPropNumForRow:index];
    [_propList updatePropertyUserID:propNum userID:text];
}

- (void)spreadsheetDidEditRowHeaderText:(NSString *)text
                                atIndex:(NSInteger)row
{
    
}

- (BOOL)spreadsheetCanEditRowHeaderTextAtIndex:(NSInteger)index
{
    return NO;
}

- (BOOL)spreadsheetCanEditColumnHeaderTextAtIndex:(NSInteger)index
{
    if (index > _propList.getPropertyNumbers.count)
        return NO;
    
    else
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
    
    [proplist setZoomValues:row
                 withOption:column];
    
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

- (void)spreadsheetDidZoomForRow:(NSInteger)row
                           column:(NSInteger)column
                            from:(NVSpreadsheetVC *)fromVC
                 tabBarController:(UITabBarController *)tabBarController
{
    PropertyList *proplist = PropertyList.new;
    int propNum = (int)[self getPropNumForRow:row];
    
    if (column == -2)
    {
        NSArray *areaRecs = [proplist getAreaRecords:propNum];
        
        [NVPopoverTableView showPopoverTableViewInView:fromVC.view
                           delegate:self
                              title:@"Area Records"
                          textArray:areaRecs
                      includeCancel:YES];
        return;
    }
    
    LLPOINT llpoint = [proplist getPropertyLatLon:propNum];
    [proplist setZoomValues:propNum
                 withOption:column];
    
    CLLocationCoordinate2D ssCoords = CLLocationCoordinate2DMake(llpoint.lat, llpoint.lon);
    NSUInteger index = 0;
    
    MapViewController *mapVC = (MapViewController *)[NVTabBarEdit viewControllerWithID:@"MapVC"
                                                                    inTabBarController:tabBarController
                                                                                 index:&index];
    ConfigurationControl.sharedInstance.currentMapitBaseLayer = MBL_None;
    CRAPI.sharedInstance.justZoom = YES;

    if (mapVC)
    {
        mapVC.fromSpreadsheet = YES;
        mapVC.spreadsheetCoords = ssCoords;
    }
    
    tabBarController.selectedIndex = index;

}
- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    [popoverTableView hide:YES];
    
}

- (void)popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
}

- (NSMutableArray *) getOptionsForCell:(NSInteger)row
                                column:(NSInteger)column
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:@[@"Map It", @"Cancel"]];

    FieldListRecord *flr = nil;
        
    if (column < _fieldList.count)
    {
        flr = _fieldList[column];
        
        switch (flr.type)
        {
            case PFT_ProsAndCons:
                array = [NSMutableArray arrayWithArray:@[@"Show Pros And Cons"]];
                break;
            case PFT_PIN:
            case PFT_Address:
            case PFT_UserID:
                array = [NSMutableArray arrayWithArray:@[@"Zoom to This Property", @"Zoom to All Properties in List", @"Cancel"]];
                break;
            case PFT_LastSaleDate:
            case PFT_LastSalePrice:
                array = [NSMutableArray arrayWithArray:@[@"Show Sales History", @"Cancel"]];
                break;
            case PFT_Links:
                array = [NSMutableArray arrayWithArray:@[@"Get Links"]];
                break;
            default:break;
        }
    }

    return array;
}
- (void) displayPropHistory:(int)propNum
                     overVC:(UIViewController*)vc
{
    ChartsViewController *chartsVC = [ChartsViewController chartViewWithType:ChartsViewTypePropReport];
    NSString *PID = [_propList getPIDforPropnum:propNum];
    chartsVC.propHistoryArray = [PropertyData.new getParcelHistory:PID];
    [vc presentViewController:chartsVC animated:YES completion:nil];
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

- (void)setCurrentFieldList:(NSString *)fieldList
{
    [FieldList setCurrentFieldList:fieldList];
}

- (void)setCurrentPropList:(NSString *)propList
{
    [PropertyList setCurrentPropertyList:propList];
}

- (NSString *)vidDirForPropNum:(int)propNum
{
    return [PropertyList.new getVideoDirectory:propNum];
}

- (BOOL)addVideoClip:(RHClip *)clip
{
    BOOL clipAdded = [PropertyList.new addVideoClip:clip];
    
    if (clipAdded)
        {NSLog(@"RHClip successfully added:\n%@", clip);}
    
    return clipAdded;
}

- (NSArray *)clipsForProperty:(int)propNum
{
    return [PropertyList.new getVideoClipsForProperty:propNum];
}

@end
