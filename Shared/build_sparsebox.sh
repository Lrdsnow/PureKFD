if [ -d "$BUILD_DIR/Libraries" ]; then
    if [ -f "$BUILD_DIR/Libraries/platform" ]; then
        LAST_PLATFORM=$(cat "$BUILD_DIR/Libraries/platform")
    else
        LAST_PLATFORM=""
    fi

    if [ "$EFFECTIVE_PLATFORM_NAME" == "$LAST_PLATFORM" ] && \
       [ -f "$BUILD_DIR/Libraries/libEMProxy.dylib" ] && \
       [ -f "$BUILD_DIR/Libraries/libimobiledevice.dylib" ]; then
        echo "Libraries already exist for the current platform ($EFFECTIVE_PLATFORM_NAME). Skipping build."
        exit 0
    else
        echo "Rebuilding libraries for platform: $EFFECTIVE_PLATFORM_NAME"
    fi
else
    echo "Building libraries for platform: $EFFECTIVE_PLATFORM_NAME"
fi

source ~/.zshrc
cd SparseBox

/bin/sh get_libraries.sh

echo """
ARCHS := $ARCHS
PACKAGE_FORMAT := ipa
TARGET := iphone:clang:latest:16.0

include $THEOS/makefiles/common.mk

LIBRARY_NAME = libEMProxy libimobiledevice

libEMProxy_FILES = lib/empty.swift
libEMProxy_LDFLAGS = -force_load lib/libem_proxy-ios.a -install_name @rpath/libEMProxy.dylib
libEMProxy_FRAMEWORKS = Security
libEMProxy_INSTALL_PATH = /Applications/SparseBox.app/Frameworks

libimobiledevice_FILES = idevicebackup2.c list_installed.c DeviceManager.m AppInfo.m
libimobiledevice_CFLAGS = -Iinclude
libimobiledevice_LDFLAGS = \
-force_load lib/libimobiledevice-1.0.a \
-force_load lib/libimobiledevice-glue-1.0.a \
-force_load lib/libplist-2.0.a \
-force_load lib/libusbmuxd-2.0.a \
-force_load lib/libcrypto.a \
-force_load lib/libssl.a \
-force_load lib/libminimuxer-ios.a \
-Wl \
-install_name @rpath/libimobiledevice.dylib
libimobiledevice_FRAMEWORKS = Foundation Security SystemConfiguration
libimobiledevice_INSTALL_PATH = /Applications/SparseBox.app/Frameworks

include $THEOS/makefiles/library.mk

SparseBox_TARGET = 
""" > Makefile

cp ../SparseRestore/include/minimuxer-Bridging-Header.h include/minimuxer-Bridging-Header.h
cp ../SparseRestore/include/list_installed.h include/list_installed.h
cp ../SparseRestore/list_installed.c list_installed.c
cp ../SparseRestore/DeviceManager.m DeviceManager.m
cp ../SparseRestore/include/DeviceManager.h include/DeviceManager.h
cp ../SparseRestore/AppInfo.h AppInfo.h
cp ../SparseRestore/AppInfo.m AppInfo.m

make

mkdir -p $BUILD_DIR/Libraries

mv .theos/obj/debug/libEMProxy.dylib $BUILD_DIR/Libraries/libEMProxy.dylib
mv .theos/obj/debug/libimobiledevice.dylib $BUILD_DIR/Libraries/libimobiledevice.dylib

echo "$EFFECTIVE_PLATFORM_NAME" > "$BUILD_DIR/Libraries/platform"

rm -rf .theos
