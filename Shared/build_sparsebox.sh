if [ -d "$BUILD_DIR/Libraries" ]; then
    echo "Libraries already exist."
else
    source ~/.zshrc
    cd SparseBox
    
    /bin/sh get_libraries.sh
    
    cp ../SparseRestore/Makefile Makefile
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
    
    rm -rf .theos
fi
