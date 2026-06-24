#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MicCam"
BUILD_DIR="$ROOT/.build/debug"
APP_DIR="$ROOT/dist/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# 检查是否有旧版本正在运行
echo "检查是否有旧版本正在运行..."
if pgrep -x "MicCamPrivacyManager" > /dev/null 2>&1; then
    echo "检测到 MicCam Privacy Manager 正在运行，正在关闭..."
    pkill -x "MicCamPrivacyManager" || true
    sleep 2
    # 如果还没关闭，强制关闭
    if pgrep -x "MicCamPrivacyManager" > /dev/null 2>&1; then
        echo "强制关闭..."
        pkill -9 -x "MicCamPrivacyManager" || true
        sleep 1
    fi
    echo "已关闭旧版本"
else
    echo "没有检测到运行中的实例"
fi

swift build --disable-sandbox --jobs 1 --package-path "$ROOT" --scratch-path "$ROOT/.build"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"
cp "$BUILD_DIR/MicCamPrivacyManager" "$MACOS/MicCamPrivacyManager"

# 复制图标文件
if [ -f "$ROOT/icon.icns" ]; then
    cp "$ROOT/icon.icns" "$RESOURCES/AppIcon.icns"
    echo "已复制图标文件"
fi

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MicCamPrivacyManager</string>
    <key>CFBundleIdentifier</key>
    <string>local.miccam.privacy.manager</string>
    <key>CFBundleName</key>
    <string>MicCam</string>
    <key>CFBundleDisplayName</key>
    <string>MicCam</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
</dict>
</plist>
PLIST

echo "Created: $APP_DIR"
