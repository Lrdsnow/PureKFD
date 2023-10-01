//
//  cs_blobs.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/08/05.
//

#ifndef cs_blobs_h
#define cs_blobs_h

#include <stdio.h>

uint64_t fun_cs_blobs(char* execPath);
uint64_t fun_proc_dump_entitlements(uint64_t proc);
uint64_t fun_vnode_dump_entitlements(const char* path);

#endif /* cs_blobs_h */
