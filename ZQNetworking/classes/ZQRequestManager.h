//
//  ZQRequestManager.h
//  ZQNetworking
//
//  Created by nobby heell on 2019/2/14.
//  Copyright © 2019年 nobby heell. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ZQRequest;

/**
 *  成功时调用的Block
 */
typedef void (^SuccessBlock)(id obj);

/**
 *  失败时调用的Block
 */
typedef void (^FailedBlock)(id obj);

@interface ZQRequestManager : NSObject

+ (instancetype)sharedInstance;

- (void)sendRequest:(ZQRequest *)request
       successBlock:(SuccessBlock)successBlock
       failureBlock:(FailedBlock)failedBlock;
- (void)updateSemaphoreCount:(NSInteger)change;

@end


NS_ASSUME_NONNULL_END
