//  SpreadSheetViewCell.m
//  GMMobile

#import "SpreadSheetViewCell.h"
#import "../../CCodeLibrary/CCodeLibrary/UserDefaults.h"

@implementation SpreadSheetViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.textAlignment = NSTextAlignmentCenter;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = UIColor.blackColor.CGColor;
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected
{
    if (selected == YES)
    {
        if (_row == 0 || _column == 0)
        {
            self.backgroundColor = UserDefaults.defaults.appleBlue;
            self.textColor = UIColor.whiteColor;
        }
        
        else
        {
            self.textColor = UserDefaults.defaults.appleBlue;
            self.layer.borderWidth = 2.0;
            self.layer.borderColor = UserDefaults.defaults.appleBlue.CGColor;
        }
        
        _selected = YES;
    }
    
    else
    {
        if (_row == 0 || _column == 0)
            self.backgroundColor = UserDefaults.defaults.appleGray;
        
        else
        {
            self.layer.borderWidth = 1.0;
            self.layer.borderColor = UIColor.blackColor.CGColor;
        }
        
        self.textColor = UIColor.blackColor;
        _selected = NO;
    }
}

@end