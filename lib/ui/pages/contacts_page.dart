import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../models/contact.dart';
import 'contact_detail_page.dart';
import 'contact_edit_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  ContactLevel? _filterLevel;
  String? _filterTag;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('联系人管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索联系人...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (_filterLevel != null || _filterTag != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_filterLevel != null)
                    Chip(
                      label: Text(_getLevelName(_filterLevel!)),
                      onDeleted: () => setState(() => _filterLevel = null),
                    ),
                  if (_filterLevel != null && _filterTag != null)
                    const SizedBox(width: 8),
                  if (_filterTag != null)
                    Chip(
                      label: Text(_filterTag!),
                      onDeleted: () => setState(() => _filterTag = null),
                    ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<ContactProvider>(
              builder: (context, provider, _) {
                var contacts = provider.contacts;

                // 应用筛选
                if (_filterLevel != null) {
                  contacts = contacts
                      .where((c) => c.level == _filterLevel)
                      .toList();
                }
                if (_filterTag != null) {
                  contacts = contacts
                      .where((c) => c.tags.contains(_filterTag))
                      .toList();
                }
                if (_searchQuery.isNotEmpty) {
                  contacts = contacts
                      .where((c) => c.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (contacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchQuery.isNotEmpty
                              ? '没有找到匹配的联系人'
                              : '还没有联系人',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return _ContactListItem(
                      contact: contact,
                      onTap: () {
                        provider.selectContact(contact);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ContactDetailPage(),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContactEditPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('添加联系人'),
      ),
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '筛选联系人',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text('按分层'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ContactLevel.values.map((level) {
                  return ChoiceChip(
                    label: Text(_getLevelName(level)),
                    selected: _filterLevel == level,
                    onSelected: (selected) {
                      setState(() {
                        _filterLevel = selected ? level : null;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('按标签'),
              const SizedBox(height: 10),
              Consumer<ContactProvider>(
                builder: (context, provider, _) {
                  final tags = provider.allTags;
                  if (tags.isEmpty) {
                    return const Text('暂无标签');
                  }
                  return Wrap(
                    spacing: 8,
                    children: tags.map((tag) {
                      return ChoiceChip(
                        label: Text(tag),
                        selected: _filterTag == tag,
                        onSelected: (selected) {
                          setState(() {
                            _filterTag = selected ? tag : null;
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterLevel = null;
                        _filterTag = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('清除筛选'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

}

class _ContactListItem extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const _ContactListItem({
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getLevelColor(contact.level),
          child: Text(
            contact.name.isNotEmpty ? contact.name[0] : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.levelName),
            if (contact.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: contact.tags.take(3).map((tag) {
                  return Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
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
}
