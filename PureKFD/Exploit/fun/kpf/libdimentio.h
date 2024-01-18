/* Copyright 2023 0x7ff
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#ifndef LIBDIMENTIO_H
#    define LIBDIMENTIO_H
#    include <CommonCrypto/CommonCrypto.h>
#    include <CoreFoundation/CoreFoundation.h>
#    define KADDR_FMT "0x%" PRIX64

#include <mach-o/loader.h>

typedef struct {
    struct section_64 s64;
    char *data;
} sec_64_t;

typedef struct {
    sec_64_t sec_text, sec_cstring;
    const char *kernel;
    size_t kernel_sz;
    char *data;
} pfinder_t;

typedef uint64_t kaddr_t;
typedef kern_return_t (*kread_func_t)(kaddr_t, void *, size_t), (*kwrite_func_t)(kaddr_t, const void *, size_t);

void
dimentio_term(void);

kern_return_t
dimentio_init(kaddr_t, kread_func_t, kwrite_func_t);

kern_return_t
dimentio(uint64_t *, bool, uint8_t[CC_SHA384_DIGEST_LENGTH], size_t *);

kern_return_t
dimentio_preinit(uint64_t *, bool, uint8_t[CC_SHA384_DIGEST_LENGTH], size_t *);

kern_return_t
pfinder_init(pfinder_t *pfinder);

int
set_libdimentio_kbase(uint64_t _kbase);

int
set_libdimentio_kfd(uint64_t kfd);

int
set_libdimentio_kernpath(char* _path);

void
pfinder_term(pfinder_t *pfinder);

kaddr_t
pfinder_kernproc(pfinder_t pfinder);

kaddr_t
pfinder_cdevsw(pfinder_t pfinder);

kaddr_t
pfinder_gPhysBase(pfinder_t pfinder);

kaddr_t
pfinder_gPhysSize(pfinder_t pfinder);

kaddr_t
pfinder_gVirtBase(pfinder_t pfinder);

kaddr_t
pfinder_perfmon_dev_open_2(pfinder_t pfinder);

kaddr_t
pfinder_perfmon_dev_open(pfinder_t pfinder);

kaddr_t
pfinder_perfmon_devices(pfinder_t pfinder);

kaddr_t
pfinder_ptov_table(pfinder_t pfinder);

kaddr_t
pfinder_vn_kqfilter_2(pfinder_t pfinder);

kaddr_t
pfinder_vn_kqfilter(pfinder_t pfinder);

kaddr_t
pfinder_proc_object_size(pfinder_t pfinder);
#endif
