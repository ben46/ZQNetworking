//
//  YQDStorageUtils.h
//  YQD_iPhone
//
//  Created by 王志盼 on 2017/7/24.
//  Copyright © 2017年 王志盼. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YQDStorageUtils : NSObject
+ (void)saveValue:(id)value forKey:(NSString *)key;

+ (id)valueWithKey:(NSString *)key;

+ (BOOL)boolValueWithKey:(NSString *)key;

+ (void)saveBoolValue:(BOOL)value withKey:(NSString *)key;

+ (NSInteger)integerValueWithKey:(NSString *)key;

+ (void)saveIntegerValue:(NSInteger)value withKey:(NSString *)key;

+ (void)removeValueWithKey:(NSString *)key;

+ (void)print;

#pragma mark - UserDefaults存自定义对象
+ (void) persistObjAsData:(id)encodableObject forKey:(NSString *)key;

+ (id) objectFromDataWithKey:(NSString*)key;

#pragma mark - 直接转化为data写入cache下的
+ (NSData *)readDataFromFileByUrl:(NSString *)url;

+ (void)saveUrl:(NSString *)url withData:(NSData *)data;
@end
