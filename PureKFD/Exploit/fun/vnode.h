//
//  vnode.h
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include <stdio.h>

//https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/mount.h#L293
#define MNT_RDONLY      0x00000001      /* read only filesystem */
#define MNT_NOSUID      0x00000008      /* don't honor setuid bits on fs */
#define MNT_ROOTFS      0x00004000      /* identifies the root filesystem */
#define MNT_UPDATE      0x00010000      /* not a real mount, just an update */
//https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/vnode_internal.h#L297
#define VISSHADOW       0x008000        /* vnode is a shadow file */

//https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/fcntl.h#L112
//https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/fcntl.h#L231
#define FREAD           0x00000001
#define FWRITE          0x00000002

uint64_t getVnodeAtPath(char* filename);    /* return vnode of path, if open(filename, RD_ONLY) returned -1, it fails */
uint64_t getVnodeAtPathByChdir(char *path); /* return vnode of path, but only directories work. NOT files. */
uint64_t findRootVnode(void);   /* return root vnode as is */
uint64_t getVnodeVar(void); /* return /var vnode as is */
uint64_t getVnodeVarMobile(void);   /* return /var/mobile vnode as is */
uint64_t getVnodePreferences(void); /* return /var/mobile/Library/Preferences vnode as is */
uint64_t getVnodeLibrary(void); /* return /var/mobile/Library vnode as is */
uint64_t getVnodeSystemGroup(void); /* return /var/containers/Shared/SystemGroup vnode as is */

/*
Description:
  Hide file or directory.
  Return vnode value for restore.
*/
uint64_t funVnodeHide(char* filename);

/*
Description:
  Reveal file or directory.
  Required vnode value to restore.
*/
uint64_t funVnodeReveal(uint64_t vnode);

/*
Description:
  Perform chown to file or directory.
*/
uint64_t funVnodeChown(char* filename, uid_t uid, gid_t gid);

/*
Description:
  Perform chmod to file or directory.
*/
uint64_t funVnodeChmod(char* filename, mode_t mode);

/*
Description:
  Redirect directory to another directory.
  Only work when mount points of directories are same.
  Can be escaped out of sandbox.
  If succeeds, return value to_vnode->v_data (for unredirect)
*/
uint64_t funVnodeRedirectFolder(char* to, char* from);

/*
Description:
  Perform overwrite file data to file.
  Only work when file size is 'lower or same' than original file size.
  Overwriting executable file also works, but executing will not work anymore. just freeze or crash.
*/
uint64_t funVnodeOverwriteFile(char* to, char* from);

/*
Description:
  Iterating sub directory or file at dirname.
*/
uint64_t funVnodeIterateByPath(char* dirname);

/*
Description:
  Iterating sub directory or file at vnode.
*/
uint64_t funVnodeIterateByVnode(uint64_t vnode);

/*
Description:
  Redirect directory to another directory using vnode.
  Only work when mount points of directories are same.
  Can be escaped out of sandbox.
  If succeeds, return value to_vnode->v_data (for unredirect)
*/
uint64_t funVnodeRedirectFolderFromVnode(char* to, uint64_t from_vnode);

/*
Description:
  UnRedirect directory to another directory.
  It needs orig_to_v_data, ususally you can get return value of funVnodeRedirectFolder / funVnodeRedirectFolderByVnode
*/
uint64_t funVnodeUnRedirectFolder(char* to, uint64_t orig_to_v_data);

/*
Description:
  Return vnode of subdirectory or sub file in vnode.
  childname can be what you want to find subdirectory or file name.
  vnode should be vnode of root directory.
*/
uint64_t findChildVnodeByVnode(uint64_t vnode, char* childname);

/*
Description:
  Perform overwrite file data to file.
  You can overwrite file data without file size limit! but only works on /var files.
  Overwriting executable file also works, but executing will also work since using write() instead of mmap().
  https://openradar.appspot.com/FB8914231
*/
uint64_t funVnodeOverwriteFileUnlimitSize(char* to, char* from);

/*
Description:
  Redirect file to another file.
  If succeeds, return 0 and it stored orig_to_vnode and orig_nc_vp (for unredirect)
*/
uint64_t funVnodeRedirectFile(char* to, char* from, uint64_t* orig_to_vnode, uint64_t* orig_nc_vp);

/*
Description:
  UnRedirect file to another file.
  It needs orig_to_vnode and orig_nc_vp, ususally you can get value from funVnodeRedirectFile
*/
uint64_t funVnodeUnRedirectFile(uint64_t orig_to_vnode, uint64_t orig_nc_vp);
