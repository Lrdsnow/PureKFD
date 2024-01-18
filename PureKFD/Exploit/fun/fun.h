//
//  fun.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/25.
//

#ifndef fun_h
#define fun_h

#include <stdio.h>
#include <mach/mach.h>

uint64_t fun_ipc_entry_lookup(mach_port_name_t port_name);
int do_fun(void);
void fix_exploit(void);

#endif /* fun_h */
