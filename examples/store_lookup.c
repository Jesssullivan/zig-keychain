/*
 * zig-keychain example: store, lookup, and delete a secret.
 *
 * Build:
 *   cd .. && zig build -Doptimize=ReleaseFast
 *   cc examples/store_lookup.c -Iinclude -Lzig-out/lib -lzig-keychain \
 *      -framework Security -framework CoreFoundation -o examples/store_lookup
 *   ./examples/store_lookup
 *
 * On Linux, replace the -framework flags with:
 *   $(pkg-config --libs libsecret-1 glib-2.0)
 */

#include "zig_keychain.h"
#include <stdio.h>
#include <string.h>

int main(void) {
    const char *service = "com.example.zig-keychain-demo";
    const char *account = "demo-user";
    const char *secret  = "s3cret-t0ken-value";

    /* Store */
    int rc = zig_keychain_store(
        service, strlen(service),
        account, strlen(account),
        (const uint8_t *)secret, strlen(secret)
    );
    if (rc != 0) {
        fprintf(stderr, "store failed (%d)\n", rc);
        return 1;
    }
    printf("Stored secret for %s / %s\n", service, account);

    /* Lookup */
    uint8_t buf[256];
    int len = zig_keychain_lookup(
        service, strlen(service),
        account, strlen(account),
        buf, sizeof(buf)
    );
    if (len < 0) {
        fprintf(stderr, "lookup failed (%d)\n", len);
        return 1;
    }
    printf("Lookup: %.*s\n", len, buf);

    /* Delete */
    rc = zig_keychain_delete(
        service, strlen(service),
        account, strlen(account)
    );
    if (rc != 0) {
        fprintf(stderr, "delete failed (%d)\n", rc);
        return 1;
    }
    printf("Deleted secret\n");

    /* Verify deletion */
    len = zig_keychain_lookup(
        service, strlen(service),
        account, strlen(account),
        buf, sizeof(buf)
    );
    if (len == -1) {
        printf("Confirmed: item not found after delete\n");
    } else {
        printf("Unexpected: item still present (%d)\n", len);
    }

    return 0;
}
