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
#include "patchfinder.h"
#include "libdimentio.h"
#include <compression.h>
#include <dlfcn.h>
#include <mach-o/fat.h>
#include <mach/mach.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#include "../krw.h"

#define LZSS_F (18)
#define LZSS_N (4096)
#define LZSS_THRESHOLD (2)
#define IPC_ENTRY_SZ (0x18)
#define OS_STRING_LEN_OFF (0xC)
#define KCOMP_HDR_PAD_SZ (0x16C)
#define OS_STRING_STRING_OFF (0x10)
#define KALLOC_ARRAY_TYPE_BIT (47U)
#define IPC_SPACE_IS_TABLE_OFF (0x20)
#define IPC_ENTRY_IE_OBJECT_OFF (0x0)
#define PROC_P_LIST_LE_PREV_OFF (0x8)
#define OS_DICTIONARY_COUNT_OFF (0x14)
#define PROC_P_LIST_LH_FIRST_OFF (0x0)
#define OS_DICTIONARY_DICT_ENTRY_OFF (0x20)
#define OS_STRING_LEN(a) extract32(a, 14, 18)
#define LOADED_KEXT_SUMMARY_HDR_NAME_OFF (0x10)
#define LOADED_KEXT_SUMMARY_HDR_ADDR_OFF (0x60)
#if TARGET_OS_OSX
#    define PREBOOT_PATH "/System/Volumes/Preboot"
#else
#    define PREBOOT_PATH "/private/preboot/"
#endif
#define IO_AES_ACCELERATOR_SPECIAL_KEYS_OFF (0xD0)
#define APPLE_MOBILE_AP_NONCE_CLEAR_NONCE_SEL (0xC9)
#define IO_AES_ACCELERATOR_SPECIAL_KEY_CNT_OFF (0xD8)
#define APPLE_MOBILE_AP_NONCE_GENERATE_NONCE_SEL (0xC8)
#define BOOT_PATH "/System/Library/Caches/com.apple.kernelcaches/kernelcache"

#define DER_INT (0x2U)
#define DER_SEQ (0x30U)
#define DER_IA5_STR (0x16U)
#define DER_OCTET_STR (0x4U)
#define ARM_PGSHIFT_16K (14U)
#define PROC_PIDREGIONINFO (7)
#define RD(a) extract32(a, 0, 5)
#define RN(a) extract32(a, 5, 5)
#define VM_KERN_MEMORY_OSKEXT (5)
#define KCOMP_HDR_MAGIC (0x636F6D70U)
#define ADRP_ADDR(a) ((a) & ~0xFFFULL)
#define ADRP_IMM(a) (ADR_IMM(a) << 12U)
#define IO_OBJECT_NULL ((io_object_t)0)
#define ADD_X_IMM(a) extract32(a, 10, 12)
#define kIODeviceTreePlane "IODeviceTree"
#define KCOMP_HDR_TYPE_LZSS (0x6C7A7373U)
#define LDR_X_IMM(a) (sextract64(a, 5, 19) << 2U)
#define kOSBundleLoadAddressKey "OSBundleLoadAddress"
#define IS_ADR(a) (((a) & 0x9F000000U) == 0x10000000U)
#define IS_ADRP(a) (((a) & 0x9F000000U) == 0x90000000U)
#define IS_LDR_X(a) (((a) & 0xFF000000U) == 0x58000000U)
#define IS_ADD_X(a) (((a) & 0xFFC00000U) == 0x91000000U)
#define IS_SUBS_X(a) (((a) & 0xFF200000U) == 0xEB000000U)
#define LDR_W_UNSIGNED_IMM(a) (extract32(a, 10, 12) << 2U)
#define LDR_X_UNSIGNED_IMM(a) (extract32(a, 10, 12) << 3U)
#define IS_LDR_W_UNSIGNED_IMM(a) (((a) & 0xFFC00000U) == 0xB9400000U)
#define IS_LDR_X_UNSIGNED_IMM(a) (((a) & 0xFFC00000U) == 0xF9400000U)
#define ADR_IMM(a) ((sextract64(a, 5, 19) << 2U) | extract32(a, 29, 2))

#ifndef SECT_CSTRING
#    define SECT_CSTRING "__cstring"
#endif

#ifndef SEG_TEXT_EXEC
#    define SEG_TEXT_EXEC "__TEXT_EXEC"
#endif

#ifndef MIN
#    define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

char* kernel_path = NULL;
uint64_t kfd = 0;

typedef char io_string_t[512];
typedef uint32_t IOOptionBits;
typedef mach_port_t io_object_t;
typedef kern_return_t (*kernrw_0_kbase_func_t)(kaddr_t *);
typedef io_object_t io_service_t, io_connect_t, io_registry_entry_t;
typedef int (*krw_0_kbase_func_t)(kaddr_t *), (*krw_0_kread_func_t)(kaddr_t, void *, size_t), (*krw_0_kwrite_func_t)(const void *, kaddr_t, size_t), (*kernrw_0_req_kernrw_func_t)(void);

int
proc_pidinfo(int, int, uint64_t, void *, int);

kern_return_t
mach_vm_write(vm_map_t, mach_vm_address_t, vm_offset_t, mach_msg_type_number_t);

kern_return_t
mach_vm_read_overwrite(vm_map_t, mach_vm_address_t, mach_vm_size_t, mach_vm_address_t, mach_vm_size_t *);

kern_return_t
mach_vm_machine_attribute(vm_map_t, mach_vm_address_t, mach_vm_size_t, vm_machine_attribute_t, vm_machine_attribute_val_t *);

extern const mach_port_t kIOMasterPortDefault;

