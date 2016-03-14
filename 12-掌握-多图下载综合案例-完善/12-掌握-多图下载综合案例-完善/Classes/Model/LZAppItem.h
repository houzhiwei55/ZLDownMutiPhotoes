//
//  LZAppItem.h
//  12-掌握-多图下载综合案例-完善
//
//  Created by apple on 16/3/14.
//  Copyright © 2016年 m14a.cn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LZAppItem : NSObject

/** 名称*/
@property (nonatomic ,strong) NSString *name;
/** 图标的地址*/
@property (nonatomic ,strong) NSString *icon;
/** 下载量*/
@property (nonatomic ,strong) NSString *download;

+(instancetype)appItemWithDict:(NSDictionary *)dict;

@end
