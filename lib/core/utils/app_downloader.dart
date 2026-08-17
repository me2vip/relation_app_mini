/// 应用内 APK 下载管理器（增强版）
///
/// 在 [AppUpdateService.downloadApk] 单线程下载基础上，新增：
///   - 实时下载速度显示
///   - 剩余时间（ETA）推算
///   - 断点续传（HTTP Range）
///   - 暂停 / 继续 / 重新下载
///   - 多线程下载（可配置线程数，默认 3）
///
/// 典型用法：
/// ```dart
/// final downloader = AppDownloader(
///   url: release.apkDownloadUrl,
///   savePath: await AppDownloader.resolveSavePath(release.apkName),
///   onProgress: (p) => print('${p.percent}% ${p.speedText} 剩余 ${p.etaText}'),
/// );
/// try {
///   final file = await downloader.start(); // 开始 / 继续（自动断点续传）
/// } on DownloadPausedException {
///   // 用户暂停，可调用 downloader.start() 继续
/// }
/// // 暂停：downloader.pause();
/// // 重下：await downloader.reset(); await downloader.start();
/// ```
library app_downloader;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// 下载进度快照（含实时速度与剩余时间估算）
class DownloadProgress {
  /// 已接收字节数
  final int received;

  /// 总字节数（未知时为 0）
  final int total;

  /// 下载速度（字节/秒）
  final double speed;

  /// 预计剩余秒数（speed<=0 或 total 未知时为 null）
  final int? remainingSeconds;

  const DownloadProgress({
    required this.received,
    required this.total,
    required this.speed,
    this.remainingSeconds,
  });

  /// 进度比例 0~1（total 未知时为 0）
  double get fraction => total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;

  /// 百分比（0~100 整数）
  int get percent => (fraction * 100).round();

  String get speedText => _formatSpeed(speed);
  String get etaText =>
      remainingSeconds == null ? '--:--' : _formatDuration(remainingSeconds!);

  static String _formatSpeed(double bps) {
    if (bps <= 0) return '0 B/s';
    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var i = 0;
    var v = bps;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    final digits = (i == 0 || v >= 100) ? 0 : 1;
    return '${v.toStringAsFixed(digits)} ${units[i]}';
  }

  static String _formatDuration(int seconds) {
    final s = seconds.clamp(0, 359999);
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '${h.toString().padLeft(2, '0')}:$mm:$ss' : '$mm:$ss';
  }
}

/// 下载状态
enum DownloadStatus {
  idle,
  downloading,
  paused,
  completed,
  failed,
}

/// 用户主动暂停时由 [AppDownloader.start] 抛出，用于区分"暂停"与"失败"
class DownloadPausedException implements Exception {
  const DownloadPausedException();
  @override
  String toString() => '下载已暂停';
}

class AppDownloader {
  final String url;
  final String savePath;
  final void Function(DownloadProgress progress)? onProgress;

  /// 是否启用多线程（默认开启）
  bool enableMultiThread;

  /// 默认线程数（仅多线程模式生效，范围 1~8）
  int threadCount;

  final Dio _dio;
  final List<CancelToken> _activeTokens = [];
  DownloadStatus _status = DownloadStatus.idle;
  int _totalSize = 0;
  bool _supportsRange = false;

  // 进度采样
  Timer? _sampler;
  int _lastSampleReceived = 0;
  int _lastSampleTime = 0;
  int _singleReceived = 0;
  List<int>? _chunkReceived;

