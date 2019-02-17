//
//  ZQRequestCache.h
//  ZQNetworking
//
//  Created by nobby heell on 2019/2/14.
//  Copyright © 2019年 nobby heell. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class  ZQRequest;
@interface ZQRequestCache : NSObject

+ (instancetype)sharedInstance;

/**
 从沙盒里面读取数据
 */
- (NSData *)readDataForKey:(NSString *)key;

/**
 将data存入沙盒路径
 */
- (void)saveData:(NSData *)data ForKey:(NSString *)key;

//将request存入数据库
- (void)saveRequestToDatabase:(ZQRequest *)request;

//将以requestId为主键的request从数据库中删除
- (void)deleteRequestFromDatabaseWithRequestId:(int)requestId;

- (NSArray *)allRequestsFromDatabase;

@end

NS_ASSUME_NONNULL_END
