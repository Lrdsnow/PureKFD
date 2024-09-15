//
//  DeviceManager.h
//  purebox
//
//  Created by Lrdsnow on 9/14/24.
//

#import <Foundation/Foundation.h>
#import "../AppInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface DeviceManager : NSObject

- (NSArray<AppInfo *> *)getInstalledApps:(NSString *)udid use_network:(BOOL)use_network;

@end

NS_ASSUME_NONNULL_END

