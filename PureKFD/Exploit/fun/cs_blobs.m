//
//  cs_blobs.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/08/05.
//

#include "cs_blobs.h"
#include "krw.h"
#include "offsets.h"
#include "vnode.h"
#include "utils.h"
#include "thanks_opa334dev_htrowii.h"

extern const uint8_t *der_decode_plist(CFAllocatorRef allocator, CFTypeRef* output, CFErrorRef *error, const uint8_t *der_start, const uint8_t *der_end);

typedef struct __SC_GenericBlob {
    uint32_t magic;                                 /* magic number */
    uint32_t length;                                /* total length of blob */
    char data[];
} CS_GenericBlob
__attribute__ ((aligned(1)));


uint32_t convertToLittleEndian(uint32_t num) {
    return ((num & 0x000000FF) << 24) |
           ((num & 0x0000FF00) << 8) |
           ((num & 0x00FF0000) >> 8) |
           ((num & 0xFF000000) >> 24);
}

//https://github.com/opa334/Dopamine/blob/master/BaseBin/libjailbreak/src/util.m#L656
NSMutableDictionary *DEREntitlementsDecode(uint8_t *start, uint8_t *end)
{
    if (!start || !end) return nil;
    if (start == end) return nil;

    CFTypeRef plist = NULL;
    CFErrorRef err;
    der_decode_plist(NULL, &plist, &err, start, end);

    if (plist) {
        if (CFGetTypeID(plist) == CFDictionaryGetTypeID()) {
            NSMutableDictionary *plistDict = (__bridge_transfer id)plist;
            return plistDict;
        }
        else if (CFGetTypeID(plist) == CFDataGetTypeID()) {
            // This code path is probably never used, but I decided to implement it anyways
            // Because I saw in disassembly that there is a possibility for this to return data
            NSData *plistData = (__bridge_transfer id)plist;
            NSPropertyListFormat format;
            NSError *decodeError;
            NSMutableDictionary *result = ((NSDictionary *)[NSPropertyListSerialization propertyListWithData:plistData options:0 format:&format error:&decodeError]).mutableCopy;
            if (!result) {
                printf("[-] Error decoding DER: %s\n", decodeError.description.UTF8String);
            }
            return result;
        }
    }
    return nil;
}

uint64_t fun_cs_blobs(char *execPath) {
    
    uint64_t ubc_info = unsign_kptr(kread64(getVnodeAtPath(execPath) + off_vnode_vu_ubcinfo));
    uint32_t cs_add_gen = kread32(ubc_info + off_ubc_info_cs_add_gen);
//    cs_add_gen += 1;
    printf("cs_add_gen: 0x%x\n", cs_add_gen);
    kwrite32(ubc_info + off_ubc_info_cs_add_gen, cs_add_gen);
    
    uint64_t csblobs = kread64(ubc_info + off_ubc_info_cs_blobs);
    printf("csblobs: 0x%llx\n", csblobs);
    uint32_t csb_flags = kread32(csblobs + off_cs_blob_csb_flags);
    printf("csb_flags: 0x%x\n", csb_flags);
    uint64_t csb_teamid = kread64(csblobs + off_cs_blob_csb_teamid);
    printf("csb_teamid: 0x%llx\n", csb_teamid);
    
    printf("csb_cdhash\n");
    HexDump(csblobs + off_cs_blob_csb_cdhash, 20);
    
    return 0;
}

