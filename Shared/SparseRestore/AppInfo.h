// AppInfo.h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppInfo : NSObject

@property (nonatomic, strong) NSString *bundleID;
@property (nonatomic, strong) NSString *container;
@property (nonatomic, strong) NSString *path;

- (instancetype)initWithBundleID:(NSString *)bundleID container:(NSString *)container path:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