static int kmem_fd = -1;
static unsigned t1sz_boot;
static void *krw_0, *kernrw_0;
static kread_func_t kread_buf;
static task_t tfp0 = TASK_NULL;
static uint64_t proc_struct_sz;
static kwrite_func_t kwrite_buf;
static krw_0_kread_func_t krw_0_kread;
static krw_0_kwrite_func_t krw_0_kwrite;
static bool has_proc_struct_sz, has_kalloc_array_decode, kalloc_array_decode_v2;
static kaddr_t kbase, kernproc, proc_struct_sz_ptr, vm_kernel_link_addr, our_task;
static size_t proc_task_off, proc_p_pid_off, task_itk_space_off, io_dt_nvram_of_dict_off, ipc_port_ip_kobject_off;

static uint32_t
extract32(uint32_t val, unsigned start, unsigned len) {
    return (val >> start) & (~0U >> (32U - len));
}

static uint64_t
sextract64(uint64_t val, unsigned start, unsigned len) {
    return (uint64_t)((int64_t)(val << (64U - len - start)) >> (64U - len));
}

static void
kxpacd(kaddr_t *addr) {
    if(t1sz_boot != 0) {
        *addr |= ~((1ULL << (64U - t1sz_boot)) - 1U);
    }
}

static size_t
decompress_lzss(const uint8_t *src, size_t src_len, uint8_t *dst, size_t dst_len) {
    const uint8_t *src_end = src + src_len, *dst_start = dst, *dst_end = dst + dst_len;
    uint16_t i, r = LZSS_N - LZSS_F, flags = 0;
    uint8_t text_buf[LZSS_N + LZSS_F - 1], j;

    memset(text_buf, ' ', r);
    while(src != src_end && dst != dst_end) {
        if(((flags >>= 1U) & 0x100U) == 0) {
            flags = *src++ | 0xFF00U;
            if(src == src_end) {
                break;
            }
        }
        if((flags & 1U) != 0) {
            text_buf[r++] = *dst++ = *src++;
            r &= LZSS_N - 1U;
        } else {
            i = *src++;
            if(src == src_end) {
                break;
            }
            j = *src++;
            i |= (j & 0xF0U) << 4U;
            j = (j & 0xFU) + LZSS_THRESHOLD;
            do {
                *dst++ = text_buf[r++] = text_buf[i++ & (LZSS_N - 1U)];
                r &= LZSS_N - 1U;
            } while(j-- != 0 && dst != dst_end);
        }
    }
    return (size_t)(dst - dst_start);
}

static const uint8_t *
der_decode(uint8_t tag, const uint8_t *der, const uint8_t *der_end, size_t *out_len) {
    size_t der_len;

    if(der_end - der > 2 && tag == *der++) {
        if(((der_len = *der++) & 0x80U) != 0) {
            *out_len = 0;
            if((der_len &= 0x7FU) <= sizeof(*out_len) && (size_t)(der_end - der) >= der_len) {
                while(der_len-- != 0) {
                    *out_len = (*out_len << 8U) | *der++;
                }
            }
        } else {
            *out_len = der_len;
        }
        if(*out_len != 0 && (size_t)(der_end - der) >= *out_len) {
            return der;
        }
    }
    return NULL;
}

static const uint8_t *
der_decode_seq(const uint8_t *der, const uint8_t *der_end, const uint8_t **seq_end) {
    size_t der_len;

    if((der = der_decode(DER_SEQ, der, der_end, &der_len)) != NULL) {
        *seq_end = der + der_len;
    }
    return der;
}

static const uint8_t *
der_decode_uint64(const uint8_t *der, const uint8_t *der_end, uint64_t *r) {
    size_t der_len;

    if((der = der_decode(DER_INT, der, der_end, &der_len)) != NULL && (*der & 0x80U) == 0 && (der_len <= sizeof(*r) || (--der_len == sizeof(*r) && *der++ == 0))) {
        *r = 0;
        while(der_len-- != 0) {
            *r = (*r << 8U) | *der++;
        }
        return der;
    }
    return NULL;
}

static void *
kdecompress(const void *src, size_t src_len, size_t *dst_len) {
    const uint8_t *der, *octet, *der_end, *src_end = (const uint8_t *)src + src_len;
    struct {
        uint32_t magic, type, adler32, uncomp_sz, comp_sz;
        uint8_t pad[KCOMP_HDR_PAD_SZ];
    } kcomp_hdr;
    size_t der_len;
    uint64_t r;
    void *dst;

    if((der = der_decode_seq(src, src_end, &der_end)) != NULL && (der = der_decode(DER_IA5_STR, der, der_end, &der_len)) != NULL && der_len == 4 && (memcmp(der, "IMG4", der_len) != 0 || ((der = der_decode_seq(der + der_len, src_end, &der_end)) != NULL && (der = der_decode(DER_IA5_STR, der, der_end, &der_len)) != NULL && der_len == 4)) && memcmp(der, "IM4P", der_len) == 0 && (der = der_decode(DER_IA5_STR, der + der_len, der_end, &der_len)) != NULL && der_len == 4 && memcmp(der, "krnl", der_len) == 0 && (der = der_decode(DER_IA5_STR, der + der_len, der_end, &der_len)) != NULL && (der = der_decode(DER_OCTET_STR, der + der_len, der_end, &der_len)) != NULL && der_len > sizeof(kcomp_hdr)) {
        octet = der;
        memcpy(&kcomp_hdr, octet, sizeof(kcomp_hdr));
        if(kcomp_hdr.magic == __builtin_bswap32(KCOMP_HDR_MAGIC)) {
            if(kcomp_hdr.type == __builtin_bswap32(KCOMP_HDR_TYPE_LZSS) && (kcomp_hdr.comp_sz = __builtin_bswap32(kcomp_hdr.comp_sz)) <= der_len - sizeof(kcomp_hdr) && (kcomp_hdr.uncomp_sz = __builtin_bswap32(kcomp_hdr.uncomp_sz)) != 0 && (dst = malloc(kcomp_hdr.uncomp_sz)) != NULL) {
                if(decompress_lzss(octet + sizeof(kcomp_hdr), kcomp_hdr.comp_sz, dst, kcomp_hdr.uncomp_sz) == kcomp_hdr.uncomp_sz) {
                    *dst_len = kcomp_hdr.uncomp_sz;
                    return dst;
                }
                free(dst);
            }
        } else if((der = der_decode_seq(der + der_len, src_end, &der_end)) != NULL && (der = der_decode_uint64(der, der_end, &r)) != NULL && r == 1 && der_decode_uint64(der, der_end, &r) != NULL && r != 0 && (dst = malloc(r)) != NULL) {
            if(compression_decode_buffer(dst, r, octet, der_len, NULL, COMPRESSION_LZFSE) == r) {
                *dst_len = r;
                return dst;
            }
            free(dst);
        }
    }
    return NULL;
}

