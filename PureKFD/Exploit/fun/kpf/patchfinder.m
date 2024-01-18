//
//  patchfinder.m
//  kfd
//
//  Created by Seo Hyun-gyu on 1/8/24.
//

#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#import <sys/mount.h>
#import "patchfinder.h"
#import "libdimentio.h"
#import "krw.h"

bool did_patchfinder = false;
uint64_t off_cdevsw = 0;
uint64_t off_gPhysBase = 0;
uint64_t off_gPhysSize = 0;
uint64_t off_gVirtBase = 0;
uint64_t off_perfmon_dev_open = 0;
uint64_t off_perfmon_devices = 0;
uint64_t off_ptov_table = 0;
uint64_t off_vn_kqfilter = 0;
uint64_t off_proc_object_size = 0;

const char* getBootManifestHash(void) {
    struct statfs fs;
    if (statfs("/usr/standalone/firmware", &fs) == 0) {
        NSString *mountedPath = [NSString stringWithUTF8String:fs.f_mntfromname];
        NSArray<NSString *> *components = [mountedPath componentsSeparatedByString:@"/"];
        if ([components count] > 3) {
            NSString *substring = components[3];
            return substring.UTF8String;
        }
    }
    return NULL;
}

const char* get_kernel_path(void) {
    NSString *kernelPath = [NSString stringWithFormat:@"/private/preboot/%s%@", getBootManifestHash(), @"/System/Library/Caches/com.apple.kernelcaches/kernelcache"];
    
    return kernelPath.UTF8String;
}

void removeIfExist(const char* path) {
    if(access(path, F_OK) == 0) remove(path);
}

int run_kfd_patchfinder(uint64_t kfd, uint64_t kbase) {
    printf("[!] Starting kfd patchfinder (Thanks 0x7ff)\n");
    
    uint64_t vm_kernel_link_addr = get_vm_kernel_link_addr();
    uint64_t kslide = kbase - vm_kernel_link_addr;
    set_libdimentio_kbase(kbase);
    set_libdimentio_kfd(kfd);
    
    pfinder_t pfinder;
    if(pfinder_init(&pfinder) != KERN_SUCCESS) {
        return -1;
    }
    printf("pfinder_init: success!\n");
    
    uint64_t cdevsw = pfinder_cdevsw(pfinder);
    if(cdevsw) off_cdevsw = cdevsw - kslide;
    printf("cdevsw: 0x%llx\n", off_cdevsw);
    if(off_cdevsw == 0) return -1;
    
    uint64_t gPhysBase = pfinder_gPhysBase(pfinder);
    if(gPhysBase) off_gPhysBase = gPhysBase - kslide;
    printf("gPhysBase: 0x%llx\n", off_gPhysBase);
    if(off_gPhysBase == 0) return -1;
    
    uint64_t gPhysSize = pfinder_gPhysSize(pfinder);
    if(gPhysSize) off_gPhysSize = gPhysSize - kslide;
    printf("gPhysSize: 0x%llx\n", off_gPhysSize);
    if(off_gPhysSize == 0) return -1;
    
    uint64_t gVirtBase = pfinder_gVirtBase(pfinder);
    if(gVirtBase) off_gVirtBase = gVirtBase - kslide;
    printf("gVirtBase: 0x%llx\n", off_gVirtBase);
    if(off_gVirtBase == 0) return -1;
    
    uint64_t perfmon_dev_open = pfinder_perfmon_dev_open(pfinder);
    if(perfmon_dev_open) off_perfmon_dev_open = perfmon_dev_open - kslide;
    printf("perfmon_dev_open: 0x%llx\n", off_perfmon_dev_open);
    if(off_perfmon_dev_open == 0) return -1;
    
    uint64_t perfmon_devices = pfinder_perfmon_devices(pfinder);
    if(perfmon_devices) off_perfmon_devices = perfmon_devices - kslide;
    printf("perfmon_devices: 0x%llx\n", off_perfmon_devices);
    if(off_perfmon_devices == 0) return -1;
    
    uint64_t ptov_table = pfinder_ptov_table(pfinder);
    if(ptov_table) off_ptov_table = ptov_table - kslide;
    printf("ptov_table: 0x%llx\n", off_ptov_table);
    if(off_ptov_table == 0) return -1;
    
    uint64_t vn_kqfilter = pfinder_vn_kqfilter(pfinder);
    if(vn_kqfilter) off_vn_kqfilter = vn_kqfilter - kslide;
    printf("vn_kqfilter: 0x%llx\n", off_vn_kqfilter);
    if(off_vn_kqfilter == 0) return -1;
    
    uint64_t proc_object_size = pfinder_proc_object_size(pfinder);
    if(proc_object_size) off_proc_object_size = proc_object_size;
    printf("proc_object_size: 0x%llx\n", off_proc_object_size);
    if(off_proc_object_size == 0) return -1;
    
    pfinder_term(&pfinder);
    
    save_kfd_offsets();
    
    return 0;
}

