// AppInfo.m
#import "AppInfo.h"

@implementation AppInfo

- (instancetype)initWithBundleID:(NSString *)bundleID container:(NSString *)container path:(NSString *)path {
    self = [super init];
    if (self) {
        _bundleID = bundleID;
        _container = container;
        _path = path;
    }
    return self;
}

@end
