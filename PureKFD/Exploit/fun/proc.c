//
//  proc.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include "proc.h"
#include "offsets.h"
#include "krw.h"
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <CoreFoundation/CoreFoundation.h>

void NSLog(CFStringRef, ...);

uint64_t getProc(pid_t pid) {
    uint64_t proc = get_kernproc();
    
    while (true) {
        if(kread32(proc + off_p_pid) == pid) {
            return proc;
        }
        proc = kread64(proc + off_p_list_le_prev);
        if(!proc) {
            return -1;
        }
    }
    
    return 0;
}

uint64_t getProcByName(char* nm) {
    uint64_t proc = get_kernproc();
    
    while (true) {
        uint64_t nameptr = proc + off_p_name;
        char name[32];
        do_kread(nameptr, &name, 32);
//        NSLog(CFSTR("[i] pid: %d, process name: %s"), kread32(proc + off_p_pid), name);
        if(strcmp(name, nm) == 0) {
            return proc;
        }
        proc = kread64(proc + off_p_list_le_prev);
        if(!proc) {
            return -1;
        }
    }
    
    return 0;
}

int getPidByName(char* nm) {
    uint64_t proc = getProcByName(nm);
    if(proc == -1) return -1;
    return kread32(proc + off_p_pid);
}

int funProc(uint64_t proc) {
    int p_ppid = kread32(proc + off_p_ppid);
    NSLog(CFSTR("[i] self proc->p_ppid: %d\n"), p_ppid);
    NSLog(CFSTR("[i] Patching proc->p_ppid %d -> 1 (for testing kwrite32, getppid)"), p_ppid);
    kwrite32(proc + off_p_ppid, 0x1);
    NSLog(CFSTR("[+] Patched getppid(): %u"), getppid());
    kwrite32(proc + off_p_ppid, p_ppid);
    NSLog(CFSTR("[+] Restored getppid(): %u"), getppid());

    int p_original_ppid = kread32(proc + off_p_original_ppid);
    NSLog(CFSTR("[i] self proc->p_original_ppid: %d"), p_original_ppid);
    
    int p_pgrpid = kread32(proc + off_p_pgrpid);
    NSLog(CFSTR("[i] self proc->p_pgrpid: %d"), p_pgrpid);
    
    int p_uid = kread32(proc + off_p_uid);
    NSLog(CFSTR("[i] self proc->p_uid: %d"), p_uid);
    
    int p_gid = kread32(proc + off_p_gid);
    NSLog(CFSTR("[i] self proc->p_gid: %d"), p_gid);
    
    int p_ruid = kread32(proc + off_p_ruid);
    NSLog(CFSTR("[i] self proc->p_ruid: %d"), p_ruid);
    
    int p_rgid = kread32(proc + off_p_rgid);
    NSLog(CFSTR("[i] self proc->p_rgid: %d"), p_rgid);
    
    int p_svuid = kread32(proc + off_p_svuid);
    NSLog(CFSTR("[i] self proc->p_svuid: %d"), p_svuid);
    
    int p_svgid = kread32(proc + off_p_svgid);
    NSLog(CFSTR("[i] self proc->p_svgid: %d"), p_svgid);
    
    int p_sessionid = kread32(proc + off_p_sessionid);
    NSLog(CFSTR("[i] self proc->p_sessionid: %d"), p_sessionid);
    
    uint64_t p_puniqueid = kread64(proc + off_p_puniqueid);
    NSLog(CFSTR("[i] self proc->p_puniqueid: 0x%llx"), p_puniqueid);
    
    NSLog(CFSTR("[i] Patching proc->p_puniqueid 0x%llx -> 0x4142434445464748 (for testing kwrite64)"), p_puniqueid);
    kwrite64(proc + off_p_puniqueid, 0x4142434445464748);
    NSLog(CFSTR("[+] Patched self proc->p_puniqueid: 0x%llx"), kread64(proc + off_p_puniqueid));
    kwrite64(proc + off_p_puniqueid, p_puniqueid);
    NSLog(CFSTR("[+] Restored self proc->p_puniqueid: 0x%llx"), kread64(proc + off_p_puniqueid));
    
    return 0;
}
