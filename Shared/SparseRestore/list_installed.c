#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>
#include <libimobiledevice/installation_proxy.h>
#include <plist/plist.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include "list_installed.h"

#define BUFFER_SIZE 1024

app_info_t *list_installed_app_info(instproxy_client_t client, int *app_count) {
    plist_t apps = NULL;
    plist_t client_options = NULL;
    *app_count = 0;
    app_info_t *app_infos = NULL;

    instproxy_error_t result = instproxy_browse(client, client_options, &apps);
    if (result != INSTPROXY_E_SUCCESS) {
        syslog(LOG_ERR, "Error: Unable to browse apps. Error code: %d", result);
        return NULL;
    }

    if (apps && plist_get_node_type(apps) == PLIST_ARRAY) {
        *app_count = plist_array_get_size(apps);

        app_infos = (app_info_t *)malloc((*app_count) * sizeof(app_info_t));
        if (!app_infos) {
            syslog(LOG_ERR, "Error: Memory allocation failed.");
            plist_free(apps);
            return NULL;
        }

        for (int i = 0; i < *app_count; i++) {
            plist_t app = plist_array_get_item(apps, i);
            if (plist_get_node_type(app) != PLIST_DICT) {
                syslog(LOG_ERR, "Error: Invalid plist node type.");
                continue;
            }

            // Get bundle identifier
            plist_t app_id = plist_dict_get_item(app, "CFBundleIdentifier");
            char *bundle_id = NULL;
            if (app_id) plist_get_string_val(app_id, &bundle_id);
            app_infos[i].bundle_id = bundle_id ? strdup(bundle_id) : strdup("Unknown");

            plist_t _container = plist_dict_get_item(app, "Container");
            char *container = NULL;
            if (_container) plist_get_string_val(_container, &container);
            app_infos[i].container = container ? strdup(container) : strdup("Unknown");

            plist_t _path = plist_dict_get_item(app, "Path");
            char *path = NULL;
            if (_path) plist_get_string_val(_path, &path);
            app_infos[i].path = path ? strdup(path) : strdup("Unknown");
        }
    } else {
        syslog(LOG_ERR, "Error: No apps found or invalid plist structure.");
    }

    plist_free(apps);
    return app_infos;
}

void free_app_info(app_info_t *app_infos, int count) {
    if (app_infos) {
        for (int i = 0; i < count; i++) {
            free(app_infos[i].bundle_id);
            free(app_infos[i].container);
            free(app_infos[i].path);
        }
        free(app_infos);
    }
}