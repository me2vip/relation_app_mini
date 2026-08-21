import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';

class TaskCard extends StatefulWidget {
  final SocialTask task;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onComplete,
    this.onSkip,
    this.onTap,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Card(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: task.status == TaskStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.status == TaskStatus.completed
                            ? Colors.grey
                            : null,
                      ),
                    ),
                  ),
                  if (task.contactName.isNotEmpty && task.contactName != '无')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        task.contactName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: _expanded ? 10 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (task.steps.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildStepsPreview(),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: task.isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MM-dd HH:mm').format(task.scheduledAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: task.isOverdue ? Colors.red : Colors.grey[600],
                        ),
                      ),
                      if (task.isOverdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '已过期',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  _buildStatusBadge(),
                ],
              ),
              if (task.status == TaskStatus.pending) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (task.steps.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _expanded = !_expanded);
                        },
                        icon: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                        ),
                        label: Text(_expanded ? '收起步骤' : '查看步骤(${task.steps.length})'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple,
                        ),
                      ),
                    if (widget.onComplete != null)
                      TextButton.icon(
                        onPressed: widget.onComplete,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('完成'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    if (widget.onSkip != null)
                      TextButton.icon(
                        onPressed: widget.onSkip,
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text('跳过'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepsPreview() {
    final task = widget.task;
    final displaySteps = _expanded ? task.steps : task.steps.take(2).toList();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, size: 14, color: Colors.purple),
              const SizedBox(width: 4),
              const Text(
                '执行步骤',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
              if (task.steps.length > 2 && !_expanded)
                Text(
                  '  +${task.steps.length - 2}',
                  style: const TextStyle(fontSize: 12, color: Colors.purple),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...displaySteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < displaySteps.length - 1 ? 6 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                      maxLines: _expanded ? null : 2,
                      overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypeIcon() {
    final task = widget.task;
    IconData icon;
    Color color;

    switch (task.type) {
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusBadge() {
    final task = widget.task;
    Color color;
    String text;

    switch (task.status) {
      case TaskStatus.pending:
        color = Colors.blue;
        text = '待完成';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        text = '已完成';
        break;
      case TaskStatus.skipped:
        color = Colors.orange;
        text = '已跳过';
        break;
      case TaskStatus.expired:
        color = Colors.red;
        text = '已过期';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
