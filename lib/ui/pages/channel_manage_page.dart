import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/channel_provider.dart';
import '../../models/channel.dart';

/// 社交途径管理页：定义与联系人的联系渠道（线下/微信/QQ/抖音等）
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
      body: Consumer<ChannelProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 说明卡片
              Card(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Color(0xFF6366F1), size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '联系渠道',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '定义你与联系人的联系途径，可在联系人详情页为每个联系人配置具体账号',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 途径列表
              if (provider.channels.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('暂无社交途径', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...provider.channels.map((channel) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          channel.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(channel.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500)),
                          if (channel.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '默认',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: channel.description != null &&
                              channel.description!.isNotEmpty
                          ? Text(channel.description!,
                              style: const TextStyle(fontSize: 12))
                          : null,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _editChannel(channel);
                          if (value == 'delete') _deleteChannel(channel);
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
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('删除'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
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
        ),
      );
    }
  }

  Future<void> _deleteChannel(SocialChannel channel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除途径「${channel.name}」吗？\n联系人与该途径的关联也会一并删除。'),
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel?.name ?? '');
    _descController =
        TextEditingController(text: widget.channel?.description ?? '');
    _icon = widget.channel?.icon ?? '🔗';
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
            const Text('选择图标', style: TextStyle(fontSize: 14)),
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
