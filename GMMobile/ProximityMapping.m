//
//  ProximityMapping.m
//  NVMobile
//
//  Created by Jeff Smith on 9/29/23.
//  Copyright © 2023 GSSi. All rights reserved.
//

#import "ProximityMapping.h"

@implementation CellPointOffsets
@synthesize xoff,yoff;
@synthesize dst;
@end

@interface ProximityMapping ()
@property int cellWidth, cellHeight;
@property int contextWidth, contextHeight;
@property NSArray * offsets;

@end

@implementation ProximityMapping
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _cellWidth = _cellHeight = 256;
        _contextWidth = _contextHeight = _cellWidth * 3;
        [self createOffsets];
    }
    return self;
}

-(void) createOffsets
{
    NSMutableArray *arr = NSMutableArray.new;
    DPOINT centerpt={_cellWidth/2,_cellWidth/2};
    DPOINT pt;
    double maxdist = _cellWidth/2;
    int dst;
    for (int irow = 0;irow<_cellHeight;irow++)
    {
        pt.y = irow;
        for (int icol = 0;icol<_cellWidth;icol++)
        {
            pt.x = icol;
            dst = 100 * (ldistpp (&centerpt,&pt)/maxdist);
            CellPointOffsets * cpo = CellPointOffsets.new;
            cpo.yoff = irow;
            cpo.xoff = icol;
            cpo.dst = dst;
            if (dst <= 100)
                [arr addObject:cpo];
        }
    }
    
    NSArray* sorted = [arr sortedArrayUsingComparator:^(id obj1, id obj2){
        if ([obj1 isKindOfClass:[CellPointOffsets class]] && [obj2 isKindOfClass:[CellPointOffsets class]]) {
            CellPointOffsets * cpo1 = obj2;
            CellPointOffsets * cpo2 = obj1;

            if (cpo1.dst > cpo2.dst) {
                return (NSComparisonResult)NSOrderedAscending;
            } else if (cpo1.dst < cpo2.dst) {
                return (NSComparisonResult)NSOrderedDescending;
            }
        }
        return (NSComparisonResult)NSOrderedSame;
    }];

    _offsets = sorted;
    CellPointOffsets *last = _offsets.lastObject;
    return;
}

-(void) CreateCell
{
    
}
-(int) CreateSurface
{
    int rtn = 0;
    return rtn;
}

- (void)dealloc
{
    
}

@end