uint64_t fun_proc_dump_entitlements(uint64_t proc) {
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    uint64_t ucreds = kread64(proc_ro + off_p_ro_p_ucred);
    
    uint64_t cr_label_pac = kread64(ucreds + off_u_cr_label);
    uint64_t cr_label = unsign_kptr(cr_label_pac);
    printf("[i] ucred->cr_label: 0x%llx\n", cr_label);
    
    
    //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/osfmk/kern/cs_blobs.h#L283
    //Thanks @jmpews, https://twitter.com/jmpews/status/1623669186894659584/photo/3
    uint64_t osents = kread64(cr_label + 8);//+8, 16, 32, 64, 104, 112, 128, 168, 176, 232, 240 has kernel pointer values...
    printf("[i] osents: 0x%llx\n", osents);
    uint64_t osentitlements = kread64(osents + 0x10);
    printf("[i] osentitlements: 0x%llx\n", osentitlements);
    uint64_t dict = kread64(osentitlements + 0x70);
    printf("[i] dict: 0x%llx\n", dict);
    uint64_t query_ctx = osentitlements + 0x20;
    printf("[i] query_ctx: 0x%llx\n", query_ctx);
    uint64_t der_start = kread64(query_ctx + 0x40);
    printf("[i] der_start: 0x%llx\n", der_start);
    uint64_t der_end = kread64(query_ctx + 0x20);
    printf("[i] der_end: 0x%llx\n", der_end);
    uint64_t der_len = der_end - der_start;
    printf("[i] der_len: 0x%llx\n", der_len);
    uint8_t has_no_der_ents = kread8(osentitlements + 0x50);
    printf("[i] has_no_der_ents: 0x%x\n", has_no_der_ents);
    uint64_t csb_der_entitlements_blob = kread64(osentitlements + 0x60);
    printf("[i] csb_der_entitlements_blob: 0x%llx\n", csb_der_entitlements_blob);
    
    if(!has_no_der_ents) {
        CS_GenericBlob der_ents_blob = {0};
        kreadbuf(csb_der_entitlements_blob, (uint8_t *)&der_ents_blob, sizeof(der_ents_blob));
        uint32_t der_ents_data_len = der_ents_blob.length;
        printf("[i] der_ents_blob.length: 0x%x\n", convertToLittleEndian(der_ents_data_len));
        
        uint8_t *der_ents_data = malloc(der_len);
        kreadbuf(csb_der_entitlements_blob + 8, der_ents_data, der_len);
        uint8_t *us_der_end = der_ents_data + der_len;
        
        NSMutableDictionary *entitlements = DEREntitlementsDecode(der_ents_data, us_der_end);
        if(entitlements != nil) {
            NSLog(@"[+] Got decoded entitlements!\n%@", entitlements);
        } else {
            HexDump(csb_der_entitlements_blob, der_len);
        }
        free(der_ents_data);
    }
    
    return 0;
}

uint64_t fun_vnode_dump_entitlements(const char* path) {
    uint64_t vnode = getVnodeAtPath(path);
    
    uint64_t ubc_info_pac = kread64(vnode + off_vnode_vu_ubcinfo);
    uint64_t ubc_info = unsign_kptr(ubc_info_pac);
    
    uint64_t csblobs = kread64(ubc_info + off_ubc_info_cs_blobs);
    if(csblobs == 0) {
        printf("[-] Couldn't get vnode->ubc_info->cs_blobs.\n");
        return -1;
    }
    
    uint64_t csb_pmap_cs_entry = kread64(csblobs + off_cs_blob_csb_pmap_cs_entry);
    printf("[i] vnode->ubc_info->cs_blobs->csb_pmap_cs_entry: 0x%llx\n", csb_pmap_cs_entry);
    
    uint32_t csb_validation_category = kread32(csblobs + off_cs_blob_csb_validation_category);
    printf("[i] vnode->ubc_info->cs_blobs->csb_validation_category: 0x%x\n", csb_validation_category);
    
    uint64_t ce_ctx = kread64(csb_pmap_cs_entry + off_pmap_cs_code_directory_ce_ctx);
    printf("[i] vnode->ubc_info->cs_blobs->csb_pmap_cs_entry->ce_ctx: 0x%llx\n", ce_ctx);
    uint32_t der_entitlements_size = kread32(csb_pmap_cs_entry + off_pmap_cs_code_directory_der_entitlements_size);
    printf("[i] vnode->ubc_info->cs_blobs->csb_pmap_cs_entry->der_entitlements_size: 0x%x\n", der_entitlements_size);
    uint32_t trust_level = kread32(csb_pmap_cs_entry + off_pmap_cs_code_directory_trust);
    printf("[i] vnode->ubc_info->cs_blobs->csb_pmap_cs_entry->trust: 0x%x\n", trust_level);
    
    //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/EXTERNAL_HEADERS/CoreEntitlements/EntitlementsPriv.h#L21
    //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/EXTERNAL_HEADERS/CoreEntitlements/der_vm.h#L33
    uint64_t der_start = kread64(ce_ctx + 0x38);
    printf("[i] der_start: 0x%llx\n", der_start);
    uint64_t der_end = kread64(ce_ctx + 0x20);
    printf("[i] der_end: 0x%llx\n", der_end);
    uint64_t der_len = der_end - der_start;
    printf("[i] der_len: 0x%llx\n", der_len);
    
    CS_GenericBlob der_ents_blob = {0};
    kreadbuf(der_start, (uint8_t *)&der_ents_blob, sizeof(der_ents_blob));
    uint32_t der_ents_data_len = der_ents_blob.length;
    printf("[i] der_ents_blob.length: 0x%x\n", convertToLittleEndian(der_ents_data_len));
    
    uint8_t *der_ents_data = malloc(der_len);
    kreadbuf(der_start + 8, der_ents_data, der_len);
    uint8_t *us_der_end = der_ents_data + der_len;
    
    NSMutableDictionary *entitlements = DEREntitlementsDecode(der_ents_data, us_der_end);
    if(entitlements != nil) {
        NSLog(@"[+] Got decoded entitlements!\n%@", entitlements);
    } else {
        HexDump(der_start, der_len);
    }
    free(der_ents_data);
    
    return 0;
}
