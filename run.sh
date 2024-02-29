#!/usr/bin/env bash

# 1=device: eg. ZY22FZHPWW (flutter devices)
# 2=[dev|prod]

source .env.${2} && \
  flutter run --no-track-widget-creation -d "${1}" \
  --dart-define="GCPS_AUTH_HEADER_KEY=${GCPS_AUTH_HEADER_KEY}" \
  --dart-define="GCPS_AUTH_HEADER_VALUE=${GCPS_AUTH_HEADER_VALUE}" \
  --dart-define="GCPS_POST_ENDPOINT=${GCPS_POST_ENDPOINT}"
  # --build-name="$(git describe --tags --abbrev=0)" --build-number="$(date +%s)"
