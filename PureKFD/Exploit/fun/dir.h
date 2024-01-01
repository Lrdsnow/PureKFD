//
//  dir.h
//  PureKFD
//
//  Created by Lrdsnow on 9/2/23.
//

#ifndef dir_h
#define dir_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

uint64_t createFolderAndRedirect2(NSString *path);
uint64_t createFolderAndRedirect3(NSString *path);
uint64_t createFolderAndRedirectIconsCache(NSString *path);
uint64_t createFolderAndRedirectTemp(NSString *path);
uint64_t createFolderAndRedirectMobile();
uint64_t createFolderAndRedirectMobileDocs();
void UnRedirectAndRemoveFolder2(uint64_t orig_to_v_data);
void UnRedirectAndRemoveFolder3(uint64_t orig_to_v_data);
void UnRedirectAndRemoveFolderIconsCache(uint64_t orig_to_v_data);
void UnRedirectAndRemoveFolderTemp(uint64_t orig_to_v_data);
void UnRedirectAndRemoveFolderMobile(uint64_t orig_to_v_data);
void UnRedirectAndRemoveFolderMobileDocs(uint64_t orig_to_v_data);
//void createFolder0755(NSString *path, NSString *foldername);
//void createFolderUwU(NSString *path, NSString *foldername);

#endif /* dir_h */
