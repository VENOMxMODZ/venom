#!/bin/bash
set -e

echo "===> Checking Xcode developer environment..."
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true)

if [ -z "$SDK_PATH" ]; then
    echo "ERROR: Apple iPhoneOS SDK not found."
    echo "Make sure Xcode and iOS command line developer tools are installed."
    exit 1
fi

echo "===> Found iPhoneOS SDK at: $SDK_PATH"
echo "===> Compiling DefineAura.dylib (arm64)..."

make clean
make

echo "===> Build completed successfully!"
ls -lh DefineAura.dylib
file DefineAura.dylib
