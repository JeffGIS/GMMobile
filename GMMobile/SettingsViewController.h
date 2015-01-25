//
//  SettingsViewController.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/25/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface SettingsViewController : UIViewController<FTPDataPullDelegate>
- (IBAction)loadDatabase:(id)sender;
- (IBAction)preloadTiles:(id)sender;

@end
