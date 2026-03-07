#!/bin/bash

# Importar Módulos
source toolchain/scripts/env_setup.sh
source toolchain/scripts/boards_config.sh
source toolchain/scripts/image_tools.sh

usage() {
    cat << EOF
Usage: $(basename "$0") [options]
Options:
    -m, --model [value]      Model code (ex: x1s)
    -v, --version [value]    Local Version (ex: MyKernel)
    -a, --additional [args]  Extra configs (ex: ksu.config,perf.config)
    -c, --config             Open menuconfig
    -s, --save [name]        Save resulting defconfig
    -cl, --clean             Clear 'out' directory
    -r, --recovery [y/N]     Build for Recovery
    -d, --dtbs [y/N]         Build only DTBs
EOF
    exit 1
}

# Variáveis Iniciais
ADDITIONAL_CONFIGS=""
MENUCONFIG=false
SAVE_NAME=""
L_VERSION=""
CLEAN_BUILD=false
RECOVERY=""
DTBS=""

# Parsing de Argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model) MODEL="$2"; shift 2 ;;
        -v|--version) L_VERSION="$2"; shift 2 ;;
        -a|--additional) RAW="$2"; ADDITIONAL_CONFIGS="${RAW//,/ }"; shift 2 ;;
        -c|--config) MENUCONFIG=true; shift ;;
        -s|--save) SAVE_NAME="$2"; shift 2 ;;
        -cl|--clean) CLEAN_BUILD=true; shift ;;
        -r|--recovery) RECOVERY="recovery.config"; shift ;;
        -d|--dtbs) DTBS="y"; shift ;;
        *) usage ;;
    esac
done

[[ -z "$MODEL" ]] && usage
BOARD=$(get_board_id "$MODEL") || abort "Model $MODEL not supported!"

# Setup do Ambiente
setup_toolchain

if [ "$CLEAN_BUILD" = true ]; then
    echo "Cleaning output directory..."
    rm -rf out
fi

# Preparação de pastas do build (Fiel ao original)
rm -rf build/out/$MODEL
mkdir -p build/out/$MODEL/zip/files
mkdir -p build/out/$MODEL/zip/META-INF/com/google/android

# Aplicar Local Version se fornecido
[[ ! -z "$L_VERSION" ]] && MAKE_ARGS="${MAKE_ARGS} LOCALVERSION=-${L_VERSION}"

echo "-----------------------------------------------"
echo "Generating configuration file..."
make ${MAKE_ARGS} -j$CORES exynos9830_defconfig "$MODEL.config" $RECOVERY $ADDITIONAL_CONFIGS || abort

[[ "$MENUCONFIG" = true ]] && make ${MAKE_ARGS} menuconfig

if [ ! -z "$SAVE_NAME" ]; then
    make ${MAKE_ARGS} savedefconfig
    cp out/defconfig arch/arm64/configs/"$SAVE_NAME"
    echo "Config saved to arch/arm64/configs/$SAVE_NAME"
fi

# Compilação
if [ ! -z "$DTBS" ]; then
    echo "Building DTBs..."
    make ${MAKE_ARGS} -j$CORES dtbs || abort
else
    echo "Building kernel..."
    make ${MAKE_ARGS} -j$CORES || abort
    cp out/arch/arm64/boot/Image build/out/$MODEL/
fi

# Processamento de Imagens e ZIP
build_images "$MODEL" "$BOARD" "$ADDITIONAL_CONFIGS" "$L_VERSION" "$RECOVERY" "$DTBS"

echo "Build finished successfully!"
