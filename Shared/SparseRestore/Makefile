ARCHS := arm64
PACKAGE_FORMAT := ipa
TARGET := iphone:clang:latest:16.0

include $(THEOS)/makefiles/common.mk

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

include $(THEOS)/makefiles/library.mk

SparseBox_TARGET = 