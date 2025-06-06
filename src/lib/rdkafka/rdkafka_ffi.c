#include <string.h>
#include <librdkafka/rdkafka.h>
#include "moonbit.h"

struct rd_kafka_conf_ref {
    rd_kafka_conf_t *conf; // NULL if the ownership is transferred to rd_kafka_new()
};

void __rd_kafka_conf_ref_destroy(void* v) {
    struct rd_kafka_conf_ref *ref = (struct rd_kafka_conf_ref *)(v);
    if (ref->conf) {
        rd_kafka_conf_destroy(ref->conf);
        ref->conf = NULL;
    }
}

MOONBIT_FFI_EXPORT struct rd_kafka_conf_ref* __rd_kafka_conf_ref_new() {
  struct rd_kafka_conf_ref* conf =
      moonbit_make_external_object(__rd_kafka_conf_ref_destroy, sizeof(struct rd_kafka_conf_ref));
  conf->conf = rd_kafka_conf_new();
  return conf;
}

MOONBIT_FFI_EXPORT rd_kafka_conf_t* __rd_kafka_conf_ref_get(struct rd_kafka_conf_ref* conf) {
  return conf->conf;
}

struct rd_kafka_ref {
    rd_kafka_t *kafka;
};

void __rd_kafka_ref_destroy(void* v) {
  struct rd_kafka_ref *ref = (struct rd_kafka_ref *)(v);
  if (ref->kafka) {
    rd_kafka_destroy(ref->kafka);
    ref->kafka = NULL;
  }
}

MOONBIT_FFI_EXPORT struct rd_kafka_ref* __rd_kafka_ref_new(rd_kafka_type_t type, struct rd_kafka_conf_ref* conf, char* errstr, size_t errstr_size) {
  struct rd_kafka_ref* kafka =
      moonbit_make_external_object(__rd_kafka_ref_destroy, sizeof(struct rd_kafka_ref));
  kafka->kafka = rd_kafka_new(type, conf->conf, errstr, errstr_size);
  if (kafka->kafka != NULL) {
    conf->conf = NULL; // transfer ownership to rd_kafka_new
  }
  return kafka;
}

MOONBIT_FFI_EXPORT int __rd_kafka_ref_is_not_null(struct rd_kafka_ref* kafka) {
  return kafka->kafka != NULL;
}

MOONBIT_FFI_EXPORT rd_kafka_t* __rd_kafka_ref_get(struct rd_kafka_ref* kafka) {
  return kafka->kafka;
}

// Message reference type for automatic cleanup
struct rd_kafka_message_ref {
    rd_kafka_message_t *message;
};

void __rd_kafka_message_ref_destroy(void* v) {
  struct rd_kafka_message_ref *ref=(struct rd_kafka_message_ref *)(v);
  if (ref->message) {
    rd_kafka_message_destroy(ref->message);
    ref->message = NULL;
  }
}

MOONBIT_FFI_EXPORT struct rd_kafka_message_ref* __rd_kafka_message_ref_poll(rd_kafka_t *client, int timeout_ms) {
  struct rd_kafka_message_ref* msg_ref =
      moonbit_make_external_object(__rd_kafka_message_ref_destroy, sizeof(struct rd_kafka_message_ref));
  msg_ref->message = rd_kafka_consumer_poll(client, timeout_ms);
  return msg_ref;
}

MOONBIT_FFI_EXPORT int __rd_kafka_message_ref_is_not_null(struct rd_kafka_message_ref* msg_ref) {
  return msg_ref->message != NULL;
}

MOONBIT_FFI_EXPORT rd_kafka_message_t* __rd_kafka_message_ref_get(struct rd_kafka_message_ref* msg_ref) {
  return msg_ref->message;
}

MOONBIT_FFI_EXPORT int rd_kafka_message_err(rd_kafka_message_t *msg) {
    return msg->err;
}

MOONBIT_FFI_EXPORT size_t rd_kafka_message_len(rd_kafka_message_t *msg) {
    return msg->len;
}

MOONBIT_FFI_EXPORT void rd_kafka_message_read_payload(rd_kafka_message_t *msg, void* buf, size_t len) {
    memcpy(buf, msg->payload, len);
}

MOONBIT_FFI_EXPORT int64_t rd_kafka_message_offset(rd_kafka_message_t *msg) {
    return msg->offset;
}

// Topic partition list reference type for automatic cleanup
struct rd_kafka_topic_partition_list_ref {
    rd_kafka_topic_partition_list_t *list;
};

void __rd_kafka_topic_partition_list_ref_destroy(void* v) {
  struct rd_kafka_topic_partition_list_ref *ref = (struct rd_kafka_topic_partition_list_ref *)(v);
  if (ref->list) {
    rd_kafka_topic_partition_list_destroy(ref->list);
    ref->list = NULL;
  }
}

MOONBIT_FFI_EXPORT struct rd_kafka_topic_partition_list_ref* __rd_kafka_topic_partition_list_ref_new(size_t size) {
  struct rd_kafka_topic_partition_list_ref* list_ref =
      moonbit_make_external_object(__rd_kafka_topic_partition_list_ref_destroy, sizeof(struct rd_kafka_topic_partition_list_ref));
  list_ref->list = rd_kafka_topic_partition_list_new(size);
  return list_ref;
}

MOONBIT_FFI_EXPORT rd_kafka_topic_partition_list_t* __rd_kafka_topic_partition_list_ref_get(struct rd_kafka_topic_partition_list_ref* list_ref) {
  return list_ref->list;
}

MOONBIT_FFI_EXPORT void __rd_kafka_err2str(int err, char* errstr, size_t errstr_size) {
  const char* err_str = rd_kafka_err2str(err);
  strncpy(errstr, err_str, errstr_size);
  errstr[errstr_size - 1] = '\0'; // Ensure null termination
}
