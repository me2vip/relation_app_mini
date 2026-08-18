import 'package:flutter/material.dart';
import '../../models/contact_group.dart';
import '../../models/persona.dart';

/// 人设编辑页：定义该人设可向联系人暴露的信息项
/// （工作、学习、环境、公司位置、公司文化、招人计划、薪资待遇…）
class PersonaEditPage extends StatefulWidget {
  final ContactGroup? group;
  final Persona persona;

  const PersonaEditPage({
    super.key,
    required this.group,
    required this.persona,
  });

  @override
  State<PersonaEditPage> createState() => _PersonaEditPageState();
}

/// 命名路由包装页：支持通过 ModalRoute 参数打开人设编辑页
class PersonaEditRoutePage extends StatelessWidget {
  const PersonaEditRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is PersonaEditArgs) {
      return PersonaEditPage(group: args.group, persona: args.persona);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('人设设置')),
      body: const Center(child: Text('缺少人设参数，请从人设页面进入')),
    );
  }
}

/// 人设编辑页路由参数
class PersonaEditArgs {
  final ContactGroup? group;
  final Persona persona;

  const PersonaEditArgs({required this.group, required this.persona});
}

class _PersonaEditPageState extends State<PersonaEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late List<PersonaInfoItem> _infoItems;
  late bool _isNew;

  /// 信息分类预设（可扩展）
  static const _categories = kInfoCategories;

  @override
  void initState() {
    super.initState();
    _isNew = widget.persona.name.isEmpty;
    _nameController = TextEditingController(text: widget.persona.name);
    _descController = TextEditingController(text: widget.persona.description ?? '');
    _infoItems = List.from(widget.persona.infoItems);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.group?.color ?? 0xFF6366F1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('人设设置'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: '删除人设',
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
          // 关联分组（可选）
          if (widget.group != null)
            Card(
              color: color.withOpacity(0.06),
              child: ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.group!.icon ?? '👥',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                title: const Text(
                  '关联分组',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                subtitle: Text(
                  widget.group!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (widget.group == null)
            Card(
              color: color.withOpacity(0.06),
              child: const ListTile(
                leading: Icon(Icons.public, color: Color(0xFF6366F1)),
                title: Text('全局人设',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  '适用于所有未指定分组人设的联系人',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 人设名称
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '人设名称 *',
              hintText: '例如：同事看到的我、家人看到的我',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.face_outlined),
            ),
          ),
          const SizedBox(height: 12),

          // 描述
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: '描述（可选）',
              hintText: '这个人设的使用场景说明',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // 信息暴露项列表
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '可暴露的信息项',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _addInfoItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加信息项'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '定义该人设下，联系人可以看到的你的信息内容。'
            '同一个人在不同人设里可以有不同的信息内容。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          if (_infoItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        '还没有信息项',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击「添加信息项」定义该人设可暴露的信息',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._infoItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _categoryEmoji(item.category),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: Text(item.label, style: const TextStyle(fontSize: 15)),
                  subtitle: Text(
                    '${item.category} · ${item.content}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editInfoItem(index);
                      if (value == 'delete') {
                        setState(() => _infoItems.removeAt(index));
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑')),
                      PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                  onTap: () => _editInfoItem(index),
                ),
              );
            }),

          const SizedBox(height: 24),

          // 保存按钮
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '保存人设',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case '工作': return '💼';
      case '学习': return '📚';
      case '环境': return '🏠';
      case '公司位置': return '📍';
      case '公司文化': return '🏢';
      case '公司招人计划': return '📢';
      case '薪资待遇': return '💰';
      case '家庭': return '👨‍👩‍👧';
      case '情感': return '❤️';
      case '兴趣': return '🎯';
      default: return '📋';
    }
  }

  Future<void> _addInfoItem() async {
    final result = await showDialog<PersonaInfoItem>(
      context: context,
      builder: (context) => _InfoItemDialog(
        categories: _categories,
      ),
    );
    if (result != null) {
      setState(() => _infoItems.add(result));
    }
  }

  Future<void> _editInfoItem(int index) async {
    final item = _infoItems[index];
    final result = await showDialog<PersonaInfoItem>(
      context: context,
      builder: (context) => _InfoItemDialog(
        categories: _categories,
        item: item,
      ),
    );
    if (result != null) {
      setState(() => _infoItems[index] = result);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写人设名称')),
      );
      return;
    }

    final updated = widget.persona.copyWith(
      name: name,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      infoItems: _infoItems
          .map((i) => i.copyWith(
                personaId: widget.persona.id,
                displayOrder: _infoItems.indexOf(i),
              ))
          .toList(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, updated);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除人设「${widget.persona.name}」吗？'),
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
      Navigator.pop(context, 'DELETE:${widget.persona.id}');
    }
  }
}

/// 信息项编辑对话框：分类（可下拉选择或自定义）+ 标签 + 内容
class _InfoItemDialog extends StatefulWidget {
  final List<String> categories;
  final PersonaInfoItem? item;

  const _InfoItemDialog({required this.categories, this.item});

  @override
  State<_InfoItemDialog> createState() => _InfoItemDialogState();
}

class _InfoItemDialogState extends State<_InfoItemDialog> {
  late String _category;
  late final TextEditingController _labelController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _category = widget.item?.category ?? widget.categories.first;
    _labelController =
        TextEditingController(text: widget.item?.label ?? '');
    _contentController =
        TextEditingController(text: widget.item?.content ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? '添加信息项' : '编辑信息项'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: '信息分类',
              border: OutlineInputBorder(),
            ),
            items: widget.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: '信息标签',
              hintText: '例如：我的工作、所在公司',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: '信息内容',
              hintText: '例如：互联网公司程序员',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_labelController.text.isEmpty ||
                _contentController.text.isEmpty) {
              return;
            }
            final now = DateTime.now();
            final item = PersonaInfoItem(
              id: widget.item?.id ?? '',
              personaId: widget.item?.personaId ?? '',
              category: _category,
              label: _labelController.text.trim(),
              content: _contentController.text.trim(),
              displayOrder: widget.item?.displayOrder ?? 0,
              createdAt: widget.item?.createdAt ?? now,
              updatedAt: now,
            );
            Navigator.pop(context, item);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
