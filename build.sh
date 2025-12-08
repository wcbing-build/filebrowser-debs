#!/bin/sh

PACKAGE="filebrowser"
REPO="filebrowser/filebrowser"

# Processing again to avoid errors of remote incoming 
VERSION=$(echo $1 | sed -n 's|[^0-9]*\([^_]*\).*|\1|p')

ARCH="amd64 arm64"
AMD64_FILENAME="linux-amd64-filebrowser.tar.gz"
ARM64_FILENAME="linux-arm64-filebrowser.tar.gz"

build() {
    # Prepare
    BASE_DIR="$PACKAGE"_"$1"
    cp -r templates "$BASE_DIR"
    sed -i "s/Architecture: arch/Architecture: $1/" "$BASE_DIR/DEBIAN/control"
    sed -i "s/Version: version/Version: $VERSION-1/" "$BASE_DIR/DEBIAN/control"
    # Download and move file
    curl -sLo "$PACKAGE-$1.tar.gz" "$(get_url_by_arch $1)"
    TMPDIR=$(mktemp -dp .)
    tar -xzf "$PACKAGE-$1.tar.gz" -C $TMPDIR
    mv "$TMPDIR/$PACKAGE" "$BASE_DIR/usr/bin/$PACKAGE"
    chmod 755 "$BASE_DIR/usr/bin/$PACKAGE"
    mv $TMPDIR/* "$BASE_DIR/usr/share/doc/$PACKAGE/"
    rmdir $TMPDIR
    # Build
    dpkg-deb -b --root-owner-group -Z xz "$BASE_DIR" output
}

get_url_by_arch() {
    DOWNLOAD_PERFIX="https://github.com/$REPO/releases/latest/download"
    case $1 in
    "amd64") echo "$DOWNLOAD_PERFIX/$AMD64_FILENAME" ;;
    "arm64") echo "$DOWNLOAD_PERFIX/$ARM64_FILENAME" ;;
    esac
}

# Check parameters
if [ $# -ne 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage:
    $0 <version>"
    exit 1
fi

mkdir -p output

for i in $ARCH; do
    echo "Building $i package..."
    build "$i"
done

# Create repo files
cd output
apt-ftparchive packages . > Packages
apt-ftparchive release . > Release
