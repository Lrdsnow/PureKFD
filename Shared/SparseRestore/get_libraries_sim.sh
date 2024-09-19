#!/bin/bash
set -e

cd lib

extract_deb() {
  wget -nc $1 -O tmp.deb
  ar -x tmp.deb
  rm tmp.deb
  tar --zstd -xvf data.tar.zst
  mv usr/lib/*.a ..
}

wget -nc https://github.com/SideStore/EMPackage/raw/main/RustXcframework.xcframework/ios-arm64/libem_proxy-ios.a
wget -nc https://github.com/SideStore/MinimuxerPackage/raw/main/RustXcframework.xcframework/ios-arm64/libminimuxer-ios.a

mkdir tmp && cd tmp

extract_deb https://apt.procurs.us/pool/main/iphoneos-arm64/1700/libimobiledevice/libimobiledevice-dev_1.3.0+git20220702.2eec1b9-1_iphoneos-arm.deb
extract_deb https://apt.procurs.us/pool/main/iphoneos-arm64/1700/libimobiledevice-glue/libimobiledevice-glue-dev_1.0.0+git20220522.d2ff796_iphoneos-arm.deb
extract_deb https://apt.procurs.us/pool/main/iphoneos-arm64/1700/libplist/libplist-dev_2.2.0+git20230130.4b50a5a_iphoneos-arm.deb
extract_deb https://apt.procurs.us/pool/main/iphoneos-arm64/1700/libusbmuxd/libusbmuxd-dev_2.0.2+git20220504.36ffb7a_iphoneos-arm.deb
extract_deb https://apt.procurs.us/pool/main/iphoneos-arm64/1700/openssl/libssl-dev_3.2.1_iphoneos-arm.deb

cd .. && rm -r tmp
