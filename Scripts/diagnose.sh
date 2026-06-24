#!/bin/bash
# 快速诊断脚本 - 检查为什么扫描到0个应用

echo "=== MicCam 诊断工具 ==="
echo ""

# 1. 检查是否能访问 /Applications
echo "1. 检查 /Applications 目录访问权限..."
if [ -r "/Applications" ]; then
    app_count=$(find /Applications -maxdepth 2 -name "*.app" -type d 2>/dev/null | wc -l | tr -d ' ')
    echo "   ✓ 可以访问 /Applications，找到 $app_count 个 .app"
else
    echo "   ✗ 无法访问 /Applications"
fi
echo ""

# 2. 检查 TCC.db 是否存在且可读
echo "2. 检查 TCC.db..."
tcc_path="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
if [ -f "$tcc_path" ]; then
    if [ -r "$tcc_path" ]; then
        echo "   ✓ TCC.db 存在且可读"
        # 尝试读取
        mic_count=$(sqlite3 "$tcc_path" "SELECT COUNT(*) FROM access WHERE service LIKE '%kTCCServiceMicrophone%' OR service LIKE '%kTCCServiceAudio%' 2>/dev/null || echo 'error'")
        if [ "$mic_count" = "error" ]; then
            echo "   ✗ 无法读取 TCC.db（可能需要完全磁盘访问权限）"
        else
            echo "   ✓ 可以读取 TCC.db，麦克风记录: $mic_count 条"
        fi
    else
        echo "   ✗ TCC.db 存在但不可读（需要完全磁盘访问权限）"
    fi
else
    echo "   ✗ TCC.db 不存在"
fi
echo ""

# 3. 检查当前 App 是否有完全磁盘访问权限
echo "3. 检查完全磁盘访问权限..."
if [ -r "$tcc_path" ]; then
    echo "   ✓ 有完全磁盘访问权限"
else
    echo "   ✗ 没有完全磁盘访问权限"
    echo "   → 请打开「系统设置 > 隐私与安全性 > 完全磁盘访问权限」"
    echo "   → 添加 Terminal.app 或你的 App"
fi
echo ""

# 4. 建议
echo "=== 建议操作 ==="
echo "1. 打开「系统设置 > 隐私与安全性 > 完全磁盘访问权限」"
echo "2. 点击「+」按钮，添加 Terminal.app（如果你在终端运行）"
echo "3. 或者添加 MicCam.app（如果你直接运行 App）"
echo "4. 重启 App 或终端"
echo ""
echo "详细说明请查看 README.md"
