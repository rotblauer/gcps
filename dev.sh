#!/usr/bin/env bash

source .env.dev && flutter run -d ZY22BK96TD --dart-define="GCPS_APP_VERSION=v.catInTheHandroid-${version},GCPS_AUTH_HEADER_KEY=${GCPS_AUTH_HEADER_KEY},GCPS_AUTH_HEADER_VALUE=${GCPS_AUTH_HEADER_VALUE}"
