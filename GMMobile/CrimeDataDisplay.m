//
//  CrimeDataDisplay.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/3/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import "CrimeDataDisplay.h"

@implementation CrimeDataDisplay
{
    CrimeData *_cd;
}

- (BOOL)continue
{
    if (self.processingID == keepProcessing)
        return YES;
    
    return NO;
}
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _cd = [[CrimeData alloc]init];
    }
    
    return self;
}

- (void)dealloc
{
    [_cd close];
    NSLog(@"Sewer Database dealloc");
}


- (void)setTrans:(CORNERPOINTS *)corners
      viewBounds:(MNMXCORD *)pvbounds
{
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    _pTranLLtoView = STRANCornersToBounds(corners, pvbounds);
}



- (void)displayCrimePoints:(CGContextRef)context
    displayCharacteristics:(DisplayCharacteristics *)dc
                 llCorners:(CORNERPOINTS *) latlonCornerPoints
                  LLBounds:(MNMXCORD *)platlonBounds
                viewBounds:(MNMXCORD *)pvbounds
{
    NSString *query;
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt;
    int UCR;
    int controlNbr;
    int fromTime=(int)CRAPI.sharedInstance.fromDate, toTime=(int)CRAPI.sharedInstance.toDate;
    int nFound=0;
    LPSTR offense;
    CGFloat size;
    CGColorRef color=0;
    CGFloat sizeFactor = 5;
    
    if (_zoom > 18)
        sizeFactor *= (2.0 *(_zoom - 18.0));
    
    else if (_zoom < 18)
        sizeFactor /= (2.0 * (18.0 - _zoom));
    
    if (![self continue])
        return;
    
    [self setTrans:latlonCornerPoints viewBounds:pvbounds];
    
    [_cd open];
    _minUCR = 1;
    _maxUCR = 10;
    switch (CRAPI.sharedInstance.project)
    {
        case PROJECT_METROGIS:
            query = [NSString stringWithFormat:@"SELECT ControlNbr,X,Y,Offense,UCR,FromDate,ToDate FROM OFFENSEXY,OFFENSEXY_index WHERE OFFENSEXY.id=OFFENSEXY_index.id AND OFFENSEXY_index.maxX>=%f AND OFFENSEXY_index.minX<=%f AND OFFENSEXY_index.maxY>=%f AND OFFENSEXY_index.minY<=%f AND OFFENSEXY_index.MinUCR>=%f AND OFFENSEXY_index.MaxUCR<=%f AND OFFENSEXY_index.minTime>=%f AND OFFENSEXY_index.maxTime <= %f",
                     platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx,_minUCR*10.0-1,_maxUCR*10.0+1,fromTime/1000.0-1,toTime/1000.0+1];
    }
    
    SQLOK(sqlite3_prepare_v2(_cd.database, query.UTF8String, -1, &statement, 0), _cd.database);
    
    while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
    {
        nFound++;
        controlNbr = sqlite3_column_int(statement,0);
        BasePt.x = sqlite3_column_double(statement,1);
        BasePt.y = sqlite3_column_double(statement,2);
        offense = (LPSTR)sqlite3_column_text(statement,3);
        UCR = sqlite3_column_int(statement,4);
        dc.itemBeginTime = sqlite3_column_int(statement,5);
        dc.itemEndTime = sqlite3_column_int(statement,6);
        [ConfigurationControl.sharedInstance setDisplayCharacteristics:dc
                                                             displayID:_processingID];
        DPOINT llpoint = TranDPOINT(&BasePt, _pTranLLtoView);
        
        if (UCR < 6)
        {
            //color = _red.CGColor;
            size = 20.0;
        }
        else
        {
            color = UIColor.brownColor.CGColor;
            size = 16.0;
        }
        [self drawCrimePoint:context
                     atPoint:&llpoint
                   withColor:color
                     andSize:(size * sizeFactor)];
    }
    SQLOK(sqlite3_finalize(statement), _cd.database);
    [_cd close];
}

- (void)drawCrimePoint:(CGContextRef)context
               atPoint:(DPOINT *)pPoint
             withColor:(CGColorRef)color
               andSize:(CGFloat)size

{
    CGRect pointRect = CGRectMake((pPoint->x - size / 2.0),
                                  (pPoint->y - size / 2.0), size, size);
    
    //CGContextSetStrokeColorWithColor(context,color);
    CGContextSetFillColorWithColor(context,color);
    CGContextFillEllipseInRect(context, pointRect);
    //CGContextStrokeEllipseInRect(context, pointRect);
    //CGContextFillPath(context);
}

@end
