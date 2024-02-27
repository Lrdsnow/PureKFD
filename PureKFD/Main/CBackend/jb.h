//
//  jb.h
//  PureKFD
//
//  Created by Lrdsnow on 2/27/24.
//

#ifndef jb_h
#define jb_h

#include <stdio.h>
#include <xpc/xpc.h>
#include <stdint.h>

#define JBS_DOMAIN_SYSTEMWIDE 1
enum {
    JBS_SYSTEMWIDE_GET_JBROOT = 1,
    JBS_SYSTEMWIDE_GET_BOOT_UUID,
    JBS_SYSTEMWIDE_TRUST_BINARY,
    JBS_SYSTEMWIDE_TRUST_LIBRARY,
    JBS_SYSTEMWIDE_PROCESS_CHECKIN,
    JBS_SYSTEMWIDE_FORK_FIX,
    JBS_SYSTEMWIDE_CS_REVALIDATE,
    // JBS_SYSTEMWIDE_LOCK_PAGE,
};

void jbclient_xpc_set_custom_port(mach_port_t serverPort);

xpc_object_t jbserver_xpc_send_dict(xpc_object_t xdict);
xpc_object_t jbserver_xpc_send(uint64_t domain, uint64_t action, xpc_object_t xargs);

int jbclient_process_checkin(char **rootPathOut, char **bootUUIDOut, char **sandboxExtensionsOut);

#endif /* jb_h */
