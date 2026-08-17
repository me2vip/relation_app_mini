import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../models/contact.dart';
import '../../models/task.dart';
import '../../services/storage_service.dart';
import '../widgets/contact_card.dart';
import '../widgets/task_card.dart';
import '../../core/widgets/update_dialog.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  void _checkForUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateDialog.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _DashboardView(),
          const _ContactsView(),
          const _TasksView(),
          const _AIDashboardView(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: '联系人',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_outlined),
              activeIcon: Icon(Icons.task_alt),
              label: '任务',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy),
              label: 'AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 升级提示按钮（当有新版本时显示）
                  Consumer<AppProvider>(
                    builder: (context, app, _) {
                      if (app.hasUpdate && app.latestRelease != null) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showUpdateDialog(context, app),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.system_update,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '发现新版本',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'v${app.latestRelease!.version} 可用 · 点击更新',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '你好',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '社交塔子',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Consumer<AppProvider>(
                        builder: (context, app, _) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (app.hasUpdate) ...[
                                GestureDetector(
                                  onTap: () => UpdateDialog.show(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.system_update, size: 16, color: Colors.red),
                                        SizedBox(width: 4),
                                        Text(
                                          '升级',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'v${app.currentVersion}',
                                  style: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildStatsCards(context),
                  const SizedBox(height: 30),
                  const _RelationshipFeedSection(),
                  const SizedBox(height: 30),
                  const Text(
                    '今日待办',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
          Consumer<TaskProvider>(
            builder: (context, taskProvider, _) {
              final pendingTasks = taskProvider.pendingTasks.take(3).toList();
              if (pendingTasks.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            '今日没有待办任务 🎉',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: TaskCard(
                        task: pendingTasks[index],
                        onComplete: () => taskProvider.completeTask(
                          pendingTasks[index].id,
                        ),
                      ),
                    );
                  },
                  childCount: pendingTasks.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Consumer<ContactProvider>(
            builder: (context, provider, _) {
              return _StatCard(
                icon: Icons.people,
                iconColor: const Color(0xFF6366F1),
                title: '联系人',
                value: '${provider.contacts.length}',
              );
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Consumer<TaskProvider>(
            builder: (context, provider, _) {
              return _StatCard(
                icon: Icons.task_alt,
                iconColor: Colors.green,
                title: '待办任务',
                value: '${provider.pendingTasks.length}',
              );
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Consumer<ContactProvider>(
            builder: (context, provider, _) {
              final importantCount = provider.contacts
                  .where((c) => c.level == ContactLevel.important ||
                      c.level == ContactLevel.core)
                  .length;
              return _StatCard(
                icon: Icons.star,
                iconColor: Colors.orange,
                title: '重要',
                value: '$importantCount',
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示升级对话框
void _showUpdateDialog(BuildContext context, AppProvider app) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Color(0xFF6366F1)),
          SizedBox(width: 10),
          Text('发现新版本'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '版本: ${app.latestRelease!.version}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            '大小: ${app.latestRelease!.apkSizeMB} MB',
            style: const TextStyle(color: Colors.grey),
          ),
          if (app.latestRelease!.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 15),
            const Text(
              '更新内容:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 5),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  app.latestRelease!.releaseNotes,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('稍后更新'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.pushNamed(context, '/settings');
          },
          child: const Text('去更新'),
        ),
      ],
    ),
  );
}

class _ContactsView extends StatelessWidget {
  const _ContactsView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '联系人',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/contacts'),
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ContactProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.contacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '还没有联系人',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/contacts'),
                          icon: const Icon(Icons.add),
                          label: const Text('添加联系人'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.contacts.length,
                  itemBuilder: (context, index) {
                    final contact = provider.contacts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ContactCard(
                        contact: contact,
                        onTap: () {
                          provider.selectContact(contact);
                          Navigator.pushNamed(context, '/contact');
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksView extends StatelessWidget {
  const _TasksView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '社交任务',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/tasks'),
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = provider.tasks;
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      '还没有任务\n去添加一些社交任务吧',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(
                        task: tasks[index],
                        onComplete: () => provider.completeTask(tasks[index].id),
                        onSkip: () => provider.skipTask(tasks[index].id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AIDashboardView extends StatelessWidget {
  const _AIDashboardView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI助手',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _AIFeatureCard(
              icon: Icons.smart_toy,
              title: '内部AI对话',
              description: '使用配置的AI模型进行对话',
              color: const Color(0xFF6366F1),
              onTap: () => Navigator.pushNamed(context, '/ai-chat'),
            ),
            const SizedBox(height: 15),
            _AIFeatureCard(
              icon: Icons.picture_as_pdf,
              title: '外部AI交互',
              description: '导出PDF与千问、豆包等AI交互',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/external-ai'),
            ),
            const SizedBox(height: 15),
            _AIFeatureCard(
              icon: Icons.auto_awesome,
              title: '任务生成',
              description: 'AI自动生成社交任务计划',
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/ai'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _AIFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 首页关系升迁动态（全局跟踪视图）
class _RelationshipFeedSection extends StatelessWidget {
  const _RelationshipFeedSection();

  Color _levelColor(ContactLevel level) {
    switch (level) {
      case ContactLevel.unimportant: return Colors.grey;
      case ContactLevel.normal: return Colors.blue;
      case ContactLevel.important: return Colors.orange;
      case ContactLevel.core: return Colors.red;
    }
  }

  String _levelName(ContactLevel level) {
    switch (level) {
      case ContactLevel.unimportant: return '不重要';
      case ContactLevel.normal: return '一般';
      case ContactLevel.important: return '重要';
      case ContactLevel.core: return '核心';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, contactProvider, _) {
        return FutureBuilder<List<RelationshipChange>>(
          future: DatabaseService.getAllRelationshipChanges(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final changes = all
                .where((c) => c.type != RelationshipChangeType.initial)
                .take(4)
                .toList();
            final nameOf = (String id) =>
                contactProvider.contacts
                    .where((c) => c.id == id)
                    .firstOrNull?.name ??
                '联系人';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '关系升迁动态',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (changes.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          final contact = contactProvider.contacts
                              .where((c) => c.id == changes.first.contactId)
                              .firstOrNull;
                          if (contact != null) {
                            contactProvider.selectContact(contact);
                            Navigator.pushNamed(context, '/contact-detail');
                          }
                        },
                        child: const Text('查看详情'),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                if (changes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '暂无关系升迁记录，去联系人详情调整层级试试',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...changes.map((c) {
                    final color = c.isPromotion
                        ? Colors.green
                        : c.isDemotion
                            ? Colors.orange
                            : Colors.grey;
                    final icon = c.isPromotion
                        ? Icons.arrow_upward
                        : c.isDemotion
                            ? Icons.arrow_downward
                            : Icons.remove;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(
                          '${nameOf(c.contactId)}: ${_levelName(c.fromLevel)} → ${_levelName(c.toLevel)}',
                        ),
                        subtitle: Text(
                          '${c.reason} · ${DateFormat('MM-dd').format(c.changedAt)}',
                        ),
                        onTap: () {
                          final contact = contactProvider.contacts
                              .where((x) => x.id == c.contactId)
                              .firstOrNull;
                          if (contact != null) {
                            contactProvider.selectContact(contact);
                            Navigator.pushNamed(context, '/contact-detail');
                          }
                        },
                      ),
                    );
                  }).toList(),
              ],
            );
          },
        );
      },
    );
  }
}
