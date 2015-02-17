//  VectorView.m
//  GMMobile

#import "VectorView.h"
#import "BoundaryData.h"
#import "PropertyData.h"

@implementation VectorView

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.opaque = NO;
        self.backgroundColor = UIColor.clearColor;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (_displayData)
    {
        _viewBounds.xmn = self.bounds.origin.x;
        _viewBounds.xmx = (self.bounds.origin.x + self.bounds.size.width);
        _viewBounds.ymn = (self.bounds.origin.y + self.bounds.size.height);
        _viewBounds.ymx = self.bounds.origin.y;
        if (_zoom >= CRAPI.sharedInstance.parcelsVisibleAtZoom)
        {
            PropertyData *pd = [[PropertyData alloc] init];
            
            [pd displayParcels:context
                      LLBounds:&_latlonBounds
                    viewBounds:&_viewBounds];
            
            [pd displayParcelText:context
                         LLBounds:&_latlonBounds
                       viewBounds:&_viewBounds];
            
        }
        if (CRAPI.sharedInstance.currentOverallBoundaryRefno)
        {
            BoundaryData *bd = [[BoundaryData alloc]init];
            [bd displayBoundary:CRAPI.sharedInstance.currentOverallBoundaryRefno inContext:context
                       LLBounds:&_latlonBounds
                     viewBounds:&_viewBounds];
        }
    }
    
}

@end