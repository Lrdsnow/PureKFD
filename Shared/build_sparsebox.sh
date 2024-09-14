if [ -d "$BUILD_DIR/Libraries" ]; then
    echo "Libraries already exist."
else
    source ~/.zshrc
    cd SparseBox
    
    /bin/sh get_libraries.sh
    
    echo """
ARCHS := arm64
PACKAGE_FORMAT := ipa
TARGET := iphone:clang:latest:16.0

include $THEOS/makefiles/common.mk

LIBRARY_NAME = libEMProxy libimobiledevice

libEMProxy_FILES = lib/empty.swift
libEMProxy_LDFLAGS = -force_load lib/libem_proxy-ios.a -install_name @rpath/libEMProxy.dylib
libEMProxy_FRAMEWORKS = Security
libEMProxy_INSTALL_PATH = /Applications/SparseBox.app/Frameworks

libimobiledevice_FILES = idevicebackup2.c
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
    
    make
    
    mkdir -p $BUILD_DIR/Libraries
    
    mv .theos/obj/debug/libEMProxy.dylib $BUILD_DIR/Libraries/libEMProxy.dylib
    mv .theos/obj/debug/libimobiledevice.dylib $BUILD_DIR/Libraries/libimobiledevice.dylib
    
    rm -rf .theos
fi
