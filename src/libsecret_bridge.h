#ifndef LIBSECRET_BRIDGE_H
#define LIBSECRET_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int libsecret_bridge_store(
    const char *service, const char *account,
    const uint8_t *data, size_t data_len
);

int libsecret_bridge_lookup(
    const char *service, const char *account,
    uint8_t *out, size_t out_capacity
);

int libsecret_bridge_delete(const char *service, const char *account);

int libsecret_bridge_search(
    const char *account,
    char *out, size_t out_capacity
);

#ifdef __cplusplus
}
#endif

#endif