static kern_return_t
kread_buf_kfd(kaddr_t addr, void *buf, size_t sz) {
    if(kfd == 0)
        return KERN_FAILURE;
    early_kreadbuf(kfd, addr, buf, sz);
    return KERN_SUCCESS;
}

static kern_return_t
find_section_kernel(kaddr_t p, struct segment_command_64 sg64, const char *sect_name, struct section_64 *sp) {
    for(; sg64.nsects-- != 0; p += sizeof(*sp)) {
        if(kread_buf(p, sp, sizeof(*sp)) != KERN_SUCCESS) {
            break;
        }
        if((sp->flags & SECTION_TYPE) != S_ZEROFILL) {
            if(sp->offset < sg64.fileoff || sp->size > sg64.filesize || sp->offset - sg64.fileoff > sg64.filesize - sp->size) {
                break;
            }
            if(sp->size != 0 && strncmp(sp->segname, sg64.segname, sizeof(sp->segname)) == 0 && strncmp(sp->sectname, sect_name, sizeof(sp->sectname)) == 0) {
                return KERN_SUCCESS;
            }
        }
    }
    return KERN_FAILURE;
}

static kern_return_t
find_section_macho(const char *p, struct segment_command_64 sg64, const char *sect_name, struct section_64 *sp) {
    for(; sg64.nsects-- != 0; p += sizeof(*sp)) {
        memcpy(sp, p, sizeof(*sp));
        if((sp->flags & SECTION_TYPE) != S_ZEROFILL) {
            if(sp->offset < sg64.fileoff || sp->size > sg64.filesize || sp->offset - sg64.fileoff > sg64.filesize - sp->size) {
                break;
            }
            if(sp->size != 0 && strncmp(sp->segname, sg64.segname, sizeof(sp->segname)) == 0 && strncmp(sp->sectname, sect_name, sizeof(sp->sectname)) == 0) {
                return KERN_SUCCESS;
            }
        }
    }
    return KERN_FAILURE;
}

static void
sec_reset(sec_64_t *sec) {
    memset(&sec->s64, '\0', sizeof(sec->s64));
    sec->data = NULL;
}

static void
sec_term(sec_64_t *sec) {
    free(sec->data);
}

static kern_return_t
sec_read_buf(sec_64_t sec, kaddr_t addr, void *buf, size_t sz) {
    size_t off;

    if(addr < sec.s64.addr || sz > sec.s64.size || (off = addr - sec.s64.addr) > sec.s64.size - sz) {
        return KERN_FAILURE;
    }
    memcpy(buf, sec.data + off, sz);
    return KERN_SUCCESS;
}

static void
pfinder_reset(pfinder_t *pfinder) {
    pfinder->data = NULL;
    pfinder->kernel = NULL;
    pfinder->kernel_sz = 0;
    sec_reset(&pfinder->sec_text);
    sec_reset(&pfinder->sec_cstring);
}

void
pfinder_term(pfinder_t *pfinder) {
    free(pfinder->data);
    sec_term(&pfinder->sec_text);
    sec_term(&pfinder->sec_cstring);
    pfinder_reset(pfinder);
}

