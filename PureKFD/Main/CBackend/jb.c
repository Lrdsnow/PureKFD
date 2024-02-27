//
//  jb.c
//  PureKFD
//
//  Created by Lrdsnow on 2/27/24.
//

#include "jb.h"
#include <dispatch/dispatch.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <pthread.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

#define OS_ALLOC_ONCE_KEY_MAX    100

struct _os_alloc_once_s {
    long once;
    void *ptr;
};

struct xpc_global_data {
    uint64_t    a;
    uint64_t    xpc_flags;
    mach_port_t    task_bootstrap_port;  /* 0x10 */
#ifndef _64
    uint32_t    padding;
#endif
    xpc_object_t    xpc_bootstrap_pipe;   /* 0x18 */
};

extern struct _os_alloc_once_s _os_alloc_once_table[];
extern void* _os_alloc_once(struct _os_alloc_once_s *slot, size_t sz, os_function_t init);

mach_port_t gJBServerCustomPort = MACH_PORT_NULL;

void jbclient_xpc_set_custom_port(mach_port_t serverPort)
{
    if (gJBServerCustomPort != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), gJBServerCustomPort);
    }
    gJBServerCustomPort = serverPort;
}

xpc_object_t jbserver_xpc_send_dict(xpc_object_t xdict)
{
    xpc_object_t xreply = NULL;

    xpc_object_t xpipe = NULL;
    if (gJBServerCustomPort != MACH_PORT_NULL) {
        // Communicate with custom port if set
        xpipe = xpc_pipe_create_from_port(gJBServerCustomPort, 0);
    }
    else {
        // Else, communicate with launchd
        struct xpc_global_data* globalData = NULL;
        if (_os_alloc_once_table[1].once == -1) {
            globalData = _os_alloc_once_table[1].ptr;
        }
        else {
            globalData = _os_alloc_once(&_os_alloc_once_table[1], 472, NULL);
            if (!globalData) _os_alloc_once_table[1].once = -1;
        }
        if (!globalData) return NULL;
        if (!globalData->xpc_bootstrap_pipe) {
            mach_port_t *initPorts;
            mach_msg_type_number_t initPortsCount = 0;
            if (mach_ports_lookup(mach_task_self(), &initPorts, &initPortsCount) == 0) {
                globalData->task_bootstrap_port = initPorts[0];
                globalData->xpc_bootstrap_pipe = xpc_pipe_create_from_port(globalData->task_bootstrap_port, 0);
            }
        }
        if (!globalData->xpc_bootstrap_pipe) return NULL;
        xpipe = xpc_retain(globalData->xpc_bootstrap_pipe);
    }

    if (!xpipe) return NULL;
    int err = xpc_pipe_routine_with_flags(xpipe, xdict, &xreply, 0);
    xpc_release(xpipe);
    if (err != 0) {
        return NULL;
    }
    return xreply;
}

xpc_object_t jbserver_xpc_send(uint64_t domain, uint64_t action, xpc_object_t xargs)
{
    bool ownsXargs = false;
    if (!xargs) {
        xargs = xpc_dictionary_create_empty();
        ownsXargs = true;
    }

    xpc_dictionary_set_uint64(xargs, "jb-domain", domain);
    xpc_dictionary_set_uint64(xargs, "action", action);

    xpc_object_t xreply = jbserver_xpc_send_dict(xargs);
    if (ownsXargs) {
        xpc_release(xargs);
    }

    return xreply;
}

int jbclient_process_checkin(char **rootPathOut, char **bootUUIDOut, char **sandboxExtensionsOut)
{
    xpc_object_t xreply = jbserver_xpc_send(JBS_DOMAIN_SYSTEMWIDE, JBS_SYSTEMWIDE_PROCESS_CHECKIN, NULL);
    if (xreply) {
        int64_t result = xpc_dictionary_get_int64(xreply, "result");
        const char *rootPath = xpc_dictionary_get_string(xreply, "root-path");
        const char *bootUUID = xpc_dictionary_get_string(xreply, "boot-uuid");
        const char *sandboxExtensions = xpc_dictionary_get_string(xreply, "sandbox-extensions");
        if (rootPathOut) *rootPathOut = rootPath ? strdup(rootPath) : NULL;
        if (bootUUIDOut) *bootUUIDOut = bootUUID ? strdup(bootUUID) : NULL;
        if (sandboxExtensionsOut) *sandboxExtensionsOut = sandboxExtensions ? strdup(sandboxExtensions) : NULL;
        xpc_release(xreply);
        return result;
    }
    return -1;
}