  AppDownloader({
    required this.url,
    required this.savePath,
    this.onProgress,
    this.enableMultiThread = true,
    this.threadCount = 3,
  }) : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(minutes: 30),
          headers: {
            'Accept': '*/*',
            'User-Agent': 'relation-app-mini-updater/1.0',
          },
        ));

  DownloadStatus get status => _status;

  /// 解析默认保存路径（与旧 [AppUpdateService.downloadApk] 一致）
  static Future<String> resolveSavePath(String apkName) async {
    final dir =
        await getExternalStorageDirectory() ?? await getTemporaryDirectory();
    return '${dir.path}/${apkName.isEmpty ? 'app-release.apk' : apkName}';
  }

  /// 开始 / 继续下载（幂等：已部分下载会从断点续传）
  Future<File> start() async {
    _stopSampler();
    _activeTokens.clear();
    _status = DownloadStatus.downloading;

    await _probe();

    // 未知大小：单线程从头（无法断点续传）
    if (_totalSize <= 0) {
      final tmp = File('$savePath.tmp');
      if (await tmp.exists()) await tmp.delete();
      return _downloadSingle(0, supportsRange: false);
    }

    final useMulti = enableMultiThread &&
        _supportsRange &&
        threadCount > 1 &&
        _totalSize >= _minMultiSize;

    if (useMulti) {
      try {
        return await _downloadMulti();
      } on DownloadPausedException {
        rethrow;
      } catch (_) {
        // 多线程失败：退化单线程续传
        final tmp = File('$savePath.tmp');
        if (await tmp.exists()) await tmp.delete();
        return _downloadSingle(0, supportsRange: _supportsRange);
      }
    } else {
      final offset = _supportsRange ? _resumeOffset() : 0;
      if (!_supportsRange) {
        final tmp = File('$savePath.tmp');
        if (await tmp.exists()) await tmp.delete();
      }
      return _downloadSingle(offset, supportsRange: _supportsRange);
    }
  }

  /// 暂停（保留已下载数据，可继续）
  void pause() {
    if (_status != DownloadStatus.downloading) return;
    _status = DownloadStatus.paused;
    for (final t in List.of(_activeTokens)) {
      t.cancel();
    }
    _activeTokens.clear();
    _stopSampler();
  }

  /// 重新下载（清空已下载数据，从头开始）
  Future<void> reset() async {
    _stopSampler();
    for (final t in List.of(_activeTokens)) {
      t.cancel();
    }
    _activeTokens.clear();
    _status = DownloadStatus.idle;
    final base = savePath;
    final toDelete = <String>[
      base,
      '$base.tmp',
      for (var i = 0; i < 8; i++) '$base.part$i',
    ];
    for (final p in toDelete) {
      final f = File(p);
      if (await f.exists()) await f.delete();
    }
    // 清理任意 .part 残留（线程数变化时数量可能不同）
    final dir = Directory(File(base).parent.path);
    if (await dir.exists()) {
      await for (final e in dir.list()) {
        if (e is File && e.path.startsWith('$base.part')) {
          await e.delete();
        }
      }
    }
  }

  /// 释放资源（对话框销毁时调用）
  void dispose() {
    _stopSampler();
    for (final t in List.of(_activeTokens)) {
      t.cancel();
    }
    _activeTokens.clear();
  }

  // ==========================================================================
  // 内部实现
  // ==========================================================================

  Future<void> _probe() async {
    try {
      final resp = await _dio.head(url);
      final cl = resp.headers.value('content-length');
      _totalSize = cl != null ? (int.tryParse(cl) ?? 0) : 0;
      final ar = (resp.headers.value('accept-ranges') ?? '').toLowerCase();
      _supportsRange = ar.contains('bytes');
    } catch (_) {
      _totalSize = 0;
      _supportsRange = false;
    }
  }

  int _resumeOffset() {
    final f = File('$savePath.tmp');
    return f.existsSync() ? f.lengthSync() : 0;
  }

  int _currentReceived() {
    if (_chunkReceived != null) {
      var sum = 0;
      for (final c in _chunkReceived!) {
        sum += c;
      }
      return sum;
    }
    return _singleReceived;
  }

  void _startSampler() {
    _lastSampleReceived = _currentReceived();
    _lastSampleTime = DateTime.now().millisecondsSinceEpoch;
    _stopSampler();
    _sampler = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _emitProgress();
    });
  }

  void _stopSampler() {
    _sampler?.cancel();
    _sampler = null;
  }

  void _emitProgress() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = now - _lastSampleTime;
    if (dt <= 0) return;
    final speed = (_currentReceived() - _lastSampleReceived) / (dt / 1000);
    final remaining = _totalSize > 0 ? _totalSize - _currentReceived() : 0;
    final eta = (speed > 0 && _totalSize > 0)
        ? (remaining / speed).round()
        : null;
    onProgress?.call(DownloadProgress(
      received: _currentReceived(),
      total: _totalSize,
      speed: speed,
      remainingSeconds: eta,
    ));
    _lastSampleReceived = _currentReceived();
    _lastSampleTime = now;
  }

  Future<File> _downloadSingle(int initialOffset,
      {required bool supportsRange}) async {
    final tempPath = '$savePath.tmp';
    final raf = await File(tempPath).open(mode: FileMode.append);
    _singleReceived = initialOffset;
    _chunkReceived = null;
    _startSampler();
    try {
      while (true) {
        if (_status == DownloadStatus.paused) {
          await raf.close();
          _stopSampler();
          throw const DownloadPausedException();
        }
        final token = CancelToken();
        _activeTokens.add(token);
        final headers = (supportsRange && _singleReceived > 0)
            ? {'Range': 'bytes=$_singleReceived-'}
            : null;
        final resp = await _dio.get<ResponseBody>(
          url,
          options: Options(
            responseType: ResponseType.stream,
            headers: headers,
          ),
          cancelToken: token,
        );
        _activeTokens.remove(token);
        final body = resp.data;
        if (body == null) {
          await raf.close();
          _stopSampler();
          throw Exception('下载响应为空');
        }
        await for (final chunk in body.stream) {
          if (_status == DownloadStatus.paused) {
            await raf.close();
            _stopSampler();
            throw const DownloadPausedException();
          }
          raf.writeFromSync(chunk);
          _singleReceived += chunk.length;
        }
        // 单线程下载完成
        await raf.close();
        _stopSampler();
        final target = File(savePath);
        if (await target.exists()) await target.delete();
        await File(tempPath).rename(savePath);
        _status = DownloadStatus.completed;
        onProgress?.call(DownloadProgress(
          received: _singleReceived,
          total: _totalSize > 0 ? _totalSize : _singleReceived,
          speed: 0,
          remainingSeconds: 0,
        ));
        return target;
      }
    } catch (e) {
      await raf.close();
      _stopSampler();
      if (e is DownloadPausedException) rethrow;
      if (_status == DownloadStatus.paused) {
        throw const DownloadPausedException();
      }
      _status = DownloadStatus.failed;
      rethrow;
    }
  }

  Future<File> _downloadMulti() async {
    final partCount = threadCount.clamp(1, 8);
    final chunkSize = (_totalSize / partCount).ceil();
    final parts = <_Chunk>[];
    for (var i = 0; i < partCount; i++) {
      final start = i * chunkSize;
      final end = (i == partCount - 1) ? _totalSize - 1 : start + chunkSize - 1;
      if (start <= end) {
        parts.add(_Chunk(
          index: i,
          start: start,
          end: end,
          path: '$savePath.part$i',
        ));
      }
    }
    _chunkReceived = List.filled(parts.length, 0);
    // 初始化已下载基线（断点续传）
    for (var i = 0; i < parts.length; i++) {
      final pf = File(parts[i].path);
      if (await pf.exists()) {
        _chunkReceived![i] = await pf.length();
      }
    }
    _startSampler();
    final futures = <Future>[];
    for (final part in parts) {
      futures.add(_downloadChunk(part));
    }
    try {
      await Future.wait(futures);
    } on DownloadPausedException {
      _stopSampler();
      rethrow;
    } catch (e) {
      _stopSampler();
      if (_status == DownloadStatus.paused) {
        throw const DownloadPausedException();
      }
      rethrow;
    }
    _stopSampler();

    // 合并分块
    final target = File(savePath);
    if (await target.exists()) await target.delete();
    final sink = target.openWrite();
    for (final part in parts) {
      final pf = File(part.path);
      if (await pf.exists()) {
        sink.add(await pf.readAsBytes());
        await pf.delete();
      }
    }
    await sink.close();
    _status = DownloadStatus.completed;
    onProgress?.call(DownloadProgress(
      received: _totalSize,
      total: _totalSize,
      speed: 0,
      remainingSeconds: 0,
    ));
    return target;
  }

  Future<void> _downloadChunk(_Chunk part) async {
    var offset = 0;
    final pf = File(part.path);
    if (await pf.exists()) {
      offset = await pf.length();
    }
    final start = part.start + offset;
    if (start > part.end) {
      // 整块已完成
      _chunkReceived![part.index] = part.end - part.start + 1;
      return;
    }
    final raf = await File(part.path).open(mode: FileMode.append);
    final token = CancelToken();
    _activeTokens.add(token);
    try {
      final resp = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Range': 'bytes=$start-${part.end}'},
        ),
        cancelToken: token,
      );
      _activeTokens.remove(token);
      final body = resp.data;
      if (body == null) {
        await raf.close();
        throw Exception('分块响应为空');
      }
      await for (final chunk in body.stream) {
        if (_status == DownloadStatus.paused) {
          await raf.close();
          throw const DownloadPausedException();
        }
        raf.writeFromSync(chunk);
        _chunkReceived![part.index] += chunk.length;
      }
      await raf.close();
    } catch (e) {
      await raf.close();
      _activeTokens.remove(token);
      if (e is DownloadPausedException) rethrow;
      if (e is DioException &&
          e.type == DioExceptionType.cancel &&
          _status == DownloadStatus.paused) {
        throw const DownloadPausedException();
      }
      rethrow;
    }
  }

  /// 多线程下载的最小文件体积（小于此值不值得多线程）
  static const int _minMultiSize = 1024 * 1024; // 1MB
}

class _Chunk {
  final int index;
  final int start;
  final int end;
  final String path;
  _Chunk({
    required this.index,
    required this.start,
    required this.end,
    required this.path,
  });
}