static kern_return_t
pfinder_init_macho(pfinder_t *pfinder, size_t off) {
    const char *p = pfinder->kernel + off, *e;
    struct fileset_entry_command fec;
    struct segment_command_64 sg64;
    struct mach_header_64 mh64;
    struct load_command lc;
    struct section_64 s64;

    memcpy(&mh64, p, sizeof(mh64));
    if(mh64.magic == MH_MAGIC_64 && mh64.cputype == CPU_TYPE_ARM64 &&
       (mh64.filetype == MH_EXECUTE || (off == 0 && mh64.filetype == MH_FILESET))
       && mh64.sizeofcmds < (pfinder->kernel_sz - sizeof(mh64)) - off) {
        for(p += sizeof(mh64), e = p + mh64.sizeofcmds; mh64.ncmds-- != 0 && (size_t)(e - p) >= sizeof(lc); p += lc.cmdsize) {
            memcpy(&lc, p, sizeof(lc));
            if(lc.cmdsize < sizeof(lc) || (size_t)(e - p) < lc.cmdsize) {
                break;
            }
            if(lc.cmd == LC_SEGMENT_64) {
                if(lc.cmdsize < sizeof(sg64)) {
                    break;
                }
                memcpy(&sg64, p, sizeof(sg64));
                if(sg64.vmsize == 0) {
                    continue;
                }
                if(sg64.nsects != (lc.cmdsize - sizeof(sg64)) / sizeof(s64) || sg64.fileoff > pfinder->kernel_sz || sg64.filesize > pfinder->kernel_sz - sg64.fileoff) {
                    break;
                }
                if(mh64.filetype == MH_EXECUTE) {
                    if(strncmp(sg64.segname, SEG_TEXT_EXEC, sizeof(sg64.segname)) == 0) {
                        if(find_section_macho(p + sizeof(sg64), sg64, SECT_TEXT, &s64) != KERN_SUCCESS || s64.size == 0 || (pfinder->sec_text.data = malloc(s64.size)) == NULL) {
                            break;
                        }
                        memcpy(pfinder->sec_text.data, pfinder->kernel + s64.offset, s64.size);
                        pfinder->sec_text.s64 = s64;
                        printf("sec_text_addr: " KADDR_FMT ", sec_text_off: 0x%" PRIX32 ", sec_text_sz: 0x%" PRIX64 "\n", s64.addr, s64.offset, s64.size);
                    } else if(strncmp(sg64.segname, SEG_TEXT, sizeof(sg64.segname)) == 0) {
                        if(find_section_macho(p + sizeof(sg64), sg64, SECT_CSTRING, &s64) != KERN_SUCCESS || s64.size == 0 || (pfinder->sec_cstring.data = calloc(1, s64.size + 1)) == NULL) {
                            break;
                        }
                        memcpy(pfinder->sec_cstring.data, pfinder->kernel + s64.offset, s64.size);
                        pfinder->sec_cstring.s64 = s64;
                        printf("sec_cstring_addr: " KADDR_FMT ", sec_cstring_off: 0x%" PRIX32 ", sec_cstring_sz: 0x%" PRIX64 "\n", s64.addr, s64.offset, s64.size);
                    }
                }
            }
            else if(mh64.filetype == MH_FILESET && lc.cmd == LC_FILESET_ENTRY) {
                if(lc.cmdsize < sizeof(fec)) {
                    break;
                }
                memcpy(&fec, p, sizeof(fec));
                if(fec.fileoff == 0 || fec.fileoff > pfinder->kernel_sz - sizeof(mh64) || fec.entry_id.offset > fec.cmdsize || p[fec.cmdsize - 1] != '\0') {
                    break;
                }
                if(strcmp(p + fec.entry_id.offset, "com.apple.kernel") == 0 && pfinder_init_macho(pfinder, fec.fileoff) == KERN_SUCCESS) {
                    return KERN_SUCCESS;
                }
            }
            if(pfinder->sec_text.s64.size != 0 && pfinder->sec_cstring.s64.size != 0) {
                pfinder->sec_text.s64.addr += kbase - vm_kernel_link_addr;
                pfinder->sec_cstring.s64.addr += kbase - vm_kernel_link_addr;
                return KERN_SUCCESS;
            }
        }
    }
    return KERN_FAILURE;
}

static int
kstrcmp(kaddr_t p, const char *s0) {
    size_t len = strlen(s0);
    int ret = 1;
    char *s;

    if((s = malloc(len + 1)) != NULL) {
        s[len] = '\0';
        if(kread_buf(p, s, len) == KERN_SUCCESS) {
            ret = strcmp(s, s0);
        }
        free(s);
    }
    return ret;
}

static kern_return_t
pfinder_init_kernel(pfinder_t *pfinder, size_t off) {
    struct fileset_entry_command fec;
    struct segment_command_64 sg64;
    kaddr_t p = kbase + off, e;
    struct mach_header_64 mh64;
    struct load_command lc;
    struct section_64 s64;

    if(kread_buf(p, &mh64, sizeof(mh64)) == KERN_SUCCESS && mh64.magic == MH_MAGIC_64 && mh64.cputype == CPU_TYPE_ARM64 &&
       (mh64.filetype == MH_EXECUTE || (off == 0 && mh64.filetype == MH_FILESET))
       ) {
        for(p += sizeof(mh64), e = p + mh64.sizeofcmds; mh64.ncmds-- != 0 && e - p >= sizeof(lc); p += lc.cmdsize) {
            if(kread_buf(p, &lc, sizeof(lc)) != KERN_SUCCESS || lc.cmdsize < sizeof(lc) || e - p < lc.cmdsize) {
                break;
            }
            if(lc.cmd == LC_SEGMENT_64) {
                if(lc.cmdsize < sizeof(sg64) || kread_buf(p, &sg64, sizeof(sg64)) != KERN_SUCCESS) {
                    break;
                }
                if(sg64.vmsize == 0) {
                    continue;
                }
                if(sg64.nsects != (lc.cmdsize - sizeof(sg64)) / sizeof(s64)) {
                    break;
                }
                if(mh64.filetype == MH_EXECUTE) {
                    if(strncmp(sg64.segname, SEG_TEXT_EXEC, sizeof(sg64.segname)) == 0) {
                        if(find_section_kernel(p + sizeof(sg64), sg64, SECT_TEXT, &s64) != KERN_SUCCESS || s64.size == 0 || (pfinder->sec_text.data = malloc(s64.size)) == NULL || kread_buf(s64.addr, pfinder->sec_text.data, s64.size) != KERN_SUCCESS) {
                            break;
                        }
                        pfinder->sec_text.s64 = s64;
                        printf("sec_text_addr: " KADDR_FMT ", sec_text_off: 0x%" PRIX32 ", sec_text_sz: 0x%" PRIX64 "\n", s64.addr, s64.offset, s64.size);
                    } else if(strncmp(sg64.segname, SEG_TEXT, sizeof(sg64.segname)) == 0) {
                        if(find_section_kernel(p + sizeof(sg64), sg64, SECT_CSTRING, &s64) != KERN_SUCCESS || s64.size == 0 || (pfinder->sec_cstring.data = calloc(1, s64.size + 1)) == NULL || kread_buf(s64.addr, pfinder->sec_cstring.data, s64.size) != KERN_SUCCESS) {
                            break;
                        }
                        pfinder->sec_cstring.s64 = s64;
                        printf("sec_cstring_addr: " KADDR_FMT ", sec_cstring_off: 0x%" PRIX32 ", sec_cstring_sz: 0x%" PRIX64 "\n", s64.addr, s64.offset, s64.size);
                    }
                }
            }
            else if(mh64.filetype == MH_FILESET && lc.cmd == LC_FILESET_ENTRY) {
                if(lc.cmdsize < sizeof(fec) || kread_buf(p, &fec, sizeof(fec)) != KERN_SUCCESS) {
                    break;
                }
                if(fec.fileoff == 0 || fec.entry_id.offset > fec.cmdsize) {
                    break;
                }
                if(kstrcmp(p + fec.entry_id.offset, "com.apple.kernel") == 0 && pfinder_init_kernel(pfinder, fec.fileoff) == KERN_SUCCESS) {
                    return KERN_SUCCESS;
                }
            }
            if(pfinder->sec_text.s64.size != 0 && pfinder->sec_cstring.s64.size != 0) {
                return KERN_SUCCESS;
            }
        }
    }
    return KERN_FAILURE;
}

