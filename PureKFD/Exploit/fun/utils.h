//
//  utils.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/30.
//

#include <stdio.h>
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

int ResSet16(NSInteger height, NSInteger width);
int removeSMSCache(void);
int VarMobileWriteTest(void);
int VarMobileRemoveTest(void);
int VarMobileWriteFolderTest(void);
int VarMobileRemoveFolderTest(void);
int setSuperviseMode(bool enable);
int removeKeyboardCache(void);
int regionChanger(NSString *country_value, NSString *region_value);
void HexDump(uint64_t addr, size_t size);
bool sandbox_escape_can_i_access_file(char* path, int mode);
void DynamicKFD(int subtype);
