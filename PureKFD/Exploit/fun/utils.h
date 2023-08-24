//
//  utils.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/30.
//

#include <stdio.h>
int clearUICache(void);
int themePasscodes(void);
int ResSet16(NSInteger height, NSInteger width);
int removeSMSCache(void);
int VarMobileWriteTest(void);
int VarMobileRemoveTest(void);
int setSuperviseMode(bool enable);
int removeKeyboardCache(void);
int regionChanger(NSString *country_value, NSString *region_value);
void DynamicCOW(int subtype);
int whitelist(void);