static kern_return_t
pfinder_init_file(pfinder_t *pfinder, const char *filename) {
    kern_return_t ret = KERN_FAILURE;
    struct mach_header_64 mh64;
    struct fat_header fh;
    struct stat stat_buf;
    struct fat_arch fa;
    const char *p;
    size_t len;
    void *m;
    int fd;

    pfinder_reset(pfinder);
    if((fd = open(filename, O_RDONLY | O_CLOEXEC)) != -1) {
        if(fstat(fd, &stat_buf) != -1 && S_ISREG(stat_buf.st_mode) && stat_buf.st_size > 0) {
            len = (size_t)stat_buf.st_size;
            if((m = mmap(NULL, len, PROT_READ, MAP_PRIVATE, fd, 0)) != MAP_FAILED) {
                if((pfinder->data = kdecompress(m, len, &pfinder->kernel_sz)) != NULL && pfinder->kernel_sz > sizeof(fh) + sizeof(mh64)) {
                    pfinder->kernel = pfinder->data;
                    memcpy(&fh, pfinder->kernel, sizeof(fh));
                    if(fh.magic == __builtin_bswap32(FAT_MAGIC) && (fh.nfat_arch = __builtin_bswap32(fh.nfat_arch)) < (pfinder->kernel_sz - sizeof(fh)) / sizeof(fa)) {
                        for(p = pfinder->kernel + sizeof(fh); fh.nfat_arch-- != 0; p += sizeof(fa)) {
                            memcpy(&fa, p, sizeof(fa));
                            if(fa.cputype == (cpu_type_t)__builtin_bswap32(CPU_TYPE_ARM64) && (fa.offset = __builtin_bswap32(fa.offset)) < pfinder->kernel_sz && (fa.size = __builtin_bswap32(fa.size)) <= pfinder->kernel_sz - fa.offset && fa.size > sizeof(mh64)) {
                                pfinder->kernel_sz = fa.size;
                                pfinder->kernel += fa.offset;
                                break;
                            }
                        }
                    }
                    ret = pfinder_init_macho(pfinder, 0);
                }
                munmap(m, len);
            }
        }
        close(fd);
    }
    if(ret != KERN_SUCCESS) {
        pfinder_term(pfinder);
    }
    return ret;
}

int set_libdimentio_kbase(uint64_t _kbase) {
    kbase = _kbase;
    
    return 0;
}

int set_libdimentio_kfd(uint64_t _kfd) {
    kfd = _kfd;
    
    return 0;
}

int set_libdimentio_kernpath(char* _path) {
    kernel_path = _path;
    
    return 0;
}

kern_return_t
pfinder_init(pfinder_t *pfinder) {
    kern_return_t ret = KERN_FAILURE;
    
    vm_kernel_link_addr = get_vm_kernel_link_addr();
    
    pfinder_reset(pfinder);
    
    if(kernel_path != NULL && access(kernel_path, F_OK) == 0) {
        printf("kernel_path: %s\n", kernel_path);
        if((ret = pfinder_init_file(pfinder, kernel_path)) != KERN_SUCCESS) {
            pfinder_term(pfinder);
        }
    }
    
    kread_buf = kread_buf_kfd;
    if(kernel_path == NULL && (ret = pfinder_init_kernel(pfinder, 0)) != KERN_SUCCESS) {
        pfinder_term(pfinder);
    }
    
    return ret;
}

