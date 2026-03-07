#!/bin/bash

setup_toolchain() {
    export CLANG_DIR="$PWD/toolchain/clang_14"
    export PATH=$CLANG_DIR/bin:$PATH
    export CORES=$(nproc 2>/dev/null || grep -c processor /proc/cpuinfo)

    if [ ! -f "$CLANG_DIR/bin/clang-14" ]; then
        echo "Toolchain not found! Downloading..."
        rm -rf "$CLANG_DIR"
        mkdir -p "$CLANG_DIR"
        pushd "$CLANG_DIR" > /dev/null
        curl -LJOk https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/tags/android-13.0.0_r13/clang-r450784d.tar.gz
        tar xf android-13.0.0_r13-clang-r450784d.tar.gz
        rm android-13.0.0_r13-clang-r450784d.tar.gz
        popd > /dev/null
    fi

    export MAKE_ARGS="LLVM=1 LLVM_IAS=1 ARCH=arm64 O=out"
}

abort() {
    echo "-----------------------------------------------"
    echo "ERROR: ${1:-Kernel compilation failed!}"
    echo "-----------------------------------------------"
    exit 1
}
