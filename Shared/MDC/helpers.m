#import <Foundation/Foundation.h>
#include <string.h>
#include <mach/mach.h>
#include <dirent.h>

//char* get_temp_file_path(void) {
//  return strdup([[NSTemporaryDirectory() stringByAppendingPathComponent:@"AAAAs"] fileSystemRepresentation]);
//}

// create a read-only test file we can target:
//char* set_up_tmp_file(void) {
//  char* path = get_temp_file_path();
//  NSLog(@"path: %s", path);
//  
//  FILE* f = fopen(path, "w");
//  if (!f) {
//    NSLog(@"opening the tmp file failed...");
//    return NULL;
//  }
//  char* buf = malloc(PAGE_SIZE*10);
//  memset(buf, 'A', PAGE_SIZE*10);
//  fwrite(buf, PAGE_SIZE*10, 1, f);
//  //fclose(f);
//  return path;
//}

