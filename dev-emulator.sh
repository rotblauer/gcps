#!/usr/bin/env bash

source .env.dev && flutter run -d emulator-5554 --dart-define="GCPS_APP_VERSION=v.catInTheHandroid-${version},GCPS_AUTH_HEADER_KEY=${GCPS_AUTH_HEADER_KEY},GCPS_AUTH_HEADER_VALUE=${GCPS_AUTH_HEADER_VALUE}"
