//
//  ZQRequestManager.m
//  ZQNetworking
//
//  Created by nobby heell on 2019/2/14.
//  Copyright © 2019年 nobby heell. All rights reserved.
//

#import "ZQRequestManager.h"
#import "ZQRequest.h"
#import "ZQHttpClientCore.h"
#import "ZQRequestCache.h"
#import <pthread.h>

@interface ZQNetworkingOperation : NSObject

@property  (nonatomic, strong) ZQRequest *request;
@property  (nonatomic, copy) SuccessBlock suc;
@property  (nonatomic, copy) FailedBlock failure;

@end
@implementation ZQNetworkingOperation
@end

@interface ZQRequestManager(){
    pthread_mutex_t _lock; // 互斥锁, 普通, 不支持递归
    dispatch_queue_t _semaphoreQueue; // 对应并发信号量的串行队列
}

@property (nonatomic, strong) NSMutableOrderedSet<ZQNetworkingOperation *> *queuedOperations;
//存放request的成功回调
@property (nonatomic, strong) dispatch_semaphore_t concurrentSem;
//requestQueue队列是否正在轮询
@property (nonatomic, assign) BOOL isRetaining;

//定时器，每隔60s查询一次realm数据库里面的request
//如果存在request，并且kIsConnectingNetwork为true的情况下，将这些request重新装入队列发送
@property (nonatomic, strong) NSTimer *timer;
@end

static id _instance = nil;

@implementation ZQRequestManager
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (!_instance)
        {
            _instance = [[self alloc] init];
        }
    });
    return _instance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);        //普通互斥锁
        pthread_mutex_init(&_lock, &attr);
        _semaphoreQueue = dispatch_queue_create("ZQNetworkOperationQueue Serial Semaphore Queue", DISPATCH_QUEUE_SERIAL);
        NSInteger maxConcurrentNum = ZQNetworkWiFi;
        self.concurrentSem = dispatch_semaphore_create(maxConcurrentNum);
        self.isRetaining = false;
        [self startTimer];
    }
    return self;
}

//暴露给外界
- (void)sendRequest:(ZQRequest *)request successBlock:(SuccessBlock)successBlock failureBlock:(FailedBlock)failedBlock
{
    //如果是ZYRequestReliabilityStoreToDB类型
    //第一时间先存储到数据库，然后再发送该请求，如果成功再从数据库中移除
    //不成功再出发某机制从数据库中取出重新发送
    if (request.reliability == ZQRequestReliabilityStoreToDB)
    {
        [[ZQRequestCache sharedInstance] saveRequestToDatabase:request];
    }
    
    [self queueAddRequest:request successBlock:successBlock failureBlock:failedBlock];
    
}

- (void)updateSemaphoreCount:(NSInteger)change
{
    if (change != 0) {
        dispatch_async(_semaphoreQueue, ^{
            if (change > 0) {
                for (int i = 0 ; i<change; i++) {
                    dispatch_semaphore_signal(self.concurrentSem);
                }
            }
            if (change < 0) {
                for (NSInteger i = change ; i<0; i++) {
                    dispatch_semaphore_wait(self.concurrentSem, DISPATCH_TIME_FOREVER);
                }
            }
        });
    }
}

