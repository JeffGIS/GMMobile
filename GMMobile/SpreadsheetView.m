//  SpreadsheetView.m
//  GMMobile

#import "SpreadsheetView.h"
#import "SpreadSheetViewCell.h"
#import "../../CCodeLibrary/CCodeLibrary/UserDefaults.h"

@interface SpreadsheetView ()

@property (nonatomic) UIView *overlayView, *contentView;
@property (nonatomic) NSArray *alphabet;

@end

@implementation SpreadsheetView

@dynamic delegate;

+ (SpreadsheetView *)spreadsheetViewWithRows:(NSUInteger)rows
                                     columns:(NSUInteger)columns
                                       view:(UIView *)view
{
    CGRect frame;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        frame = CGRectMake(20.0, 20.0, (view.frame.size.width - 40.0),
                           (view.frame.size.height - 40.0));
    }
    
    else
    {
        frame = CGRectMake(60.0, 60.0, (view.frame.size.width - 120.0),
                           (view.frame.size.height - 120.0));
    }
    
    SpreadsheetView *spreadsheetView = [[SpreadsheetView alloc] initWithFrame:frame];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        spreadsheetView.columnWidth = 120.0;
    
    else
        spreadsheetView.columnWidth = 160.0;
    
    spreadsheetView.rowHeight = 40.0;
    spreadsheetView.overlayView = [[UIView alloc] initWithFrame:view.frame];
    spreadsheetView.overlayView.backgroundColor = UIColor.blackColor;
    spreadsheetView.overlayView.alpha = 0.6;
    [view addSubview:spreadsheetView.overlayView];
    
    spreadsheetView.contentSize = CGSizeMake(((columns + 1) * spreadsheetView.columnWidth),
                                             ((rows + 1) * spreadsheetView.rowHeight));
    
    spreadsheetView.backgroundColor = UIColor.blackColor;
    spreadsheetView.layer.borderColor = UIColor.blackColor.CGColor;
    spreadsheetView.layer.borderWidth = 2.0;
    
    spreadsheetView.contentView = [[UIView alloc] initWithFrame:spreadsheetView.bounds];
    spreadsheetView.contentView.backgroundColor = UIColor.clearColor;
    [spreadsheetView addSubview:spreadsheetView.contentView];
    
    spreadsheetView.alphabet = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M",
                                 @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
    
    for (int r = 0; r <= rows; r++)
    {
        for (int c = 0; c <= columns; c++)
        {
            SpreadSheetViewCell *cell = [[SpreadSheetViewCell alloc] initWithFrame:CGRectMake((c * spreadsheetView.columnWidth),
                                                                                              (r * spreadsheetView.rowHeight),
                                                                                              spreadsheetView.columnWidth,
                                                                                              spreadsheetView.rowHeight)];
            
            if (r == 0 && c == 0)
            {
                cell.identifier = @"< Return";
                cell.font = [UIFont boldSystemFontOfSize:24.0];
                cell.backgroundColor = UIColor.blackColor;
                cell.textColor = UIColor.whiteColor;
                
            }
            
            else if (r == 0)
            {
                cell.identifier = spreadsheetView.alphabet[c - 1];
                cell.font = [UIFont boldSystemFontOfSize:24.0];
                cell.backgroundColor = UserDefaults.defaults.appleGray;
            }
            
            else if (c == 0)
            {
                cell.identifier = [NSString stringWithFormat:@"%i", r];
                cell.font = [UIFont boldSystemFontOfSize:24.0];
                cell.backgroundColor = UserDefaults.defaults.appleGray;
            }
            
            else
            {
                cell.identifier = [NSString stringWithFormat:@"%@%i", spreadsheetView.alphabet[c - 1], r];
                cell.backgroundColor = UIColor.whiteColor;
                cell.textColor = UIColor.blackColor;
            }
            
            cell.row = r;
            cell.column = c;
            cell.text = cell.identifier;
            [spreadsheetView.contentView addSubview:cell];
        }
    }
    
    return spreadsheetView;
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self];
    CGPoint pointID = CGPointMake((point.x / _columnWidth), (point.y / _rowHeight));
    
    int xPoint = pointID.x;
    int yPoint = pointID.y;
    
    NSString *selection;
    
    if (xPoint == 0 && yPoint == 0)
    {
        [_overlayView removeFromSuperview];
        [self removeFromSuperview];
    }
    
    else if (xPoint == 0)
    {
        for (SpreadSheetViewCell *cell in _contentView.subviews)
        {
            if (cell.row == yPoint)
                cell.selected = !cell.selected;
        }
    }
    
    else if (yPoint == 0)
    {
        for (SpreadSheetViewCell *cell in _contentView.subviews)
        {
            if (cell.column == xPoint)
                cell.selected = !cell.selected;
        }
    }
    
    else
    {
        selection = [NSString stringWithFormat:@"%@%i", _alphabet[xPoint - 1], yPoint];
        
       for (SpreadSheetViewCell *cell in _contentView.subviews)
        {
            if ([cell.identifier isEqualToString:selection])
                cell.selected = !cell.selected;
        }
    }
}

@end