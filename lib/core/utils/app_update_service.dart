/// 应用内自动更新服务
///
/// 通过 GitHub Release API 检查最新版本，下载 APK 后调用系统安装器安装。
library app_update_service;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// GitHub Release 元信息
class GithubReleaseInfo {
  final String tagName;
  final String version;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String apkName;
  final int apkSize;
  final DateTime publishedAt;
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

  bool get hasApkAsset => apkDownloadUrl.isNotEmpty;

  String get apkSizeMB {
    if (apkSize <= 0) return '未知';
    return (apkSize / 1024 / 1024).toStringAsFixed(1);
  }
}

enum UpdateCheckResult {
  hasUpdate,
  upToDate,
  error,
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

  static const _repoOwner = 'me2vip';
  static const _repoName = 'relation_app_mini';

  static const _apiReleases =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases?per_page=100';

  static const _releasePageUrl =
      'https://github.com/$_repoOwner/$_repoName/releases/latest';

  static const _connectTimeout = Duration(seconds: 15);
  static const _receiveTimeout = Duration(seconds: 15);
  static const _maxRetries = 3;

  static Dio _createDio() {
    return Dio(BaseOptions(
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'relation-app-mini-updater/1.0',
      },
    ));
  }

  static Future<UpdateCheckOutcome> checkForUpdate() async {
    final currentInfo = await PackageInfo.fromPlatform();
    final currentVersion = currentInfo.version;

    final dio = _createDio();
    try {
      final resp = await dio.get(_apiReleases);
      if (resp.statusCode != 200) {
        return UpdateCheckOutcome(
          result: UpdateCheckResult.error,
          errorMessage: 'GitHub API 返回状态码 ${resp.statusCode}',
          currentVersion: currentVersion,
        );
      }

      final list = (resp.data is List) ? (resp.data as List) : <dynamic>[];

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

      releases.sort((a, b) {
        final ta = DateTime.tryParse((a['published_at'] ?? '').toString()) ??
            DateTime(1970);
        final tb = DateTime.tryParse((b['published_at'] ?? '').toString()) ??
            DateTime(1970);
        return tb.compareTo(ta);
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

      final assets = data['assets'] is List
          ? (data['assets'] as List)
          : <dynamic>[];
      String apkUrl = '';
      String apkName = '';
      int apkSize = 0;

      final apks = <Map<String, dynamic>>[];
      for (final a in assets) {
        if (a is! Map<String, dynamic>) continue;
        final name = (a['name'] ?? '').toString().toLowerCase();
        if (name.endsWith('.apk')) apks.add(a);
      }

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

      if (!releaseInfo.hasApkAsset) {
        return UpdateCheckOutcome(
          result: UpdateCheckResult.noAsset,
          releaseInfo: releaseInfo,
          currentVersion: currentVersion,
        );
      }

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

        final finalFile = File(savePath);
        if (await finalFile.exists()) {
          await finalFile.delete();
        }
        await tempFile.rename(savePath);
        return finalFile;
      } on DioException catch (e) {
        lastError = e;
        if (e.type == DioExceptionType.cancel) rethrow;
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    throw lastError ?? DioException(
      requestOptions: RequestOptions(path: release.apkDownloadUrl),
      message: '下载 APK 失败（已重试 $maxRetries 次）',
    );
  }

  static Future<OpenResult> installApk(File apkFile) async {
    return await OpenFilex.open(apkFile.path);
  }

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
    return false;
  }

  static List<int> _parseVersion(String v) {
    final clean = v.trim().toLowerCase().replaceAll(RegExp(r'^v'), '');
    final parts = clean.split(RegExp(r'[.\-+]'));
    return parts.map((s) => int.tryParse(s) ?? 0).toList();
  }

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
