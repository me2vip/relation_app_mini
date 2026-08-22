import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/channel_provider.dart';
import '../../core/providers/channel_config_provider.dart';
import '../../models/channel.dart';
import '../../models/social_channel_config.dart';

/// 社交途径管理页：定义与联系人的联系渠道（线下/微信/QQ/抖音等）
/// 每个渠道与联系人的社交配置（ContactChannelConfig）关联，可查看多少人在用此渠道。
class ChannelManagePage extends StatefulWidget {
  const ChannelManagePage({super.key});

  @override
  State<ChannelManagePage> createState() => _ChannelManagePageState();
}

/// 可选图标（emoji）
const List<String> kChannelEmojis = [
  '🤝', '💬', '🐧', '🎬', '🎵', '📕', '⚔️', '🔫',
  '📞', '✉️', '📰', '📺', '📷', '🎮', '🏀', '⚽',
  '🎤', '🎨', '💼', '🏫', '🏠', '☕', '🍺', '✈️',
  '🐱', '🐶', '🌱', '💡', '🔗', '📌', '🌟', '🎯',
];

/// 内置平台枚举下拉选项（映射到 SocialChannel.platformKey）
const List<Map<String, dynamic>> kPlatformKeyOptions = [
  {'key': 'custom', 'label': '自定义平台', 'emoji': '✨'},
  {'key': 'wechat', 'label': '微信', 'emoji': '💚'},
  {'key': 'qq', 'label': 'QQ', 'emoji': '🐧'},
  {'key': 'douyin', 'label': '抖音', 'emoji': '🎵'},
  {'key': 'kuaishou', 'label': '快手', 'emoji': '🎬'},
  {'key': 'xiaohongshu', 'label': '小红书', 'emoji': '📕'},
  {'key': 'weibo', 'label': '微博', 'emoji': '📰'},
  {'key': 'bilibili', 'label': 'B站', 'emoji': '📺'},
  {'key': 'wangzhe', 'label': '王者荣耀', 'emoji': '⚔️'},
  {'key': 'pubg', 'label': '和平精英', 'emoji': '🔫'},
  {'key': 'offline', 'label': '线下', 'emoji': '🤝'},
  {'key': 'phone', 'label': '电话', 'emoji': '📞'},
  {'key': 'sms', 'label': '短信', 'emoji': '✉️'},
];

