

#import "LXBasicDBManager.h"
#import <objc/runtime.h>
#import "YYModel.h"
#import "NSObject+LXDataBaseCategory.h"




@implementation LXBasicDBManager

@synthesize db;

- (void)dealloc
{
    [self.db close];
    self.db = nil;
}

+ (void)updateVersionCleanCache
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSError *error = nil;
        NSArray *fileList = [fm contentsOfDirectoryAtPath:documentsDirectory error:&error];
        if (error)
        {
            return;
        }
        for (NSString *tempPath in fileList)
        {
            if ([tempPath rangeOfString:[self getNeedCleanDBName]].location != NSNotFound)
            {
                if ([fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, tempPath] error:&error])
                {
                    NSLog(@"Rremove %@ Success", tempPath);
                }
                
            }
        }
    });
}

+ (NSString *)getNeedCleanDBName {
    return @"";
}

- (BOOL)isExistTable:(NSString *)tableName
{
    NSString *sql = [NSString stringWithFormat:@"select count(*) from sqlite_master where type='table' and name = '%@'",
                     tableName];
    NSArray *arr = [self getDataBySQL:sql];
    if (arr.count == 0)
    {
        return false;
    }
    return ([[arr[0] valueForKey:@"count(*)"]intValue] > 0?YES:NO);
}

#pragma mark -
#pragma mark public method

