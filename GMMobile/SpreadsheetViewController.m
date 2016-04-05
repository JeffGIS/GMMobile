//  SpreadsheetViewController.m
//  GMMobile

#import "SpreadsheetViewController.h"
#import "CCodeLibrary/NVTabBarEdit.h"
#import "MapViewController.h"
#import "CCodeLibrary/NVWebKitVC.h"

@interface SpreadsheetViewController ()

@property (nonatomic) NVSpreadsheetView *ssv;
@property (nonatomic) NSUInteger selectedRow, selectedColumn, numRows, numColumns;

@end

@implementation SpreadsheetViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.blackColor;
    _selectedRow = _selectedColumn = 0;
    _numRows = (PropertyList.new.availablePropertyFields.count - 1);
    _numColumns = 16;
    
    _ssv = [NVSpreadsheetView showSpreadsheetWithRows:_numRows
                                              columns:_numColumns
                                                 view:self.view
                                              flipped:NO
                                             delegate:self];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pasteboardChanged:)
                                               name:UIPasteboardChangedNotification
                                             object:UIPasteboard.generalPasteboard];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:NSBundle.mainBundle];
    
    UIViewController *fovc = [storyboard instantiateViewControllerWithIdentifier:@"FieldOptionsVC"];
    
    [NVTabBarEdit tabBarController:self.tabBarController
       replaceViewControllerWithID:@"FindVC"
                withViewController:fovc];
    
    UIViewController *dvc = [storyboard instantiateViewControllerWithIdentifier:@"DestinationsVC"];
    
    [NVTabBarEdit tabBarController:self.tabBarController
       replaceViewControllerWithID:@"ApplicationsVC"
                withViewController:dvc];
    
    [self populateSpreadsheetCells];
}

- (void)pasteboardChanged:(id)selector
{
    NSLog(@"Pasteboard Item:%@", UIPasteboard.generalPasteboard.strings.lastObject);
}

- (void)populateSpreadsheetCells
{
    PropertyList *proplist = PropertyList.new;
    proplist.delegate = self;
    NSArray *props = [proplist getPropertyNumbers];
    NSArray *fields = [proplist availablePropertyFields];
    
    _ssv.activeColumns = props.count;
    _ssv.activeRows = fields.count;
    
    NSMutableArray *fieldNames = NSMutableArray.array;
    
    for (NSNumber *field in fields)
    {
        if (field.integerValue != PFT_UserID)
        {
            NSString *fieldName = [proplist propertyFieldName:field.integerValue];
            [fieldNames addObject:fieldName];
        }
    }
    
    [_ssv setRowHeaderText:fieldNames];
    
    for (NSNumber *pnum in props)
    {
        NSInteger iprop = pnum.integerValue;
        
        for (NSNumber *field in fields)
        {
            [proplist getPropertyFieldValueOfType:field.integerValue
                                forPropertyNumber:iprop];
        }
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)PropertyList:(PropertyList *)propList
        returnsValue:(NSString *)value
   forPropertyNumber:(NSInteger)propNum
        andFieldType:(PropFieldType)type
          withStatus:(long)status;
{
    [_ssv setText:value
     forCellAtRow:type
           column:propNum];
}

- (NSString *)ssvGetTitleText
{
    return [PropertyList getCurrentPropertyListName];
}

- (BOOL)ssvDidEditTitleText:(NSString *)text
{
    return [PropertyList renameCurrentPropertyList:text];
}

- (NSArray *)ssvGetFileList
{
    return [PropertyList getPropertyLists];
}

- (void)ssvSetCurrentFile:(NSString *)file
{
    [PropertyList setCurrentPropertyList:file];
    [self resetSSV];
}

- (BOOL)ssvDeleteCurrentFile
{
    if ([PropertyList deleteCurrentPropertyList])
    {
        [self resetSSV];
        return YES;
    }
    
    return NO;
}

- (void)ssvCreateWasTapped
{
    [PropertyList createNewPropertyList];
    [self resetSSV];
}

- (void)ssvDidEditColumnHeaderText:(NSString *)text
                           atIndex:(NSUInteger)index
{
    PropertyList *proplist = PropertyList.new;
    
    [proplist updatePropertyUserID:index
                            userID:text];
}

- (void)ssvCellWasTappedAtRowIndex:(NSUInteger)rowIndex
                       columnIndex:(NSUInteger)columnIndex
{
    _selectedRow = rowIndex;
    _selectedColumn = columnIndex;
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:@"Spreadsheet Options"
                                               buttonTextArray:@[@"Map It", @"Cancel"]
                                              destructiveIndex:0];
#pragma unused(alert)
}

- (void)ssvDidSetFlipped:(BOOL)flipped
{
    [_ssv removeFromSuperview];
    _numRows = (PropertyList.new.availablePropertyFields.count - 1);
    
    if (![self.view.subviews containsObject:_ssv])
    {
        _ssv = [NVSpreadsheetView showSpreadsheetWithRows:_numRows
                                                  columns:_numColumns
                                                     view:self.view
                                                  flipped:flipped
                                                 delegate:self];
        
        [self populateSpreadsheetCells];
    }
}

- (void)ssvDidRequestWebViewAtURL:(NSString *)URL
{
    NVWebKitVC *nvwkvc = NVWebKitVC.new;
    nvwkvc.urlString = URL;
    
    [self presentViewController:nvwkvc
                       animated:YES
                     completion:nil];
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        PropertyList *proplist = [[PropertyList alloc] init];
        
        LLPOINT llpoint = [proplist getPropertyLatLon:_selectedColumn];
        
        [proplist setZoomValues:_selectedColumn
                         forRow:_selectedRow];
        
        CLLocationCoordinate2D ssCoords = CLLocationCoordinate2DMake(llpoint.lat, llpoint.lon);
        NSUInteger index = 0;
        
        MapViewController *mapVC = (MapViewController *)[NVTabBarEdit viewControllerWithID:@"MapVC"
                                                                        inTabBarController:self.tabBarController
                                                                                     index:&index];
        
        if (mapVC)
        {
            mapVC.fromSpreadsheet = YES;
            mapVC.spreadsheetCoords = ssCoords;
        }
        
        self.tabBarController.selectedIndex = index;
    }
    
    [alertView hideLargeAlertView:YES];
}

- (void)resetSSV
{
    [_ssv clearContents];
    [self populateSpreadsheetCells];
}

@end