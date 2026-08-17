import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../models/persona.dart';
import '../../models/contact.dart';

/// 预设图标（emoji）列表
const List<String> kGroupEmojis = [
  '👥', '💼', '🎉', '🏠', '❤️', '🎮', '📚', '⚽',
  '🍜', '🎵', '✈️', '🐱', '🐶', '🌱', '🎬', '🛒',
  '☕', '🍺', '🏋️', '💡', '🧑‍💻', '👨‍👩‍👧', '🤝', '💬',
];

/// 预设颜色列表
const List<Color> kGroupColors = [
  Color(0xFF6366F1), // 靛蓝
  Color(0xFFEC4899), // 粉红
  Color(0xFFF59E0B), // 琥珀
  Color(0xFF10B981), // 翠绿
  Color(0xFF3B82F6), // 蓝
  Color(0xFF8B5CF6), // 紫
  Color(0xFFEF4444), // 红
  Color(0xFF06B6D4), // 青
  Color(0xFF84CC16), // 黄绿
  Color(0xFFF97316), // 橙
];

class GroupEditPage extends StatefulWidget {
  final ContactGroup group;
  final bool isNew;

  const GroupEditPage({
    super.key,
    required this.group,
    this.isNew = false,
  });

  @override
  State<GroupEditPage> createState() => _GroupEditPageState();
}

/// 命名路由包装页：支持通过 ModalRoute 参数打开分组编辑页
/// 参数为 ContactGroup（编辑已有分组）。
class GroupEditRoutePage extends StatelessWidget {
  const GroupEditRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ContactGroup) {
      return GroupEditPage(group: args);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('新建分组')),
      body: const Center(child: Text('缺少分组参数，请从人设页面进入')),
    );
  }
}

class _GroupEditPageState extends State<GroupEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _icon;
  late int _colorValue;
  late Set<String> _selectedContactIds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descController = TextEditingController(text: widget.group.description ?? '');
    _icon = widget.group.icon;
    _colorValue = widget.group.colorValue;
    _selectedContactIds = Set<String>.from(widget.group.contactIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? '新建分组' : '编辑分组'),
        actions: [
          if (!widget.isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: '删除分组',
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _save,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 分组名称
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '分组名称 *',
              hintText: '例如：同事组、死党组、家人组',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.group_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // 描述
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: '描述（可选）',
              hintText: '描述这个分组的特点',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // 图标选择
          const Text(
            '选择图标',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kGroupEmojis.map((emoji) {
                  final selected = emoji == _icon;
                  return InkWell(
                    onTap: () => setState(() => _icon = emoji),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF6366F1).withOpacity(0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(
                                color: const Color(0xFF6366F1), width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 颜色选择
          const Text(
            '选择颜色',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kGroupColors.map((color) {
                  final selected = color.toARGB32() == _colorValue;
                  return InkWell(
                    onTap: () => setState(() => _colorValue = color.toARGB32()),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Colors.black87, width: 2.5)
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 关联联系人
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '关联联系人',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '已选 ${_selectedContactIds.length} 人',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Consumer<ContactProvider>(
              builder: (context, contactProvider, _) {
                final contacts = contactProvider.contacts;
                if (contacts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        '暂无联系人，请先在「联系人」页添加',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return Column(
                  children: contacts.map((contact) {
                    return CheckboxListTile(
                      value: _selectedContactIds.contains(contact.id),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedContactIds.add(contact.id);
                          } else {
                            _selectedContactIds.remove(contact.id);
                          }
                        });
                      },
                      activeColor: const Color(0xFF6366F1),
                      title: Text(contact.name),
                      subtitle: Text(
                        '${contact.levelName}${contact.tags.isEmpty ? '' : ' · ${contact.tags.join('、')}'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            const Color(0xFF6366F1).withOpacity(0.1),
                        child: Text(
                          contact.name.isNotEmpty
                              ? contact.name.substring(0, 1)
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写分组名称')),
      );
      return;
    }

    final updated = widget.group.copyWith(
      name: name,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      icon: _icon,
      colorValue: _colorValue,
      contactIds: _selectedContactIds.toList(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, updated);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分组「${widget.group.name}」吗？'),
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

    if (confirmed == true) {
      if (mounted) {
        Navigator.pop(context, 'DELETE:${widget.group.id}');
      }
    }
  }
}
