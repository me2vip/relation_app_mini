import 'package:flutter/material.dart';
import '../../models/contact.dart';

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;

  const ContactCard({
    super.key,
    required this.contact,
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _getLevelColor(contact.level),
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildLevelBadge(contact.level),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (contact.goalRelation != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.flag_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            contact.goalRelation!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    if (contact.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: contact.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(ContactLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getLevelColor(level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _getLevelName(level),
        style: TextStyle(
          fontSize: 10,
          color: _getLevelColor(level),
          fontWeight: FontWeight.w500,
        ),
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
}