static kaddr_t
pfinder_xref_rd(pfinder_t pfinder, uint32_t rd, kaddr_t start, kaddr_t to) {
    kaddr_t x[32] = { 0 };
    uint32_t insn;

    for(; sec_read_buf(pfinder.sec_text, start, &insn, sizeof(insn)) == KERN_SUCCESS; start += sizeof(insn)) {
        if(IS_LDR_X(insn)) {
            x[RD(insn)] = start + LDR_X_IMM(insn);
        } else if(IS_ADR(insn)) {
            x[RD(insn)] = start + ADR_IMM(insn);
        } else if(IS_ADD_X(insn)) {
            x[RD(insn)] = x[RN(insn)] + ADD_X_IMM(insn);
        } else if(IS_LDR_W_UNSIGNED_IMM(insn)) {
            x[RD(insn)] = x[RN(insn)] + LDR_W_UNSIGNED_IMM(insn);
        } else if(IS_LDR_X_UNSIGNED_IMM(insn)) {
            x[RD(insn)] = x[RN(insn)] + LDR_X_UNSIGNED_IMM(insn);
        } else {
            if(IS_ADRP(insn)) {
                x[RD(insn)] = ADRP_ADDR(start) + ADRP_IMM(insn);
            }
            continue;
        }
        if(RD(insn) == rd) {
            if(to == 0) {
                return x[rd];
            }
            if(x[rd] == to) {
                return start;
            }
        }
    }
    return 0;
}

static kaddr_t
pfinder_xref_str(pfinder_t pfinder, const char *str, uint32_t rd) {
    const char *p, *e;
    size_t len;

    for(p = pfinder.sec_cstring.data, e = p + pfinder.sec_cstring.s64.size; p != e; p += len) {
        len = strlen(p) + 1;
        if(strncmp(str, p, len) == 0) {
            return pfinder_xref_rd(pfinder, rd, pfinder.sec_text.s64.addr, pfinder.sec_cstring.s64.addr + (kaddr_t)(p - pfinder.sec_cstring.data));
        }
    }
    return 0;
}

kaddr_t
pfinder_kernproc(pfinder_t pfinder) {
    kaddr_t ref = pfinder_xref_str(pfinder, "Should never have an EVFILT_READ except for reg or fifo. @%s:%d", 0);
    uint32_t insns[2];

    if(ref == 0) {
        ref = pfinder_xref_str(pfinder, "\"Should never have an EVFILT_READ except for reg or fifo.\"", 0);
    }
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref -= sizeof(*insns)) {
        if(IS_ADRP(insns[0]) && IS_LDR_X_UNSIGNED_IMM(insns[1]) && RD(insns[1]) == 3) {
            return pfinder_xref_rd(pfinder, RD(insns[1]), ref, 0);
        }
    }
    return 0;
}

static kaddr_t
pfinder_proc_struct_sz_ptr(pfinder_t pfinder) {
    uint32_t insns[3];
    kaddr_t ref;

    for(ref = pfinder_xref_str(pfinder, "panic: ticket lock acquired check done outside of kernel debugger @%s:%d", 0); sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref -= sizeof(*insns)) {
        if(IS_ADRP(insns[0]) && IS_LDR_X_UNSIGNED_IMM(insns[1]) && IS_SUBS_X(insns[2]) && RD(insns[2]) == 1) {
            return pfinder_xref_rd(pfinder, RD(insns[1]), ref, 0);
        }
    }
    return 0;
}

static kaddr_t
pfinder_bof64(pfinder_t pfinder, kaddr_t start, kaddr_t where)
{
    for (; where >= start; where -= 4) {
        uint32_t insns[1];
        
        sec_read_buf(pfinder.sec_text, where, insns, sizeof(insns));
        
//        kread_buf(where, &op, sizeof(op));//*(uint32_t *)(buf + where);
        if ((insns[0] & 0xFFC003FF) == 0x910003FD) {
            unsigned delta = (insns[0] >> 10) & 0xFFF;
            //printf("0x%llx: ADD X29, SP, #0x%x\n", where + kerndumpbase, delta);
            if ((delta & 0xF) == 0) {
                kaddr_t prev = where - ((delta >> 4) + 1) * 4;
                uint32_t au[1];
                
                sec_read_buf(pfinder.sec_text, where, au, sizeof(au));
                
                //kread_buf(prev, &au, sizeof(au));//*(uint32_t *)(buf + prev);
                //printf("0x%llx: (%llx & %llx) == %llx\n", prev + kerndumpbase, au, 0x3BC003E0, au & 0x3BC003E0);
                if ((au[0] & 0x3BC003E0) == 0x298003E0) {
                    //printf("%x: STP x, y, [SP,#-imm]!\n", prev);
                    return prev;
                } else if ((au[0] & 0x7F8003FF) == 0x510003FF) {
                    //printf("%x: SUB SP, SP, #imm\n", prev);
                    return prev;
                }
                for (kaddr_t diff = 4; diff < delta/4+4; diff+=4) {
                    uint32_t ai[1];
                    
                    sec_read_buf(pfinder.sec_text, where, ai, sizeof(ai));
                    
                    
//                    kread_buf(where - diff, &ai, sizeof(ai));//*(uint32_t *)(buf + where - diff);
                    // SUB SP, SP, #imm
                    //printf("0x%llx: (%llx & %llx) == %llx\n", where - diff + kerndumpbase, ai, 0x3BC003E0, ai & 0x3BC003E0);
                    if ((ai[0] & 0x7F8003FF) == 0x510003FF) {
                        return where - diff;
                    }
                    // Not stp and not str
                    if (((ai[0] & 0xFFC003E0) != 0xA90003E0) && (ai[0]&0xFFC001F0) != 0xF90001E0) {
                        break;
                    }
                }
                // try something else
                while (where > start) {
                    where -= 4;
//                    au = *(uint32_t *)(buf + where);
//                    au = 0;
                    au[0] = 0;
                    
                    sec_read_buf(pfinder.sec_text, where, au, sizeof(au));
//                    kread_buf(where, &au, sizeof(au));
                    // SUB SP, SP, #imm
                    if ((au[0] & 0xFFC003FF) == 0xD10003FF && ((au[0] >> 10) & 0xFFF) == delta + 0x10) {
                        return where;
                    }
                    // STP x, y, [SP,#imm]
                    if ((au[0] & 0xFFC003E0) != 0xA90003E0) {
                        where += 4;
                        break;
                    }
                }
            }
        }
    }
    return 0;
}

