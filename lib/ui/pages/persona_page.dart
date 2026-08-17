import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/persona_provider.dart';
import '../../models/persona.dart';
import 'group_edit_page.dart';
import 'persona_edit_page.dart';

class PersonaPage extends StatefulWidget {
  const PersonaPage({super.key});

  @override
  State<PersonaPage> createState() => _PersonaPageState();
}

class _PersonaPageState extends State<PersonaPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonaProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('人设'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建分组',
            onPressed: () => _openGroupEdit(),
          ),
          IconButton(
            icon: const Icon(Icons.article_outlined),
            tooltip: '动态文案',
            onPressed: () => Navigator.pushNamed(context, '/dynamic-post'),
          ),
        ],
      ),
      body: Consumer<PersonaProvider>(
        builder: (context, persona, _) {
          if (persona.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 顶部说明卡片
              Card(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.face_retouching_natural,
                        color: Color(0xFF6366F1),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '按分组打造你的朋友圈人设',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '给不同联系人分组设置专属人设，AI 按人设帮你生成朋友圈文案',
                              style: TextStyle(
                                color: Colors.grey.shade600,
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

              // 分组列表
              if (persona.groups.isEmpty)
                _buildEmptyState()
              else
                ...persona.groups.map((group) {
                  final personaOfGroup = persona.getPersonaByGroup(group.id);
                  final contactCount = group.contactIds.length;
                  return _GroupCard(
                    group: group,
                    contactCount: contactCount,
                    persona: personaOfGroup,
                    onTap: () => _openPersonaEdit(group),
                    onEditGroup: () => _openGroupEdit(group: group),
                    onDelete: () => _deleteGroup(group),
                  );
                }),

              const SizedBox(height: 16),

              // 动态文案入口
              _ActionCard(
                icon: Icons.auto_awesome,
                color: const Color(0xFF6366F1),
                title: '动态文案',
                subtitle:
                    '查看按人设生成的文案（${persona.dynamicPosts.length} 条）',
                onTap: () => Navigator.pushNamed(context, '/dynamic-post'),
              ),
              const SizedBox(height: 8),

              // 临时素材入口
              _ActionCard(
                icon: Icons.add_photo_alternate_outlined,
                color: Colors.orange,
                title: '临时素材',
                subtitle: '添加照片/文字，让 AI 帮你配文案发圈',
                onTap: () => Navigator.pushNamed(context, '/temp-material'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.group_off_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            '还没有联系人分组',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '先创建分组，再为分组设置人设',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openGroupEdit,
            icon: const Icon(Icons.add),
            label: const Text('新建分组'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _openGroupEdit({ContactGroup? group}) async {
    final provider = context.read<PersonaProvider>();
    final isNew = group == null;
    final target = group ?? provider.createEmptyGroup();

    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupEditPage(group: target, isNew: isNew),
      ),
    );

    if (result is ContactGroup) {
      if (isNew) {
        await provider.addGroup(result);
      } else {
        await provider.updateGroup(result);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNew ? '分组已创建' : '分组已更新')),
        );
      }
    } else if (result is String && result.startsWith('DELETE:')) {
      final groupId = result.substring('DELETE:'.length);
      await provider.deleteGroup(groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分组已删除')),
        );
      }
    }
  }

  Future<void> _openPersonaEdit(ContactGroup group) async {
    final provider = context.read<PersonaProvider>();
    final existing = provider.getPersonaByGroup(group.id);
    final persona = existing ?? provider.createEmptyPersona(group.id);

    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonaEditPage(group: group, persona: persona),
      ),
    );

    if (result is Persona) {
      await provider.savePersona(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('人设已保存')),
        );
      }
    } else if (result is String && result.startsWith('DELETE:')) {
      final personaId = result.substring('DELETE:'.length);
      await provider.deletePersona(personaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('人设已删除')),
        );
      }
    }
  }

  Future<void> _deleteGroup(ContactGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分组「${group.name}」吗？关联的人设也会一并删除。'),
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
      final provider = context.read<PersonaProvider>();
      await provider.deleteGroup(group.id);
    }
  }
}

class _GroupCard extends StatelessWidget {
  final ContactGroup group;
  final int contactCount;
  final Persona? persona;
  final VoidCallback onTap;
  final VoidCallback onEditGroup;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.contactCount,
    required this.persona,
    required this.onTap,
    required this.onEditGroup,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(group.colorValue);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 分组图标
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  group.icon,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (persona != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '已设人设',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$contactCount 位联系人',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.face_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          persona?.name ?? '未设置人设',
                          style: TextStyle(
                            fontSize: 13,
                            color: persona != null
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    if (group.description != null &&
                        group.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEditGroup();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('编辑分组'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
