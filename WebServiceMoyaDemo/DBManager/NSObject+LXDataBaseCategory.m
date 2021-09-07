//
//  NSObject+LXDataBaseCategory.m
//  ModelDemo
//
//  Created by Apple on 2021/9/1.
//

#import "NSObject+LXDataBaseCategory.h"

@implementation NSObject (LXDataBaseCategory)

+ (NSString *)lx_tableName {
    NSString *name = NSStringFromClass([self class]);
    NSString *result = name;
    
    if ([name containsString:@"."] && [name componentsSeparatedByString:@"."].count == 2) {
        NSArray *array = [name componentsSeparatedByString:@"."];
        NSString *temp = array[0];
        
        NSString *projectName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
        if ([projectName isEqualToString:temp]) {
            result = array[1];
        } else {
            
        }
    }
    return  result;
}

+ (NSString *)lx_primaryKey {
    return @"fId";
}

+ (NSString *)lx_uniqueKey {
    return @"";
}

+ (NSDictionary<NSString *, NSString *> *)lx_customPropertyMapper {
    return @{@"id": @"transaction_id"};
}

@end
