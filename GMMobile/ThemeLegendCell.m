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

/*- (void)setStatus:(BOOL)status
{
    int ii;
    _status = status;
    if ([_label containsString:@"Homicide"] && !status)
        ii=1;
}*/

- (id)copyWithZone:(NSZone *)zone
{
    ThemeLegendCell *another = [[ThemeLegendCell allocWithZone: zone] init];
    
    another.count = _count;
    another.symbolWidth = _symbolWidth;
    another.symbol = _symbol;
    another.status = _status;
    another.symbolColor = _symbolColor.copy;//[[UIColor alloc] initWithCGColor:_symbolColor.CGColor];
    another.label = [NSString stringWithString:_label];
    return  another;
}

- (void) setSymbolColor:(UIColor *)symbolColor
{
    _symbolColor = symbolColor;
}
@end
