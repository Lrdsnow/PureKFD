//
//  memoryControl.m
//  PureKFD
//
//  Created by Nick Chan on 10/12/2023.
//

#import <Foundation/Foundation.h>
#include "memoryControl.h"

bool hasEntitlement(CFStringRef entitlement) {
    SecTaskRef task = SecTaskCreateFromSelf(NULL);
    CFTypeRef value = SecTaskCopyValueForEntitlement(task, entitlement, NULL);
    if (value != nil) {
        CFRelease(value);
    }
    CFRelease(task);
    return (value != NULL);
}

uint64_t getPhysicalMemorySize(void) {
    return NSProcessInfo.processInfo.physicalMemory;
}
