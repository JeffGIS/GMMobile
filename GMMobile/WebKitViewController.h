//  WebKitViewController.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import <WebKit/WebKit.h>

@interface WebKitViewController : UIViewController <WKNavigationDelegate>

- (id)initWithPID:(NSString *)PID;

@end