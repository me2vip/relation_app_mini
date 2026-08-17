import 'package:flutter/material.dart';
import '../../models/persona.dart';

class PersonaEditPage extends StatefulWidget {
  final ContactGroup group;
  final Persona persona;

  const PersonaEditPage({
    super.key,
    required this.group,
    required this.persona,
  });

  @override
  State<PersonaEditPage> createState() => _PersonaEditPageState();
}

/// 命名路由包装页：支持通过 ModalRoute 参数打开人设编辑页。
/// 参数需为 PersonaEditArgs（含 group 与 persona）。
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
  final ContactGroup group;
  final Persona persona;

  const PersonaEditArgs({
    required this.group,
    required this.persona,
  });
}

class _PersonaEditPageState extends State<PersonaEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _styleController;
  late final TextEditingController _toneController;
  late List<String> _personalityTags;
  late List<String> _contentTopics;
  late List<String> _tabooTopics;
  late bool _isNew;

  @override
  void initState() {
    super.initState();
    _isNew = widget.persona.name.isEmpty;
    _nameController = TextEditingController(text: widget.persona.name);
    _roleController =
        TextEditingController(text: widget.persona.roleDescription ?? '');
    _styleController =
        TextEditingController(text: widget.persona.postingStyle ?? '');
    _toneController =
        TextEditingController(text: widget.persona.toneGuidance ?? '');
    _personalityTags = List.from(widget.persona.personalityTags);
    _contentTopics = List.from(widget.persona.contentTopics);
    _tabooTopics = List.from(widget.persona.tabooTopics);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _styleController.dispose();
    _toneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.group.colorValue);
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
          // 关联分组（只读显示）
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
                  widget.group.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              title: const Text(
                '关联分组',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              subtitle: Text(
                widget.group.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Text(
                '${widget.group.contactIds.length} 人',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 人设名称
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '人设名称 *',
              hintText: '例如：职场精英、阳光开朗、文艺青年',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.face_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // 角色描述
          TextField(
            controller: _roleController,
            decoration: const InputDecoration(
              labelText: '角色描述',
              hintText: '例如：认真负责的职场人，热爱生活，喜欢分享工作中的小确幸',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // 性格特征标签
          _TagSection(
            title: '性格特征标签',
            icon: Icons.psychology_outlined,
            tags: _personalityTags,
            hint: '例如：乐观、幽默、稳重',
            onChanged: (tags) => setState(() => _personalityTags = tags),
          ),
          const SizedBox(height: 16),

          // 发圈风格指导
          const Text(
            '发圈风格指导',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _styleController,
            decoration: const InputDecoration(
              hintText: '例如：简洁明了，配图精致，偶尔用点幽默；不发牢骚，不晒负能量',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // 内容主题
          _TagSection(
            title: '内容主题',
            icon: Icons.topic_outlined,
            tags: _contentTopics,
            hint: '例如：美食、旅行、健身、工作日常',
            onChanged: (tags) => setState(() => _contentTopics = tags),
          ),
          const SizedBox(height: 16),

          // 语气指导
          const Text(
            '语气指导',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _toneController,
            decoration: const InputDecoration(
              hintText: '例如：轻松自然，接地气，带点俏皮；避免说教',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // 禁忌话题
          _TagSection(
            title: '禁忌话题',
            icon: Icons.block_outlined,
            tags: _tabooTopics,
            hint: '例如：工资、八卦、政治',
            color: Colors.red,
            onChanged: (tags) => setState(() => _tabooTopics = tags),
          ),
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
      roleDescription: _roleController.text.trim().isEmpty
          ? null
          : _roleController.text.trim(),
      personalityTags: _personalityTags,
      postingStyle: _styleController.text.trim().isEmpty
          ? null
          : _styleController.text.trim(),
      contentTopics: _contentTopics,
      toneGuidance: _toneController.text.trim().isEmpty
          ? null
          : _toneController.text.trim(),
      tabooTopics: _tabooTopics,
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

/// 标签编辑区块：展示标签 chip + 输入框添加 / 点击删除
class _TagSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<String> tags;
  final String hint;
  final Color color;
  final ValueChanged<List<String>> onChanged;

  const _TagSection({
    required this.title,
    required this.icon,
    required this.tags,
    required this.hint,
    required this.onChanged,
    this.color = const Color(0xFF6366F1),
  });

  @override
  State<_TagSection> createState() => _TagSectionState();
}

class _TagSectionState extends State<_TagSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!widget.tags.contains(text)) {
      widget.onChanged([...widget.tags, text]);
    }
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.tags.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '暂无标签，点击下方添加',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: widget.color.withOpacity(0.1),
                        labelStyle: TextStyle(
                            color: widget.color, fontSize: 13),
                        side: BorderSide.none,
                        deleteIcon: Icon(
                          Icons.close,
                          size: 16,
                          color: widget.color.withOpacity(0.7),
                        ),
                        onDeleted: () {
                          final updated = List<String>.from(widget.tags)
                            ..remove(tag);
                          widget.onChanged(updated);
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          isDense: true,
                          prefixIcon:
                              Icon(widget.icon, size: 18, color: widget.color),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addTag,
                      icon: Icon(Icons.add_circle, color: widget.color),
                      tooltip: '添加标签',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
