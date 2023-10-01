#!/bin/bash

set -e

cd "$(dirname "$0")"

WORKING_LOCATION="$(pwd)"
APPLICATION_NAME=PureKFD
CONFIGURATION=Debug
DEB_PACKAGE_NAME="uwu.lrdsnow.PureKFD"
DEB_PACKAGE_VERSION="4.0"
DEB_ARCHITECTURE="iphoneos-arm"
DEB_ARCHITECTURE_ROOTLESS="iphoneos-arm64"
DEB_MAINTAINER="Lrdsnow"

# Function to create the .deb package
create_deb_package() {
    PACKAGE_DIR="$DEB_PACKAGE_NAME-$DEB_PACKAGE_VERSION-$DEB_ARCHITECTURE"
    DEBIAN_DIR="$PACKAGE_DIR/DEBIAN"
    APPLICATIONS_DIR="$PACKAGE_DIR/Applications"

    mkdir -p "$DEBIAN_DIR"
    mkdir -p "$APPLICATIONS_DIR"

    # Create the control file
    CONTROL_FILE="$DEBIAN_DIR/control"
    echo "Package: $DEB_PACKAGE_NAME" > "$CONTROL_FILE"
    echo "Version: $DEB_PACKAGE_VERSION" >> "$CONTROL_FILE"
    echo "Architecture: $DEB_ARCHITECTURE" >> "$CONTROL_FILE"
    echo "Maintainer: $DEB_MAINTAINER" >> "$CONTROL_FILE"
    echo "Description: PureKFD" >> "$CONTROL_FILE"
    echo "Depends: " >> "$CONTROL_FILE"  # Add dependencies if needed
    echo "Section: Applications" >> "$CONTROL_FILE"

    # Copy your .app directory to the package
    cp -r "Payload/$APPLICATION_NAME.app" "$APPLICATIONS_DIR"

    # Create the post-installation script
    POSTINST_FILE="$DEBIAN_DIR/postinst"
    echo "#!/bin/bash" > "$POSTINST_FILE"
    echo "chmod 755 /Applications/$APPLICATION_NAME/$APPLICATION_NAME" >> "$POSTINST_FILE"

    # Make the post-installation script executable
    chmod +x "$POSTINST_FILE"

    # Build the .deb package
    dpkg-deb -b "$PACKAGE_DIR"
}
create_rootless_deb_package() {
    PACKAGE_DIR="$DEB_PACKAGE_NAME-$DEB_PACKAGE_VERSION-$DEB_ARCHITECTURE_ROOTLESS"
    DEBIAN_DIR="$PACKAGE_DIR/DEBIAN"
    APPLICATIONS_DIR="$PACKAGE_DIR/var/jb/Applications"

    mkdir -p "$DEBIAN_DIR"
    mkdir -p "$APPLICATIONS_DIR"

    # Create the control file
    CONTROL_FILE="$DEBIAN_DIR/control"
    echo "Package: $DEB_PACKAGE_NAME" > "$CONTROL_FILE"
    echo "Version: $DEB_PACKAGE_VERSION" >> "$CONTROL_FILE"
    echo "Architecture: $DEB_ARCHITECTURE_ROOTLESS" >> "$CONTROL_FILE"
    echo "Maintainer: $DEB_MAINTAINER" >> "$CONTROL_FILE"
    echo "Description: PureKFD" >> "$CONTROL_FILE"
    echo "Depends: " >> "$CONTROL_FILE"  # Add dependencies if needed
    echo "Section: Applications" >> "$CONTROL_FILE"

    # Copy your .app directory to the package
    cp -r "Payload/$APPLICATION_NAME.app" "$APPLICATIONS_DIR"

    # Create the post-installation script
    POSTINST_FILE="$DEBIAN_DIR/postinst"
    echo "#!/bin/bash" > "$POSTINST_FILE"
    echo "chmod 755 /Applications/$APPLICATION_NAME/$APPLICATION_NAME" >> "$POSTINST_FILE"

    # Make the post-installation script executable
    chmod +x "$POSTINST_FILE"

    # Build the .deb package
    dpkg-deb -b "$PACKAGE_DIR"
}

# Build .app
if [ ! -d "build" ]; then
    mkdir build
fi

cd build

if [ -e "$APPLICATION_NAME.tipa" ]; then
    rm "$APPLICATION_NAME.tipa"
fi
if [ -e "PureKFD.ipa" ]; then
    rm "PureKFD.ipa"
fi

xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
    -scheme $APPLICATION_NAME \
    -configuration Debug \
    -derivedDataPath "$WORKING_LOCATION/build/DerivedData" \
    -destination 'generic/platform=iOS' \
    ONLY_ACTIVE_ARCH="NO" \
    CODE_SIGNING_ALLOWED="NO"

DD_APP_PATH="$WORKING_LOCATION/build/DerivedData/Build/Products/$CONFIGURATION-iphoneos/$APPLICATION_NAME.app"
TARGET_APP="$WORKING_LOCATION/build/$APPLICATION_NAME.app"
cp -r "$DD_APP_PATH" "$TARGET_APP"

# Normal ipa
rm -rf Payload
mkdir Payload
cp -r $APPLICATION_NAME.app Payload/$APPLICATION_NAME.app
zip -vr PureKFD.ipa Payload

# Remove signature
codesign --remove "$TARGET_APP"
if [ -e "$TARGET_APP/_CodeSignature" ]; then
    rm -rf "$TARGET_APP/_CodeSignature"
fi
if [ -e "$TARGET_APP/embedded.mobileprovision" ]; then
    rm -rf "$TARGET_APP/embedded.mobileprovision"
fi

# Add entitlements
echo "Adding entitlements"
ldid -S"$WORKING_LOCATION/entitlements.plist" "$TARGET_APP/$APPLICATION_NAME"
# ldid -S"$WORKING_LOCATION/entitlements.plist" "$TARGET_APP/RootHelper"

# Package .ipa & .deb
rm -rf Payload
mkdir Payload
cp -r $APPLICATION_NAME.app Payload/$APPLICATION_NAME.app
zip -vr $APPLICATION_NAME.tipa Payload
create_deb_package
rm -rf $PACKAGE_DIR
create_rootless_deb_package
rm -rf $PACKAGE_DIR
rm -rf $APPLICATION_NAME.app
rm -rf Payload

echo "Done."