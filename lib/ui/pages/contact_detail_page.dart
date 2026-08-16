import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../models/contact.dart';
import '../../models/task.dart';
import 'package:intl/intl.dart';

class ContactDetailPage extends StatefulWidget {
  const ContactDetailPage({super.key});

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, provider, _) {
        final contact = provider.selectedContact;
        if (contact == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('联系人详情')),
            body: const Center(child: Text('未选择联系人')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(contact.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context, contact),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('删除联系人'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmation(context, contact);
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildHeader(contact),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '信息'),
                  Tab(text: '互动'),
                  Tab(text: '任务'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _InfoTab(contact: contact),
                    _InteractionTab(contact: contact),
                    _TaskTab(contact: contact),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Contact contact) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: _getLevelColor(contact.level),
            child: Text(
              contact.name.isNotEmpty ? contact.name[0] : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getLevelColor(contact.level).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contact.levelName,
                    style: TextStyle(
                      color: _getLevelColor(contact.level),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (contact.goalRelation != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.flag, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        '目标: ${contact.goalRelation}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(ContactLevel level) {
    switch (level) {
      case ContactLevel.unimportant:
        return Colors.grey;
      case ContactLevel.normal:
        return Colors.blue;
      case ContactLevel.important:
        return Colors.orange;
      case ContactLevel.core:
        return Colors.red;
    }
  }

  void _showEditDialog(BuildContext context, Contact contact) {
    final nameController = TextEditingController(text: contact.name);
    final goalController = TextEditingController(text: contact.goalRelation);
    var selectedLevel = contact.level;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('编辑联系人'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '姓名'),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<ContactLevel>(
                      value: selectedLevel,
                      decoration: const InputDecoration(labelText: '分层'),
                      items: ContactLevel.values.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(_getLevelName(level)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedLevel = value);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: goalController,
                      decoration: const InputDecoration(
                        labelText: '目标关系',
                        hintText: '如: 好朋友',
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
                ElevatedButton(
                  onPressed: () {
                    final provider = context.read<ContactProvider>();
                    provider.updateContact(contact.copyWith(
                      name: nameController.text,
                      level: selectedLevel,
                      goalRelation: goalController.text.isEmpty
                          ? null
                          : goalController.text,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getLevelName(ContactLevel level) {
    switch (level) {
      case ContactLevel.unimportant:
        return '不重要';
      case ContactLevel.normal:
        return '一般';
      case ContactLevel.important:
        return '重要';
      case ContactLevel.core:
        return '核心';
    }
  }

  void _showDeleteConfirmation(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除联系人'),
          content: Text('确定要删除联系人"${contact.name}"吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                context.read<ContactProvider>().deleteContact(contact.id);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Contact contact;

  const _InfoTab({required this.contact});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (contact.methods.isNotEmpty) ...[
          const Text(
            '联系方式',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...contact.methods.map((method) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(_getPlatformIcon(method.platform)),
                title: Text(method.platform),
                subtitle: Text(method.account),
                trailing: const Icon(Icons.copy),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
        if (contact.tags.isNotEmpty) ...[
          const Text(
            '标签',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: contact.tags.map((tag) {
              return Chip(label: Text(tag));
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '时间信息',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline, size: 16),
                    const SizedBox(width: 8),
                    Text('添加时间: ${DateFormat('yyyy-MM-dd').format(contact.createdAt)}'),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.update, size: 16),
                    const SizedBox(width: 8),
                    Text('更新时间: ${DateFormat('yyyy-MM-dd').format(contact.updatedAt)}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case '微信':
        return Icons.chat;
      case 'QQ':
        return Icons.chat_bubble;
      case '手机':
        return Icons.phone;
      case '邮箱':
        return Icons.email;
      default:
        return Icons.contact_page;
    }
  }
}

class _InteractionTab extends StatelessWidget {
  final Contact contact;

  const _InteractionTab({required this.contact});

  @override
  Widget build(BuildContext context) {
    if (contact.interactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('还没有互动记录'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contact.interactions.length,
      itemBuilder: (context, index) {
        final interaction = contact.interactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(_getTypeIcon(interaction.type)),
            ),
            title: Text(interaction.typeName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(interaction.content),
                const SizedBox(height: 5),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(interaction.occurredAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getTypeIcon(InteractionType type) {
    switch (type) {
      case InteractionType.textChat:
        return Icons.chat;
      case InteractionType.voiceChat:
        return Icons.mic;
      case InteractionType.videoCall:
        return Icons.videocam;
      case InteractionType.shareVideo:
        return Icons.share;
      case InteractionType.socialMedia:
        return Icons.public;
      case InteractionType.other:
        return Icons.more_horiz;
    }
  }
}

class _TaskTab extends StatelessWidget {
  final Contact contact;

  const _TaskTab({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final tasks = provider.getTasksForContact(contact.id);

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.task_alt, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text('还没有任务'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 生成AI任务
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI生成任务'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  _getTaskIcon(task.type),
                  color: task.status == TaskStatus.completed
                      ? Colors.green
                      : null,
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.status == TaskStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text(
                  DateFormat('MM-dd HH:mm').format(task.scheduledAt),
                ),
                trailing: task.status == TaskStatus.pending
                    ? IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () => provider.completeTask(task.id),
                      )
                    : Text(
                        task.statusName,
                        style: TextStyle(
                          color: task.status == TaskStatus.completed
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getTaskIcon(TaskType type) {
    switch (type) {
      case TaskType.sendMessage:
        return Icons.message;
      case TaskType.sendVideo:
        return Icons.videocam;
      case TaskType.greeting:
        return Icons.waving_hand;
      case TaskType.socialInteraction:
        return Icons.thumb_up;
      case TaskType.phoneCall:
        return Icons.phone;
      case TaskType.other:
        return Icons.task;
    }
  }
}
