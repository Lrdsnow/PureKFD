#import "DeviceManager.h"
#import "AppInfo.h"
#include "list_installed.h"

@implementation DeviceManager

- (NSArray<AppInfo *> *)getInstalledApps:(NSString *)udid use_network:(BOOL)use_network {
    idevice_t device = NULL;
    lockdownd_client_t lockdown_client = NULL;
    lockdownd_service_descriptor_t service = NULL;
    instproxy_client_t instproxy_client = NULL;
    NSArray<AppInfo *> *appInfoArray = nil;
    int appCount = 0;

    const char *udid_cstr = [udid UTF8String];

    if (idevice_new_with_options(&device, udid_cstr, (use_network) ? IDEVICE_LOOKUP_NETWORK : IDEVICE_LOOKUP_USBMUX) != IDEVICE_E_SUCCESS) {
        NSLog(@"Error: No device found.");
        return nil;
    }

    if (lockdownd_client_new_with_handshake(device, &lockdown_client, "com.apple.mobile.installation_proxy") != LOCKDOWN_E_SUCCESS) {
        NSLog(@"Error: Unable to connect to lockdownd.");
        idevice_free(device);
        return nil;
    }

    if (lockdownd_start_service(lockdown_client, INSTPROXY_SERVICE_NAME, &service) == LOCKDOWN_E_SUCCESS) {
        if (instproxy_client_new(device, service, &instproxy_client) == INSTPROXY_E_SUCCESS) {
            app_info_t *appInfos = list_installed_app_info(instproxy_client, &appCount);
            if (appInfos) {
                NSMutableArray *appInfoArrayMutable = [[NSMutableArray alloc] initWithCapacity:appCount];
                for (int i = 0; i < appCount; i++) {
                    NSString *bundleID = [NSString stringWithUTF8String:appInfos[i].bundle_id];
                    NSString *container = [NSString stringWithUTF8String:appInfos[i].container];
                    NSString *path = [NSString stringWithUTF8String:appInfos[i].path];

                    if (bundleID && container && path) {
                        AppInfo *appInfo = [[AppInfo alloc] initWithBundleID:bundleID container:container path:path];
                        [appInfoArrayMutable addObject:appInfo];
                    } else {
                        NSLog(@"Error: Invalid data at index %d", i);
                    }
                }
                appInfoArray = [appInfoArrayMutable copy];

                free_app_info(appInfos, appCount);
            } else {
                NSLog(@"Error: list_installed_app_info returned NULL.");
            }
            instproxy_client_free(instproxy_client);
        } else {
            NSLog(@"Error: Unable to create instproxy client.");
        }
        lockdownd_service_descriptor_free(service);
    } else {
        NSLog(@"Error: Unable to start installation proxy service.");
    }

    lockdownd_client_free(lockdown_client);
    idevice_free(device);

    return appInfoArray;
}

@end
