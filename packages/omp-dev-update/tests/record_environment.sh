#!/bin/sh
printf '%s\n' "$SSL_CERT_FILE" "$NIX_SSL_CERT_FILE" "$PATH" > "$OMP_DEV_UPDATE_TEST_ENV_LOG"
printf '{}\n'