- (void)dealRequestQueue
{
    // 递归调用
    // 让请求按队列先后顺序发送
    dispatch_async(_semaphoreQueue, ^{ // 串行队列
        dispatch_semaphore_wait(self.concurrentSem, DISPATCH_TIME_FOREVER);
        if(self.queuedOperations.count > 0){
            ZQNetworkingOperation *opr = self.queuedOperations.firstObject;
            ZQRequest *request = opr.request;
            SuccessBlock successBlock = opr.suc;
            FailedBlock failedBlock = opr.failure;
            [self locked_queueRemoveFirstObj];
            NSLog(@"----------------[%@]", request.requestId);
            //利用AFN发送请求
            [[ZQHttpClientCore sharedClient] requestWithPath:request.urlStr method:request.method parameters:request.params prepareExecute:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                dispatch_semaphore_signal(self.concurrentSem);
                
                //                NSLog(@"++++++++%d", request.requestId);
                //在这里可以根据状态码处理相应信息、序列化数据、是否需要缓存等
                if (request.cacheKey)
                {
                    NSError *error = nil;
                    NSData *data = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&error];
                    
                    if (!error)
                    {
                        [[ZQRequestCache sharedInstance] saveData:data ForKey:request.cacheKey];
                    }
                }
                
                //在成功的时候移除数据库中的缓存
                if (request.reliability == ZQRequestReliabilityStoreToDB)
                {
                    [[ZQRequestCache sharedInstance] deleteRequestFromDatabaseWithRequestId:request.requestId];
                }
                
                successBlock(responseObject);
                
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                
                dispatch_semaphore_signal(self.concurrentSem);
                
                //请求失败之后，根据约定的错误码判断是否需要再次请求
                //这里，-1001是AFN的超时error
                if (error.code == -1001 &&request.retryCount > 0)
                {
                    [request reduceRetryCount];
                    [self queueAddRequest:request successBlock:successBlock failureBlock:failedBlock];
                    [self dealRequestQueue];
                }
                else  //处理错误信息
                {
                    failedBlock(error);
                }
            }];
            
            [self dealRequestQueue];
        } else {
            dispatch_semaphore_signal(self.concurrentSem);
        }
    });
}

- (void)queueAddRequest:(ZQRequest *)request successBlock:successBlock failureBlock:failedBlock{
    
    if (request == nil) {
        NSLog(@"ZYRequest 不能为nil");
        return;
    }
    
    [self locked_addRequest:request successBlock:successBlock failureBlock:failedBlock];
    [self dealRequestQueue];
}

- (void)locked_addRequest:(ZQRequest *)request successBlock:successBlock failureBlock:failedBlock{
    
    //做容错处理，如果block为空，设置默认block
    id tmpBlock = [successBlock copy];
    if (successBlock == nil) {
        tmpBlock = [^(id obj){} copy];
    }
    
    id tmpBlock2 = [failedBlock copy];
    if (failedBlock == nil) {
        tmpBlock2 = [^(id obj){} copy];
    }
    
    ZQNetworkingOperation *opr = [[ZQNetworkingOperation alloc] init];
    opr.request = request;
    opr.suc = tmpBlock;
    opr.failure = tmpBlock2;
    
    [self lock];
    [self.queuedOperations addObject:opr];
    [self unlock];
}

- (void)locked_queueRemoveFirstObj
{
    if (self.queuedOperations.count >= 1) {
        [self lock];
        [self.queuedOperations removeObjectAtIndex:0];
        [self unlock];
    }
}

#pragma mark - Timer
- (void)startTimer
{
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:kTimerDuration target:self selector:@selector(updateTimer) userInfo:nil repeats:true];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)updateTimer
{
    NSArray *requestArr = [[ZQRequestCache sharedInstance] allRequestsFromDatabase];
    
    if (requestArr != nil && requestArr.count > 0)
    {
        //需要注意的是，存入数据库里面的request是不需要回调的
        //必定成功，当然如果需要更新时间戳的话，可以重新拼接参数的时间戳
        [requestArr enumerateObjectsUsingBlock:^(ZQRequest *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self queueAddRequest:[obj copy] successBlock:nil failureBlock:nil];
        }];
        [self dealRequestQueue];
    }
    
}

#pragma mark - getter && setter
- (NSMutableOrderedSet *)queuedOperations
{
    if (!_queuedOperations) {
        _queuedOperations = [[NSMutableOrderedSet alloc] init];
    }
    return _queuedOperations;
}

- (void)lock
{
    pthread_mutex_lock(&_lock);
}

- (void)unlock
{
    pthread_mutex_unlock(&_lock);
}

- (void)dealloc
{
    pthread_mutex_destroy(&_lock);
}

@end

