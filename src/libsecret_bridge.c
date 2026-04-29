#include "libsecret_bridge.h"
#include <libsecret/secret.h>
#include <string.h>

static const SecretSchema cmux_schema = {
    "com.cmuxterm.secrets",
    SECRET_SCHEMA_NONE,
    {
        { "service", SECRET_SCHEMA_ATTRIBUTE_STRING },
        { "account", SECRET_SCHEMA_ATTRIBUTE_STRING },
        { NULL, 0 }
    }
};

static GHashTable *make_attrs(const char *service, const char *account) {
    GHashTable *attrs = g_hash_table_new(g_str_hash, g_str_equal);
    g_hash_table_insert(attrs, (gpointer)"service", (gpointer)service);
    g_hash_table_insert(attrs, (gpointer)"account", (gpointer)account);
    return attrs;
}

int libsecret_bridge_store(
    const char *service, const char *account,
    const uint8_t *data, size_t data_len
) {
    GError *error = NULL;
    GHashTable *attrs = make_attrs(service, account);
    SecretValue *value = secret_value_new(
        (const gchar *)data,
        (gssize)data_len,
        "application/octet-stream"
    );
    if (!value) {
        g_hash_table_destroy(attrs);
        return -1;
    }

    gboolean ok = secret_password_storev_binary_sync(
        &cmux_schema, attrs, SECRET_COLLECTION_DEFAULT, service,
        value, NULL, &error);

    secret_value_unref(value);
    g_hash_table_destroy(attrs);
    if (!ok || error) {
        if (error) g_error_free(error);
        return -1;
    }
    return 0;
}

int libsecret_bridge_lookup(
    const char *service, const char *account,
    uint8_t *out, size_t out_capacity
) {
    GError *error = NULL;
    GHashTable *attrs = make_attrs(service, account);
    SecretValue *result = secret_password_lookupv_binary_sync(
        &cmux_schema, attrs, NULL, &error);
    g_hash_table_destroy(attrs);

    if (error) {
        g_error_free(error);
        return -2;
    }
    if (!result) return -1; /* not found */

    gsize len = 0;
    const gchar *secret = secret_value_get(result, &len);
    if (len > out_capacity) {
        secret_value_unref(result);
        return -2;
    }
    memcpy(out, secret, len);
    secret_value_unref(result);
    return (int)len;
}

int libsecret_bridge_delete(const char *service, const char *account) {
    GError *error = NULL;
    gboolean ok = secret_password_clear_sync(
        &cmux_schema,
        NULL, /* cancellable */
        &error,
        "service", service,
        "account", account,
        NULL
    );
    if (error) {
        g_error_free(error);
        return -1;
    }
    (void)ok; /* clear returns false if not found, which is fine */
    return 0;
}

int libsecret_bridge_search(
    const char *account,
    char *out, size_t out_capacity
) {
    GError *error = NULL;

    GHashTable *attrs = g_hash_table_new(g_str_hash, g_str_equal);
    g_hash_table_insert(attrs, (gpointer)"account", (gpointer)account);

    SecretService *svc = secret_service_get_sync(
        SECRET_SERVICE_LOAD_COLLECTIONS, NULL, &error);
    if (!svc || error) {
        if (error) g_error_free(error);
        g_hash_table_destroy(attrs);
        return -1;
    }

    GList *items = secret_service_search_sync(
        svc, &cmux_schema, attrs,
        SECRET_SEARCH_ALL, NULL, &error);

    g_hash_table_destroy(attrs);
    g_object_unref(svc);

    if (error) {
        g_error_free(error);
        if (items) g_list_free_full(items, g_object_unref);
        return -1;
    }
    if (!items) return 0;

    size_t written = 0;
    int matches = 0;

    for (GList *iter = items; iter; iter = iter->next) {
        SecretItem *item = (SecretItem *)iter->data;
        GHashTable *item_attrs = secret_item_get_attributes(item);
        if (!item_attrs) continue;

        const gchar *svc_name = g_hash_table_lookup(item_attrs, "service");
        if (svc_name) {
            size_t svc_len = strlen(svc_name);
            if (written + svc_len + 1 <= out_capacity) {
                memcpy(out + written, svc_name, svc_len);
                written += svc_len;
                out[written++] = '\0';
                matches++;
            }
        }
        g_hash_table_unref(item_attrs);
    }

    g_list_free_full(items, g_object_unref);
    return matches;
}
