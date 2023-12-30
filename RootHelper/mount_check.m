//
//  mount_check.m
//  PureKFD
//
//  Created by Nick Chan on 14/12/2023.
//

#import <Foundation/Foundation.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/statvfs.h>

#include "apfs_mount.h"

NSString *mount_check(const char *mountpoint) {

    int ret;
    struct statfs fs;

    if ((ret = statfs(mountpoint, &fs))) {
        return [NSString stringWithFormat:@"could not statfs %s: %d (%s)\n", mountpoint, errno, strerror(errno)];
    }

    bool isreadonly = (fs.f_flags & ST_RDONLY);

    if (!isreadonly) {
        NSLog(@"%s: mount point %s is NOT read-only... will not remount!\n", __func__, mountpoint);
        return @"All Good!";
    }

    struct apfs_mount_args preboot_arg = {
        .fspec = fs.f_mntfromname,
        .apfs_flags = MNT_UPDATE,
        .mount_mode = APFS_MOUNT_FILESYSTEM,
    };
    ret = mount("apfs", "/private/preboot", MNT_UPDATE, &preboot_arg);
    if (ret) {
        return [NSString stringWithFormat:@"could not remount /private/preboot: %d (%s)\n", errno, strerror(errno)];
    }
    return @"All Good!";
}
