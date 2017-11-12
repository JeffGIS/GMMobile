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


@interface MinnesotaGame : NSObject<NVPopoverTableViewDelegate,GSSiPopoverViewDelegate>

@property LPTRANDATA pTranLLtoView;
@property LPTRANDATA pTranViewtoLL;
@property float delayBetweenItems;
@property int itemsCompleted, totalItems, maxDistance;
@property int refno;
@property int group;
@property NSString *areaType;
@property int attempts;
@property int gameDuration;
@property (nonatomic, weak) UIView *parentView;
@property NSTimer * timer;
@property NSTimer * gameTimer;
@property int endTime;
@property UILabel * headerLabel;
@property UILabel * distanceLabel;
@property UILabel * timerLabel;
@property UIImageView * hourglassImage;
@property UIImageView * happySadImage;
@property double distance;
@property int totDistance;
@property int bestGuess;
@property DPOINT minPoint;
@property DPOINT bestGuessPoint;
@property BOOL wantViews;
@property NSArray * choices;
@property NSString * itemType;
@property int itemCount;
@property NSString * itemDescription;
@property int numGroups, numPerGroup, numChoicesPerItem;
@property NSMutableArray *usedChoices;
@property NSArray * groupNames;
@property NSArray * groupName;
@property UIViewController * mvc;
@property NVPopoverTableView *poTableView;
@property GSSiPopoverView *popoverView;

- (void)displayPickedPoint:(LLPOINT)pt
                 inContext:(CGContextRef)context
                 llCorners:(CORNERPOINTS *)latlonCornerPoints
                  LLBounds:(MNMXCORD *)platlonBounds
                viewBounds:(MNMXCORD *)pvbounds;
-(void) bringViewsToFront:(BOOL)fromTimer;

@end
