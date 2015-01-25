//
//  ProperyData.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/25/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface ProperyData : NSObject
{
    sqlite3 *_database;
   
}


-(NSMutableArray*) getPIDsMatchingString:(NSString*)matchChar;

@property BOOL isOpen;
@property NSString *path;
@end
