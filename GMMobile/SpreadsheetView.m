//  SpreadsheetView.m
//  GMMobile

#import "SpreadsheetView.h"
#import "../../CCodeLibrary/CCodeLibrary/UserDefaults.h"

@interface SpreadsheetView ()

@property (nonatomic) UIView *overlayView;
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
    {
        spreadsheetView.rowHeight = 40.0;
        spreadsheetView.columnWidth = 120.0;
    }
    
    else
    {
        spreadsheetView.rowHeight = 40.0;
        spreadsheetView.columnWidth = 160.0;
    }
    
    spreadsheetView.overlayView = [[UIView alloc] initWithFrame:view.frame];
    spreadsheetView.overlayView.backgroundColor = UIColor.blackColor;
    spreadsheetView.overlayView.alpha = 0.6;
    [view addSubview:spreadsheetView.overlayView];
    
    spreadsheetView.contentSize = CGSizeMake(((columns + 1) * spreadsheetView.columnWidth),
                                             ((rows + 1) * spreadsheetView.rowHeight));
    
    spreadsheetView.backgroundColor = UIColor.blackColor;
    spreadsheetView.layer.borderColor = UIColor.blackColor.CGColor;
    spreadsheetView.layer.borderWidth = 2.0;
    
    UIView *contentView = [[UIView alloc] initWithFrame:spreadsheetView.bounds];
    contentView.backgroundColor = UIColor.clearColor;
    [spreadsheetView addSubview:contentView];
    
    spreadsheetView.alphabet = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M",
                                 @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
    
    for (int r = 0; r <= rows; r++)
    {
        for (int c = 0; c <= columns; c++)
        {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((c * spreadsheetView.columnWidth),
                                                                       (r * spreadsheetView.rowHeight),
                                                                       spreadsheetView.columnWidth,
                                                                       spreadsheetView.rowHeight)];
            
            if (r == 0 && c == 0)
            {
                label.text = @"< Return";
                label.font = [UIFont boldSystemFontOfSize:24.0];
                label.backgroundColor = UIColor.blackColor;
                label.textColor = UIColor.whiteColor;
                
            }
            
            else if (r == 0)
            {
                label.text = spreadsheetView.alphabet[c];
                label.font = [UIFont boldSystemFontOfSize:24.0];
                label.backgroundColor = UserDefaults.defaults.appleGray;
            }
            
            else if (c == 0)
            {
                label.text = [NSString stringWithFormat:@"%i", r];
                label.font = [UIFont boldSystemFontOfSize:24.0];
                label.backgroundColor = UserDefaults.defaults.appleGray;
            }
            
            else
            {
                label.text = [NSString stringWithFormat:@"%@%i", spreadsheetView.alphabet[c], r];
                label.backgroundColor = UIColor.whiteColor;
                label.textColor = UIColor.blackColor;
            }
            
            label.textAlignment = NSTextAlignmentCenter;
            label.layer.borderWidth = 1.0;
            label.layer.borderColor = UIColor.blackColor.CGColor;
            [contentView addSubview:label];
        }
    }
    
    return spreadsheetView;
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self];
    CGPoint identifier = CGPointMake((point.x / _columnWidth), (point.y / _rowHeight));
    
    NSUInteger xPoint = identifier.x;
    NSUInteger yPoint = identifier.y;
    
    NSString *selection;
    
    if (xPoint == 0 && yPoint == 0)
    {
        [_overlayView removeFromSuperview];
        [self removeFromSuperview];
    }
    
    else if (xPoint == 0)
        NSLog(@"Selected Row:%lu", (unsigned long)yPoint);
    
    else if (yPoint == 0)
        NSLog(@"Selected Column:%lu", (unsigned long)xPoint);
    
    else
    {
        selection = [NSString stringWithFormat:@"%@%lu", _alphabet[xPoint], (unsigned long)yPoint];
        NSLog(@"Selected Cell:%@", selection);
    }
}

@end