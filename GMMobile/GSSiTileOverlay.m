//  GSSiTileOverlay.m
//  GMMobile

#import "GSSiTileOverlay.h"

@implementation GSSiTileOverlay

- (void)loadTileAtPath:(MKTileOverlayPath)path
                result:(void (^)(NSData *data, NSError *error))result
{
    if (!result)
    {
        return;
    }
    
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *key = [NSString stringWithFormat:@"%@", [self URLForTilePath:path]];
    NSData *cachedData = [defaults objectForKey:key];
    
    if (cachedData)
        result(cachedData, nil);
    
    else
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:NSOperationQueue.mainQueue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   
                                   if (data)
                                   {
                                       [defaults setObject:data
                                                    forKey:key];
                                       
                                       [defaults synchronize];
                                   }
                                   
                                       result(data, connectionError);
                               }];
    }
}

@end