const char* get_kernversion(void) {
    char kern_version[512] = {};
    size_t size = sizeof(kern_version);
    sysctlbyname("kern.version", &kern_version, &size, NULL, 0);
    
    return strdup(kern_version);;
}

int import_kfd_offsets(void) {
    NSString* save_path = [NSString stringWithFormat:@"%@/Documents/kfund_offsets.plist", NSHomeDirectory()];
    if(access(save_path.UTF8String, F_OK) == -1)
        return -1;
    
    NSDictionary *offsets = [NSDictionary dictionaryWithContentsOfFile:save_path];
    NSString *saved_kern_version = [offsets objectForKey:@"kern_version"];
    if(strcmp(get_kernversion(), saved_kern_version.UTF8String) != 0)
        return -1;
    
    printf("[!] Found saved kfd offsets\n");
    
    off_cdevsw = [offsets[@"off_cdevsw"] unsignedLongLongValue];
    printf("cdevsw: 0x%llx\n", off_cdevsw);
    off_gPhysBase = [offsets[@"off_gPhysBase"] unsignedLongLongValue];
    printf("gPhysBase: 0x%llx\n", off_gPhysBase);
    off_gPhysSize = [offsets[@"off_gPhysSize"] unsignedLongLongValue];
    printf("gPhysSize: 0x%llx\n", off_gPhysSize);
    off_gVirtBase = [offsets[@"off_gVirtBase"] unsignedLongLongValue];
    printf("gVirtBase: 0x%llx\n", off_gVirtBase);
    off_perfmon_dev_open = [offsets[@"off_perfmon_dev_open"] unsignedLongLongValue];
    printf("perfmon_dev_open: 0x%llx\n", off_perfmon_dev_open);
    off_perfmon_devices = [offsets[@"off_perfmon_devices"] unsignedLongLongValue];
    printf("perfmon_devices: 0x%llx\n", off_perfmon_devices);
    off_ptov_table = [offsets[@"off_ptov_table"] unsignedLongLongValue];
    printf("ptov_table: 0x%llx\n", off_ptov_table);
    off_vn_kqfilter = [offsets[@"off_vn_kqfilter"] unsignedLongLongValue];
    printf("vn_kqfilter: 0x%llx\n", off_vn_kqfilter);
    off_proc_object_size = [offsets[@"off_proc_object_size"] unsignedLongLongValue];
    printf("proc_object_size: 0x%llx\n", off_proc_object_size);
    
    return 0;
}

int save_kfd_offsets(void) {
    NSString* save_path = [NSString stringWithFormat:@"%@/Documents/kfund_offsets.plist", NSHomeDirectory()];
    remove(save_path.UTF8String);
    
    printf("[!] Saving kfd offsets\n");
    
    NSDictionary *offsets = @{
        @"kern_version": @(get_kernversion()),
        @"off_cdevsw": @(off_cdevsw),
        @"off_gPhysBase": @(off_gPhysBase),
        @"off_gPhysSize": @(off_gPhysSize),
        @"off_gVirtBase": @(off_gVirtBase),
        @"off_perfmon_dev_open": @(off_perfmon_dev_open),
        @"off_perfmon_devices": @(off_perfmon_devices),
        @"off_ptov_table": @(off_ptov_table),
        @"off_vn_kqfilter": @(off_vn_kqfilter),
        @"off_proc_object_size": @(off_proc_object_size),
    };
    
    BOOL success = [offsets writeToFile:save_path atomically:YES];
    if (!success) {
        printf("failed to saved offsets: %s\n", save_path.UTF8String);
        return -1;
    }
    printf("saved offsets for kfd: %s\n", save_path.UTF8String);
    
    return 0;
}

uint64_t get_vm_kernel_link_addr(void) {
    const char* kernversion = get_kernversion();
    if(strstr(kernversion, "T8103") != NULL || strstr(kernversion, "T8112") != NULL)
        return 0xFFFFFE0007004000;
    else
        return 0xFFFFFFF007004000;
}
