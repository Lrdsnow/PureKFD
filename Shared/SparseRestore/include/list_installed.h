#ifndef LIST_INSTALLED_APPS_H
#define LIST_INSTALLED_APPS_H

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/installation_proxy.h>

typedef struct {
    char *bundle_id;
    char *container;
    char *path;
} app_info_t;

app_info_t *list_installed_app_info(instproxy_client_t client, int *app_count);
void free_app_info(app_info_t *app_infos, int count);

#endif // LIST_INSTALLED_APPS_H
