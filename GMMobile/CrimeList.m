//
//  CrimeList.m
//  NVMobile
//
//  Created by Jeff Smith on 4/5/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import "CrimeList.h"

@implementation CrimeList

@end

NSString* CrimeListFieldDescription (NSInteger fieldNumber)
{
    NSString *file;
    
    NSString *name = [NSString stringWithFormat:@"PropListField_%li",(long)fieldNumber];
    file = [NSBundle.mainBundle pathForResource:name ofType:@"pdf"];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:file])
        file = [NSBundle.mainBundle pathForResource:@"PropListField_default" ofType:@"pdf"];
    return file;
}

