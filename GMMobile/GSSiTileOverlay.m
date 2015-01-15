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
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = paths.firstObject;
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%li/%li/%li",
                          cachesDirectory, _type, (long)path.z, (long)path.x, (long)path.y];
    
    if ([NSFileManager.defaultManager fileExistsAtPath:filePath])
    {
        NSData *cachedData = [NSData dataWithContentsOfFile:filePath];
        result(cachedData, nil);
    }
    
    else
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:NSOperationQueue.mainQueue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   
                                   if (data)
                                   {
                                       [data writeToFile:filePath
                                              atomically:YES];
                                   }
                                   
                                       result(data, connectionError);
                               }];
    }
}

@end