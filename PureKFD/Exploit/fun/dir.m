//
//  dir.m
//  PureKFD
//
//  Created by Lrdsnow on 9/2/23.
//

#import <Foundation/Foundation.h>
#import <dirent.h>
#import <sys/statvfs.h>
#import <sys/stat.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>
#include "vnode.h"
#import "utils.h"

uint64_t createFolderAndRedirectTemp(NSString *path) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/temp"];
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    NSLog(@"%s", path.UTF8String);
    uint64_t vnode = getVnodeAtPathByChdir(path.UTF8String);
    NSLog(@"[i] vnode: 0x%llx", vnode);
    uint64_t orig_to_v_data = -1;
    if (vnode != -1) {
        orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
    } else {
        NSLog(@"Failed to get folder vnode");
    }
    return orig_to_v_data;
}

uint64_t createFolderAndRedirect2(NSString *path) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    NSLog(@"%s", path.UTF8String);
    uint64_t vnode = getVnodeAtPathByChdir(path.UTF8String);
    NSLog(@"[i] vnode: 0x%llx", vnode);
    uint64_t orig_to_v_data = -1;
    if (vnode != -1) {
        orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
    } else {
        NSLog(@"Failed to get folder vnode");
    }
    return orig_to_v_data;
}

uint64_t createFolderAndRedirect3(NSString *path) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mount"];
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    NSLog(@"%s", path.UTF8String);
    uint64_t vnode = getVnodeAtPathByChdir(path.UTF8String);
    NSLog(@"[i] vnode: 0x%llx", vnode);
    uint64_t orig_to_v_data = -1;
    if (vnode != -1) {
        orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
    } else {
        NSLog(@"Failed to get folder vnode");
    }
    return orig_to_v_data;
}

uint64_t createFolderAndRedirectIconsCache(NSString *path) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/iconscache"];
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    NSLog(@"%s", path.UTF8String);
    uint64_t vnode = getVnodeAtPathByChdir(path.UTF8String);
    NSLog(@"[i] vnode: 0x%llx", vnode);
    uint64_t orig_to_v_data = -1;
    if (vnode != -1) {
        orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
    } else {
        NSLog(@"Failed to get folder vnode");
    }
    return orig_to_v_data;
}

uint64_t createFolderAndRedirectMobile() {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mobile_mount"];
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    NSLog(@"/var/mobile/");
    uint64_t vnode = getVnodeAtPathByChdir("/var/mobile/");
    NSLog(@"[i] vnode: 0x%llx", vnode);
    uint64_t orig_to_v_data = -1;
    if (vnode != -1) {
        orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
    } else {
        NSLog(@"Failed to get folder vnode");
    }
    return orig_to_v_data;
}

uint64_t createFolderAndRedirectMobileDocs() {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mobiledocs_mount"];
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    NSLog(@"/var/mobile/");
    uint64_t vnode = getVnodeAtPathByChdir("/var/mobile/");
    NSLog(@"[i] vnode: 0x%llx", vnode);
    uint64_t orig_to_v_data = -1;
    if (vnode != -1) {
        orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
    } else {
        NSLog(@"Failed to get folder vnode");
    }
    return orig_to_v_data;
}

void UnRedirectAndRemoveFolderMobileDocs(uint64_t orig_to_v_data) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mobiledocs_mount"];
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    NSLog(@"Unredirected");
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
}

void UnRedirectAndRemoveFolderMobile(uint64_t orig_to_v_data) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mobile_mount"];
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    NSLog(@"Unredirected");
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
}

void UnRedirectAndRemoveFolder2(uint64_t orig_to_v_data) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    NSLog(@"Unredirected");
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
}

void UnRedirectAndRemoveFolder3(uint64_t orig_to_v_data) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mount"];
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    NSLog(@"Unredirected");
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
}

void UnRedirectAndRemoveFolderIconsCache(uint64_t orig_to_v_data) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/iconscache"];
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    NSLog(@"Unredirected");
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
}

void UnRedirectAndRemoveFolderTemp(uint64_t orig_to_v_data) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/temp"];
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    NSLog(@"Unredirected");
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
}