static kaddr_t
follow_adrl(kaddr_t ref, uint32_t adrp_op, uint32_t add_op)
{
    //Stage1. ADRP
    uint64_t imm_hi_lo = (uint64_t)((adrp_op >> 3)  & 0x1FFFFC);
    imm_hi_lo |= (uint64_t)((adrp_op >> 29) & 0x3);
    if ((adrp_op & 0x800000) != 0) {
        // Sign extend
        imm_hi_lo |= 0xFFFFFFFFFFE00000;
    }
    
    // Build real imm
    uint64_t imm = imm_hi_lo << 12;
    
    uint64_t ret = (ref & ~0xFFF) + imm;
    
    //Stage2. ADD
    uint64_t imm12 = (add_op & 0x3FFC00) >> 10;
        
    uint32_t shift = (add_op >> 22) & 1;
    if (shift == 1) {
        imm12 = imm12 << 12;
    }
    ret += imm12;
    return ret;
}

static kaddr_t
follow_adrpLdr(kaddr_t ref, uint32_t adrp_op, uint32_t ldr_op)
{
    //Stage1. ADRP
    uint64_t imm_hi_lo = (uint64_t)((adrp_op >> 3)  & 0x1FFFFC);
    imm_hi_lo |= (uint64_t)((adrp_op >> 29) & 0x3);
    if ((adrp_op & 0x800000) != 0) {
        // Sign extend
        imm_hi_lo |= 0xFFFFFFFFFFE00000;
    }
    
    // Build real imm
    uint64_t imm = imm_hi_lo << 12;
    uint64_t ret = (ref & ~0xFFF) + imm;
    
    //Stage2. STR, LDR
    uint64_t imm12 = ((ldr_op >> 10) & 0xFFF) << 3;
    ret += imm12;
    
    return ret;
}

kaddr_t
pfinder_cdevsw(pfinder_t pfinder) {
    bool found = false;
    
    //1. opcode
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[6];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if((insns[0] & 0xff000000) == 0xb4000000   //cbz
           && insns[1] == 0xd2800001   //mov x1, #0
           && insns[2] == 0xd2800002   //mov x2, #0
           && insns[3] == 0x52800003   //mov w3, #0
           && insns[4] == 0x52800024   //mov w4, #1
           && insns[5] == 0xd2800005  /* mov x5, #0 */) {
            found = true;
            break;
        }
    }
    if(!found)
        return 0;
    
//    printf("1 ref: 0x%llx, ref\n", ref);
    
    //2. Step into High address, and find adrp opcode.
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if(IS_ADRP(insns[0]) && IS_ADD_X(insns[1])) {
            break;
        }
    }
    
//    printf("2 ref: 0x%llx, ref-kslide: 0x%llx\n", ref, ref-get_kslide());
    
    //3. Get label from adrl opcode.
    return follow_adrl(ref, insns[0], insns[1]);
}

kaddr_t
pfinder_gPhysBase(pfinder_t pfinder) {
    bool found = false;
    
    //1. opcode
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[6];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if(insns[0] == 0x7100005F
           && insns[1] == 0x54000120
           && (insns[2] & 0x9F000000) == 0x90000000    //adrp
           && (insns[3] & 0xFF800000) == 0x91000000    //add
           && insns[4]== 0xF9400042
           && insns[5] == 0xCB020000) {
            found = true;
            break;
        }
    }
    if(!found)
        return 0;
    
    return follow_adrl(ref, insns[2], insns[3]);
}

kaddr_t
pfinder_gPhysSize(pfinder_t pfinder)
{
    bool found = false;
    
    //1. opcode
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[8];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if ((insns[0] & 0xFFC00000) == 0xF9000000   //str
            && insns[1] == 0x8b090108
            && insns[2] == 0x9272c508
            && insns[3] == 0xcb090108) {
            found = true;
            break;
        }
    }
    if(!found)
        return pfinder_gPhysBase(pfinder) + 8;
    
    return follow_adrpLdr(ref, insns[6], insns[7]);
}

kaddr_t
pfinder_gVirtBase(pfinder_t pfinder)
{
    bool found = false;
    
    //1. opcode
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[8];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if (insns[0] == 0x7100005F
            && insns[1] == 0x54000120
            && (insns[2] & 0x9F000000) == 0x90000000    //adrp
            && (insns[3] & 0xFF800000) == 0x91000000    //add
            && insns[4]== 0xF9400042
            && insns[5] == 0xCB020000) {
            found = true;
            break;
        }
    }
    if(!found)
        return 0;
    
    return follow_adrl(ref, insns[6], insns[7]);
}

