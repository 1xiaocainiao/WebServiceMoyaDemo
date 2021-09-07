//
//  LXBaseModel.m
//  ModelDemo
//
//  Created by Apple on 2021/8/31.
//

#import "LXBaseModel.h"
#import <objc/runtime.h>

@implementation LXBaseModel

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    int i;
    unsigned int propertyCount = 0;
    objc_property_t *propertyList = class_copyPropertyList([self class], &propertyCount);
    
    for ( i=0; i < propertyCount; i++ )
    {
        objc_property_t *thisProperty = propertyList + i;
        
        const char* propertyName = property_getName(*thisProperty);
        
        NSString *propertyKeyName = [NSString stringWithUTF8String:propertyName];
        [self setValue:[decoder decodeObjectForKey: propertyKeyName] forKey:propertyKeyName];
    }
    free(propertyList);
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    int i;
    unsigned int propertyCount = 0;
    objc_property_t *propertyList = class_copyPropertyList([self class], &propertyCount);
    
    for ( i=0; i < propertyCount; i++ )
    {
        objc_property_t *thisProperty = propertyList + i;
        
        const char* propertyName = property_getName(*thisProperty);
        
        NSString *propertyKeyName = [NSString stringWithUTF8String:propertyName];
        [aCoder encodeObject:[self valueForKey:propertyKeyName] forKey:propertyKeyName];
    }
    free(propertyList);
}


@end
