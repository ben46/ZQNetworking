//
//  ZQNetworkingMacro.h
//  ZQNetworking
//
//  Created by nobby heell on 2019/2/14.
//  Copyright © 2019年 nobby heell. All rights reserved.
//

#ifndef ZQNetworkingMacro_h
#define ZQNetworkingMacro_h

typedef NS_ENUM(NSInteger, ZQRequestType) {
    ZQRequestTypeGet,
    ZQRequestTypePost,
    ZQRequestTypeDelete,
    ZQRequestTypePut
};

//定时器每隔60s查询一次数据库
#define kTimerDuration 60

#endif /* ZYRequestMacro_h */
