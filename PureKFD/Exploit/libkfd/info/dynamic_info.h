/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef dynamic_info_h
#define dynamic_info_h

#include "../../fun/kpf/patchfinder.h"

struct dynamic_info {
    const char* kern_version;
    bool kread_kqueue_workloop_ctl_supported;
    bool perf_supported;
    // struct proc
    u64 proc__p_list__le_prev;
    u64 proc__p_pid;
    u64 proc__p_fd__fd_ofiles;
    u64 proc__object_size;
    // struct task
    u64 task__map;
    // struct thread
    u64 thread__thread_id;
    // kernelcache static addresses (perf)
    u64 kernelcache__cdevsw;                          // "spec_open type" or "Can't mark ptc as kqueue ok"
    u64 kernelcache__gPhysBase;                       // "%s: illegal PA: 0x%llx; phys base 0x%llx, size 0x%llx"
    u64 kernelcache__gPhysSize;                       // (gPhysBase + 0x8)
    u64 kernelcache__gVirtBase;                       // "%s: illegal PA: 0x%llx; phys base 0x%llx, size 0x%llx"
    u64 kernelcache__perfmon_dev_open;                // "perfmon: attempt to open unsupported source: 0x%x"
    u64 kernelcache__perfmon_devices;                 // "perfmon: %s: devfs_make_node_clone failed"
    u64 kernelcache__ptov_table;                      // "%s: illegal PA: 0x%llx; phys base 0x%llx, size 0x%llx"
    u64 kernelcache__vn_kqfilter;                     // "Invalid knote filter on a vnode!"
};

struct dynamic_info kern_versions[] = {
    // iOS 16.x / arm64e
    {
        .kern_version = "Darwin Kernel Version 22.x.x / arm64e",
        .kread_kqueue_workloop_ctl_supported = false,
        .perf_supported = true,
        .proc__p_list__le_prev = 0x0008,
        .proc__p_pid = 0x0060,
        .proc__p_fd__fd_ofiles = 0x00f8,
        .proc__object_size = 0,
        .task__map = 0x0028,
        .thread__thread_id = 0,
        .kernelcache__cdevsw = 0,
        .kernelcache__gPhysBase = 0,
        .kernelcache__gPhysSize = 0,
        .kernelcache__gVirtBase = 0,
        .kernelcache__perfmon_dev_open = 0,
        .kernelcache__perfmon_devices = 0,
        .kernelcache__ptov_table = 0,
        .kernelcache__vn_kqfilter = 0,
    },
//    // iOS 16.6 - iPhone 12 Pro
//    // T1SZ_BOOT must be changed to 25 instead of 17
//    {
//        .kern_version = "Darwin Kernel Version 22.6.0: Wed Jun 28 20:50:15 PDT 2023; root:xnu-8796.142.1~1/RELEASE_ARM64_T8101",
//        .kread_kqueue_workloop_ctl_supported = false,
//        .perf_supported = true,
//        .proc__p_list__le_prev = 0x0008,
//        .proc__p_pid = 0x0060,
//        .proc__p_fd__fd_ofiles = 0x00f8,
//        .proc__object_size = 0x0730,
//        .task__map = 0x0028,
//        .thread__thread_id = 0,
//        .kernelcache__cdevsw = 0xfffffff00a4a5288,
//        .kernelcache__gPhysBase = 0xfffffff0079303b8,
//        .kernelcache__gPhysSize = 0xfffffff0079303c0,
//        .kernelcache__gVirtBase = 0xfffffff00792e570,
//        .kernelcache__perfmon_dev_open = 0xfffffff007ef4278,
//        .kernelcache__perfmon_devices = 0xfffffff00a4e5320,
//        .kernelcache__ptov_table = 0xfffffff0078e38f0,
//        .kernelcache__vn_kqfilter = 0xfffffff007f42f40,
//    },
//    // macOS 13.4 - MacBook Air (M2, 2022)
//    {
//        .kern_version = "todo",
//        .kread_kqueue_workloop_ctl_supported = false,
//        .perf_supported = false,
//        .proc__p_list__le_prev = 0x0008,
//        .proc__p_pid = 0x0060,
//        .proc__p_fd__fd_ofiles = 0x00f8,
//        .proc__object_size = 0x0778,
//        .task__map = 0x0028,
//        .thread__thread_id = 0,
//        .kernelcache__cdevsw = 0,
//        .kernelcache__gPhysBase = 0,
//        .kernelcache__gPhysSize = 0,
//        .kernelcache__gVirtBase = 0,
//        .kernelcache__perfmon_dev_open = 0,
//        .kernelcache__perfmon_devices = 0,
//        .kernelcache__ptov_table = 0,
//        .kernelcache__vn_kqfilter = 0,
//    },
//    // macOS 13.5 - MacBook Air (M2, 2022)
//    {
//        .kern_version = "Darwin Kernel Version 22.6.0: Wed Jul  5 22:17:35 PDT 2023; root:xnu-8796.141.3~6/RELEASE_ARM64_T8112",
//        .kread_kqueue_workloop_ctl_supported = false,
//        .perf_supported = false,
//        .proc__p_list__le_prev = 0x0008,
//        .proc__p_pid = 0x0060,
//        .proc__p_fd__fd_ofiles = 0x00f8,
//        .proc__object_size = 0x0778,
//        .task__map = 0x0028,
//        .thread__thread_id = 0,
//        .kernelcache__cdevsw = 0,
//        .kernelcache__gPhysBase = 0,
//        .kernelcache__gPhysSize = 0,
//        .kernelcache__gVirtBase = 0,
//        .kernelcache__perfmon_dev_open = 0,
//        .kernelcache__perfmon_devices = 0,
//        .kernelcache__ptov_table = 0,
//        .kernelcache__vn_kqfilter = 0,
//    },
//    // iOS 16.1.2 - iPhone 14 Pro
//    // T1SZ_BOOT = 25
//    {
//        .kern_version = "Darwin Kernel Version 22.1.0: Thu Oct  6 19:34:16 PDT 2022; root:xnu-8792.42.7~1/RELEASE_ARM64_T8120",
//        .kread_kqueue_workloop_ctl_supported = false,
//        .perf_supported = true,
//        .proc__p_list__le_prev = 0x0008,
//        .proc__p_pid = 0x0060,
//        .proc__p_fd__fd_ofiles = 0x00f8,
//        .proc__object_size = 0x530,
//        .task__map = 0x0028,
//        .thread__thread_id = 0,
//        .kernelcache__cdevsw = 0xFFFFFFF00A311168,
//        .kernelcache__gPhysBase = 0xFFFFFFF00784BD50,
//        .kernelcache__gPhysSize = 0xFFFFFFF00784BD58,
//        .kernelcache__gVirtBase = 0xFFFFFFF007849F38,
//        .kernelcache__perfmon_dev_open = 0xFFFFFFF007EC0288,
//        .kernelcache__perfmon_devices = 0xFFFFFFF00A34C310,
//        .kernelcache__ptov_table = 0xFFFFFFF0077FFA18,
//        .kernelcache__vn_kqfilter = 0xFFFFFFF007F101A0,
//    },
};

#endif /* dynamic_info_h */
