# Luma

一款面向 Android TV 的安静、快速媒体播放器。将 Luma 指向一个文件夹或 USB 磁盘，它将构建海报墙：递归扫描、文件名解析、NFO 支持、TMDB 刮削、断点续播和自动下一集。

UI 语言中文优先。

## 概览

[主页预览](docs/home1.png)

## 功能特性

- **海报墙** — 电影和剧集自动分组，无画作时采用确定性渐变兜底。
- **本地 + USB** — 通过系统选择器添加文件夹，或添加整个存储卷。扫描会递归遍历最多 24 层子目录。
- **自动元数据** — 文件名解析 → 本地 `.nfo` → TMDB。海报、背景图、剧集剧照、评分、类型、片长和概述。
- **剧集分组** — 识别 `S01E02`、`1x02`、`第 2 集`、`Show - 12` 和文件夹季；剧集被分组到同一个剧目下。
- **播放** — 基于 `media_kit`/libmpv 的自定义 TV 控件，支持 D-pad、断点续播、音频/字幕轨道选择、播放速度和宽高比控制，外挂字幕发现和自动下一集。
- **TV-first UX** — D-pad 焦点环、紧凑导航栏、10 英尺排版和香槟金对近黑配色。

## 环境要求

| 工具 | 版本 |
| --- | --- |
| Flutter | 3.47 或更高 |
| Dart | 3.13 或更高 |
| Android | 7.0 (API 24) 或更高 |
| Android TV | 推荐目标平台 |


