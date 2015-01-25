//  GSSiTileOverlay.m
//  GMMobile

#import "GSSiTileOverlay.h"

@implementation GSSiTileOverlay

- (void)loadTileAtPath:(MKTileOverlayPath)path
                result:(void (^)(NSData *data, NSError *error))result
{
    if (!result)
        return;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = paths.firstObject;
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%li/%li/%li",
                          cachesDirectory, _type, (long)path.z, (long)path.x, (long)path.y];
    
    if ([NSFileManager.defaultManager fileExistsAtPath:filePath])
    {
        NSData *cachedData = [NSData dataWithContentsOfFile:filePath];
        
        if (cachedData)
            result(cachedData, nil);
    }
    
    else
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:NSOperationQueue.mainQueue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   
                                   if (!data)
                                       return;

                                    NSLog(@"Length:%lu", (unsigned long)data.length);
                                       
                                    [NSFileManager.defaultManager createDirectoryAtPath:filePath.stringByDeletingLastPathComponent
                                                            withIntermediateDirectories:YES
                                                                             attributes:nil
                                                                                  error:nil];
                                       
                                    if (![data writeToFile:filePath
                                                atomically:YES])
                                    {
                                        NSLog (@"Failed to cache file");
                                    }
                                   
                                   if (connectionError)
                                       NSLog(@"NSURL Connection Error:%@", connectionError.localizedDescription);
                                   
                                   result(data, connectionError);
                               }];
    }
}

@end