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
    
    NSCache *cache = [[NSCache alloc] init];
    NSData *cachedData = [cache objectForKey:[self URLForTilePath:path]];
    
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
                                       [cache setObject:data
                                                 forKey:[self URLForTilePath:path]];
                                   }
                                   
                                       result(data, connectionError);
                               }];
    }
}

@end