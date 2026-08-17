/// App 统一版本信息服务
///
/// 版本号唯一来源：`pubspec.yaml` 中的 `version:` 字段（例如 `1.0.6+6`，
/// `1.0.6` 为显示版本号，`6` 为构建号）。
///
/// 改一处 → 所有地方同步更新：
///   1. pubspec.yaml   → Flutter 打包版本 & 构建号
///   2. Android 应用 → `build.gradle` 自动从 pubspec 读取
///   3. iOS 应用     → `Generated.xcconfig` 自动从 pubspec 读取
///   4. 关于对话框   → 通过 [AppVersionInfo] 动态显示
///   5. 任何需要显示版本号的地方 → 调用 `AppVersionInfo.version`
///
/// 使用方式：
///   ```dart
///   final info = await AppVersionInfo.load();
///   print(info.version);     // "1.0.6"
///   print(info.buildNumber); // "6"
///   print(info.full);        // "1.0.6 (6)"
///   ```
library app_version_info;

import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  final String appName;         // 应用名（AndroidManifest/Info.plist 中配置）
  final String packageName;     // 包名 / bundleId
  final String version;         // 显示版本号（对应 pubspec version 的 x.y.z）
  final String buildNumber;     // 构建号（对应 pubspec version 的 +n）

  const AppVersionInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  /// 完整版本号字符串，常用于 UI 显示
  String get full => '$version ($buildNumber)';

  /// 仅显示版本号，无构建号（简洁，用于关于页副标题）
  String get display => version;

  /// 从平台层异步加载版本信息（从 pubspec / AndroidManifest / Info.plist 汇总）
  static Future<AppVersionInfo> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppVersionInfo(
        appName: info.appName,
        packageName: info.packageName,
        version: info.version.isEmpty ? '未知版本' : info.version,
        buildNumber: info.buildNumber.isEmpty ? '1' : info.buildNumber,
      );
    } catch (_) {
      // 极端情况（如测试环境）加载失败时，返回兜底值，避免 About 页面崩溃
      return const AppVersionInfo(
        appName: '社交塔子',
        packageName: 'unknown',
        version: '加载中',
        buildNumber: '0',
      );
    }
  }
}
