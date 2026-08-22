import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/channel_provider.dart';
import '../../core/providers/channel_config_provider.dart';
import '../../models/channel.dart';
import '../../models/social_channel_config.dart';

/// 社交途径管理页：定义与联系人的联系渠道（线下/微信/QQ/抖音等）
///
/// 支持两级结构：
/// - 父途径（如「微信」）
/// - 子途径（如「私聊 / 朋友圈 / 微信群」）
///
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
  '🔖', '🎥', '👥', '📸', '🍜', '🏕️', '🆘', '⏰',
  '🎉', '📝',
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
  /// 展开的父途径 id 集合（用于折叠/展开子途径）
  final Set<String> _expandedIds = <String>{};

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
          final parents = provider.parentChannels;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHintCard(),
              const SizedBox(height: 16),
              if (parents.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('暂无社交途径', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...parents.map((parent) {
                  final platformCfg = resolvePlatformConfig(
                    parent.platform, parent.name, parent.icon,
                  );
                  final usedBy = configProvider.contactCountForChannel(
                    parent.id, parent.platform, parent.name,
                  );
                  final subs = provider.subChannelsOf(parent.id);
                  return _buildParentCard(
                    parent: parent,
                    platformCfg: platformCfg,
                    usedBy: usedBy,
                    subs: subs,
                    provider: provider,
                    configProvider: configProvider,
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
                      '• 父途径与子途径：如「微信」（父）→「私聊 / 朋友圈 / 微信群」（子）\n'
                      '• 默认途径不可删除，但可编辑图标和描述\n'
                      '• 删除父途径会同时删除它的全部子途径\n'
                      '• 被联系人使用的途径（人数>0），删除后关联配置保留快照名避免空白',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.55),
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
                    '社交途径 · 父/子两级管理',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '定义联系渠道（微信/QQ/线下等），再为每个渠道设置具体场景（私聊/朋友圈等），联系人可精确到子场景。',
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

  Widget _buildParentCard({
    required SocialChannel parent,
    required PlatformConfig platformCfg,
    required int usedBy,
    required List<SocialChannel> subs,
    required ChannelProvider provider,
    required ChannelConfigProvider configProvider,
  }) {
    final accent = platformCfg.color;
    final isExpanded = _expandedIds.contains(parent.id);
    final subCount = subs.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: accent.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.22), accent.withOpacity(0.06)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(parent.icon, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              parent.name,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (parent.isDefault)
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                  style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      if (parent.description != null && parent.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            parent.description!,
                            style: const TextStyle(fontSize: 12.5, color: Colors.black45),
                          ),
                        ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
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
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (subCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$subCount 个子途径',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
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
                    if (value == 'edit') _editChannel(parent);
                    if (value == 'addSub') _addSubChannel(parent);
                    if (value == 'delete') _deleteChannel(parent, usedBy, subCount);
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
                    const PopupMenuItem(
                      value: 'addSub',
                      child: Row(
                        children: [
                          Icon(Icons.account_tree_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('添加子途径'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: !parent.isDefault,
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: parent.isDefault ? Colors.grey : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            parent.isDefault ? '默认途径不可删除' : '删除途径',
                            style: TextStyle(
                              color: parent.isDefault ? Colors.grey : null,
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
          // 展开/折叠按钮与子途径列表
          if (subs.isNotEmpty)
            Column(
              children: [
                InkWell(
                  onTap: () => setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(parent.id);
                    } else {
                      _expandedIds.add(parent.id);
                    }
                  }),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: accent,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpanded ? '收起子途径' : '展开子途径（$subCount）',
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _addSubChannel(parent),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('新增', style: TextStyle(fontSize: 13)),
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: subs.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        final subUsedBy = configProvider.contactCountBySubChannelId(s.id);
                        return Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                          child: _buildSubRow(
                            sub: s,
                            accent: accent,
                            usedBy: subUsedBy,
                            parent: parent,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            )
          else
            // 无子途径：显示一个提示条 + 一键添加
            InkWell(
              onTap: () => _addSubChannel(parent),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.04),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(
                    top: BorderSide(color: accent.withOpacity(0.08)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_tree_outlined, size: 18, color: accent.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '尚未设置子途径，点击添加（如：私聊 / 朋友圈 / 微信群）',
                        style: TextStyle(fontSize: 13, color: accent.withOpacity(0.85)),
                      ),
                    ),
                    Icon(Icons.add_circle_outline, size: 18, color: accent),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubRow({
    required SocialChannel sub,
    required Color accent,
    required int usedBy,
    required SocialChannel parent,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withOpacity(0.15)),
            ),
            alignment: Alignment.center,
            child: Text(sub.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sub.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sub.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          '默认',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (sub.description != null && sub.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      sub.description!,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (usedBy > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$usedBy 位联系人用此场景',
                      style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _editChannel(sub);
              if (value == 'delete') _deleteChannel(sub, usedBy, 0);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 17),
                    SizedBox(width: 8),
                    Text('编辑', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                enabled: !sub.isDefault,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 17,
                      color: sub.isDefault ? Colors.grey : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      sub.isDefault ? '默认子途径不可删除' : '删除',
                      style: TextStyle(
                        fontSize: 14,
                        color: sub.isDefault ? Colors.grey : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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

  Future<void> _addSubChannel(SocialChannel parent) async {
    final result = await showDialog<SocialChannel>(
      context: context,
      builder: (context) => _ChannelEditDialog(parent: parent),
    );
    if (result != null && mounted) {
      final provider = context.read<ChannelProvider>();
      await provider.addSubChannel(
        parentId: parent.id,
        name: result.name,
        icon: result.icon,
        description: result.description,
      );
    }
  }

  Future<void> _editChannel(SocialChannel channel) async {
    final parent = context.read<ChannelProvider>().findParentOf(channel);
    final result = await showDialog<SocialChannel>(
      context: context,
      builder: (context) => _ChannelEditDialog(channel: channel, parent: parent),
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

  Future<void> _deleteChannel(SocialChannel channel, int usedBy, int subCount) async {
    if (channel.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(channel.isSubChannel ? '默认子途径不可删除' : '默认途径不可删除')),
      );
      return;
    }

    final bool isParent = !channel.isSubChannel;
    StringBuffer message = StringBuffer('确定要删除${isParent ? '途径' : '子途径'}「${channel.name}」吗？');
    if (isParent && subCount > 0) {
      message.write('\n\n其下 $subCount 个子途径也会被一并删除。');
    }
    if (usedBy > 0) {
      message.write('\n\n$usedBy 位联系人使用此${isParent ? '父途径（含子场景统计）' : '子场景'}，删除后关联的配置将仅保留名称快照避免空白。');
    } else {
      message.write('\n\n暂无联系人使用，可安全删除。');
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(message.toString()),
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
            content: Text('「${channel.name}」已删除；关联联系人保留历史名称快照，编辑联系人时可重新选择'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// 途径/子途径 添加或编辑对话框
///
/// - 传 [channel] 为编辑，不传为添加
/// - 传 [parent] 为「在指定父途径下添加子途径」
class _ChannelEditDialog extends StatefulWidget {
  final SocialChannel? channel;
  final SocialChannel? parent;

  const _ChannelEditDialog({this.channel, this.parent});

  @override
  State<_ChannelEditDialog> createState() => _ChannelEditDialogState();
}

class _ChannelEditDialogState extends State<_ChannelEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _icon;
  late String _platformKey;

  bool get _isSubChannel => widget.channel?.isSubChannel ?? (widget.parent != null);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel?.name ?? '');
    _descController =
        TextEditingController(text: widget.channel?.description ?? '');
    _icon = widget.channel?.icon ?? (_isSubChannel ? '🔖' : '🔗');
    // 子途径平台键跟随父途径，不可改
    _platformKey = widget.channel?.platformKey
        ?? widget.parent?.platformKey
        ?? 'custom';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titlePrefix = _isSubChannel ? '子途径' : '途径';
    final title = widget.channel == null ? '添加$titlePrefix' : '编辑$titlePrefix';
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.parent != null)
              _buildParentHint(widget.parent!),
            if (widget.parent != null) const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _isSubChannel ? '子途径名称 *' : '途径名称 *',
                hintText: _isSubChannel ? '例如：私聊、朋友圈、微信群' : '例如：微信、QQ、线下、抖音',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 父途径时允许平台映射选择；子途径自动跟随，只展示
            if (!_isSubChannel) ...[
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
                      if (_nameController.text.trim().isEmpty &&
                          opt['key'] != 'custom') {
                        _nameController.text = opt['label'] as String;
                      }
                      if (widget.channel == null && opt['key'] != 'custom') {
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
            ] else ...[
              // 子途径：固定展示所属平台信息
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '所属平台：${kPlatformKeyOptions.firstWhere(
                        (o) => o['key'] == _platformKey,
                        orElse: () => {'label': _platformKey, 'emoji': '✨'},
                      )['label'] as String}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
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
                    width: 36,
                    height: 36,
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
                    child: Text(emoji, style: const TextStyle(fontSize: 19)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: _isSubChannel ? '场景说明（可选）' : '描述（可选）',
                hintText: _isSubChannel ? '例如：一对一私聊互动' : null,
                border: const OutlineInputBorder(),
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
            final parentId = widget.channel?.parentId ?? widget.parent?.id;
            Navigator.pop(
              context,
              SocialChannel(
                id: widget.channel?.id ?? '',
                name: _nameController.text.trim(),
                icon: _icon,
                platformKey: _platformKey,
                parentId: parentId,
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

  Widget _buildParentHint(SocialChannel parent) {
    final cfg = resolvePlatformConfig(parent.platform, parent.name, parent.icon);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cfg.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cfg.color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Text(parent.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('所属父途径', style: TextStyle(fontSize: 11, color: Colors.black45)),
                Text(
                  parent.name,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
