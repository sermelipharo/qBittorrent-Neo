/*
 * qBittorrent Neo — C interface of the in-process qBittorrent core.
 *
 * The core (qBittorrent's src/base with its Qt event loop) runs on a thread
 * owned by the library. Every request is a method name plus a JSON object of
 * arguments; the reply is a JSON value. Requests are queued to the core
 * thread and answered through a callback, so callers never touch Qt objects
 * and no C++ types cross this boundary.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef QBTNEO_H
#define QBTNEO_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Opaque handle of a running core.
typedef struct qbtn_core qbtn_core;

/// Reply status codes. Non-zero values match the `QbtError` cases of the app.
enum {
    QBTN_OK = 0,
    QBTN_ERR_NOT_FOUND = 1,
    QBTN_ERR_INVALID_ARGUMENT = 2,
    QBTN_ERR_CONFLICT = 3,
    QBTN_ERR_IO = 4,
    QBTN_ERR_NETWORK = 5,
    QBTN_ERR_ENGINE = 6,
    QBTN_ERR_UNSUPPORTED = 7,
    QBTN_ERR_OTHER = 8,
    /// The request was cancelled with `qbtn_core_cancel` or the core stopped.
    QBTN_CANCELLED = 9
};

/// Called exactly once per request, normally on the core thread. For QBTN_OK
/// `data` is a UTF-8 JSON value (`null` for calls without a result);
/// otherwise it is a UTF-8 error message. `data` is only valid during the call.
typedef void (*qbtn_reply_fn)(void *context, int32_t status, const char *data, size_t length);

/// Receives core events as UTF-8 JSON (see docs/ARCHITECTURE.md). Called on
/// core threads; the data is only valid during the call.
typedef void (*qbtn_event_fn)(void *context, const char *json, size_t length);

/// Starts the core. `config_json` is an object:
///   {"profileDir": "/path", "webuiPortOverride": 0, "frontEnd": "macOS"}
/// An empty `profileDir` selects the app's default profile folder.
/// Blocks until the session is created. On failure returns NULL and stores a
/// malloc'ed, NUL-terminated message in `*error` (free with `qbtn_free`).
/// `on_event` may be called until `qbtn_core_shutdown` returns.
qbtn_core *qbtn_core_start(const char *config_json, size_t config_length,
                           qbtn_event_fn on_event, void *event_context,
                           char **error);

/// Queues a request. Returns a request id usable with `qbtn_core_cancel`.
/// `reply` is called exactly once (with QBTN_CANCELLED after shutdown).
uint64_t qbtn_core_call(qbtn_core *core, const char *method,
                        const char *args_json, size_t args_length,
                        qbtn_reply_fn reply, void *context);

/// Cancels a pending request (e.g. fetching metadata). Harmless if it
/// already completed.
void qbtn_core_cancel(qbtn_core *core, uint64_t request_id);

/// Saves resume data, stops the session, joins the core thread and frees the
/// handle. Blocks for up to the configured shutdown timeout.
void qbtn_core_shutdown(qbtn_core *core);

/// Frees memory returned by this library.
void qbtn_free(void *pointer);

#ifdef __cplusplus
}
#endif

#endif /* QBTNEO_H */
