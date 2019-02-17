//
//  YQDStorageUtils.m
//  YQD_iPhone
//
//  Created by 王志盼 on 2017/7/24.
//  Copyright © 2017年 王志盼. All rights reserved.
//

#import "YQDStorageUtils.h"
#import "NSString+MD5.h"

@implementation YQDStorageUtils
+ (void)saveValue:(id)value forKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:value forKey:key];
    [userDefaults synchronize];
}

+ (id)valueWithKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:key];
}

+ (void)saveBoolValue:(BOOL)value withKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:value forKey:key];
    [userDefaults synchronize];
}

+ (BOOL)boolValueWithKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:key];
}

+ (void)saveIntegerValue:(NSInteger)value withKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:value forKey:key];
    [userDefaults synchronize];
}

+ (NSInteger)integerValueWithKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:key];
}


+ (void)removeValueWithKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)removeWithBoolValueWithKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}

+ (void)print
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dic = [userDefaults dictionaryRepresentation];
    NSLog(@"%@",dic);
}


#pragma mark - UserDefaults存自定义对象

+ (void) persistObjAsData:(id)encodableObject forKey:(NSString *)key {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:encodableObject];
    NSLog(@"死循环");
    [self saveValue:data forKey:key];
}

+ (id) objectFromDataWithKey:(NSString*)key {
    NSData *data = [self valueWithKey:key];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

#pragma mark - 直接转化为data写入cache下的

+ (NSData *)readDataFromFileByUrl:(NSString *)url
{
    NSString *md5 = [url MD5Hash];
    NSString *dir = [NSHomeDirectory() stringByAppendingFormat:@"%@",@"/Library/Caches"];
    NSString *path = [NSString stringWithFormat:@"%@/%@",dir,md5];

    return [NSData dataWithContentsOfFile:path];
    
}

+ (void)saveUrl:(NSString *)url withData:(NSData *)data
{
    NSString *md5 = [url MD5Hash];
    NSString *dir = [NSHomeDirectory() stringByAppendingFormat:@"%@",@"/Library/Caches"];
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *path = [NSString stringWithFormat:@"%@/%@",dir,md5];
    if ([mgr fileExistsAtPath:path])
    {
        [mgr removeItemAtPath:path error:nil];
    }
    [data writeToFile:path atomically:YES];
}
@end
