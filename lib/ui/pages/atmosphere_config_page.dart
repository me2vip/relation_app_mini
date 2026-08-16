import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/atmosphere_provider.dart';
import '../../models/atmosphere.dart';

class AtmosphereConfigPage extends StatefulWidget {
  const AtmosphereConfigPage({super.key});

  @override
  State<AtmosphereConfigPage> createState() => _AtmosphereConfigPageState();
}

class _AtmosphereConfigPageState extends State<AtmosphereConfigPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('氛围配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addProfile(),
            tooltip: '新建配置',
          ),
        ],
      ),
      body: Consumer<AtmosphereProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.color_lens_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '还没有氛围配置',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _addProfile(),
                    icon: const Icon(Icons.add),
                    label: const Text('创建配置'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.profiles.length,
            itemBuilder: (context, index) {
              final profile = provider.profiles[index];
              return _ProfileCard(
                profile: profile,
                onTap: () => _editProfile(profile),
                onDelete: () => _deleteProfile(profile),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addProfile() async {
    final provider = context.read<AtmosphereProvider>();
    final profile = provider.createEmptyProfile();
    
    final result = await Navigator.push<AtmosphereProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditPage(profile: profile),
      ),
    );
    
    if (result != null) {
      await provider.addProfile(result);
    }
  }

  Future<void> _editProfile(AtmosphereProfile profile) async {
    final provider = context.read<AtmosphereProvider>();
    
    final result = await Navigator.push<AtmosphereProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditPage(profile: profile),
      ),
    );
    
    if (result != null) {
      await provider.updateProfile(result);
    }
  }

  Future<void> _deleteProfile(AtmosphereProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除配置「${profile.name}」吗？'),
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
      final provider = context.read<AtmosphereProvider>();
      await provider.deleteProfile(profile.id);
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final AtmosphereProfile profile;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.onTap,
    required this.onDelete,
  });

  int get _itemCount {
    int count = 0;
    for (final items in profile.items.values) {
      count += items.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.color_lens,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_itemCount} 个配置项 · ${profile.items.length} 个分类',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    if (profile.description != null && profile.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.description!,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 配置编辑页面
class ProfileEditPage extends StatefulWidget {
  final AtmosphereProfile profile;

  const ProfileEditPage({super.key, required this.profile});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late AtmosphereProfile _profile;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _nameController.text = _profile.name;
    _descController.text = _profile.description ?? '';
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
        title: const Text('编辑配置'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 基本信息
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '配置名称',
              hintText: '例如：工作关系、朋友关系',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: '描述（可选）',
              hintText: '描述这个配置的用途',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          
          // 分类列表
          const Text(
            '配置项',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._profile.items.entries.map((entry) {
            return _CategorySection(
              category: entry.key,
              items: entry.value,
              onAddItem: () => _addItem(entry.key),
              onEditItem: (item) => _editItem(entry.key, item),
              onDeleteItem: (item) => _deleteItem(entry.key, item),
              onToggleItem: (item, enabled) => _toggleItem(entry.key, item, enabled),
            );
          }),
          
          const SizedBox(height: 16),
          
          // 添加新分类按钮
          OutlinedButton.icon(
            onPressed: _addCategory,
            icon: const Icon(Icons.add),
            label: const Text('添加新分类'),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(String category) async {
    final result = await showDialog<AtmosphereItem>(
      context: context,
      builder: (context) => _ItemEditDialog(
        category: category,
      ),
    );
    
    if (result != null) {
      setState(() {
        _profile.items[category]!.add(result);
      });
    }
  }

  Future<void> _editItem(String category, AtmosphereItem item) async {
    final result = await showDialog<AtmosphereItem>(
      context: context,
      builder: (context) => _ItemEditDialog(
        category: category,
        item: item,
      ),
    );
    
    if (result != null) {
      setState(() {
        final index = _profile.items[category]!.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _profile.items[category]![index] = result;
        }
      });
    }
  }

  void _deleteItem(String category, AtmosphereItem item) {
    setState(() {
      _profile.items[category]!.removeWhere((i) => i.id == item.id);
    });
  }

  void _toggleItem(String category, AtmosphereItem item, bool enabled) {
    setState(() {
      final index = _profile.items[category]!.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _profile.items[category]![index] = item.copyWith(enabled: enabled);
      }
    });
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加分类'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '分类名称',
            hintText: '例如：兴趣爱好',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        _profile.items[result] = [];
      });
    }
  }

  void _save() {
    final updated = _profile.copyWith(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty 
          ? null 
          : _descController.text.trim(),
      updatedAt: DateTime.now(),
    );
    
    Navigator.pop(context, updated);
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<AtmosphereItem> items;
  final VoidCallback onAddItem;
  final void Function(AtmosphereItem) onEditItem;
  final void Function(AtmosphereItem) onDeleteItem;
  final void Function(AtmosphereItem, bool) onToggleItem;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    '暂无配置项',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...items.map((item) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Switch(
                  value: item.enabled,
                  onChanged: (v) => onToggleItem(item, v),
                  activeColor: const Color(0xFF6366F1),
                ),
                title: Text(item.label),
                subtitle: Text(item.value, style: const TextStyle(fontSize: 12)),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEditItem(item);
                    if (value == 'delete') onDeleteItem(item);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('编辑'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('删除'),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _ItemEditDialog extends StatefulWidget {
  final String category;
  final AtmosphereItem? item;

  const _ItemEditDialog({
    required this.category,
    this.item,
  });

  @override
  State<_ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<_ItemEditDialog> {
  final _labelController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _labelController.text = widget.item!.label;
      _valueController.text = widget.item!.value;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? '添加配置项' : '编辑配置项'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: '标签',
              hintText: '例如：姓名、年龄',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: const InputDecoration(
              labelText: '默认值',
              hintText: '例如：真实姓名、年龄范围',
            ),
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
            if (_labelController.text.isEmpty) return;
            
            final item = AtmosphereItem(
              id: widget.item?.id ?? '',
              category: widget.category,
              label: _labelController.text.trim(),
              value: _valueController.text.trim(),
              enabled: widget.item?.enabled ?? true,
              displayOrder: widget.item?.displayOrder ?? 0,
            );
            
            Navigator.pop(context, item);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
