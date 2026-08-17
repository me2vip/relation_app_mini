import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../core/providers/persona_provider.dart';
import '../../models/dynamic_post.dart';
import '../../models/persona.dart';

class DynamicPostPage extends StatefulWidget {
  const DynamicPostPage({super.key});

  @override
  State<DynamicPostPage> createState() => _DynamicPostPageState();
}

class _DynamicPostPageState extends State<DynamicPostPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('动态文案'),
      ),
      body: Consumer<PersonaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.dynamicPosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '还没有动态文案',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '在「临时素材」页添加素材，AI 帮你配文案',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/temp-material'),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('去添加素材'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.dynamicPosts.length,
            itemBuilder: (context, index) {
              final post = provider.dynamicPosts[index];
              return _PostCard(
                post: post,
                groupName:
                    provider.getGroupById(post.groupId)?.name ?? '未分组',
                personaName: post.personaId != null
                    ? provider.getPersonaById(post.personaId!)?.name ?? '未命名人设'
                    : null,
                onEdit: () => _editPost(provider, post),
                onMarkPublished: () => _markPublished(provider, post),
                onCreateTask: () => _createTask(provider, post),
                onDelete: () => _deletePost(provider, post),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editPost(PersonaProvider provider, DynamicPost post) async {
    final controller = TextEditingController(text: post.content);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑文案'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '输入朋友圈文案',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await provider.updateDynamicPost(
        post.copyWith(content: result.trim(), updatedAt: DateTime.now()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文案已更新')),
        );
      }
    }
  }

  Future<void> _markPublished(PersonaProvider provider, DynamicPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('标记为已发布'),
        content: const Text('确定这条文案已经发布到朋友圈了吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('确认发布'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.updateDynamicPost(
        post.copyWith(
            status: DynamicPostStatus.published, updatedAt: DateTime.now()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已标记为发布')),
        );
      }
    }
  }

  Future<void> _createTask(PersonaProvider provider, DynamicPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生成发圈任务'),
        content: const Text('将为这条文案生成发朋友圈任务，稍后在任务列表中提醒你发布。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('生成任务'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 通过素材方式重建任务：将动态转为发圈任务
      await provider.createTaskFromPost(post);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发圈任务已生成')),
        );
      }
    }
  }

  Future<void> _deletePost(PersonaProvider provider, DynamicPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条文案吗？'),
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
      await provider.deleteDynamicPost(post.id);
    }
  }
}

class _PostCard extends StatelessWidget {
  final DynamicPost post;
  final String groupName;
  final String? personaName;
  final VoidCallback onEdit;
  final VoidCallback onMarkPublished;
  final VoidCallback onCreateTask;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.groupName,
    required this.personaName,
    required this.onEdit,
    required this.onMarkPublished,
    required this.onCreateTask,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (post.status) {
      case DynamicPostStatus.draft:
        return Colors.grey;
      case DynamicPostStatus.published:
        return const Color(0xFF10B981);
      case DynamicPostStatus.taskCreated:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get _statusIcon {
    switch (post.status) {
      case DynamicPostStatus.draft:
        return Icons.edit_outlined;
      case DynamicPostStatus.published:
        return Icons.check_circle_outline;
      case DynamicPostStatus.taskCreated:
        return Icons.assignment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：分组 + 人设 + 状态
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                if (personaName != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '人设：$personaName',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 13, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(
                        post.statusName,
                        style:
                            TextStyle(fontSize: 12, color: _statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 文案内容
            Text(
              post.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),

            // 配图
            if (post.mediaPaths.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.mediaPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(post.mediaPaths[index]),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('编辑'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: post.status == DynamicPostStatus.published
                        ? null
                        : onMarkPublished,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('已发布'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: post.status == DynamicPostStatus.taskCreated
                        ? null
                        : onCreateTask,
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: const Text('生成任务'),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  tooltip: '删除',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
