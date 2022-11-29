//
//  CompassViewController.h
//  NVMobile
//
//  Created by Jeff Smith on 10/21/22.
//  Copyright © 2022 GSSi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCodeLibrary/CRAPI.h"
#import "HuntingData.h"

NS_ASSUME_NONNULL_BEGIN

@interface CompassViewController : UIViewController<CLLocationManagerDelegate,NVPopoverTableViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *compassImage;
@property (strong, nonatomic) IBOutlet NSObject *topGuide;

@end

NS_ASSUME_NONNULL_END
