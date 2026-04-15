#!/bin/bash
# 修复内核 EFI 格式问题的脚本

set -euo pipefail

if [ -z "${TOP_DIR:-}" ]; then
    export TOP_DIR=$(dirname $(realpath $0))/..
fi

KERNEL_DIR="$TOP_DIR/build/kernel"
KERNEL_BUILD_DIR="$KERNEL_DIR/build"

echo "=========================================="
echo "修复内核 EFI 格式问题"
echo "=========================================="
echo ""

# 检查内核目录是否存在
if [ ! -d "$KERNEL_DIR" ]; then
    echo "错误：内核目录不存在: $KERNEL_DIR"
    echo "请先运行: ./build.sh kernel az04"
    exit 1
fi

# 检查配置文件是否存在
if [ ! -f "$KERNEL_BUILD_DIR/.config" ]; then
    echo "错误：内核配置文件不存在: $KERNEL_BUILD_DIR/.config"
    echo "请先运行: ./build.sh kernel az04"
    exit 1
fi

cd "$KERNEL_DIR"

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

echo "1. 检查当前 EFI 配置..."
if grep -q "CONFIG_EFI_STUB=y" "$KERNEL_BUILD_DIR/.config" 2>/dev/null; then
    echo "   发现 CONFIG_EFI_STUB=y，需要禁用"
    NEED_FIX=1
elif grep -q "CONFIG_EFI_STUB=n" "$KERNEL_BUILD_DIR/.config" 2>/dev/null; then
    echo "   CONFIG_EFI_STUB 已禁用"
    NEED_FIX=0
else
    echo "   未找到 CONFIG_EFI_STUB 配置，将添加禁用配置"
    NEED_FIX=1
fi

if [ "$NEED_FIX" -eq 1 ]; then
    echo ""
    echo "2. 禁用 EFI Stub..."
    
    # 备份原配置
    cp "$KERNEL_BUILD_DIR/.config" "$KERNEL_BUILD_DIR/.config.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 禁用 EFI Stub
    if grep -q "CONFIG_EFI_STUB=y" "$KERNEL_BUILD_DIR/.config" 2>/dev/null; then
        sed -i 's/^CONFIG_EFI_STUB=y/CONFIG_EFI_STUB=n/' "$KERNEL_BUILD_DIR/.config"
    else
        echo "# EFI stub disabled for U-Boot compatibility" >> "$KERNEL_BUILD_DIR/.config"
        echo "CONFIG_EFI_STUB=n" >> "$KERNEL_BUILD_DIR/.config"
    fi
    
    # 可选：也禁用 EFI（如果不需要）
    if grep -q "^CONFIG_EFI=y" "$KERNEL_BUILD_DIR/.config" 2>/dev/null; then
        echo "   警告：发现 CONFIG_EFI=y，是否也要禁用？(y/n)"
        read -r answer
        if [ "$answer" = "y" ]; then
            sed -i 's/^CONFIG_EFI=y/CONFIG_EFI=n/' "$KERNEL_BUILD_DIR/.config"
            echo "   已禁用 CONFIG_EFI"
        fi
    fi
    
    echo "   ✓ EFI Stub 已禁用"
    
    echo ""
    echo "3. 重新编译内核镜像..."
    make O=build Image -j$(nproc)
    
    echo ""
    echo "4. 验证内核镜像格式..."
    if command -v file >/dev/null 2>&1; then
        IMAGE_FILE="$KERNEL_BUILD_DIR/arch/arm64/boot/Image"
        FILE_TYPE=$(file "$IMAGE_FILE" 2>/dev/null | grep -o "Linux kernel\|PE32\|MS-DOS" || echo "unknown")
        
        if echo "$FILE_TYPE" | grep -q "Linux kernel"; then
            echo "   ✓ 内核镜像格式正确: Linux kernel"
            echo "   文件信息:"
            file "$IMAGE_FILE"
        elif echo "$FILE_TYPE" | grep -q "PE32\|MS-DOS"; then
            echo "   ✗ 错误：内核镜像仍然是 EFI 格式！"
            echo "   可能需要检查其他配置选项"
            exit 1
        else
            echo "   ? 无法确定镜像格式，请手动检查:"
            file "$IMAGE_FILE"
        fi
    else
        echo "   警告：未安装 'file' 命令，无法自动验证"
        echo "   请手动运行: file $KERNEL_BUILD_DIR/arch/arm64/boot/Image"
    fi
    
    echo ""
    echo "=========================================="
    echo "修复完成！"
    echo "=========================================="
    echo ""
    echo "下一步：重新构建系统镜像"
    echo "  cd $TOP_DIR"
    echo "  ./build.sh image az04 alpine"
else
    echo ""
    echo "配置已正确，无需修复"
    echo ""
    echo "验证当前内核镜像格式："
    if [ -f "$KERNEL_BUILD_DIR/arch/arm64/boot/Image" ]; then
        file "$KERNEL_BUILD_DIR/arch/arm64/boot/Image" || true
    else
        echo "  内核镜像不存在，请先编译内核"
    fi
fi
