#!/bin/bash

build_images() {
    local MODEL=$1; local BOARD=$2; local ADD_CONFIGS=$3
    local L_VERSION=$4; local RECOVERY_OPT=$5; local DTB_OPT=$6

    # Constantes e Offsets Originais
    local DTB_PATH="build/out/$MODEL/dtb.img"
    local KERNEL_PATH="build/out/$MODEL/Image"
    local RAMDISK="build/out/$MODEL/ramdisk.cpio.gz"
    local OUTPUT_FILE="build/out/$MODEL/boot.img"
    
    # Parâmetros mkbootimg
    local BASE=0x10000000; local PAGE=2048; local HASH=sha1; local HV=2
    local KO=0x00008000; local DO=0x00000000; local RO=0x01000000; local SO=0xF0000000; local TO=0x00000100
    local CMD='androidboot.hardware=exynos990 loop.max_part=7'
    local OS_V=15.0.0; local OS_P=2025-08

    echo "Building DTB Image..."
    ./toolchain/mkdtimg cfg_create "$DTB_PATH" build/dtconfigs/exynos9830.cfg -d out/arch/arm64/boot/dts/exynos
    echo "Building DTBO Image..."
    ./toolchain/mkdtimg cfg_create "build/out/$MODEL/dtbo.img" "build/dtconfigs/$MODEL.cfg" -d out/arch/arm64/boot/dts/samsung

    if [ -z "$RECOVERY_OPT" ] && [ -z "$DTB_OPT" ]; then
        echo "Building RAMDisk..."
        pushd build/ramdisk > /dev/null
        find . ! -name . | LC_ALL=C sort | cpio -o -H newc -R root:root | gzip > "../../$RAMDISK" || return 1
        popd > /dev/null

        echo "Creating boot image..."
        ./toolchain/mkbootimg --base $BASE --board "$BOARD" --cmdline "$CMD" --dtb "$DTB_PATH" \
            --dtb_offset $DO --hashtype $HASH --header_version $HV --kernel "$KERNEL_PATH" \
            --kernel_offset $KO --os_patch_level $OS_P --os_version $OS_V --pagesize $PAGE \
            --ramdisk "$RAMDISK" --ramdisk_offset $RO --second_offset $SO --tags_offset $TO -o "$OUTPUT_FILE"

        echo "Building flashable zip..."
        cp "$OUTPUT_FILE" "build/out/$MODEL/zip/files/boot.img"
        cp "build/out/$MODEL/dtbo.img" "build/out/$MODEL/zip/files/dtbo.img"
        cp build/update-binary "build/out/$MODEL/zip/META-INF/com/google/android/update-binary"
        cp build/updater-script "build/out/$MODEL/zip/META-INF/com/google/android/updater-script"

        # Versão e Nome do ZIP
        local version=$(grep -o 'CONFIG_LOCALVERSION="[^"]*"' out/.config | cut -d '"' -f 2 | sed 's/"//g')
        local FINAL_V=${L_VERSION:-${version#?}}
        local DATE=$(date +"%d-%m-%Y_%H-%M-%S")
        local KSU_TAG=""; [[ "$ADD_CONFIGS" == *"ksu.config"* ]] && KSU_TAG="_KSU"
        
        local ZIP_NAME="${FINAL_V}_${MODEL}_UNOFFICIAL${KSU_TAG}_${DATE}.zip"
        
        pushd "build/out/$MODEL/zip" > /dev/null
        zip -r -qq "../$ZIP_NAME" .
        popd > /dev/null
        echo "ZIP generated: $ZIP_NAME"
    fi
}
