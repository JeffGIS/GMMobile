//  FindPIDViewController.m
//  GMMobile

#import "FindPIDViewController.h"
#import "PropertyData.h"

@interface FindPIDViewController ()

@property (nonatomic) NSMutableArray *pidList;
@property (nonatomic) PropertyData *propData;

@end

@implementation FindPIDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _propData = [[PropertyData alloc] init];
    _pidEntry.delegate = self;
    _pidEntry.keyboardType = UIKeyboardTypeNumberPad;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    _pidList = [_propData getPIDsMatchingString:textField.text];
    NSString *pid = _pidList[0];
    LLPOINT pt = [_propData getPointForPID:pid];
    pid = [_propData pickPID:pt];
    
    _pidList = [_propData getPIDsMatchingAddress:5144
                                      streetName:@"30"];
    return NO;
}

@end