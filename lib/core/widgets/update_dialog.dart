/// 应用内更新对话框
///
/// 调用 [AppUpdateService.checkForUpdate] 检查 GitHub Release，
/// 有新版本时弹出此对话框，用户确认后下载 APK 并调起系统安装器。
///
/// 下载过程支持：
///   - 实时下载速度显示
///   - 剩余时间（ETA）推算
///   - 断点续传（中断后可继续，不从头重下）
///   - 暂停 / 继续 / 重新下载
///   - 多线程下载（可设置默认线程数）
library update_dialog;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../utils/app_downloader.dart';
import '../utils/app_update_service.dart';

/// 更新对话框状态
enum _UpdateState { idle, downloading, paused, installing, done, error }

class UpdateDialog {
  UpdateDialog._();

  /// 入口：检查 → 弹对话框（含进度）
  ///
  /// 调用方式：`UpdateDialog.show(context);`
  /// 流程：检查 → 有新版本则弹窗 → 用户点"立即下载" → 下载 → 调起系统安装器
  static Future<void> show(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CheckingDialog(),
    );
  }
}

// ============================================================================
// 检查中
// ============================================================================

class _CheckingDialog extends StatefulWidget {
  const _CheckingDialog();

  @override
  State<_CheckingDialog> createState() => _CheckingDialogState();
}

class _CheckingDialogState extends State<_CheckingDialog> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final outcome = await AppUpdateService.checkForUpdate();
    if (!mounted) return;
    Navigator.of(context).pop(); // 关闭检查中对话框
    if (!mounted) return;
    switch (outcome.result) {
      case UpdateCheckResult.hasUpdate:
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _UpdateContentDialog(
            release: outcome.releaseInfo!,
            currentVersion: outcome.currentVersion,
          ),
        );
        break;
      case UpdateCheckResult.upToDate:
        _toast('当前已是最新版（v${outcome.currentVersion}）');
        break;
      case UpdateCheckResult.noAsset:
        _toast('检测到新版本 ${outcome.releaseInfo?.version}，但暂未上传 APK，'
            '请稍后再试或在浏览器打开 Release 页面下载');
        break;
      case UpdateCheckResult.error:
        _toast('检查更新失败：${outcome.errorMessage}');
        break;
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在检查更新...', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 更新内容对话框（含下载进度 / 速度 / 剩余时间 / 暂停继续）
// ============================================================================

class _UpdateContentDialog extends StatefulWidget {
  final GithubReleaseInfo release;
  final String currentVersion;

  const _UpdateContentDialog({
    required this.release,
    required this.currentVersion,
  });

  @override
  State<_UpdateContentDialog> createState() => _UpdateContentDialogState();
}

class _UpdateContentDialogState extends State<_UpdateContentDialog> {
  _UpdateState _state = _UpdateState.idle;
  DownloadProgress? _progress;
  String _errorMsg = '';

  AppDownloader? _downloader;
  int _threadCount = 3;
  bool _multiThread = true;

  @override
  void dispose() {
    _downloader?.dispose();
    super.dispose();
  }

