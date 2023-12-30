//
//  waitpid_decode.h
//  PureKFD
//
//  Created by Nick Chan on 14/12/2023.
//

#ifndef waitpid_decode_h
#define waitpid_decode_h

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/wait.h>

char* waitpid_decode(int status);
#endif /* waitpid_decode_h */
