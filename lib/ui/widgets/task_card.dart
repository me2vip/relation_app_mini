import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';

class TaskCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
                    if (onComplete != null)
                      TextButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('完成'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    if (onSkip != null)
                      TextButton.icon(
                        onPressed: onSkip,
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

  Widget _buildTypeIcon() {
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
