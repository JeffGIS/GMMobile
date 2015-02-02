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
        NSURL *url=[self URLForTilePath:path];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:NSOperationQueue.mainQueue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   
                                   if (data)
                                   {
                                       [NSFileManager.defaultManager createDirectoryAtPath:filePath.stringByDeletingLastPathComponent
                                                               withIntermediateDirectories:YES
                                                                                attributes:nil
                                                                                     error:nil];
                                       
                                       if (![data writeToFile:filePath
                                                   atomically:YES])
                                       {
                                           NSLog (@"Failed to cache file");
                                       }
                                   }
                                   
                                   if (connectionError)
                                       NSLog(@"NSURL Connection Error:%@", connectionError.localizedDescription);
                                   
                                   result(data, connectionError);
                               }];
    }
}

- (void)cacheTileAtPath:(MKTileOverlayPath)path
              condition:(NSCondition *)condition
               complete:(int *)pComplete
                 failed:(int *)pFailed
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = paths.firstObject;
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%li/%li/%li",
                          cachesDirectory, _type, (long)path.z, (long)path.x, (long)path.y];

    if (![NSFileManager.defaultManager fileExistsAtPath:filePath])
    {
         NSURL *url = [self URLForTilePath:path];
         NSURLRequest *request = [NSURLRequest requestWithURL:url];
         
         [NSURLConnection sendAsynchronousRequest:request
                                            queue:NSOperationQueue.mainQueue
                                completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                    if (data)
                                    {
                                        [NSFileManager.defaultManager createDirectoryAtPath:filePath.stringByDeletingLastPathComponent
                                                                withIntermediateDirectories:YES
                                                                                 attributes:nil
                                                                                      error:nil];
                 
                                        if (![data writeToFile:filePath
                                                    atomically:YES])
                                        {
                                            NSLog (@"Failed to cache file");
                                            (*pFailed)++;
                                        }
                 
                                        else
                                            (*pComplete)++;
                                    }
             
                                    [condition lock];
                                    [condition signal];
                                    [condition unlock];
             
                                    if (connectionError)
                                        NSLog(@"NSURL Connection Error:%@", connectionError.localizedDescription);
             
                                }];
    }
    
    else
    {
        (*pComplete)++;
        [condition lock];
        [condition signal];
        [condition unlock];
    }
}

- (void)dealloc
{
    //NSLog (@"Dealloc called");
}

@end