class _ChannelManagePageState extends State<ChannelManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('社交途径管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加途径',
            onPressed: () => _addChannel(),
          ),
        ],
      ),
      body: Consumer2<ChannelProvider, ChannelConfigProvider>(
        builder: (context, provider, configProvider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHintCard(),
              const SizedBox(height: 16),
              if (provider.channels.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('暂无社交途径', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...provider.channels.map((channel) {
                  final platformCfg = resolvePlatformConfig(
                    channel.platform, channel.name, channel.icon,
                  );
                  final usedBy = configProvider.contactCountForChannel(
                    channel.id, channel.platform, channel.name,
                  );
                  return _buildChannelCard(
                    channel: channel,
                    platformCfg: platformCfg,
                    usedBy: usedBy,
                  );
                }),
              const SizedBox(height: 24),
              // 底部说明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        const Text('提示', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 默认途径不可删除，但可编辑图标和描述\n'
                      '• 被联系人使用的途径（人数>0），删除将清除关联配置\n'
                      '• 内置平台（微信/QQ等）与互动任务生成关联；自定义平台会使用通用配色和功能',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHintCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.hub, color: Color(0xFF6366F1), size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '社交途径与关联联系人',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '定义联系渠道（微信/QQ/线下等），并为每个联系人配置具体账号。',
                    style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard({
    required SocialChannel channel,
    required PlatformConfig platformCfg,
    required int usedBy,
  }) {
    final accent = platformCfg.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: accent.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.18), accent.withOpacity(0.06)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(channel.icon, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        channel.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (channel.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '默认',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(platformCfg.emoji, style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 3),
                            Text(
                              platformCfg.name,
                              style: TextStyle(fontSize: 11, color: accent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (channel.description != null && channel.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        channel.description!,
                        style: const TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$usedBy 位联系人',
                          style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editChannel(channel);
                if (value == 'delete') _deleteChannel(channel, usedBy);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('编辑'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  enabled: !channel.isDefault,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: channel.isDefault ? Colors.grey : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        channel.isDefault ? '默认途径不可删除' : '删除',
                        style: TextStyle(
                          color: channel.isDefault ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addChannel() async {
    final result = await showDialog<SocialChannel>(
      context: context,
      builder: (context) => const _ChannelEditDialog(),
    );
    if (result != null && mounted) {
      final provider = context.read<ChannelProvider>();
      await provider.addChannel(
        name: result.name,
        icon: result.icon,
        description: result.description,
        platformKey: result.platformKey,
      );
    }
  }

  Future<void> _editChannel(SocialChannel channel) async {
    final result = await showDialog<SocialChannel>(
      context: context,
      builder: (context) => _ChannelEditDialog(channel: channel),
    );
    if (result != null && mounted) {
      final provider = context.read<ChannelProvider>();
      await provider.updateChannel(
        channel.copyWith(
          name: result.name,
          icon: result.icon,
          description: result.description,
          platformKey: result.platformKey,
        ),
      );
    }
  }

  Future<void> _deleteChannel(SocialChannel channel, int usedBy) async {
    if (channel.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('默认途径不可删除')),
      );
      return;
    }

    String message = '确定要删除途径「${channel.name}」吗？';
    if (usedBy > 0) {
      message += '\n\n$usedBy 位联系人使用此途径，删除后关联的配置将失效（可在联系人详情中重新配置）。';
    } else {
      message += '\n暂无联系人使用此途径，可以安全删除。';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ChannelProvider>();
      await provider.deleteChannel(channel.id);
      if (usedBy > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${channel.name}」途径已删除；若要清理关联配置请编辑联系人'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// 途径添加/编辑对话框
class _ChannelEditDialog extends StatefulWidget {
  final SocialChannel? channel;

  const _ChannelEditDialog({this.channel});

  @override
  State<_ChannelEditDialog> createState() => _ChannelEditDialogState();
}

class _ChannelEditDialogState extends State<_ChannelEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _icon;
  late String _platformKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel?.name ?? '');
    _descController =
        TextEditingController(text: widget.channel?.description ?? '');
    _icon = widget.channel?.icon ?? '🔗';
    _platformKey = widget.channel?.platformKey ?? 'custom';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.channel == null ? '添加途径' : '编辑途径'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '途径名称 *',
                hintText: '例如：微信、QQ、线下、抖音',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 平台映射选择
            const Text('平台映射（用于颜色、互动任务配置）',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kPlatformKeyOptions.map((opt) {
                final selected = opt['key'] == _platformKey;
                return InkWell(
                  onTap: () => setState(() {
                    _platformKey = opt['key'] as String;
                    // 若名称为空，自动填充
                    if (_nameController.text.trim().isEmpty &&
                        opt['key'] != 'custom') {
                      _nameController.text = opt['label'] as String;
                    }
                    // 同步默认图标
                    if (widget.channel == null &&
                        opt['key'] != 'custom') {
                      final ch = SocialChannel(
                        id: '',
                        name: opt['label'] as String,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        platformKey: opt['key'] as String,
                      );
                      if (ch.platform != SocialPlatform.custom) {
                        final cfg = getPlatformConfig(ch.platform);
                        setState(() => _icon = cfg.emoji);
                      }
                    }
                  }),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF6366F1).withOpacity(0.12) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: const Color(0xFF6366F1), width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${opt['emoji']} ${opt['label']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: selected ? const Color(0xFF6366F1) : Colors.black87,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('选择图标', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kChannelEmojis.map((emoji) {
                final selected = emoji == _icon;
                return InkWell(
                  onTap: () => setState(() => _icon = emoji),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF6366F1).withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(color: const Color(0xFF6366F1), width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            final now = DateTime.now();
            Navigator.pop(
              context,
              SocialChannel(
                id: widget.channel?.id ?? '',
                name: _nameController.text.trim(),
                icon: _icon,
                platformKey: _platformKey,
                description: _descController.text.trim().isEmpty
                    ? null
                    : _descController.text.trim(),
                isDefault: widget.channel?.isDefault ?? false,
                createdAt: widget.channel?.createdAt ?? now,
                updatedAt: now,
              ),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
