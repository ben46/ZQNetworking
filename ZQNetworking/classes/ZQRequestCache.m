//
//  ZQRequestCache.m
//  ZQNetworking
//
//  Created by nobby heell on 2019/2/14.
//  Copyright © 2019年 nobby heell. All rights reserved.
//

#import "ZQRequestCache.h"
#import "ZQRequest.h"
#import "YQDStorageUtils.h"

@implementation ZQRequestCache

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static id sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ZQRequestCache alloc] init];
    });
    return sharedInstance;
}

- (NSData *)readDataForKey:(NSString *)key;
{
    return [YQDStorageUtils readDataFromFileByUrl:key];
}

- (void)saveData:(NSData *)data ForKey:(NSString *)key
{
    [YQDStorageUtils saveUrl:key withData:data];
}

- (void)saveRequestToDatabase:(ZQRequest *)request{
    ZQRequest *dbreq = [ZQRequest JM_findFirstWithRaw:@"order by requestId desc"];
    if (dbreq) {
        if (request.requestId == 0) {
            request.requestId = @(dbreq.requestId.integerValue + 1);
        }
        [request JM_insert];
    } else {
        request.requestId = @(1);
        [request JM_insert];
    }
}

- (NSArray *)allRequestsFromDatabase;
{
    return [ZQRequest JM_all];
}

- (void)deleteRequestFromDatabaseWithRequestId:(int)requestId;
{
    [ZQRequest JM_deleteWithPrimaryKeyValue:@(requestId)];
}


@end
