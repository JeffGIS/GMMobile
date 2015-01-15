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
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%li/%li/%li",
                          documentsDirectory, _type, (long)path.z, (long)path.x, (long)path.y];
    
    NSData *cachedData = [NSData dataWithContentsOfFile:filePath];
    
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
                                       [data writeToFile:filePath
                                              atomically:YES];
                                   }
                                   
                                       result(data, connectionError);
                               }];
    }
}

@end