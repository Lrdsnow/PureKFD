//
//  userspaceReboot.c
//  PureKFD
//
//  Created by Nick Chan on 10/12/2023.
//

#include "userspaceReboot.h"

void NSLog(CFStringRef format, ...);
typedef void* xpc_object_t;
typedef void* xpc_type_t;
typedef void* xpc_connection_t;
typedef void* launch_data_t;
typedef void (^xpc_handler_t)(xpc_object_t object);
typedef bool (^xpc_dictionary_applier_t)(const char *key, xpc_object_t value);

xpc_object_t xpc_dictionary_create(const char * const *keys, const xpc_object_t *values, size_t count);
void xpc_dictionary_set_uint64(xpc_object_t dictionary, const char *key, uint64_t value);
void xpc_dictionary_set_string(xpc_object_t dictionary, const char *key, const char *value);
int64_t xpc_dictionary_get_int64(xpc_object_t dictionary, const char *key);
xpc_object_t xpc_dictionary_get_value(xpc_object_t dictionary, const char *key);
bool xpc_dictionary_get_bool(xpc_object_t dictionary, const char *key);
void xpc_dictionary_set_fd(xpc_object_t dictionary, const char *key, int value);
void xpc_dictionary_set_bool(xpc_object_t dictionary, const char *key, bool value);
const char *xpc_dictionary_get_string(xpc_object_t dictionary, const char *key);
void xpc_dictionary_set_value(xpc_object_t dictionary, const char *key, xpc_object_t value);
xpc_type_t xpc_get_type(xpc_object_t object);
bool xpc_dictionary_apply(xpc_object_t xdict, xpc_dictionary_applier_t applier);
int64_t xpc_int64_get_value(xpc_object_t xint);
char *xpc_copy_description(xpc_object_t object);
void xpc_dictionary_set_int64(xpc_object_t dictionary, const char *key, int64_t value);
const char *xpc_string_get_string_ptr(xpc_object_t xstring);
xpc_object_t xpc_array_create(const xpc_object_t *objects, size_t count);
xpc_object_t xpc_string_create(const char *string);
size_t xpc_dictionary_get_count(xpc_object_t dictionary);
void xpc_array_append_value(xpc_object_t xarray, xpc_object_t value);
xpc_connection_t xpc_connection_create_mach_service(const char *name, dispatch_queue_t _Nullable targetq, uint64_t flags);
void xpc_release(xpc_object_t object);
void xpc_connection_activate(xpc_connection_t connection);
void xpc_connection_set_event_handler(xpc_connection_t connection, xpc_handler_t handler);
xpc_object_t xpc_connection_send_message_with_reply_sync(xpc_connection_t connection, xpc_object_t message);
void xpc_connection_cancel(xpc_connection_t connection);

#define XPC_ARRAY_APPEND ((size_t)(-1))
#define XPC_ERROR_CONNECTION_INVALID XPC_GLOBAL_OBJECT(_xpc_error_connection_invalid)
#define XPC_ERROR_TERMINATION_IMMINENT XPC_GLOBAL_OBJECT(_xpc_error_termination_imminent)
#define XPC_TYPE_ARRAY (&_xpc_type_array)
#define XPC_TYPE_BOOL (&_xpc_type_bool)
#define XPC_TYPE_DICTIONARY (&_xpc_type_dictionary)
#define XPC_TYPE_ERROR (&_xpc_type_error)
#define XPC_TYPE_STRING (&_xpc_type_string)


extern const struct _xpc_dictionary_s _xpc_error_connection_invalid;
extern const struct _xpc_dictionary_s _xpc_error_termination_imminent;
extern const struct _xpc_type_s _xpc_type_array;
extern const struct _xpc_type_s _xpc_type_bool;
extern const struct _xpc_type_s _xpc_type_dictionary;
extern const struct _xpc_type_s _xpc_type_error;
extern const struct _xpc_type_s _xpc_type_string;

int userspaceReboot(void) {
    kern_return_t ret = 0;
    xpc_object_t xdict = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(xdict, "cmd", 5);
    ret = unlink("/private/var/mobile/Library/MemoryMaintenance/mmaintenanced");
    if (ret && errno != ENOENT) {
        NSLog(CFSTR("could not delete mmaintenanced last reboot file"));
        return -1;
    }
    xpc_connection_t connection = xpc_connection_create_mach_service("com.apple.mmaintenanced", NULL, 0);
    
    if (xpc_get_type(connection) == XPC_TYPE_ERROR) {
        char* desc = xpc_copy_description(connection);
        NSLog(CFSTR("%s"),desc);
        free(desc);
        xpc_release(connection);
        return -1;
    }
    xpc_connection_set_event_handler(connection, ^(xpc_object_t random) {});
    xpc_connection_activate(connection);
    char* desc = xpc_copy_description(connection);
    puts(desc);
    NSLog(CFSTR("mmaintenanced connection created"));
    xpc_object_t reply = xpc_connection_send_message_with_reply_sync(connection, xdict);
    if (reply) {
        char* desc = xpc_copy_description(reply);
        NSLog(CFSTR("%s"),desc);
        free(desc);
        ret = 0;
    } else {
        NSLog(CFSTR("no reply received from mmaintenanced"));
        ret = -1;
    }
    
    xpc_connection_cancel(connection);
    xpc_release(connection);
    xpc_release(reply);
    xpc_release(xdict);
    return 0;
}
