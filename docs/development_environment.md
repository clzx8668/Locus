# Locus 开发环境固化说明

## 1. 固定路径

Locus 项目的本地开发工具链统一固定在 `D:` 盘，后续开发、调试、脚本执行与 AI 协助都应遵循以下约定：

- Flutter SDK 根目录：`D:\flutter`
- Android SDK 根目录：`D:\AndroidSDK`

硬性约束：

- 不要把 Flutter SDK 安装到 `C:\Users\...` 下。
- 不要把 Android SDK / ADB / cmdline-tools / NDK 的根目录放到 `C:\Users\...` 下。
- 当 AI 需要修复 Flutter / Android 环境时，默认先检查 `D:\flutter` 与 `D:\AndroidSDK`，不要擅自新建 `C:` 盘用户目录下的 SDK。

## 2. 当前版本要求

由于项目已接入 `zvec 0.5.2`，当前工具链至少需要满足：

- Flutter：建议 `3.41.9+`
- Dart：`3.11.3+`

本次已验证可用的一组版本为：

- Flutter `3.41.9`
- Dart `3.11.5`

如果终端里的 `flutter --version` 仍指向较旧版本，需要先切换到 `D:\flutter` 下满足要求的 SDK 再执行依赖与构建命令。

## 3. 建议环境变量

推荐在系统或 PowerShell 配置中固定以下环境变量：

```powershell
$env:ANDROID_SDK_ROOT = 'D:\AndroidSDK'
$env:ANDROID_HOME = 'D:\AndroidSDK'
```

如果当前 `PATH` 中存在多个 Flutter 版本，建议把目标版本的 `bin` 目录放在更高优先级，例如：

```powershell
$env:PATH = 'D:\flutter\<your_flutter_version>\bin;' + $env:PATH
```

说明：

- `<your_flutter_version>` 应替换为 `D:\flutter` 下实际使用的版本目录。
- 若直接使用根目录式安装，也可以是 `D:\flutter\bin`。
- 仓库内已提供便捷脚本 `scripts/use_locus_dev_env.ps1`，可用于把当前终端切换到项目约定的 D 盘工具链。

示例：

```powershell
. .\scripts\use_locus_dev_env.ps1
flutter --version
```

## 4. 项目执行规范

执行以下命令前，先确认 Flutter SDK 指向 `D:\flutter` 下符合版本要求的安装：

```powershell
. .\scripts\use_locus_dev_env.ps1
flutter --version
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run
```

对于 Android 调试与构建，默认也只认 `D:\AndroidSDK`：

- `adb`
- `platform-tools`
- `build-tools`
- `cmdline-tools`
- `ndk`

## 5. AI / Agent 协作约束

后续任何 AI 协作都应遵循：

- 先检查 `D:\flutter` 和 `D:\AndroidSDK` 是否已有可用安装。
- 优先复用已有工具链，不要重新下载到 `C:\Users\...`。
- 若确需下载新版本 Flutter，也应优先落到 `D:\flutter` 的版本子目录中。
- 若需修复 Android 环境，优先修复 `D:\AndroidSDK` 下的组件，而不是重新初始化一套新的用户目录 SDK。

## 6. 与项目架构的关系

本项目当前的关键依赖关系如下：

- `Drift + SQLCipher` 负责主明文数据仓库
- `GetIt` 负责依赖注入
- `Repository` 负责隔离 UI 与数据库
- `ProcessingPipeline` 负责后台异步处理
- `zvec 0.5.2` 负责本地脱敏向量索引

因此，工具链版本漂移会直接影响：

- `flutter pub get`
- `build_runner` / `drift_dev`
- `zvec` SDK 解析
- `flutter analyze`

为了避免后续反复踩坑，所有环境修复都应以本文档为准。
