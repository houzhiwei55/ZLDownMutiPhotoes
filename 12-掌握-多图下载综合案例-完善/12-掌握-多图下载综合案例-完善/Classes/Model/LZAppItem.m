//
//  LZAppItem.m
//  12-掌握-多图下载综合案例-完善
//
//  Created by apple on 16/3/14.
//  Copyright © 2016年 m14a.cn. All rights reserved.
//

#import "LZAppItem.h"

@implementation LZAppItem

+ (instancetype)appItemWithDict:(NSDictionary *)dict
{
    // 创建对象
    LZAppItem *appItem = [[LZAppItem alloc] init];
    // KVC
    [appItem setValuesForKeysWithDictionary:dict];
    // 返回对象
    return appItem;
}

@end
