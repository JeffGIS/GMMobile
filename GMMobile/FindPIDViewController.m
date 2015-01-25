//
//  FindPIDViewController.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/25/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "FindPIDViewController.h"
#import "ProperyData.h"

@interface FindPIDViewController ()
{
    NSMutableArray *_pidList;
    ProperyData *_propData;
}

@end

@implementation FindPIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _propData = [[ProperyData alloc]init];
    _pidEntry.delegate = self;
    _pidEntry.keyboardType = UIKeyboardTypeNumberPad;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    _pidList = [_propData getPIDsMatchingString:textField.text];
    
    return NO;
}

@end
