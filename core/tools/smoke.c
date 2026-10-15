/*
 * qBittorrent Neo — command-line smoke test of the core bridge.
 *
 *   qbtneo-smoke <profile-dir> [method [json-args]]...
 *
 * Starts the core with the given profile folder, runs each request in turn
 * (printing the reply), and shuts down. The special method "sleep:<seconds>"
 * waits; "events" toggles printing core events.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "qbtneo.h"

static int printEvents = 0;

typedef struct
{
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int done;
    int status;
    char *data;
} Waiter;

static void onReply(void *context, int32_t status, const char *data, size_t length)
{
    Waiter *w = context;
    pthread_mutex_lock(&w->mutex);
    w->status = status;
    w->data = malloc(length + 1);
    memcpy(w->data, data, length);
    w->data[length] = '\0';
    w->done = 1;
    pthread_cond_signal(&w->cond);
    pthread_mutex_unlock(&w->mutex);
}

static void onEvent(void *context, const char *json, size_t length)
{
    (void)context;
    if (printEvents)
        fprintf(stderr, "event: %.*s\n", (int)length, json);
}

int main(int argc, char **argv)
{
    if (argc < 2)
    {
        fprintf(stderr, "usage: %s <profile-dir> [method [json-args]]...\n", argv[0]);
        return 2;
    }

    char config[4096];
    snprintf(config, sizeof(config), "{\"profileDir\":\"%s\",\"frontEnd\":\"smoke\"}", argv[1]);
    char *error = NULL;
    qbtn_core *core = qbtn_core_start(config, strlen(config), onEvent, NULL, &error);
    if (!core)
    {
        fprintf(stderr, "start failed: %s\n", error ? error : "?");
        qbtn_free(error);
        return 1;
    }

    for (int i = 2; i < argc; ++i)
    {
        const char *method = argv[i];
        if (strncmp(method, "sleep:", 6) == 0)
        {
            sleep((unsigned)atoi(method + 6));
            continue;
        }
        if (strcmp(method, "events") == 0)
        {
            printEvents = !printEvents;
            continue;
        }
        const char *args = "{}";
        if ((i + 1 < argc) && (argv[i + 1][0] == '{'))
            args = argv[++i];

        Waiter w = {PTHREAD_MUTEX_INITIALIZER, PTHREAD_COND_INITIALIZER, 0, 0, NULL};
        qbtn_core_call(core, method, args, strlen(args), onReply, &w);
        pthread_mutex_lock(&w.mutex);
        while (!w.done)
            pthread_cond_wait(&w.cond, &w.mutex);
        pthread_mutex_unlock(&w.mutex);
        printf("%s -> [%d] %s\n", method, w.status, w.data);
        fflush(stdout);
        free(w.data);
    }

    qbtn_core_shutdown(core);
    return 0;
}
