//
//  patchfinder.h
//  kfd
//
//  Created by Seo Hyun-gyu on 1/8/24.
//

#ifndef patchfinder_h
#define patchfinder_h

#import <Foundation/Foundation.h>

typedef UInt32        IOOptionBits;
#define IO_OBJECT_NULL ((io_object_t)0)
typedef mach_port_t io_object_t;
typedef io_object_t io_registry_entry_t;
extern const mach_port_t kIOMainPortDefault;
typedef char io_string_t[512];

kern_return_t IOObjectRelease(io_object_t object );

io_registry_entry_t IORegistryEntryFromPath(mach_port_t, const io_string_t);

CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);

const char* get_kernversion(void);

int run_kfd_patchfinder(uint64_t kfd, uint64_t kbase);

int import_kfd_offsets(void);

int save_kfd_offsets(void);

uint64_t get_vm_kernel_link_addr(void);

extern uint64_t off_cdevsw;
extern uint64_t off_gPhysBase;
extern uint64_t off_gPhysSize;
extern uint64_t off_gVirtBase;
extern uint64_t off_perfmon_dev_open;
extern uint64_t off_perfmon_devices;
extern uint64_t off_ptov_table;
extern uint64_t off_vn_kqfilter;
extern uint64_t off_proc_object_size;

#endif /* patchfinder_h */