kaddr_t
pfinder_perfmon_dev_open_2(pfinder_t pfinder)
{
//__TEXT_EXEC:__text:FFFFFFF007324700 3F 01 08 6B                 CMP             W9, W8
//__TEXT_EXEC:__text:FFFFFFF007324704 E1 01 00 54                 B.NE            loc_FFFFFFF007324740
//__TEXT_EXEC:__text:FFFFFFF007324708 A8 5E 00 12                 AND             W8, W21, #0xFFFFFF
//__TEXT_EXEC:__text:FFFFFFF00732470C 1F 05 00 71                 CMP             W8, #1
//__TEXT_EXEC:__text:FFFFFFF007324710 68 02 00 54                 B.HI            loc_FFFFFFF00732475C
    
    bool found = false;
    
    //1. opcode
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[8];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if (insns[0] == 0x53187ea8  //lsr w8, w21, #0x18
            && (insns[2] & 0xffc0001f) == 0xb9400009   // ldr w9, [Xn, n]
            && insns[3] == 0x6b08013f    //cmp w9, w8 v
            && (insns[4] & 0xff00001f) == 0x54000001    //b.ne *
            && (insns[5] & 0xfffffc00) == 0x12005c00    //and Wn, Wn, 0xfffff v
            && insns[6] == 0x7100051f   //cmp w8, #1 v
            && (insns[7] & 0xff00001f) == 0x54000008    /* b.hi * v */) {
            found = true;
            break;
        }
    }
    if(!found)
        return 0;
    
    ref = pfinder_bof64(pfinder, pfinder.sec_text.s64.addr, ref);
    
    sec_read_buf(pfinder.sec_text, ref-4, insns, sizeof(insns));
    if(insns[0] == 0xD503237F) {
        ref -= 4;
    }
    
    return ref;
}

kaddr_t
pfinder_perfmon_dev_open(pfinder_t pfinder)
{
    bool found = false;
    
    //1. opcode
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[5];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if ((insns[0] & 0xff000000) == 0x34000000    //cbz w*
            && insns[1] == 0x52800300    //mov W0, #0x18
            && (insns[2] & 0xff000000) == 0x14000000    //b*
            && insns[3] == 0x52800340   //mov w0, #0x1A
            && (insns[4] & 0xff000000) == 0x14000000    /* b* */) {
            found = true;
            break;
        }
    }
    if(!found)
        return pfinder_perfmon_dev_open_2(pfinder);
    
    ref = pfinder_bof64(pfinder, pfinder.sec_text.s64.addr, ref);
    
    sec_read_buf(pfinder.sec_text, ref-4, insns, sizeof(insns));
    if(insns[0] == 0xD503237F) {
        ref -= 4;
    }
    
    return ref;
}

kaddr_t
pfinder_perfmon_devices(pfinder_t pfinder)
{
    bool found = false;
    
    //1. opcode
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[5];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if (insns[0] == 0x6b08013f    //cmp w9, w8
            && (insns[1] & 0xff00001f) == 0x54000001    //b.ne *
            && insns[2] == 0x52800028    //mov w8, #1
            && insns[3] == 0x5280140a   /* mov w10, #0xa0 */) {
            found = true;
            break;
        }
    }
    if(!found)
        return 0;
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if(IS_ADRP(insns[0]) && IS_ADD_X(insns[1])) {
            break;
        }
    }
    
    return follow_adrl(ref, insns[0], insns[1]);
}

kaddr_t
pfinder_ptov_table(pfinder_t pfinder)
{
    bool found = false;
    
    //1. opcode
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[5];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if (insns[0] == 0x52800049
            && insns[1] == 0x14000004
            && insns[2] == 0xd2800009
            && insns[3] == 0x14000002) {
            found = true;
            break;
        }
    }
    if(!found)
        return 0;
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if(IS_ADRP(insns[0]) && IS_ADD_X(insns[1])) {
            break;
        }
    }
    
    return follow_adrl(ref, insns[0], insns[1]);
}

kaddr_t 
pfinder_vn_kqfilter_2(pfinder_t pfinder)
{
    bool found = false;
    
    //1. opcode
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[5];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if (insns[0] == 0x7100051f  //cmp w8, #1
            && (insns[1] & 0xff00001f) == 0x54000000    //b.eq *
            && insns[2] == 0x7100111f    //cmp w8, #4
            && (insns[3] & 0xff00001f) == 0x54000000  //b.eq *
            && insns[4] == 0x71001d1f    /* cmp w8, #7 */) {
            found = true;
            break;
        }
    }
    if(!found)
        return 0;
    
    ref = pfinder_bof64(pfinder, pfinder.sec_text.s64.addr, ref);
    
    sec_read_buf(pfinder.sec_text, ref-4, insns, sizeof(insns));
    if(insns[0] == 0xD503237F) {
        ref -= 4;
    }
    
    return ref;
}

kaddr_t
pfinder_vn_kqfilter(pfinder_t pfinder)
{
    bool found = false;

    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[5];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if (insns[0] == 0xD2800001
            && insns[1] == 0xAA1503E0
            && insns[2] == 0xAA1303E2
            && insns[3] == 0xAA1403E3) {
            found = true;
            break;
        }
    }
    if(!found)
        return pfinder_vn_kqfilter_2(pfinder);
    
    ref = pfinder_bof64(pfinder, pfinder.sec_text.s64.addr, ref);
    
    sec_read_buf(pfinder.sec_text, ref-4, insns, sizeof(insns));
    if(insns[0] == 0xD503237F) {
        ref -= 4;
    }
    
    return ref;
}

kaddr_t
pfinder_proc_object_size(pfinder_t pfinder) {
    bool found = false;
    
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[5];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if (insns[0] == 0xAA1503E0
            && insns[1] == 0x528104E1
            && insns[2] == 0x52800102
            && insns[3] == 0x52801103) {
            found = true;
            break;
        }
    }
    if(!found)
        return 0;
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if(IS_ADRP(insns[0]) && (IS_LDR_X(insns[1]) || IS_LDR_W_UNSIGNED_IMM(insns[1]) || IS_LDR_X_UNSIGNED_IMM(insns[1]))) {
            break;
        }
    }
    
    ref = follow_adrpLdr(ref, insns[0], insns[1]);
    printf("proc_object_size addr: 0x%llx\n", ref);
    
    uint64_t val = 0;
    kread_buf(ref, &val, sizeof(val));
    
    return val;
}
