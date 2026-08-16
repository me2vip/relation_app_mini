import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/utils/app_update_service.dart';

class UpdateDialog extends StatefulWidget {
  final GithubReleaseInfo release;

  const UpdateDialog({super.key, required this.release});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0;
  String _statusText = '准备下载...';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Color(0xFF6366F1)),
          SizedBox(width: 10),
          Text('发现新版本'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '版本: ${widget.release.version}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            '大小: ${widget.release.apkSizeMB} MB',
            style: const TextStyle(color: Colors.grey),
          ),
          if (widget.release.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 15),
            const Text(
              '更新内容:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 5),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  widget.release.releaseNotes,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
          if (_isDownloading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
            ),
            const SizedBox(height: 5),
            Text(
              _statusText,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后更新'),
          ),
          ElevatedButton(
            onPressed: _downloadAndInstall,
            child: const Text('立即更新'),
          ),
        ],
      ],
    );
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _statusText = '正在下载...';
    });

    try {
      final file = await AppUpdateService.downloadApk(
        widget.release,
        onProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _progress = received / total;
              _statusText = '${(_progress * 100).toInt()}%';
            });
          }
        },
      );

      setState(() {
        _statusText = '下载完成，正在安装...';
      });

      final result = await AppUpdateService.installApk(file);

      if (mounted) {
        if (result.type == OpenResultType.done) {
          // 安装成功，退出应用
          Navigator.pop(context);
        } else {
          setState(() {
            _statusText = '安装失败，请手动安装';
            _isDownloading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = '下载失败: $e';
          _isDownloading = false;
        });
      }
    }
  }
}
