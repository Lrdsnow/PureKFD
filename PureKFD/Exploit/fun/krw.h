//
//  krw.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#ifndef krw_h
#define krw_h

#include <stdio.h>
#include "fun.h"

uint64_t unsign_kptr(uint64_t pac_kaddr);
void do_kclose(void);
void early_kread(uint64_t kfd, uint64_t kaddr, void* uaddr, uint64_t size);
void early_kreadbuf(uint64_t kfd, uint64_t kaddr, void* output, size_t size);
void do_kread(uint64_t kaddr, void* uaddr, uint64_t size);
void do_kwrite(void* uaddr, uint64_t kaddr, uint64_t size);
uint64_t get_kslide(void);
uint64_t get_kernproc(void);
uint64_t get_selftask(void);
uint64_t get_selfpmap(void);
uint64_t get_kerntask(void);
uint8_t kread8(uint64_t where);
uint32_t kread16(uint64_t where);
uint32_t kread32(uint64_t where);
uint64_t kread64(uint64_t where);
uint64_t kread64_smr(uint64_t where);
void kwrite8(uint64_t where, uint8_t what);
void kwrite16(uint64_t where, uint16_t what);
void kwrite32(uint64_t where, uint32_t what);
void kwrite64(uint64_t where, uint64_t what);
uint64_t do_vtophys(uint64_t what);
uint64_t do_phystokv(uint64_t what);
uint64_t kread64_ptr(uint64_t kaddr);
void kreadbuf(uint64_t kaddr, void* output, size_t size);

#endif /* krw_h */
