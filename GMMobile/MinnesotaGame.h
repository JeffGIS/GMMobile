//
//  MinnesotaGame.h
//  NVMobile
//
//  Created by Jeff Smith on 11/9/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import "CCodeLibrary/NVPopoverTableView.h"


@interface MinnesotaGame : NSObject<NVPopoverTableViewDelegate>

@property LPTRANDATA pTranLLtoView;
@property LPTRANDATA pTranViewtoLL;
@property int refno;
@property int attempts;
@property (nonatomic, weak) UIView *parentView;
@property NSTimer * timer;
@property UILabel * headerLabel;
@property UILabel * distanceLabel;
@property UILabel * timerLabel;
@property double distance;
@property BOOL wantViews;
@property UIViewController * mvc;

- (void)displayPickedPoint:(LLPOINT)pt
                 inContext:(CGContextRef)context
                 llCorners:(CORNERPOINTS *)latlonCornerPoints
                  LLBounds:(MNMXCORD *)platlonBounds
                viewBounds:(MNMXCORD *)pvbounds;
-(void) bringViewsToFront;

@end
