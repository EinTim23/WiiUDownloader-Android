#!/bin/bash
set -e

cd WiiUDownloader

python3 grabTitles.py

cd ..

export SDK=$(xcrun --sdk iphoneos --show-sdk-path)
export CC=$(xcrun --sdk iphoneos --find clang)

cd native_lib

GOOS=ios \
GOARCH=arm64 \
CGO_ENABLED=1 \
CC=$CC \
CGO_CFLAGS="-isysroot $SDK -arch arm64 -miphoneos-version-min=14.0" \
CGO_LDFLAGS="-isysroot $SDK -arch arm64 -miphoneos-version-min=14.0" \
go build -buildmode=c-archive -o ../ios/Runner/libs/libwiiudownloader.a

cd ..
flutter build ios --no-codesign --release
mkdir Payload
mv build/ios/iphoneos/Runner.app Payload
zip -r wiiudownloader.ipa Payload
rm -rf Payload