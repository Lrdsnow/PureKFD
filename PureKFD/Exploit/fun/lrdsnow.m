//
//  lrdsnow.m
//  PureKFD
//
//  Created by Lrdsnow on 8/25/23.
//

#import <Foundation/Foundation.h>
#import "vnode.h"
#import "krw.h"
#import "helpers.h"

// Ez functions:
void removeFileName(char* path) {
    char* lastSlash = strrchr(path, '/'); // Find the last slash in the path

    if (lastSlash != NULL) {
        *lastSlash = '\0'; // Replace the last slash with null terminator
    }
}

const char* getFilename(const char* path) {
    const char* lastSlash = strrchr(path, '/'); // Find the last slash in the path
    
    if (lastSlash != NULL) {
        return lastSlash + 1; // Return the string after the last slash
    }
    
    return path; // If no slash found, return the whole path as the filename
}

char* getPathWithoutFilename(const char* path) {
    char* newPath = strdup(path); // Create a copy of the original path
    removeFileName(newPath);
    return newPath;
}

//

uint64_t createFolderAndRedirect3(uint64_t vnode) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    uint64_t orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
    
    return orig_to_v_data;
}

uint64_t UnRedirectAndRemoveFolder3(uint64_t orig_to_v_data) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    
    return 0;
}

void funVnodeOverwrite3(char* to, char* from) {
    uint64_t var_vnode = getVnodeVar();
    uint64_t var_tmp_vnode = findChildVnodeByVnode(var_vnode, "tmp");
    printf("[i] /var/tmp vnode: 0x%llx\n", var_tmp_vnode);
    uint64_t orig_to_v_data = createFolderAndRedirect3(var_tmp_vnode);
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    NSError *error = nil;
    NSString *sourcePath = [NSString stringWithUTF8String:from];
    NSString *toFileName = [NSString stringWithUTF8String:getFilename(to)];
    NSString *destinationPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted/", toFileName];
    // Read data from the source file
    NSData *data = [NSData dataWithContentsOfFile:sourcePath options:NSDataReadingMappedIfSafe error:&error];
    if (data) {
        // Write the data to the destination file
        BOOL success = [data writeToFile:destinationPath options:NSDataWritingAtomic error:&error];
        if (success) {
            NSLog(@"Data successfully copied from %@ to %@", sourcePath, destinationPath);
        } else {
            NSLog(@"Error writing data to %@: %@", destinationPath, error);
        }
    } else {
        NSLog(@"Error reading data from %@: %@", sourcePath, error);
    }
    
    UnRedirectAndRemoveFolder3(orig_to_v_data);
    uint64_t to_vnode = getVnodeAtPathByChdir(getPathWithoutFilename(to));
    orig_to_v_data = createFolderAndRedirect3(to_vnode);
    remove([mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"].UTF8String);
    printf("symlink ret: %d\n", symlink("/var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist", [mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"].UTF8String));
    UnRedirectAndRemoveFolder3(orig_to_v_data);
}