- (NSArray *)getDataBySQL:(NSString *)sql
{
    NSMutableArray *res = [NSMutableArray array];
    if ( [db open] )
    {
        [db setShouldCacheStatements:YES];
        FMResultSet *rs = [db executeQuery:sql];
        if([db hadError])
        {
            NSLog(@"%s", __FUNCTION__);
            NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
        while([rs next])
        {
            [res addObject:[rs resultDictionary]];
        }
        
        [db close];
    }
    
    return res;
}


//insert
- (BOOL)insertDataWithSQL:(NSString *)sql
{
    BOOL success = YES;
    if ( [db open] )
    {
        [db setShouldCacheStatements:YES];
        [db executeUpdate:sql];
        if([db hadError])
        {
            NSLog(@"%s", __FUNCTION__);
            NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            success = NO;
        }
        [db close];
    }
    return success;
}

- (BOOL)deleteDataBySQL:(NSString *)sql
{
    BOOL success=YES;
    if ( [db open] )
    {
        [db setShouldCacheStatements:YES];
        [db executeUpdate:sql];
        if([db hadError])
        {
            NSLog(@"%s", __FUNCTION__);
            NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            success=NO;
        }
        [db close];
    }
    
    return success;
}

- (NSString *)getPropertyClassWithClass:(Class)class propertyName:(NSString *)propertyName
{
    objc_property_t property = class_getProperty(class, [propertyName UTF8String]);
    const char * type = property_getAttributes(property);
    NSString *typeString = [NSString stringWithUTF8String:type];
    NSArray *attributes = [typeString componentsSeparatedByString:@","];
    NSString *typeAttribute = [attributes objectAtIndex:0];
    NSString *propertyType = [typeAttribute substringFromIndex:1];
    propertyType = [propertyType stringByReplacingOccurrencesOfString:@"@" withString:@""];
    propertyType = [propertyType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    return propertyType;
}

- (NSString *)getSqlType: (LXPropertyEncodingType)type {
    NSArray *datas = @[@"INTEGER", @"DOUBLE", @"TEXT", @"TINYINT", @"BLOB"];
    return datas[type];
}

- (LXPropertyEncodingType)property:(NSString *)propertyName inClassType:(Class)class
{
    LXPropertyEncodingType encodingType;
    
    objc_property_t property = class_getProperty(class, [propertyName UTF8String]);
    const char * type = property_getAttributes(property);
    NSString *typeString = [NSString stringWithUTF8String:type];
    NSArray *attributes = [typeString componentsSeparatedByString:@","];
    NSString *typeAttribute = [attributes objectAtIndex:0];
    NSString *propertyType = [typeAttribute substringFromIndex:1];
    
    const char * rawPropertyType = [propertyType UTF8String];
    if (strcmp(rawPropertyType, @encode(float)) == 0 ||
        strcmp(rawPropertyType, @encode(double)) == 0) {
        encodingType = LXPropertyEncodingTypeDouble;
    } else if (strcmp(rawPropertyType, @encode(int)) == 0 ||
               strcmp(rawPropertyType, @encode(NSInteger)) == 0) {
        encodingType = LXPropertyEncodingTypeInt;
    } else if (strcmp(rawPropertyType, @encode(_Bool)) == 0 ||
               strcmp(rawPropertyType, @encode(bool)) == 0) {
        encodingType = LXPropertyEncodingTypeBool;
    } else {
        propertyType = [propertyType stringByReplacingOccurrencesOfString:@"@" withString:@""];
        propertyType = [propertyType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        if ([propertyType isEqualToString:@"NSString"])
        {
            encodingType = LXPropertyEncodingTypeString;
        } else {
            encodingType = LXPropertyEncodingTypeData;
        }
    }
    return encodingType;
}

- (id)needUnarchive:(id)info class:(Class)class dic:(NSDictionary *)dic
{
    int i;
    unsigned int propertyCount = 0;
    objc_property_t *propertyList = class_copyPropertyList(class, &propertyCount);
    
    for ( i=0; i < propertyCount; i++ )
    {
        objc_property_t *thisProperty = propertyList + i;
        
        const char* propertyName = property_getName(*thisProperty);
        
        NSString *propertyKeyName = [NSString stringWithUTF8String:propertyName];
        
        LXPropertyEncodingType type = [self property:propertyKeyName inClassType:class];
        
        if (type == LXPropertyEncodingTypeData) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            id data = [NSKeyedUnarchiver unarchiveObjectWithData: [self convertDataBaseStoredStringToData:dic[propertyKeyName]]];
            if (data == nil)
            {
                data = [[NSClassFromString([self getPropertyClassWithClass:class propertyName:propertyKeyName]) alloc] init];
            }
            [info setValue:data forKey:propertyKeyName];
#pragma clang diagnostic pop
        }
    }
    free(propertyList);
    return info;
}

- (NSData *)convertDataBaseStoredStringToData:(NSString *)command
{
    if (![command isKindOfClass:[NSString class]]) {
        return [NSData data];
    }
    command = [command stringByReplacingOccurrencesOfString:@">" withString:@""];
    command = [command stringByReplacingOccurrencesOfString:@"<" withString:@""];
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [command length]/2; i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    return commandToSend;
}

- (NSMutableString *)dataToHexString:(NSData *)valueData insertSql:(NSMutableString *)insertSql {
    if (@available(iOS 13, *)) {
        if ([valueData isKindOfClass:[NSData class]]) {
            NSMutableString *valueString = [NSMutableString string];
            const char *bytes = valueData.bytes;
            NSInteger count = valueData.length;
            for (int i = 0; i < count; i++) {
                [valueString appendFormat:@"%02x", bytes[i]&0x000000FF];
            }
            
            [insertSql appendFormat:@"'%@',", [valueString stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
        } else {
            [insertSql appendFormat:@"'%@',", [[NSString stringWithFormat:@"%@", valueData] stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
        }
    } else {
        [insertSql appendFormat:@"'%@',", [[NSString stringWithFormat:@"%@", valueData] stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    }
    return insertSql;
}

- (NSMutableString *)lastDataToHexString:(NSData *)valueData insertSql:(NSMutableString *)insertSql {
    if (@available(iOS 13, *)) {
        if ([valueData isKindOfClass:[NSData class]]) {
            NSMutableString *valueString = [NSMutableString string];
            const char *bytes = valueData.bytes;
            NSInteger count = valueData.length;
            for (int i = 0; i < count; i++) {
                [valueString appendFormat:@"%02x", bytes[i]&0x000000FF];
            }
            
            [insertSql appendFormat:@"'%@')", [valueString stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
        } else {
            [insertSql appendFormat:@"'%@')", [[NSString stringWithFormat:@"%@", valueData] stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
        }
    } else {
        [insertSql appendFormat:@"'%@')", [[NSString stringWithFormat:@"%@", valueData] stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    }
    return insertSql;
}

- (void)setDbName:(NSString *)dbName
{
    if ([_dbName isEqualToString:dbName])
    {
        return;
    }
    _dbName = dbName;
    BOOL success;
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [cachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", _dbName]];
    success = [fm fileExistsAtPath:writableDBPath];
    
    if ( !success )
    {
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", _dbName]];
        success = [fm copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
        if(!success)
        {
            NSLog(@"%@",[error localizedDescription]);
        }
    }
    
    // 连接DB
    self.db = [FMDatabase databaseWithPath:writableDBPath];
}

#pragma mark - 初始化
+ (instancetype)sharedDBManager:(NSString *)dbName {
    LXBasicDBManager *db = [[LXBasicDBManager alloc] init];
    db.dbName = dbName;
    return  db;
}

- (NSArray *)getAllProperty:(Class)class {
    unsigned int propertyCount = 0;
    objc_property_t * properties = class_copyPropertyList(class, &propertyCount);
    
    NSMutableArray * propertyNames = [NSMutableArray array];
    for (unsigned int i = 0; i < propertyCount; ++i) {
        objc_property_t property = properties[i];
        const char * name = property_getName(property);
        [propertyNames addObject:[NSString stringWithUTF8String:name]];
    }
    free(properties);
    return  propertyNames;
}


#pragma mark - profile
- (void)createTable:(NSString *)tableName class:(Class)class {
    if (![self isExistTable:tableName])
    {
        NSArray *keys = [self getAllProperty:class];
        NSMutableString *createTableSql = [NSMutableString stringWithFormat:@"CREATE TABLE %@ (", tableName];
        
        NSString *uniqueKey = [class lx_uniqueKey];
        
        for (id key in keys)
        {
            if ([key isEqualToString: uniqueKey])
            {
                [createTableSql appendFormat:@"%@ TEXT UNIQUE,",key];
            }
            else
            {
                NSString *targetKey = key;
                
                if ([[[class lx_customPropertyMapper] allKeys] containsObject:key]) {
                    targetKey = [class lx_customPropertyMapper][key];
                } else {
                    targetKey = key;
                }
                
                LXPropertyEncodingType type = [self property:targetKey inClassType:class];
                
                [createTableSql appendFormat:@"%@ %@,", targetKey, [self getSqlType:type]];
            }
        }
        [createTableSql appendFormat:@"%@ INTEGER PRIMARY KEY)", [class lx_primaryKey]];
        
        NSLog(@"create table sql: %@", createTableSql);
        
        BOOL createReg = [self insertDataWithSQL:(NSString *)createTableSql];
        
        if (createReg)
        {
            NSLog(@"create %@ success", tableName);
        }
    }
}

- (BOOL)insertModelObject:(LXBaseModel *)info clean:(BOOL)clean {
    Class class = [info class];
    
    NSString *tableName = [class lx_tableName];
    
    if (![self isExistTable:tableName]) {
        [self createTable:tableName class:class];
    }
    
    if (clean) {
        [self clearTableFrom:tableName];
    }
    
    NSDictionary *tempDic = info.yy_modelToJSONObject;
    NSMutableString *insertSql = [NSMutableString stringWithFormat:@"insert or replace into %@ (", tableName];
    for (id key in [tempDic allKeys])
    {
        NSString *targetKey = key;
        
        if ([[[class lx_customPropertyMapper] allKeys] containsObject:key]) {
            targetKey = [class lx_customPropertyMapper][key];
        } else {
            targetKey = key;
        }
        
        [insertSql appendFormat:@"%@,",targetKey];
    }
    [insertSql deleteCharactersInRange:NSMakeRange([insertSql length]-1, 1)];
    [insertSql appendString:@") "
     " values (" ];
    for (id key in [tempDic allKeys])
    {
        if ([key isEqual:[[tempDic allKeys] lastObject]])
        {
            NSData *valueData;
            
            NSString *targetKey = key;
            
            if ([[[class lx_customPropertyMapper] allKeys] containsObject:key]) {
                targetKey = [class lx_customPropertyMapper][key];
            } else {
                targetKey = key;
            }
            
            LXPropertyEncodingType type = [self property:targetKey inClassType:class];
            
            if (type == LXPropertyEncodingTypeData) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                if ([info valueForKey:targetKey]) {
                    valueData = [NSKeyedArchiver archivedDataWithRootObject:[info valueForKey:targetKey]];
                }
                else {
                    valueData = [NSData data];
                }
#pragma clang diagnostic pop
            } else {
                if ([targetKey isEqualToString:@"id"]) {
                    valueData = tempDic[@"id"];
                } else {
                    valueData = [info valueForKey:targetKey];
                }
            }

            insertSql = [self lastDataToHexString:valueData insertSql:insertSql];
        }
        else
        {
            NSData *valueData;
            
            NSString *targetKey = key;
            
            if ([[[class lx_customPropertyMapper] allKeys] containsObject:key]) {
                targetKey = [class lx_customPropertyMapper][key];
            } else {
                targetKey = key;
            }
            
            LXPropertyEncodingType type = [self property:targetKey inClassType:class];
            
            if (type == LXPropertyEncodingTypeData) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                if ([info valueForKey:targetKey]) {
                    valueData = [NSKeyedArchiver archivedDataWithRootObject:[info valueForKey:targetKey]];
                }
                else {
                    valueData = [NSData data];
                }
#pragma clang diagnostic pop
            } else {
                if ([targetKey isEqualToString:@"id"]) {
                    valueData = tempDic[@"id"];
                } else {
                    valueData = [info valueForKey:targetKey];
                }
            }

            insertSql = [self dataToHexString:valueData insertSql:insertSql];
        }
    }
    
    NSLog(@"create insert sql: %@", insertSql);
    
    BOOL reg  = [self insertDataWithSQL:insertSql];
    if (reg)
    {
        NSLog(@"%@ insert success", tableName);
    }
    return reg;
}

- (BOOL)insertModelArray:(NSArray<LXBaseModel *> *)infoList
                   clean:(BOOL)clean
            extTableName:(NSString *)extTableName {
    if (infoList == nil || infoList.count == 0) {
        return false;
    }
    
    Class class = [infoList.firstObject class];
    
    NSString *tableName = [class lx_tableName];
    if (extTableName != nil && extTableName.length != 0) {
        tableName = [NSString stringWithFormat:@"%@%@", tableName, extTableName];
    }
    
    if (![self isExistTable:tableName]) {
        [self createTable:tableName class:class];
    }
    
    if (clean) {
        [self clearTableFrom:tableName];
    }
    
    for (LXBaseModel *info in infoList) {
        NSDictionary *tempDic = info.yy_modelToJSONObject;
        NSMutableString *insertSql = [NSMutableString stringWithFormat:@"insert or replace into %@ (", tableName];
        for (id key in [tempDic allKeys])
        {
            NSString *targetKey = key;
            
            if ([[[class lx_customPropertyMapper] allKeys] containsObject:key]) {
                targetKey = [class lx_customPropertyMapper][key];
            } else {
                targetKey = key;
            }
            
            [insertSql appendFormat:@"%@,",targetKey];
        }
        [insertSql deleteCharactersInRange:NSMakeRange([insertSql length]-1, 1)];
        [insertSql appendString:@") "
         " values (" ];
        for (id key in [tempDic allKeys])
        {
            if ([key isEqual:[[tempDic allKeys] lastObject]])
            {
                NSData *valueData;
                
                NSString *targetKey = key;
                
                if ([[[class lx_customPropertyMapper] allKeys] containsObject:key]) {
                    targetKey = [class lx_customPropertyMapper][key];
                } else {
                    targetKey = key;
                }
                
                LXPropertyEncodingType type = [self property:targetKey inClassType:class];
                
                if (type == LXPropertyEncodingTypeData) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    if ([info valueForKey:targetKey]) {
                        valueData = [NSKeyedArchiver archivedDataWithRootObject:[info valueForKey:targetKey]];
                    }
                    else {
                        valueData = [NSData data];
                    }
#pragma clang diagnostic pop
                } else {
                    if ([targetKey isEqualToString:@"id"]) {
                        valueData = tempDic[@"id"];
                    } else {
                        valueData = [info valueForKey:targetKey];
                    }
                }

                insertSql = [self lastDataToHexString:valueData insertSql:insertSql];
            }
            else
            {
                NSData *valueData;
                
                NSString *targetKey = key;
                
                if ([[[class lx_customPropertyMapper] allKeys] containsObject:key]) {
                    targetKey = [class lx_customPropertyMapper][key];
                } else {
                    targetKey = key;
                }
                
                LXPropertyEncodingType type = [self property:targetKey inClassType:class];
                
                if (type == LXPropertyEncodingTypeData) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    if ([info valueForKey:targetKey]) {
                        valueData = [NSKeyedArchiver archivedDataWithRootObject:[info valueForKey:targetKey]];
                    }
                    else {
                        valueData = [NSData data];
                    }
#pragma clang diagnostic pop
                } else {
                    if ([targetKey isEqualToString:@"id"]) {
                        valueData = tempDic[@"id"];
                    } else {
                        valueData = [info valueForKey:targetKey];
                    }
                }

                insertSql = [self dataToHexString:valueData insertSql:insertSql];
            }
        }
        
        NSLog(@"create insert sql: %@", insertSql);
        
        BOOL reg  = [self insertDataWithSQL:insertSql];
        if (reg)
        {
            NSLog(@"%@ insert success", tableName);
        }
    }
    return true;
}

- (id)getModelFromClass:(Class)class fromExtTable: (NSString *)extTable otherSqlDic:(NSDictionary<NSString *, NSString *> *)sqlDic {
    NSString *tableName = [NSString stringWithFormat:@"%@%@", [class lx_tableName], extTable];
    
    NSMutableArray *returnArr = [NSMutableArray array];
    NSMutableString *sql = [NSMutableString stringWithFormat:@"select *from %@", tableName];
    
    if (sqlDic != nil && sqlDic.allKeys.count > 0) {
        [sql appendString:@" where"];
        
        for (NSString *key in sqlDic.allKeys) {
            NSString *value = sqlDic[key];
            
            [sql appendFormat: @" %@ = '%@'", key, value];
        }
    }
    
    NSLog(@"selected data sql: %@", sql);
    
    NSArray *tmpArr = [self getDataBySQL:sql];
    for (id dic in tmpArr)
    {
        
        id info = [[class class] yy_modelWithDictionary:dic]; // yymodel 会忽略不支持的类型字段为nil,故单独处理
        info = (id)[self needUnarchive:info class: class dic: dic];
        [returnArr addObject:info];
    }
    if (returnArr.count > 0) {
        return returnArr[0];
    }
    return nil;
}

- (id)getModelFromClass:(Class)class otherSqlDic:(NSDictionary<NSString *, NSString *> *)sqlDic {
    NSString *tableName = [class lx_tableName];
    
    NSMutableArray *returnArr = [NSMutableArray array];
    NSMutableString *sql = [NSMutableString stringWithFormat:@"select *from %@", tableName];
    
    if (sqlDic != nil && sqlDic.allKeys.count > 0) {
        [sql appendString:@" where"];
        
        for (NSString *key in sqlDic.allKeys) {
            NSString *value = sqlDic[key];
            
            [sql appendFormat: @" %@ = '%@'", key, value];
        }
    }
    
    NSLog(@"selected data sql: %@", sql);
    
    NSArray *tmpArr = [self getDataBySQL:sql];
    for (id dic in tmpArr)
    {
        
        id info = [[class class] yy_modelWithDictionary:dic]; // yymodel 会忽略不支持的类型字段为nil,故单独处理
        info = (id)[self needUnarchive:info class: class dic: dic];
        [returnArr addObject:info];
    }
    if (returnArr.count > 0) {
        return returnArr[0];
    }
    return nil;
}

- (id)getModelArrayFromClass:(Class)class fromExtTable: (NSString *)extTable otherSqlDic:(NSDictionary<NSString *, NSString *> *)sqlDic {
    NSString *tableName = [NSString stringWithFormat:@"%@%@", [class lx_tableName], extTable];
    
    NSMutableArray *returnArr = [NSMutableArray array];
    NSMutableString *sql = [NSMutableString stringWithFormat:@"select *from %@", tableName];
    
    if (sqlDic != nil && sqlDic.allKeys.count > 0) {
        [sql appendString:@" where"];
        
        for (NSString *key in sqlDic.allKeys) {
            NSString *value = sqlDic[key];
            
            [sql appendFormat: @" %@ = '%@'", key, value];
        }
    }
    
    NSLog(@"selected data sql: %@", sql);
    
    NSArray *tmpArr = [self getDataBySQL:sql];
    for (id dic in tmpArr)
    {
        id info = [[class class] yy_modelWithDictionary:dic]; // yymodel 会忽略不支持的类型字段为nil,故单独处理
        info = (id)[self needUnarchive:info class: class dic: dic];
        [returnArr addObject:info];
    }
    return returnArr;
}

- (id)getModelArrayFromClass:(Class)class otherSqlDic:(NSDictionary<NSString *, NSString *> *)sqlDic {
    NSString *tableName = [class lx_tableName];
    
    NSMutableArray *returnArr = [NSMutableArray array];
    NSMutableString *sql = [NSMutableString stringWithFormat:@"select *from %@", tableName];
    
    if (sqlDic != nil && sqlDic.allKeys.count > 0) {
        [sql appendString:@" where"];
        
        for (NSString *key in sqlDic.allKeys) {
            NSString *value = sqlDic[key];
            
            [sql appendFormat: @" %@ = '%@'", key, value];
        }
    }
    
    NSLog(@"selected data sql: %@", sql);
    
    NSArray *tmpArr = [self getDataBySQL:sql];
    for (id dic in tmpArr)
    {
        id info = [[class class] yy_modelWithDictionary:dic]; // yymodel 会忽略不支持的类型字段为nil,故单独处理
        info = (id)[self needUnarchive:info class: class dic: dic];
        [returnArr addObject:info];
    }
    return returnArr;
}

- (BOOL)clearTableFrom:(NSString *)tableName
{
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@", tableName];
    return [self deleteDataBySQL:deleteSql];
}

- (BOOL)deleteTableFrom:(NSString *)tableName otherSqlDic:(NSDictionary<NSString *, NSString *> *)sqlDic
{
    NSMutableString *deleteSql = [NSMutableString stringWithFormat:@"delete from %@", tableName];
    
    if (sqlDic != nil && sqlDic.allKeys.count > 0) {
        [deleteSql appendString:@" where"];
        
        for (NSString *key in sqlDic.allKeys) {
            NSString *value = sqlDic[key];
            
            [deleteSql appendFormat: @" %@ = '%@'", key, value];
        }
    }
    
    NSLog(@"delete data sql: %@", deleteSql);
    
    return [self deleteDataBySQL:deleteSql];
}


@end
