//  ThemeLegendCell.m
//  GMMobile

#import "ThemeLegendCell.h"

@implementation ThemeLegendCell

+ (ThemeLegendCell *)createWithLabel:(NSString *)label
{
    ThemeLegendCell *class = [[ThemeLegendCell alloc] init];
    class.label = label;
    return class;
}

- (id)copyWithZone:(NSZone *)zone
{
    ThemeLegendCell *another = [[ThemeLegendCell allocWithZone:zone] init];
    another.count = _count;
    another.symbolWidth = _symbolWidth;
    another.symbol = _symbol;
    another.status = _status;
    another.symbolColor = _symbolColor.copy;
    another.label = [NSString stringWithString:_label];
    return another;
}
- (void)setStatus:(int)status
{
    int ii;
    _status = status;
    if (status == 2)
        ii=status;
}

@end