  /// 开始 / 继续 / 重新下载的统一入口
  Future<void> _runDownload() async {
    setState(() {
      _state = _UpdateState.downloading;
      _errorMsg = '';
    });
    try {
      _downloader ??= AppDownloader(
        url: widget.release.apkDownloadUrl,
        savePath: await AppDownloader.resolveSavePath(widget.release.apkName),
        onProgress: (p) => setState(() => _progress = p),
        enableMultiThread: _multiThread,
        threadCount: _threadCount,
      );
      _downloader!
        ..enableMultiThread = _multiThread
        ..threadCount = _threadCount;
      final file = await _downloader!.start();
      if (!mounted) return;
      setState(() => _state = _UpdateState.installing);
      // 调起系统安装器
      final result = await AppUpdateService.installApk(file);
      if (!mounted) return;
      setState(() => _state = _UpdateState.done);
      if (result.message.isNotEmpty) {
        _toast('已下载完成。${result.message}');
      }
      if (mounted) Navigator.of(context).pop();
    } on DownloadPausedException {
      if (!mounted) return;
      setState(() => _state = _UpdateState.paused);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _UpdateState.error;
        _errorMsg = e.toString();
      });
    }
  }

  /// 暂停（保留已下载数据）
  void _pause() {
    _downloader?.pause();
    if (mounted) setState(() => _state = _UpdateState.paused);
  }

  /// 继续（从断点续传）
  Future<void> _resume() async {
    if (_downloader == null) {
      await _runDownload();
      return;
    }
    _downloader!
      ..enableMultiThread = _multiThread
      ..threadCount = _threadCount;
    await _runDownload();
  }

  /// 重新下载（清空已下载数据，从头开始）
  Future<void> _redownload() async {
    try {
      await _downloader?.reset();
    } catch (_) {
      // 忽略清理失败，继续
    }
    if (!mounted) return;
    setState(() => _progress = null);
    await _runDownload();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  String get _receivedMB {
    final r = _progress?.received ?? 0;
    return (r / 1024 / 1024).toStringAsFixed(1);
  }

  String get _totalMB {
    final t = _progress?.total ?? 0;
    return t > 0
        ? (t / 1024 / 1024).toStringAsFixed(1)
        : widget.release.apkSizeMB;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Row(
                children: [
                  Icon(Icons.system_update_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '发现新版本 v${widget.release.version}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '当前版本 v${widget.currentVersion} → 新版本 v${widget.release.version}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const Divider(height: 20),

              // 发行说明
              Flexible(
                child: SingleChildScrollView(
                  child: widget.release.releaseNotes.trim().isEmpty
                      ? Text(
                          '暂无发行说明',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        )
                      : MarkdownBody(
                          data: widget.release.releaseNotes,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 13),
                            h2: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                            h3: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // 下载进度 / 速度 / 剩余时间
              if (_state == _UpdateState.downloading ||
                  _state == _UpdateState.paused)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: _progress?.fraction),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_progress?.percent ?? 0}%',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_progress?.speedText ?? '0 B/s'} · 剩余 ${_progress?.etaText ?? '--:--'}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_receivedMB / $_totalMB MB',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (_state == _UpdateState.paused)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '已暂停（可从断点继续）',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: cs.primary),
                        ),
                      ),
                  ],
                )
              else if (_state == _UpdateState.installing)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('正在调起系统安装器...',
                        style: TextStyle(fontSize: 13)),
                  ],
                )
              else if (_state == _UpdateState.error)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '下载失败：$_errorMsg',
                    style: TextStyle(fontSize: 12, color: cs.onErrorContainer),
                  ),
                ),

              const SizedBox(height: 12),

              // 多线程 / 线程数设置（仅 idle / paused 可调整）
              if (_state == _UpdateState.idle ||
                  _state == _UpdateState.paused)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('多线程', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _multiThread,
                      onChanged: _state == _UpdateState.idle
                          ? (v) => setState(() => _multiThread = v)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('线程数', style: TextStyle(fontSize: 12)),
                    DropdownButton<int>(
                      value: _threadCount,
                      items: const [1, 2, 3, 4, 5, 6, 8]
                          .map((n) => DropdownMenuItem(
                                value: n,
                                child: Text('$n'),
                              ))
                          .toList(),
                      onChanged: (_multiThread &&
                              _state == _UpdateState.idle)
                          ? (n) =>
                              setState(() => _threadCount = n ?? _threadCount)
                          : null,
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // 按钮
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    switch (_state) {
      case _UpdateState.idle:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('稍后再说'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _runDownload,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('立即更新'),
            ),
          ],
        );
      case _UpdateState.downloading:
        // 下载中：仅允许暂停，禁用关闭避免误操作
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pause,
              icon: const Icon(Icons.pause_rounded, size: 18),
              label: const Text('暂停'),
            ),
          ],
        );
      case _UpdateState.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _redownload,
              child: const Text('重新下载'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _resume,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('继续'),
            ),
          ],
        );
      case _UpdateState.error:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _runDownload,
              child: const Text('重试'),
            ),
          ],
        );
      case _UpdateState.installing:
      case _UpdateState.done:
        return const SizedBox.shrink();
    }
  }
}
