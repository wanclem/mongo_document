#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Global init/cleanup.
int32_t mdd_mongoc_init(void);
void mdd_mongoc_cleanup(void);

// Client lifecycle.
void* mdd_mongoc_client_new(const char* uri, char** error_out);
void mdd_mongoc_client_destroy(void* client);

// Basic smoke-test command.
// Returns 1 on success, 0 on failure.
// On success, reply_json_out is set to an allocated UTF-8 string containing
// relaxed extended JSON for the reply document.
int32_t mdd_mongoc_ping(
    void* client, char** reply_json_out, char** error_out);

// Frees strings allocated by this shim.
void mdd_mongoc_string_free(char* s);

#ifdef __cplusplus
} // extern "C"
#endif

