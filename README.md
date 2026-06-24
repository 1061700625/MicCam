# MicCam

一款 macOS 权限管理工具，帮助你在 macOS 系统中查看和管理应用的**麦克风 / 摄像头**权限。

## 背景

最新 macOS 系统不会为未做权限适配的旧 App 显示麦克风/摄像头权限开关，导致这些 App 的权限状态无法在系统设置中查看或修改。

MicCam 通过直接读取系统的 TCC 数据库，让你**一目了然地看到所有已安装应用的权限状态**，并生成可执行的 Shell 命令来修改权限。

## 功能

* **📋 一览所有 App 的权限状态** — 扫描本机所有已安装应用，显示其麦克风和摄像头权限（允许 / 拒绝 / 未记录）

* **🔍 搜索** — 按名称、Bundle ID 或路径快速过滤

* **📄 生成 TCC Shell 命令** — 为选中的应用生成 `sqlite3 TCC.db` 命令，支持允许、拒绝、删除记录和验证

* **▶️ 一键执行** — 通过系统管理员权限直接执行命令，无需手动打开终端

* **📁 在 Finder 中显示** — 快速定位 App 所在位置

## 安装

### 下载

前往 [Releases](https://github.com/1061700625/MicCam/releases) 页面下载最新版本的 `MicCam.app`。

### 从源码构建

```bash
git clone https://github.com/1061700625/MicCam.git
cd MicCam
bash Scripts/make-app.sh
```

构建完成后，App 位于 `dist/MicCam.app`。

## 使用

1. 启动 MicCam

2. 左侧列表显示所有已安装应用及其权限状态

3. 选中某个 App，右侧显示详情

4. 在「高级：生成 TCC Shell 命令」区域：

   * 选择权限（麦克风 / 摄像头）

   * 选择动作（允许 / 拒绝 / 删除记录 / 验证）

   * 点击「执行命令」，输入管理员密码即可

### 完全磁盘访问权限（可选）

MicCam 需要读取 `~/Library/Application Support/com.apple.TCC/TCC.db`，这可能需要**完全磁盘访问权限**（如果能用就可以不用管）：

1. 打开「系统设置 → 隐私与安全性 → 完全磁盘访问权限」

2. 点击「+」添加 Terminal.app（终端运行）或 MicCam.app（直接运行）

## 技术说明

### TCC 数据库

macOS 的权限管理基于 TCC（Transparency, Consent, and Control）框架，权限记录存储在：

```
~/Library/Application Support/com.apple.TCC/TCC.db
```

MicCam 通过只读方式查询该数据库，并通过生成的 `sqlite3` 命令修改记录。

### 权限字段说明

| auth_value | 含义             |
| ---------- | -------------- |
| 0          | ❌ 已拒绝          |
| 2          | ✅ 已允许          |
| 3          | ⚠️ 受限 / 未决定    |
| 无记录        | 该 App 从未申请过此权限 |

## 局限

* ⚠️ **需要完全磁盘访问权限**才能读取 TCC.db

* ⚠️ **修改 TCC 记录有风险**，建议先备份 TCC.db（`cp ~/Library/Application\ Support/com.apple.TCC/TCC.db ~/Desktop/TCC.db.bak`）

* ⚠️ macOS 系统可能在新版本中修改 TCC 数据库结构，导致命令失效

* 无法保证修改后系统会立即生效（部分 macOS 版本需要重启相关 App 或系统）

## FAQ

**Q：为什么有些 App 显示「未记录」？**
A：表示该 App 从未向系统申请过麦克风/摄像头权限，TCC.db 中没有它的记录。

**Q：执行命令后状态没有变化？**
A：点击工具栏的「刷新」按钮重新读取 TCC.db；部分 macOS 版本需要重启相关 App。

**Q：为什么需要管理员密码？**
A：修改 TCC.db 需要 root 权限，`do shell script ... with administrator privileges` 是 macOS 标准的提权方式。

## License

MIT License
