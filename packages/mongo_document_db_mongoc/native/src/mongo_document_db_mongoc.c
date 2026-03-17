#include "mongo_document_db_mongoc.h"

#include <bson/bson.h>
#include <mongoc/mongoc.h>

#include <stdlib.h>
#include <string.h>

static char* mdd_strdup(const char* s) {
  if (s == NULL) return NULL;
  const size_t len = strlen(s);
  char* out = (char*)malloc(len + 1);
  if (out == NULL) return NULL;
  memcpy(out, s, len);
  out[len] = '\0';
  return out;
}

int32_t mdd_mongoc_init(void) {
  mongoc_init();
  return 0;
}

void mdd_mongoc_cleanup(void) {
  mongoc_cleanup();
}

void* mdd_mongoc_client_new(const char* uri, char** error_out) {
  if (error_out) *error_out = NULL;
  if (uri == NULL) {
    if (error_out) *error_out = mdd_strdup("URI is null");
    return NULL;
  }

  mongoc_uri_t* parsed = mongoc_uri_new_with_error(uri, NULL);
  if (parsed == NULL) {
    if (error_out) *error_out = mdd_strdup("Invalid MongoDB URI");
    return NULL;
  }

  mongoc_client_t* client = mongoc_client_new_from_uri(parsed);
  mongoc_uri_destroy(parsed);

  if (client == NULL) {
    if (error_out) *error_out = mdd_strdup("mongoc_client_new_from_uri failed");
    return NULL;
  }

  return (void*)client;
}

void mdd_mongoc_client_destroy(void* client) {
  if (client == NULL) return;
  mongoc_client_destroy((mongoc_client_t*)client);
}

int32_t mdd_mongoc_ping(void* client, char** reply_json_out,
                        char** error_out) {
  if (reply_json_out) *reply_json_out = NULL;
  if (error_out) *error_out = NULL;

  if (client == NULL) {
    if (error_out) *error_out = mdd_strdup("client is null");
    return 0;
  }

  bson_t cmd;
  bson_init(&cmd);
  BSON_APPEND_INT32(&cmd, "ping", 1);

  bson_t reply;
  bson_init(&reply);
  bson_error_t error;
  const bool ok = mongoc_client_command_simple(
      (mongoc_client_t*)client,
      "admin",
      &cmd,
      NULL /* read_prefs */,
      &reply,
      &error);

  bson_destroy(&cmd);

  if (!ok) {
    bson_destroy(&reply);
    if (error_out) *error_out = mdd_strdup(error.message);
    return 0;
  }

  size_t json_len = 0;
  char* json = bson_as_relaxed_extended_json(&reply, &json_len);
  bson_destroy(&reply);

  if (json == NULL) {
    if (error_out) *error_out = mdd_strdup("Failed to serialize reply BSON");
    return 0;
  }

  // bson_as_relaxed_extended_json uses bson_malloc; copy to malloc-owned memory
  // to keep allocation/freeing consistent for Dart via mdd_mongoc_string_free.
  char* out = (char*)malloc(json_len + 1);
  if (out == NULL) {
    bson_free(json);
    if (error_out) *error_out = mdd_strdup("Out of memory");
    return 0;
  }
  memcpy(out, json, json_len);
  out[json_len] = '\0';
  bson_free(json);

  if (reply_json_out) *reply_json_out = out;
  return 1;
}

void mdd_mongoc_string_free(char* s) {
  if (s == NULL) return;
  free(s);
}

