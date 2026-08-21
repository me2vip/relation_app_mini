import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/task_provider.dart';
import '../../models/task.dart';

class TaskDetailPage extends StatefulWidget {
  final SocialTask task;

  const TaskDetailPage({super.key, required this.task});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.task.steps.isNotEmpty) {
      _currentStep = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirm(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskHeader(task),
            const SizedBox(height: 20),
            _buildDescription(task),
            if (task.steps.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildStepsSection(task),
            ],
            const SizedBox(height: 20),
            _buildInfoSection(task),
            const SizedBox(height: 24),
            _buildActionButtons(task),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader(SocialTask task) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIcon(task.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(task.status),
                const SizedBox(width: 8),
                _buildPriorityChip(task.priority),
                if (task.contactName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.contactName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(SocialTask task) {
    if (task.description.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '任务描述',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection(SocialTask task) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flag,
                    size: 20,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '分步执行指导',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '共${task.steps.length}步 · 逐步完成',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...task.steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCurrentStep = index == _currentStep && task.status == TaskStatus.pending;
              final isDone = index < _currentStep || task.status != TaskStatus.pending;
              return _buildStepItem(
                index: index,
                step: step,
                isCurrentStep: isCurrentStep,
                isDone: isDone,
                isLast: index == task.steps.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int index,
    required String step,
    required bool isCurrentStep,
    required bool isDone,
    required bool isLast,
  }) {
    final circleColor = isCurrentStep
        ? const Color(0xFF6366F1)
        : isDone
            ? Colors.green
            : Colors.grey[300];
    final textColor = isCurrentStep
        ? Colors.black
        : isDone
            ? Colors.grey
            : Colors.grey[600];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDone ? Colors.green : Colors.grey[300]!,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentStep
                    ? const Color(0xFF6366F1).withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isCurrentStep
                    ? Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCurrentStep)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '当前步骤',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    step,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: textColor,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(SocialTask task) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '任务信息',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.schedule,
              label: '计划时间',
              value: DateFormat('yyyy年MM月dd日 HH:mm').format(task.scheduledAt),
            ),
            if (task.completedAt != null)
              _buildInfoRow(
                icon: Icons.check_circle,
                label: '完成时间',
                value: DateFormat('yyyy年MM月dd日 HH:mm').format(task.completedAt!),
              ),
            _buildInfoRow(
              icon: Icons.category,
              label: '任务类型',
              value: task.typeName,
            ),
            if (task.goalRelation != null && task.goalRelation!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.flag,
                label: '目标关系',
                value: task.goalRelation!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label：',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SocialTask task) {
    if (task.status != TaskStatus.pending) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markComplete(),
            icon: const Icon(Icons.check),
            label: const Text('标记完成'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _skipTask(),
            icon: const Icon(Icons.skip_next),
            label: const Text('跳过任务'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeIcon(TaskType type) {
    IconData icon;
    Color color;
    switch (type) {
      case TaskType.sendMessage:
        icon = Icons.message;
        color = Colors.blue;
        break;
      case TaskType.sendVideo:
        icon = Icons.videocam;
        color = Colors.purple;
        break;
      case TaskType.greeting:
        icon = Icons.waving_hand;
        color = Colors.orange;
        break;
      case TaskType.socialInteraction:
        icon = Icons.thumb_up;
        color = Colors.pink;
        break;
      case TaskType.phoneCall:
        icon = Icons.phone;
        color = Colors.green;
        break;
      case TaskType.other:
        icon = Icons.task;
        color = Colors.grey;
        break;
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    String text;
    Color color;
    switch (status) {
      case TaskStatus.pending:
        text = '待完成';
        color = Colors.blue;
        break;
      case TaskStatus.completed:
        text = '已完成';
        color = Colors.green;
        break;
      case TaskStatus.skipped:
        text = '已跳过';
        color = Colors.orange;
        break;
      case TaskStatus.expired:
        text = '已过期';
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildPriorityChip(int priority) {
    Color color;
    String label;
    if (priority >= 4) {
      color = Colors.red;
      label = '高优先级';
    } else if (priority >= 3) {
      color = Colors.orange;
      label = '中优先级';
    } else {
      color = Colors.grey;
      label = '低优先级';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '$label ($priority)',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  void _markComplete() {
    final taskProvider = context.read<TaskProvider>();
    taskProvider.completeTask(widget.task.id);
    Navigator.pop(context);
  }

  void _skipTask() {
    final taskProvider = context.read<TaskProvider>();
    taskProvider.skipTask(widget.task.id);
    Navigator.pop(context);
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除任务'),
        content: const Text('确定要删除这个任务吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final taskProvider = context.read<TaskProvider>();
              taskProvider.deleteTask(widget.task.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
