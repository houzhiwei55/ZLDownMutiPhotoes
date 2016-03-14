//
//  ViewController.m
//  12-掌握-多图下载综合案例-完善
//
//  Created by apple on 16/3/14.
//  Copyright © 2016年 m14a.cn. All rights reserved.
//

#import "ViewController.h"
#import "LZAppItem.h"

@interface ViewController ()
/** 队列*/
@property (nonatomic ,strong) NSOperationQueue *queue;
/** 模型数组*/
@property (nonatomic, strong) NSArray *apps;
/** 图片缓存*/
@property (nonatomic ,strong) NSMutableDictionary *images;
/** 操作*/
@property (nonatomic ,strong) NSMutableDictionary *operations;
@end

@implementation ViewController

#pragma mark - 懒加载数据
- (NSArray *)apps
{
    if (_apps == nil) {
        // 1获取字典数组
        // 1.1获取路径
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"apps.plist" ofType:nil];
        // 1.2获取到字典数组
        NSArray *dictArray = [NSArray arrayWithContentsOfFile:filePath];
        // 2.拿到模型数组
        // 2.1创建一个可变数组
        NSMutableArray *temp = [NSMutableArray array];
        // 2.2创建for循环
        for (NSDictionary *dict in dictArray) {
            LZAppItem *item = [LZAppItem appItemWithDict:dict];
            [temp addObject:item];
        }
        _apps = temp;
    }
    return _apps;
}

#pragma mark - 图片缓存
- (NSMutableDictionary *)images
{
    if (_images == nil) {
        _images = [NSMutableDictionary dictionary];
    }
    return _images;
}

#pragma mark - 队列
- (NSOperationQueue *)queue
{
    if (_queue == nil) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 3;
    }
    return _queue;
}

#pragma mark - UITableViewDataSource方法
// 返回多少组
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// 每组返回多少行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.apps.count;
}

// 每行显示什么内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"app";
    // 去缓存池里面找
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
    }
    
    // 拿到模型数据
    LZAppItem *item = self.apps[indexPath.row];
    // 赋值
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = item.download;
    
    // 赋值图片，重点
    
    // 检查缓存,用图片的地址做键
    UIImage *image = [self.images objectForKey:item.icon];
    if (image) { // 有内存缓存，即身上有钱
        // 直接赋值
        cell.imageView.image = image;
//        NSLog(@"%zd使用了内存缓存",indexPath.row);
    }else { // 没有内存缓存，即身上没有钱
        
        // 获取磁盘缓存路径
        // 0.0获取路径
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        // 0.1得到图片的名称
        NSString *fileName = [item.icon lastPathComponent];
        // 0.2拼接文件的路径
        NSString *fullPath = [cachePath stringByAppendingPathComponent:fileName];
        
        // 去检查磁盘缓存,这里找到的是保存在cache里面的NSData数据
        NSData *imgData = [NSData dataWithContentsOfFile:fullPath];
        
        if (imgData) { // 如果磁盘缓存里面有该图片，磁盘缓存即是卡里面有钱
            // 拿到Image
            UIImage *image = [UIImage imageWithData:imgData];
            cell.imageView.image = image;
            
            // 把图片保存到身上，内存缓存
            [self.images setObject:image forKey:item.icon];
            
//            NSLog(@"%zd使用了磁盘缓存",indexPath.row);
            
        } else { // 如果磁盘缓存里面没有该图片,磁盘缓存即是卡里面没有钱
            // 来到这里，说明又没有内存缓存，又没有磁盘缓存
            // 清空图片或者是设置占位图片，目的是什么，因为cell是重复利用的，假设当你第一张图片显示完毕的时候，用户继续往下拖拽，下面的cell是由上面消失的cell重复利用过来的，而下面的cell去下载图片的时间可能比较长，所以显示的效果是上一张残留下来的图片，之后再把从网络下载的图片进行覆盖，也就是图片错乱了，所以，为了防止这个问题，用一张占位图片解决
            cell.imageView.image = [UIImage imageNamed:@"Snip20200808_172"];
            
            /*避免重复操作，当程序第一次运行起来的时候，显示第一个cell的时候，创建一个操作去服务器端获取数据，然后用户又随便往下拖拽，那么第一个cell就不再显示了，此时那个获取数据的操作还在执行，假设需要10秒，然后用户又随便拖拽，滚到了第一个cell，第一个cell又重新显示出来了，那么它还会继续创建一个操作去服务器端获取数据，那么可能就有好几个操作发送到服务器端去获取同一个数据了，没有必要，所以，这里采用了一个可变字典，用来判断，好办法，谁想出来的，牛逼*/
            // 检查操作缓存
            NSBlockOperation *dowbloadOperation = [self.operations objectForKey:item.icon];
            if (dowbloadOperation) { // 如果有操作，说明之前已经发了一次操作过去了，那么再次来到这的时候，就不能再发请求了，所以什么也不能做
                
            } else { // 如果没有操作，说明之前没有发过操作过去，要添加操作
                    dowbloadOperation = [NSBlockOperation blockOperationWithBlock:^{
                    
                        
                    // 1.创建url
                    NSURL *url = [NSURL URLWithString:item.icon];
                    // 2.拿到二进制数据
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    // 3.转化为UIImage对象
                    UIImage *image = [UIImage imageWithData:data];
                        
                    // 5.保存到内存缓存
                    [self.images setValue:image forKey:item.icon];
                    // 6.保存到磁盘缓存
                    [data writeToFile:fullPath atomically:YES];
                    
                    NSLog(@"%zd直接下载",indexPath.row);
                        
                    // 设置图片
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        
                        // 4.赋值,UI操作跟主线程相关,老师解释说，这里调用的时候，
                        // cell是从storyboard创建的，这个时候的imageView还没有尺寸，
                        // 所以图片下载不显示
                        cell.imageView.image = image;
                        // 最好不要用这个重量级的刷新方法，没有必要，自己每次就下载一张图片
//                        [tableView reloadData];
                        // 刷新指定的行
                        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
                    }];
                    
                }];
                
                // 添加操作到内存缓存中
                [self.operations setObject:dowbloadOperation forKey:item.icon];
                
                // 添加到队列
                [self.queue addOperation:dowbloadOperation];
            }
            
        }
    }
    
    // 返回cell
    return cell;
}
@end
