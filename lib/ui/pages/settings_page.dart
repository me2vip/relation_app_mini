import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/app_provider.dart';
import '../../core/widgets/update_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _pushNotification = true;
  bool _dailySummary = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _pushNotification = prefs.getBool('push_notification') ?? true;
      _dailySummary = prefs.getBool('daily_summary') ?? true;
    });
  }
  
  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'AI设置',
            children: [
              _SettingsTile(
                icon: Icons.smart_toy_outlined,
                title: 'AI模型配置',
                subtitle: '管理AI模型和API密钥',
                onTap: () => Navigator.pushNamed(context, '/ai'),
              ),
              _SettingsTile(
                icon: Icons.auto_awesome,
                title: '任务生成配置',
                subtitle: '设置AI生成任务的规则',
                onTap: () => Navigator.pushNamed(context, '/ai'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: '通知设置',
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: '通知管理',
                subtitle: '推送通知、任务提醒、每日汇总',
                onTap: () => Navigator.pushNamed(context, '/notification-settings'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: '隐私设置',
            children: [
              _SettingsTile(
                icon: Icons.security_outlined,
                title: '隐私管理',
                subtitle: '数据安全、应用锁、数据备份',
                onTap: () => Navigator.pushNamed(context, '/privacy-settings'),
              ),
              _SettingsTile(
                icon: Icons.color_lens_outlined,
                title: '氛围配置',
                subtitle: '设置向不同人展示的信息',
                onTap: () => Navigator.pushNamed(context, '/atmosphere-config'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: '外观',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: '深色模式',
                subtitle: '切换深色/浅色主题',
                trailing: Switch(
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    _saveSetting('dark_mode', value);
                    // TODO: 实际切换主题
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: '关于',
            children: [
              Consumer<AppProvider>(
                builder: (context, app, _) {
                  return _SettingsTile(
                    icon: Icons.info_outline,
                    title: '关于应用',
                    subtitle: 'v${app.currentVersion}',
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.system_update_rounded,
                title: '检查更新',
                subtitle: '检查是否有新版本可用',
                onTap: () => _checkForUpdate(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 升级提示（当有新版本时）
          Consumer<AppProvider>(
            builder: (context, app, _) {
              if (app.hasUpdate && app.latestRelease != null) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Card(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    child: ListTile(
                      leading: const Icon(
                        Icons.system_update,
                        color: Color(0xFF6366F1),
                      ),
                      title: Text(
                        '发现新版本 v${app.latestRelease!.version}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      subtitle: Text(
                        app.latestRelease!.releaseNotes.split('\n').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF6366F1),
                      ),
                      onTap: () => _showUpdateDialog(context, app),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
  
  /// 主动检查更新：先刷新 AppProvider 状态（供首页/设置页角标使用），
  /// 再弹出手动更新对话框（下载 APK + 安装）。
  Future<void> _checkForUpdate(BuildContext context) async {
    final app = context.read<AppProvider>();
    await app.checkForUpdate();
    if (!mounted) return;
    await UpdateDialog.show(context);
  }

  void _showUpdateDialog(BuildContext context, AppProvider app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              '版本: ${app.latestRelease!.version}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              '大小: ${app.latestRelease!.apkSizeMB} MB',
              style: const TextStyle(color: Colors.grey),
            ),
            if (app.latestRelease!.releaseNotes.isNotEmpty) ...[
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
                    app.latestRelease!.releaseNotes,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍后更新'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              UpdateDialog.show(context);
            },
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6366F1)),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: onTap,
    );
  }
}
