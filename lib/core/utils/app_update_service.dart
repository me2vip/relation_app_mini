/// 应用内自动更新服务
///
/// 通过 GitHub Release API 检查最新版本，下载 APK 后调用系统安装器安装。
///
/// 工作流程：
///   1. [checkForUpdate]：调用 GitHub `releases` 列表接口，比对版本号
///   2. [downloadApk]：流式下载 APK 到外部存储，支持进度回调
///   3. [installApk]：调用 [OpenFilex] 拉起系统安装器（Android 8+ 自动处理未知来源权限）
///
/// GitHub API 文档：https://docs.github.com/en/rest/releases/releases#list-releases
library app_update_service;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// GitHub Release 元信息
class GithubReleaseInfo {
  /// Release tag（如 "v1.0.10"）
  final String tagName;

  /// 版本号（如 "1.0.10"，去掉 v 前缀）
  final String version;

  /// 发行说明（Markdown 原文）
  final String releaseNotes;

  /// APK 下载地址（assets.browser_download_url）
  final String apkDownloadUrl;

  /// APK 文件名（如 "社交教练_v1.0.10_arm64_release.apk"）
  final String apkName;

  /// APK 文件大小（字节）
  final int apkSize;

  /// Release 发布时间
  final DateTime publishedAt;

  /// Release HTML 页面（用户可在浏览器打开）
  final String htmlUrl;

  const GithubReleaseInfo({
    required this.tagName,
    required this.version,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.apkName,
    required this.apkSize,
    required this.publishedAt,
    required this.htmlUrl,
  });

  /// 是否有可下载的 APK 资产
  bool get hasApkAsset => apkDownloadUrl.isNotEmpty;

  /// APK 大小（MB，保留 1 位小数）
  String get apkSizeMB {
    if (apkSize <= 0) return '未知';
    return (apkSize / 1024 / 1024).toStringAsFixed(1);
  }
}

/// 检查结果
enum UpdateCheckResult {
  /// 有新版本可用
  hasUpdate,
  /// 已是最新版
  upToDate,
  /// 检查失败（网络/解析错误）
  error,
  /// 最新 Release 没有 APK 资产
  noAsset,
}

class UpdateCheckOutcome {
  final UpdateCheckResult result;
  final GithubReleaseInfo? releaseInfo;
  final String? errorMessage;
  final String currentVersion;

  const UpdateCheckOutcome({
    required this.result,
    this.releaseInfo,
    this.errorMessage,
    required this.currentVersion,
  });
}

class AppUpdateService {
  AppUpdateService._();

  /// 仓库 owner/name（GitHub 仓库地址：https://github.com/me2vip/relation_app_mini）
  static const _repoOwner = 'me2vip';
  static const _repoName = 'relation_app_mini';

  /// GitHub Release 列表 API
  ///
  /// 注意：**[不要用 `releases/latest` 端点]**。
  /// `/releases/latest` 会**排除 prerelease（预发布）与 draft**，
  /// 一旦最新版本被标记为预发布，该端点会回退到上一个旧的正式版，
  /// 导致自动更新下载并安装**旧版 APK**（本仓库出现过的 bug）。
  /// 这里改为拉取列表，过滤 draft 后按发布时间取真正最新的版本（含预发布）。
  static const _apiReleases =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases?per_page=100';

  /// Release HTML 页面（备用：浏览器下载）
  static const _releasePageUrl =
      'https://github.com/$_repoOwner/$_repoName/releases/latest';

  /// 网络超时
  static const _connectTimeout = Duration(seconds: 15);
  static const _receiveTimeout = Duration(seconds: 15);

  /// downloadApk 最大重试次数
  static const _maxRetries = 3;

