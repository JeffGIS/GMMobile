//  SpreadsheetViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "PropertyList.h"
#import "CCodeLibrary/NVSpreadsheetView.h"
#import "CCodeLibrary/NVAlertView.h"

@interface SpreadsheetViewController : UIViewController <PropertyListDelegate,NVSpreadsheetViewDelegate,NVAlertViewDelegate>

@end