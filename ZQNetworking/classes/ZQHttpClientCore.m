//
//  ZQHttpClientCore.m
//  ZQNetworking
//
//  Created by nobby heell on 2019/2/14.
//  Copyright © 2019年 nobby heell. All rights reserved.
//

#import "ZQHttpClientCore.h"
#import "AFNetworking.h"
#import "ZQNetworkingMacro.h"
#import "Reachability.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "ZQRequestManager.h"

@interface ZQHttpClientCore()
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;
@property (nonatomic, strong) CTTelephonyNetworkInfo *networkInfo;

@end

static id _instance = nil;

@implementation ZQHttpClientCore

+ (void)load
{
    [[ZQHttpClientCore sharedClient] startMonitoringNetwork];
}

#pragma mark - 单利相关方法

+ (instancetype)sharedClient
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil)
        {
            _instance = [[self alloc] init];
        }
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil)
        {
            _instance = [super allocWithZone:zone];
        }
    });
    return _instance;
}

#pragma mark - 初始化

- (instancetype)init
{
    if (self = [super init])
    {
        self.networkType = ZQNetworkWiFi;
        self.manager = [AFHTTPSessionManager manager];
        //请求参数序列化类型
        self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        //响应结果序列化类型
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
        //接受内容类型
        self.manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"text/plain",@"text/json",@"application/json", nil];
        
        //超时时间
        [self.manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        self.manager.requestSerializer.timeoutInterval = 5.0f;
        [self.manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        
        //添加http的header
        //        [self.manager.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        //        [self.manager.requestSerializer setValue:pKey forHTTPHeaderField:@"pKey"];
        
        //设备相关信息
        NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleNameKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
        
        [self.manager.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        
        //https相关
        //        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        //        securityPolicy.allowInvalidCertificates = YES;
        //        securityPolicy.validatesDomainName = NO;
        //        self.manager.securityPolicy = securityPolicy;
        
    }
    return self;
}

#pragma mark - 调用AFN方法

- (void)updateSemaphoreCount:(NSInteger)change{
    [[ZQRequestManager sharedInstance] updateSemaphoreCount:change];
}

- (void)updateNetwork:(ZQNetworkType)ty{
    [self updateSemaphoreCount:ty-self.networkType];
    self.networkType = ty;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"currentRadioAccessTechnology"] && object == self.networkInfo) {
        NSString *currentStatus = [change valueForKey:NSKeyValueChangeNewKey];
        NSString *netconnType = nil;
        if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyGPRS"]) {
            
            netconnType = @"GPRS";
            [self updateNetwork:ZQNetwork2gOrSlower];
            
        }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyEdge"]) {
            
            netconnType = @"2.75G EDGE";
            [self updateNetwork:ZQNetwork2gOrSlower];

        }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyWCDMA"]){
            
            netconnType = @"3G";
            [self updateNetwork:ZQNetwork2gOrSlower];

        }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSDPA"]){
            
            netconnType = @"3.5G HSDPA";
            [self updateNetwork:ZQNetwork2gOrSlower];

        }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSUPA"]){
            
            netconnType = @"3.5G HSUPA";
            [self updateNetwork:ZQNetwork2gOrSlower];

        }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMA1x"]){
            
            netconnType = @"2G";
            [self updateNetwork:ZQNetwork2gOrSlower];

        }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"]){
            
            netconnType = @"3G";
            [self updateNetwork:ZQNetwork3g];

        }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"]){
            
            netconnType = @"3G";
            [self updateNetwork:ZQNetwork3g];

        }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"]){
            
            netconnType = @"3G";
            [self updateNetwork:ZQNetwork3g];

        }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyeHRPD"]){
            
            netconnType = @"HRPD";
            [self updateNetwork:ZQNetwork3g];

        }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyLTE"]){
            
            netconnType = @"4G";
            [self updateNetwork:ZQNetwork4g];
        }
    }
}

- (void)startMonitoringNetwork
{
    self.networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    [self.networkInfo addObserver:self forKeyPath:@"currentRadioAccessTechnology" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    self.reachabilityManager = [AFNetworkReachabilityManager manager];
    __weak typeof(self) weakSelf = self;
    [_reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        __strong typeof (self) strongSelf = weakSelf;
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable: {
                strongSelf.networkType = ZQNetworkNoNet;
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWiFi: {
                [strongSelf updateNetwork:ZQNetworkWiFi];
                break;
            }
            default:
                break;
        }
    }];
    [self.reachabilityManager startMonitoring];
}

- (void)requestWithPath:(NSString *)url
                 method:(NSInteger)method
             parameters:(id)parameters
         prepareExecute:(PrepareExecuteBlock)prepareExecute
                success:(void (^)(NSURLSessionDataTask *, id))success
                failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    
    switch (method) {
        case ZQRequestTypeGet:
        {
            
            [self.manager GET:url parameters:parameters progress:nil success:success failure:failure];
        }
            break;
        case ZQRequestTypePost:
        {
            
            [self.manager POST:url parameters:parameters progress:nil success:success failure:failure];
        }
            break;
        case ZQRequestTypeDelete:
        {
            [self.manager DELETE:url parameters:parameters success:success failure:failure];
        }
            break;
        case ZQRequestTypePut:
        {
            [self.manager PUT:url parameters:parameters success:success failure:false];
        }
            break;
        default:
            break;
    }
}

- (void)requestWithPathInHEAD:(NSString *)url
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    
    [self.manager HEAD:url parameters:parameters success:success failure:failure];
}



#pragma mark - 上传图片方法
- (void)uploadWithURL:(NSString *)URL
           parameters:(NSDictionary *)parameters
                image:(UIImage *)image
                 name:(NSString *)name
             fileName:(NSString *)fileName
              success:(void(^)(id responseObject))success
              failure:(void(^)(NSError *error))failure{
    
    
    //AFN的上传data
    [self.manager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        //图片压缩
        NSData *imageData = UIImageJPEGRepresentation(image, 0.3);
        NSString *mimeType = @"image/jpg";
        
        /**
         拼接data到 HTTP body
         mimeType JPG:image/jpg, PNG:image/png, JSON:application/json
         */
        [formData appendPartWithFileData:imageData name:name fileName:fileName mimeType:mimeType];
        
        //表单拼接参数data
        [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id  obj, BOOL *stop) {
            
            NSString *objStr = [NSString stringWithFormat:@"%@", obj];
            NSData *objData = [objStr dataUsingEncoding:NSUTF8StringEncoding];
            [formData appendPartWithFormData:objData name:key];
        }];
        
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success(responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failure(error);
        
    }];
}

- (BOOL)isConnectingNetwork
{
    return [AFNetworkReachabilityManager manager].reachable;
}

@end
