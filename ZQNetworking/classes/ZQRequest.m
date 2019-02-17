//
//  ZQRequest.m
//  ZQNetworking
//
//  Created by nobby heell on 2019/2/14.
//  Copyright © 2019年 nobby heell. All rights reserved.
//

#import "ZQRequest.h"

@interface ZQRequest()
@property (nonatomic, assign, readwrite) int retryCount;
@property (nonatomic, copy, readwrite) NSString *paramStr;
@end

@implementation ZQRequest

+ (instancetype)requestWithURLString:(NSString *)urlString params:(NSDictionary *)params;
{
    ZQRequest *request = [[ZQRequest alloc] init];
    request.urlStr = urlString;
    request.params = params;
    return request;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.retryCount = 3;
        self.reliability = ZQRequestReliabilityRetry;
        self.method = ZQRequestTypeGet;
        self.cacheKey = nil;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ZQRequest *request = [[[self class] allocWithZone:zone] init];
    request.retryCount = self.retryCount;
    request.reliability = self.reliability;
    request.method = self.method;
    request.cacheKey = self.cacheKey;
    request.requestId = self.requestId;
    request.params = self.params;
    request.urlStr = self.urlStr;
    request.paramStr = self.paramStr;
    
    return request;
}

- (void)setReliability:(ZQRequestReliability)reliability
{
    _reliability = reliability;
    
    if (reliability == ZQRequestReliabilityNormal)
    {
        _retryCount = 1;
    }
    
    [self setParams:_params];
}


- (void)reduceRetryCount
{
    self.retryCount--;
    if (self.retryCount < 0) self.retryCount = 0;
}

- (BOOL)isEqual:(ZQRequest *)object
{
    if (object == nil) return false;
    
    if (object.requestId == self.requestId || object == self) return true;
    
    return false;
}

- (void)setParams:(NSDictionary *)params
{
    _params = params;
    
    if (!params) return;
    
    if (_reliability == ZQRequestReliabilityStoreToDB)
    {
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.params options:NSJSONWritingPrettyPrinted error:nil];
        self.paramStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err
{
    self = [super initWithDictionary:dict error:nil];
    if (_paramStr && _paramStr.length) {
        NSData *data = [_paramStr dataUsingEncoding:NSUTF8StringEncoding];
        _params = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    return self;
}

@end
