import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.auto_awesome,
                title: '任务生成配置',
                subtitle: '设置AI生成任务的规则',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: '通知设置',
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: '推送通知',
                subtitle: '任务提醒和更新通知',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              _SettingsTile(
                icon: Icons.schedule,
                title: '每日汇总',
                subtitle: '每天早上发送任务汇总',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: '隐私设置',
            children: [
              _SettingsTile(
                icon: Icons.security_outlined,
                title: '数据安全',
                subtitle: '加密和备份设置',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: '应用锁',
                subtitle: '设置应用密码',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.color_lens_outlined,
                title: '氛围配置',
                subtitle: '设置向不同人展示的信息',
                onTap: () {},
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
                  value: false,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: '关于',
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: '版本信息',
                subtitle: 'v1.0.0',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: '使用条款',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: '隐私政策',
                onTap: () {},
              ),
            ],
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