  /// 获取 Dio 实例（带默认 UA / Accept）
  static Dio _createDio() {
    return Dio(BaseOptions(
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      headers: {
        // 重要：不要设置 'Accept: application/vnd.github+json'。
        // 实测该仓库 API 在携带此 Accept 头时 releases 列表返回空数组 []，
        // 导致检查更新永远报“未找到可用的 Release”。不设置 Accept 才能拿到完整列表。
        'User-Agent': 'relation-app-mini-updater/1.0',
      },
    ));
  }

  /// 检查更新
  ///
  /// 返回 [UpdateCheckOutcome]：
  /// - hasUpdate：有新版本，[releaseInfo] 携带新版本信息
  /// - upToDate：当前已是最新版
  /// - error：检查失败（网络错误等），[errorMessage] 携带错误信息
  /// - noAsset：最新 Release 没有 .apk 资产
  static Future<UpdateCheckOutcome> checkForUpdate() async {
    final currentInfo = await PackageInfo.fromPlatform();
    final currentVersion = currentInfo.version;

    final dio = _createDio();
    try {
      // 防御性重试：GitHub API 偶发返回空数组/504，重试 3 次（1s/2s 退避）
      dynamic respData;
      int statusCode = 0;
      for (var attempt = 0; attempt < 3; attempt++) {
        if (attempt > 0) {
          await Future.delayed(Duration(seconds: attempt));
        }
        final resp = await dio.get(_apiReleases);
        statusCode = resp.statusCode ?? 0;
        respData = resp.data;
        if (statusCode == 200 && respData is List && respData.isNotEmpty) break;
      }

      if (statusCode != 200) {
        return UpdateCheckOutcome(
          result: UpdateCheckResult.error,
          errorMessage: 'GitHub API 返回状态码 $statusCode',
          currentVersion: currentVersion,
        );
      }

      final list = (respData is List) ? (respData as List) : <dynamic>[];

      // 过滤草稿（draft）。
      // 修复（自动更新下载旧版 bug）：不再使用 `releases/latest` 端点，
      // 因为它会排除 prerelease，导致新版本被标记为预发布时自动更新
      // 回退下载旧版安装。改为取时间上最新的、非草稿 Release（含预发布）。
      final releases = <Map<String, dynamic>>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        if (item['draft'] == true) continue;
        releases.add(item);
      }
      if (releases.isEmpty) {
        return UpdateCheckOutcome(
          result: UpdateCheckResult.error,
          errorMessage: '未找到可用的 Release',
          currentVersion: currentVersion,
        );
      }

      // 按发布时间降序，取真正最新的版本（无论是否 prerelease）
      releases.sort((a, b) {
        final ta = DateTime.tryParse((a['published_at'] ?? '').toString()) ??
            DateTime(1970);
        final tb = DateTime.tryParse((b['published_at'] ?? '').toString()) ??
            DateTime(1970);
        return tb.compareTo(ta); // 降序，最新在前
      });

      final data = releases.first;

      final tagName = (data['tag_name'] ?? '').toString().trim();
      if (tagName.isEmpty) {
        return UpdateCheckOutcome(
          result: UpdateCheckResult.error,
          errorMessage: '未找到最新 Release tag',
          currentVersion: currentVersion,
        );
      }
      final version =
          tagName.toLowerCase().startsWith('v') ? tagName.substring(1) : tagName;

      // 找 APK 资产
      final assets = data['assets'] is List
          ? (data['assets'] as List)
          : <dynamic>[];
      String apkUrl = '';
      String apkName = '';
      int apkSize = 0;

      // 仅保留 .apk 资产
      final apks = <Map<String, dynamic>>[];
      for (final a in assets) {
        if (a is! Map<String, dynamic>) continue;
        final name = (a['name'] ?? '').toString().toLowerCase();
        if (name.endsWith('.apk')) apks.add(a);
      }

      // 1) 优先选文件名包含本 release 版本号（如 1.0.11）的 apk。
      //    修复：v1.0.11 release 可能同时挂着 _v1.0.10_xxx.apk 与
      //    _v1.0.11_xxx.apk，若按"第一个 arm64"选取会误下载旧版 apk，
      //    导致安装后版本回退、再次检测仍提示更新（即下载最新后仍要更新）。
      //    用非数字边界匹配，避免 1.0.1 误中 1.0.11。
      final versionPattern =
          RegExp(r'(?:^|[^0-9])' + RegExp.escape(version) + r'(?:$|[^0-9])');
      for (final a in apks) {
        final name = (a['name'] ?? '').toString();
        if (versionPattern.hasMatch(name)) {
          apkUrl = (a['browser_download_url'] ?? '').toString();
          apkName = name;
          apkSize = (a['size'] as num?)?.toInt() ?? 0;
          break;
        }
      }
      // 2) 退化：按 arm64 -> universal -> 任意 选择
      if (apkUrl.isEmpty) {
        for (final pattern in ['arm64', 'universal', '']) {
          for (final a in apks) {
            final name = (a['name'] ?? '').toString().toLowerCase();
            if (pattern.isNotEmpty && !name.contains(pattern)) continue;
            apkUrl = (a['browser_download_url'] ?? '').toString();
            apkName = (a['name'] ?? '').toString();
            apkSize = (a['size'] as num?)?.toInt() ?? 0;
            break;
          }
          if (apkUrl.isNotEmpty) break;
        }
      }

      // 时间
      DateTime publishedAt = DateTime.now();
      final publishedStr = (data['published_at'] ?? '').toString();
      if (publishedStr.isNotEmpty) {
        try {
          publishedAt = DateTime.parse(publishedStr);
        } catch (_) {}
      }

      final htmlUrl = (data['html_url'] ?? _releasePageUrl).toString();
      final releaseNotes = (data['body'] ?? '').toString();

      final releaseInfo = GithubReleaseInfo(
        tagName: tagName,
        version: version,
        releaseNotes: releaseNotes,
        apkDownloadUrl: apkUrl,
        apkName: apkName.isEmpty ? 'app-release.apk' : apkName,
        apkSize: apkSize,
        publishedAt: publishedAt,
        htmlUrl: htmlUrl,
      );

      // 无 APK 资产
      if (!releaseInfo.hasApkAsset) {
        return UpdateCheckOutcome(
          result: UpdateCheckResult.noAsset,
          releaseInfo: releaseInfo,
          currentVersion: currentVersion,
        );
      }

      // 版本比较
      final isNewer = _isNewer(releaseInfo.version, currentVersion);
      return UpdateCheckOutcome(
        result: isNewer ? UpdateCheckResult.hasUpdate : UpdateCheckResult.upToDate,
        releaseInfo: releaseInfo,
        currentVersion: currentVersion,
      );
    } on DioException catch (e) {
      return UpdateCheckOutcome(
        result: UpdateCheckResult.error,
        errorMessage: _dioErrorMessage(e),
        currentVersion: currentVersion,
      );
    } catch (e) {
      return UpdateCheckOutcome(
        result: UpdateCheckResult.error,
        errorMessage: '检查更新失败：$e',
        currentVersion: currentVersion,
      );
    }
  }

  /// 下载 APK 到外部存储
  ///
  /// - [onProgress]：(received, total) 接收字节数 / 总字节数
  /// - 返回下载完成的 APK 文件路径
  ///
  /// 保存目录：`getExternalStorageDirectory()/Android/data/<pkg>/files/` 或
  /// 退化到 `getTemporaryDirectory()`。
  /// 策略：先下载到临时文件（`.tmp`），下载成功后再 rename，避免断网时旧文件被删导致无 APK 可用。
  /// 重试：最多 [_maxRetries] 次，指数退避（1s / 2s / 4s）。
  static Future<File> downloadApk(
    GithubReleaseInfo release, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
    int maxRetries = 3,
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: _connectTimeout,
      receiveTimeout: const Duration(minutes: 30),
    ));
    final dir = await getExternalStorageDirectory() ??
        await getTemporaryDirectory();
    final savePath = '${dir.path}/${release.apkName}';
    final tempPath = '$savePath.tmp';

    DioException? lastError;

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // 删除旧的临时文件（上次中断残留）
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        await dio.download(
          release.apkDownloadUrl,
          tempPath,
          onReceiveProgress: onProgress,
          cancelToken: cancelToken,
        );

        // 下载成功，重命名到目标路径
        final finalFile = File(savePath);
        if (await finalFile.exists()) {
          await finalFile.delete();
        }
        await tempFile.rename(savePath);
        return finalFile;
      } on DioException catch (e) {
        lastError = e;
        // 用户主动取消，不重试
        if (e.type == DioExceptionType.cancel) rethrow;
        // 非最后一代，等待后重试
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    // 所有重试均失败，抛出明确错误
    throw lastError ?? DioException(
      requestOptions: RequestOptions(path: release.apkDownloadUrl),
      message: '下载 APK 失败（已重试 $maxRetries 次）',
    );
  }

  /// 调用系统安装器安装 APK
  ///
  /// Android 8+ 安装未知应用需要用户授权（REQUEST_INSTALL_PACKAGES）。
  /// 这里先检查权限：
  ///  - 已授权 → 直接拉起系统安装器
  ///  - 未授权 → 返回 [OpenResult]（type=permissionDenied），由调用方引导用户去设置页开启
  ///
  /// 注意：不使用 permission_handler 的 request 弹窗——该权限属于特殊权限，
  /// 系统不会弹授权对话框，必须跳转到系统“安装未知应用”设置页。
  static Future<OpenResult> installApk(File apkFile) async {
    if (Platform.isAndroid) {
      final hasPermission = await _hasInstallPermission();
      if (!hasPermission) {
        return OpenResult(type: ResultType.permissionDenied, message: 'permissionDenied');
      }
    }
    return await OpenFilex.open(apkFile.path);
  }

  /// 检查是否有“安装未知应用”权限（Android 8+）
  ///
  /// Android 8 以下系统无此权限概念，直接返回 true。
  /// permission_handler 内部会处理版本兼容（旧版本自动视为已授权）。
  static Future<bool> _hasInstallPermission() async {
    try {
      final status = await Permission.requestInstallPackages.status;
      return status.isGranted;
    } catch (_) {
      return true; // 查询失败时不拦截，交给系统安装器处理
    }
  }

  /// 打开系统“安装未知应用”设置页（用户授权后返回，可再次安装）
  static Future<bool> openInstallPermissionSettings() async {
    final status = await Permission.requestInstallPackages.request();
    return status.isGranted;
  }

  /// 版本比较：a > b（按 x.y.z 三段式比较）
  ///
  /// 例如：
  ///   1.0.10 > 1.0.9 → true
  ///   1.0.9  > 1.0.9 → false（相等不算更新）
  ///   1.2.0  > 1.1.5 → true
  static bool _isNewer(String a, String b) {
    final pa = _parseVersion(a);
    final pb = _parseVersion(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final av = i < pa.length ? pa[i] : 0;
      final bv = i < pb.length ? pb[i] : 0;
      if (av > bv) return true;
      if (av < bv) return false;
    }
    return false; // 完全相等
  }

  /// 解析版本号字符串为整数数组
  static List<int> _parseVersion(String v) {
    final clean = v.trim().toLowerCase().replaceAll(RegExp(r'^v'), '');
    final parts = clean.split(RegExp(r'[.\-+]'));
    return parts.map((s) => int.tryParse(s) ?? 0).toList();
  }

  /// Dio 错误信息友好化
  static String _dioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络后重试';
      case DioExceptionType.sendTimeout:
        return '发送请求超时';
      case DioExceptionType.receiveTimeout:
        return '接收响应超时';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code == 403 || code == 429) {
          return 'GitHub API 限流，请稍后再试';
        }
        return '服务器返回错误（$code）';
      case DioExceptionType.cancel:
        return '已取消';
      default:
        return '下载失败：${e.message}';
    }
  }
}