> 在线刮削需要免费的 [TMDB API key](https://www.themoviedb.org/settings/api) 或在 豆瓣API key(非官方)。
> 无 API key 时 NFO 元数据仍可正常工作。

API key 在构建时通过`.env`文件中的环境变量注入, 示例:
```
TMDB_API_KEY=xxxxxx
DOUBAN_API_KEY=xxxxx
```

## 构建

```bash
export PATH="$HOME/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk"

flutter pub get
flutter build apk --debug

# Smaller, per-ABI release build
flutter build apk --release --split-per-abi
```

通过 ADB 安装到 TV 或手机：

```bash
adb connect 192.168.1.50:5555
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

发布构建目前使用 debug 签名配置，因此可立即侧载。发布前请在 `android/app/build.gradle.kts` 中配置自己的密钥库。

### 主题

Luma 内置多个主题, 的每个主题由恰好 **三个自定义颜色** 加上辅助角色定义：

- **primary** — 主要交互/CTA 色调（按钮、活跃芯片、焦点）
- **accent** — 次要品牌色调
- **surface** — 面板/卡片颜色
- 每个主题的辅助角色：背景、分割线、文本（+ textDim/textMuted）、危险、成功，以及每个角色的深/浅色调

每个主题都带有深色和浅色变体，可从 **设置 → 外观** 实时切换（每个主题记住模式）。屏幕上所有颜色均通过 `LumaColors.*` 解析，即 `LumaColors.primary`、`LumaColors.accent`、`LumaColors.surface` — 切勿在 `lib/core/theme/<name>.dart` 之外硬编码主题十六进制颜色。

添加新主题：在 `lib/core/common/themes.dart` 文件中注册。`Settings → 外观` 会自动为每个注册的主题渲染一个磁贴。

### 桌面预览

相同的 UI 可作为 Linux/macOS/Windows 桌面应用运行，用于设计评审。桌面构建使用 `sqflite_common_ffi`、原生文件夹选择器和系统 libmpv，因此无需 Android 设备即可进行扫描和播放。

```bash
# Linux 播放需要 libmpv (Fedora)
sudo dnf install mpv-libs

flutter run -d linux
```

在引导界面选择 **添加媒体目录** 以选择任意本地文件夹，或选择 **先看看界面** 浏览空状态。桌面存储权限被视为始终授予。此路径仅用于开发预览；Android TV 构建仍然是交付目标。

### Gradle 镜像

`android/settings.gradle.kts` 和 `android/build.gradle.kts` 在 Google/Maven Central 之前列出了阿里云 Maven 镜像。这使得在 `maven.google.com` 无法访问的网络上构建仍然可用。如果您偏好上游仓库，请移除或重新排序它们。

### media_kit libmpv 下载

`media_kit_libs_android_video` 会从 GitHub Releases 下载四个 libmpv jar，而 Gradle 在配置项目时进行。在 GitHub 缓慢或被封锁的网络上，截断的 jar 会导致：

```
MD5 verification failed for .../build/media_kit_libs_android_video/v1.1.7/default-armeabi-v7a.jar
```

使用辅助脚本预先获取一次 jar，该脚本尝试 GitHub 代理并验证每个校验和：

```bash
tool/fetch_media_kit_libs.sh
```

jar 缓存于 `~/.cache/luma/media-kit/v1.1.7`。Gradle 初始化脚本 `~/.gradle/init.d/aliyun-mirrors.gradle` 会将它们复制到插件的构建目录，因此 `flutter clean` 不会强制再次从 GitHub 下载。没有该初始化脚本时，请在构建前手动将 jar 复制到 `build/media_kit_libs_android_video/v1.1.7/`。

### 非 ASCII Flutter SDK 路径

Flutter 3.47 的 `FlutterAppPluginLoaderPlugin` 使用 `Properties.load(InputStream)` 读取 `local.properties`，该方法将 UTF-8 字节解码为 ISO-8859-1。如果 Flutter SDK 路径包含非 ASCII 字符（例如 `/home/me/下载/flutter`），Gradle 可能会报告畸变的路径，例如 `/home/me/ä¸‹è½½/flutter`。

使用 ASCII 路径，或将 SDK 符号链接到其中。或者，将以下内容添加到 `~/.gradle/init.d/utf8-flutter-sdk.gradle`：

```groovy
beforeSettings { settings ->
    def localProperties = new File(settings.settingsDir, 'local.properties')
    if (localProperties.isFile()) {
        def properties = new Properties()
        localProperties.withReader('UTF-8') { properties.load(it) }
        def flutterSdk = properties.getProperty('flutter.sdk')
        if (flutterSdk) settings.extraProperties.set('flutterSdkPath', flutterSdk)
    }
}
```

这会在 Flutter 的设置插件读取之前设置该值。

## TMDB 设置

1. 在 [themoviedb.org](https://www.themoviedb.org/) 创建账户。
2. 打开 **Settings → API** 并申请免费 API key。
3. 在 Luma 中打开 **设置 → TMDB API Key → 配置**，粘贴密钥并在保存前使用 **测试连接**。

密钥仅存储在设备的 SharedPreferences 中。请求直接发送到 `api.themoviedb.org`；没有代理或云账户。

TMDB 归属：本产品使用 TMDB API，但未获 TMDB 认可或认证。

## 存储权限

Android 11 及更高版本需要 **全部文件访问权限** (`MANAGE_EXTERNAL_STORAGE`)，以便应用通过真实路径浏览任意文件夹和 USB 卷：

- 首次启动时，选择 **授予文件访问权限**。
- 如果系统对话框未出现，请打开 **设置 → 媒体来源 → 去授权**，或从 Android TV 的应用设置中授予权限。
- Android 10 及更低版本改为请求 `READ_EXTERNAL_STORAGE`。
- `READ_MEDIA_VIDEO` 已声明用于 Android 13+ 兼容性。

文件夹选择器使用存储访问框架。如果提供程序未公开真实文件系统路径（例如某些云提供程序），请改从 **添加目录 → 整块磁盘** 添加整个 USB 卷。

支持的挂载点包括主共享存储以及 `/storage/<UUID>` 下的可移除卷。

## 扫描工作原理

1. 递归遍历源，忽略隐藏文件、样本/预告片文件以及小于 2 MB 的文件。
2. 从文件名解析标题、年份、季和集。发布标签（`1080p`、`BluRay`、`x265`、`WEB-DL` 等）会被剥离。
3. 查找同名 `.nfo` 和本地画作（`poster.jpg`、`fanart.jpg`、`folder.jpg`、`show.jpg` 等）。
4. 如果配置了 TMDB key 且启用自动刮削，则匹配条目并将元数据写回 SQLite。
5. 在后续扫描中，缺失的文件会被移除，而现有文件上的刮削元数据会被保留。

### 推荐目录结构

```
Movies/
  Blade Runner 2049 (2017)/
    Blade.Runner.2049.2017.2160p.mkv
    poster.jpg
    movie.nfo
Shows/
  Severance/
    Season 01/
      Severance.S01E01.mkv
      Severance.S01E01.zh.srt
      show.nfo
```

## 项目结构

```
lib/
  app.dart                 引导，启动画面，错误状态
  controllers/             AppController (ChangeNotifier)
  core/                    主题，格式化工具
                      theme.dart      桶导出
                      theme/          每个主题一个文件 (classic, byzantium)
                      themes.dart     内置主题注册表
                      luma_colors.dart  屏幕的语义颜色句柄
                      luma_theme.dart ThemeData + 页面过渡
                      palette.dart    LumaPalette，共享调色板形状
  data/
    app_database.dart      SQLite 架构
    media_repository.dart  查询和扫描 upsert
    scanner/               递归扫描器，文件名/NFO 解析器
    scraper/               TMDB 客户端，匹配器，刮削编排
    storage_service.dart   MethodChannel 桥接
  features/                主页，媒体库，详情，播放器，设置，
                           引导，壳，来源
  widgets/                 TV 焦点原语，画作，货架，导航栏
android/…/MainActivity.kt  存储权限，文件夹选择器，卷
test/                      解析器和仓库测试
```

## 测试

```bash
flutter analyze
flutter test
```

仓库测试使用 `sqflite_common_ffi` 和内存数据库，因此无需模拟器即可在主机上运行。

## 当前范围

- 仅本地存储和 USB。SMB、WebDAV 和 NFS 尚未实现。
- 无转码；libmpv 按原样播放文件。
- 支持嵌入式和外挂字幕；位图字幕样式由 libmpv 默认值处理。
- 应用以横屏优先面向 TV。手机/平板支持可用，但不是主要设计目标。
