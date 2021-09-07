//
//  NSObject+LXDataBaseCategory.h
//  ModelDemo
//
//  Created by Apple on 2021/9/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (LXDataBaseCategory)

+ (NSString *)lx_tableName;

+ (NSString *)lx_primaryKey; // 主键

+ (NSString *)lx_uniqueKey; // 唯一key

+ (NSDictionary<NSString *, NSString *> *)lx_customPropertyMapper; // 主要是处理id, 后端处理好了id的，可以吧这个相关的方法删除

@end

NS_ASSUME_NONNULL_END
