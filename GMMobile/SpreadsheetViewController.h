//  SpreadsheetViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "PropertyList.h"
#import "CCodeLibrary/NVSpreadsheetView.h"

@interface SpreadsheetViewController : UIViewController <PropertyListDelegate,NVSpreadsheetViewDelegate>

@end