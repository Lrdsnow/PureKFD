//
//  roothelper_bridge.h
//  PureKFD
//
//  Created by Nick Chan on 14/12/2023.
//

#ifndef roothelper_bridge_h
#define roothelper_bridge_h

#include "apfs_mount.h"
#include <Foundation/Foundation.h>

NSString *mount_check(const char *mountpoint);

#include <spawn.h>
#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);


#endif /* roothelper_bridge_h */
