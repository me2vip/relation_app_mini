import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../models/task.dart';
import '../../models/contact.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage>
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('社交任务'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '待完成'),
            Tab(text: '已完成'),
            Tab(text: '已过期'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TaskListView(filter: TaskStatus.pending),
          _TaskListView(filter: TaskStatus.completed),
          _TaskListView(filter: TaskStatus.expired),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('添加任务'),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedContactId;
    var selectedType = TaskType.sendMessage;
    var selectedPriority = 3;
    var selectedDate = DateTime.now();
    var selectedHour = 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '添加任务',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: '任务标题',
                          hintText: '输入任务标题',
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: '任务描述',
                          hintText: '输入任务描述',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 15),
                      Consumer<ContactProvider>(
                        builder: (context, provider, _) {
                          return DropdownButtonFormField<String>(
                            value: selectedContactId,
                            decoration: const InputDecoration(
                              labelText: '关联联系人',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('无'),
                              ),
                              ...provider.contacts.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setDialogState(() => selectedContactId = value);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<TaskType>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: '任务类型',
                        ),
                        items: TaskType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTypeName(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Text('优先级: '),
                          ...List.generate(5, (i) {
                            return IconButton(
                              icon: Icon(
                                i < selectedPriority
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                              ),
                              onPressed: () {
                                setDialogState(() => selectedPriority = i + 1);
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 15),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('计划时间'),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd HH:00').format(selectedDate
                              .add(Duration(hours: selectedHour))),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                      ),
                      Row(
                        children: [
                          const Text('小时: '),
                          Expanded(
                            child: Slider(
                              value: selectedHour.toDouble(),
                              min: 8,
                              max: 21,
                              divisions: 13,
                              label: '$selectedHour:00',
                              onChanged: (value) {
                                setDialogState(() => selectedHour = value.round());
                              },
                            ),
                          ),
                          Text('$selectedHour:00'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (titleController.text.isNotEmpty) {
                                final taskProvider = context.read<TaskProvider>();
                                final contactProvider =
                                    context.read<ContactProvider>();
                                final contact = selectedContactId != null
                                    ? contactProvider.contacts.firstWhere(
                                        (c) => c.id == selectedContactId,
                                        orElse: () => Contact(
                                          id: '',
                                          name: '未知',
                                          level: ContactLevel.normal,
                                          methods: [],
                                          tags: [],
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now(),
                                        ),
                                      )
                                    : null;
                                final task = taskProvider.createTask(
                                  contactId: selectedContactId ?? '',
                                  contactName: contact?.name ?? '无',
                                  title: titleController.text,
                                  description: descController.text,
                                  type: selectedType,
                                  scheduledAt: selectedDate.add(
                                    Duration(hours: selectedHour),
                                  ),
                                  priority: selectedPriority,
                                );
                                taskProvider.addTask(task);
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('添加'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getTypeName(TaskType type) {
    switch (type) {
      case TaskType.sendMessage:
        return '发消息';
      case TaskType.sendVideo:
        return '发视频';
      case TaskType.greeting:
        return '问候';
      case TaskType.socialInteraction:
        return '社交互动';
      case TaskType.phoneCall:
        return '打电话';
      case TaskType.other:
        return '其他';
    }
  }
}

class _TaskListView extends StatelessWidget {
  final TaskStatus filter;

  const _TaskListView({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        var tasks = provider.tasks.where((t) => t.status == filter).toList();

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyIcon(),
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                Text(
                  _getEmptyText(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // 按日期分组
        final groupedTasks = <String, List<SocialTask>>{};
        for (final task in tasks) {
          final dateKey = DateFormat('yyyy-MM-dd').format(task.scheduledAt);
          groupedTasks.putIfAbsent(dateKey, () => []).add(task);
        }

        final sortedKeys = groupedTasks.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final dateKey = sortedKeys[index];
            final dayTasks = groupedTasks[dateKey]!;
            final date = DateTime.parse(dateKey);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _formatDateHeader(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...dayTasks.map((task) => _TaskItem(task: task)),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getEmptyIcon() {
    switch (filter) {
      case TaskStatus.pending:
        return Icons.task_alt;
      case TaskStatus.completed:
        return Icons.check_circle_outline;
      case TaskStatus.expired:
        return Icons.history;
      default:
        return Icons.inbox;
    }
  }

  String _getEmptyText() {
    switch (filter) {
      case TaskStatus.pending:
        return '没有待完成的任务';
      case TaskStatus.completed:
        return '还没有已完成的任务';
      case TaskStatus.expired:
        return '没有已过期的任务';
      default:
        return '没有任务';
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) {
      return '今天';
    } else if (date == tomorrow) {
      return '明天';
    } else {
      return DateFormat('MM月dd日 EEEE', 'zh_CN').format(date);
    }
  }
}

class _TaskItem extends StatelessWidget {
  final SocialTask task;

  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/task-detail',
          arguments: task,
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getTypeIcon(task.type),
                    size: 20,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (task.contactName.isNotEmpty)
                    Chip(
                      label: Text(
                        task.contactName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  task.description,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (task.steps.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildStepsPreview(),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        DateFormat('HH:mm').format(task.scheduledAt),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (task.goalRelation != null) ...[
                        const SizedBox(width: 15),
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          task.goalRelation!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  if (task.status == TaskStatus.pending)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          color: Colors.green,
                          onPressed: () {
                            context.read<TaskProvider>().completeTask(task.id);
                            context.read<ProfileProvider>().updateProfileFromTask(
                              completed: true,
                              taskType: task.type,
                              reason: '任务完成: ${task.title}',
                            );
                            context.read<ProfileProvider>().incrementInteractions();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          color: Colors.orange,
                          onPressed: () {
                            context.read<TaskProvider>().skipTask(task.id);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepsPreview() {
    final displaySteps = task.steps.length > 2 ? task.steps.sublist(0, 2) : task.steps;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, size: 12, color: Colors.purple),
              const SizedBox(width: 4),
              Text(
                '${task.steps.length}个执行步骤',
                style: const TextStyle(fontSize: 11, color: Colors.purple),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 14, color: Colors.purple),
            ],
          ),
          const SizedBox(height: 6),
          ...displaySteps.asMap().entries.map((entry) {
            final index = entry.key;
            return Padding(
              padding: EdgeInsets.only(bottom: index < displaySteps.length - 1 ? 4 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (task.steps.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '还有${task.steps.length - 2}个步骤...',
                style: const TextStyle(fontSize: 11, color: Colors.purple),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(TaskType type) {
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
