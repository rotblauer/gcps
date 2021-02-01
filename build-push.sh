#!/usr/bin/env bash

build() {
  rm -rf build/app/outputs/apk*

  flutter build apk --debug
  mv build/app/outputs/apk{,.fat}

  flutter build apk --split-per-abi --debug
  mv build/app/outputs/apk{,.perabi}

  flutter build appbundle --debug
  echo "The release bundle for your app is created at <app dir>/build/app/outputs/bundle/release/app.aab."
  echo "The debug bundle for your app is created at <app dir>/build/app/outputs/bundle/debug/app.aab. ?"
}

push(){
  rsync -avz build/app/outputs/apk.fat/ freya:~/isaacardis.com/catdroid/
  rsync -avz build/app/outputs/apk.perabi/ freya:~/isaacardis.com/catdroid/
  rsync -avz build/app/outputs/bundle/ freya:~/isaacardis.com/catdroid/
}

# build
push
