//
//  apfs_mount.h
//  PureKFD
//
//  Created by Nick Chan on 14/12/2023.
//

/* This file is part of Nick Chan's mount_apfs clone */
#ifndef _APFS_MOUNT_H_
#define _APFS_MOUNT_H_

#include <sys/types.h>
#include <stdint.h>

enum {
    APFS_MOUNT_AS_ROOT = 0, /* mount the default snapshot */
    APFS_MOUNT_FILESYSTEM, /* mount live fs */
    APFS_MOUNT_SNAPSHOT, /* mount custom snapshot in apfs_mountarg.snapshot */
    APFS_MOUNT_FOR_CONVERSION, /* mount snapshot while suppling some representation of im4p and im4m */
    APFS_MOUNT_FOR_VERIFICATION, /* Fusion mount with tier 1 & 2, set by mount_apfs when -C is used (Conversion mount) */
    APFS_MOUNT_FOR_INVERSION, /* Fusion mount with tier 1 only, set by mount_apfs when -c is used */
    APFS_MOUNT_MODE_SIX,  /* ??????? */
    APFS_MOUNT_FOR_INVERT, /* ??? mount for invert */
    APFS_MOUNT_IMG4 /* mount live fs while suppling some representation of im4p and im4m */
};

#define APFS_MOUNT_IMG4_MAXSZ               0x100000

#define APFS_AUTH_ENV_GENERIC               4
#define APFS_AUTH_ENV_SUPPLEMENTAL          5
#define APFS_AUTH_ENV_PDI_NONCE             6

#define APFS_CRYPTEX_TYPE_GENERIC           0x67746776 /* vgtg */
#define APFS_CRYPTEX_TYPE_BRAIN             0x73796162 /* bays */

#define APFS_FLAGS_SMALL_N_OPT              0x400000000 /* mount_apfs -n */
#define APFS_FLAGS_LARGE_R_OPT              0x200000000 /* mount_apfs -R */
#define APFS_FLAGS_LARGET_S_OPT             0x800000000 /* mount_apfs -S */

#define APFSFSMNT_SKIPSANITY                0x1
#define APFSFSMNT_CHECKPOINT                0x2
#define APFSFSMNT_DEMOMODE                  0x4
#define APFSFSMNT_TINYOBJCACHE              0x8
#define APFSFSMNT_CREATETMPCP               0x10
#define APFSFSMNT_LOADTMPCP                 0x20
#define APFSFSMNT_COMMITTMPCP               0x40

/* Fourth argument to mount(2) when mounting apfs */
struct apfs_mount_args {
#ifndef KERNEL
    char* fspec; /* path to device to mount from */
#endif
    uint64_t apfs_flags; /* The standard mount flags, OR'd with apfs-specific flags (APFS_FLAGS_* above) */
    uint32_t mount_mode; /* APFS_MOUNT_* */
    uint32_t pad1; /* padding */
    uint32_t unk_flags; /* yet another type some sort of flags (bitfield), possibly volume role related */
    union {
        char snapshot[256]; /* snapshot name */
        struct {
            char tier1_dev[128]; /* Tier 1 device (Fusion mount) */
            char tier2_dev[128]; /* Tier 2 device (Fusion mount) */
        };
    };
    void* im4p_ptr;
    uint32_t im4p_size;
    uint32_t pad2; /* padding */
    void* im4m_ptr;
    uint32_t im4m_size;
    uint32_t pad3; /* padding */
    uint32_t cryptex_type; /* APFS_CRYPTEX_TYPE_* */
    int32_t auth_mode; /* APFS_AUTH_ENV_* */
    uid_t uid;
    gid_t gid;
}__attribute__((packed, aligned(4)));

typedef struct apfs_mount_args apfs_mount_args_t;

#endif /* _APFS_MOUNT_H_ */

