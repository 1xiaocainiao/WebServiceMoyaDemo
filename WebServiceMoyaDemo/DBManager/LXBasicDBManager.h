

#import <Foundation/Foundation.h>
#import "FMDB.h"
#import "LXBaseModel.h"

typedef NS_OPTIONS(NSUInteger, LXPropertyEncodingType) {
    LXPropertyEncodingTypeInt = 0,
    LXPropertyEncodingTypeDouble,
    LXPropertyEncodingTypeString,
    LXPropertyEncodingTypeBool,
    LXPropertyEncodingTypeData,
};

@interface LXBasicDBManager : NSObject {
    FMDatabase *db;
}

@property (nonatomic, retain) FMDatabase *db;

@property (nonatomic,retain) NSString *dbName;

+ (instancetype)sharedDBManager:(NSString *)dbName;

// 升级版本清理数据库
+ (void)updateVersionCleanCache;
// 获取需要清理的数据名称
+ (NSString *)getNeedCleanDBName;

- (BOOL)isExistTable:(NSString *)tableName;

- (NSArray *)getDataBySQL:(NSString *)sql;

- (BOOL)insertDataWithSQL:(NSString *)sql;

- (BOOL)deleteDataBySQL:(NSString *)sql;

- (NSString *)getPropertyClassWithClass:(Class)class propertyName:(NSString *)propertyName;

- (LXPropertyEncodingType)property:(NSString *)propertyName inClassType:(Class)class;

- (id)needUnarchive:(id)info class:(Class)class dic:(NSDictionary *)dic;



- (BOOL)insertModelObject:(LXBaseModel *)info clean:(BOOL)clean;// 没有表会先创建

- (BOOL)insertModelObject:(LXBaseModel *)info clean:(BOOL)clean extTableName:(NSString *)extTableName;

- (BOOL)insertModelArray:(NSArray<LXBaseModel *> *)infoList clean:(BOOL)clean extTableName:(NSString *)extTableName;

- (id)getModelFromClass:(Class)class otherSqlDic:(NSDictionary<NSString *, NSString *> *)sqlDic;

- (id)getModelFromClass:(Class)class fromExtTable: (NSString *)extTable otherSqlDic:(NSDictionary<NSString *, NSString *> *)sqlDic;

- (id)getModelArrayFromClass:(Class)class fromExtTable: (NSString *)extTable otherSqlDic:(NSDictionary<NSString *, NSString *> *)sqlDic;

- (id)getModelArrayFromClass:(Class)class otherSqlDic:(NSDictionary<NSString *, NSString *> *)sqlDic;

- (BOOL)clearTableFrom:(NSString *)tableName;

- (BOOL)deleteTableFrom:(NSString *)tableName otherSqlDic:(NSDictionary<NSString *, NSString *> *)sqlDic;

@end
