//
//  waitpid_decode.c
//  PureKFD
//
//  Created by Nick Chan on 14/12/2023.
//

#include "waitpid_decode.h"


char* waitpid_decode(int status) {
    char* retbuf = calloc(50, 1);
    assert(retbuf);
    
    if (WIFEXITED(status)) {
        snprintf(retbuf, 50, "exited with code %d", WEXITSTATUS(status));
    } else if (WIFSIGNALED(status)) {
        if (WCOREDUMP(status))
            snprintf(retbuf, 50, "terminated by signal %d (Core Dumped)", WTERMSIG(status));
        else
            snprintf(retbuf, 50, "terminated by signal %d", WTERMSIG(status));
    } else if (WIFSTOPPED(status)) {
        snprintf(retbuf, 50, "stopped by signal %d", WTERMSIG(status));
    }
    
    return retbuf;
    
}
