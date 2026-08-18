import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../models/contact.dart';
import '../../models/task.dart';
import 'package:intl/intl.dart';
import 'contact_edit_page.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ContactEditPage(contact: contact)),
                ),
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
                  Tab(text: '关系'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _InfoTab(contact: contact),
                    _InteractionTab(contact: contact),
                    _TaskTab(contact: contact),
                    _RelationshipTab(contact: contact),
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
        // ===== 联系方式 =====
        if (contact.methods.isNotEmpty) ...[
          _sectionTitle('联系方式'),
          ...contact.methods.map((method) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(_getPlatformIcon(method.platform)),
              title: Text(method.platform),
              subtitle: Text(method.account),
            ),
          )),
          const SizedBox(height: 16),
        ],

        // ===== 基本信息 =====
        _sectionTitle('基本信息'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          _infoRow('性别', contact.genderName),
          if (contact.age != null || contact.birthday != null)
            _infoRow('年龄/生日', '${contact.age ?? '未知'}${contact.birthday != null ? ' (${DateFormat('yyyy-MM-dd').format(contact.birthday!)})' : ''}'),
          if (contact.ethnicity != null) _infoRow('民族', contact.ethnicity!),
          if (contact.religion != null) _infoRow('宗教', contact.religion!),
          if (contact.politicalAffiliation != null) _infoRow('政治面貌', contact.politicalAffiliation!),
          _infoRow('婚姻状况', contact.maritalStatusName),
        ]))),
        const SizedBox(height: 16),

        // ===== 教育背景 =====
        if (contact.educationLevel != EducationLevel.unknown || contact.school != null || contact.major != null) ...[
          _sectionTitle('教育背景'),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            _infoRow('学历', contact.educationLevelName),
            if (contact.school != null) _infoRow('学校', contact.school!),
            if (contact.major != null) _infoRow('专业', contact.major!),
          ]))),
          const SizedBox(height: 16),
        ],

        // ===== 职业信息 =====
        if (contact.industry != null || contact.company != null || contact.position != null || contact.workExperience != null) ...[
          _sectionTitle('职业信息'),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            if (contact.industry != null) _infoRow('行业', contact.industry!),
            if (contact.company != null) _infoRow('公司', contact.company!),
            if (contact.position != null) _infoRow('职位', contact.position!),
            if (contact.workExperience != null) _infoRow('过往经历', contact.workExperience!),
          ]))),
          const SizedBox(height: 16),
        ],

        // ===== 个性与价值观 =====
        _sectionTitle('个性与价值观'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          if (contact.personalityTags != null) _infoRow('性格标签', contact.personalityTags!),
          if (contact.personalityDesc != null) _infoRow('性格描述', contact.personalityDesc!),
          if (contact.characterTags != null) _infoRow('人品标签', contact.characterTags!),
          if (contact.taboos != null) _infoRow('大忌', contact.taboos!, highlight: true),
          if (contact.values != null) _infoRow('价值观', contact.values!),
        ]))),
        const SizedBox(height: 16),

        // ===== 个人特质 =====
        if (contact.hobbies != null || contact.strengths != null || contact.weaknesses != null || contact.fears != null || contact.desires != null || contact.skills != null || contact.tastePreferences != null) ...[
          _sectionTitle('个人特质'),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            if (contact.hobbies != null) _infoRow('兴趣爱好', contact.hobbies!),
            if (contact.strengths != null) _infoRow('优点', contact.strengths!),
            if (contact.weaknesses != null) _infoRow('缺点', contact.weaknesses!),
            if (contact.fears != null) _infoRow('恐惧', contact.fears!, highlight: true),
            if (contact.desires != null) _infoRow('渴望', contact.desires!),
            if (contact.skills != null) _infoRow('技能', contact.skills!),
            if (contact.tastePreferences != null) _infoRow('口味偏好', contact.tastePreferences!),
          ]))),
          const SizedBox(height: 16),
        ],

        // ===== 家庭信息 =====
        if (contact.homeAddress != null || contact.familySituation != null || contact.familyEconomicStatus != null || contact.familyEmotionalStatus != null) ...[
          _sectionTitle('家庭信息'),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            if (contact.homeAddress != null) _infoRow('家庭住址', contact.homeAddress!),
            if (contact.familySituation != null) _infoRow('家庭情况', contact.familySituation!),
            if (contact.familyEconomicStatus != null) _infoRow('经济状况', contact.familyEconomicStatus!),
            if (contact.familyEmotionalStatus != null) _infoRow('感情状况', contact.familyEmotionalStatus!),
          ]))),
          const SizedBox(height: 16),
        ],

        // ===== 信任与关系 =====
        _sectionTitle('信任与关系'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          _infoRow('TA对我的信任度', '${contact.taTrustLevel}/10'),
          _infoRow('我对TA的信任度', '${contact.myTrustLevel}/10'),
          if (contact.socialCircles != null) _infoRow('所交往圈子', contact.socialCircles!),
          if (contact.currentStatus != null) _infoRow('目前现状', contact.currentStatus!),
        ]))),
        const SizedBox(height: 16),

        // ===== 目标与欲望 =====
        if (contact.moneyDesireLevel != null || contact.ambitionLevel != null || contact.shortTermGoals != null || contact.longTermGoals != null || contact.goalRelation != null) ...[
          _sectionTitle('目标与欲望'),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            if (contact.moneyDesireLevel != null) _infoRow('挣钱欲望', contact.moneyDesireLevel!),
            if (contact.ambitionLevel != null) _infoRow('上进心', contact.ambitionLevel!),
            if (contact.shortTermGoals != null) _infoRow('短期目标', contact.shortTermGoals!),
            if (contact.longTermGoals != null) _infoRow('长期目标', contact.longTermGoals!),
            if (contact.goalRelation != null) _infoRow('目标关系', contact.goalRelation!),
          ]))),
          const SizedBox(height: 16),
        ],

        // ===== 标签 =====
        if (contact.tags.isNotEmpty) ...[
          _sectionTitle('标签'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: contact.tags.map((tag) => Chip(label: Text(tag))).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // ===== 系统信息 =====
        _sectionTitle('系统信息'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          _infoRow('添加时间', DateFormat('yyyy-MM-dd HH:mm').format(contact.createdAt)),
          _infoRow('更新时间', DateFormat('yyyy-MM-dd HH:mm').format(contact.updatedAt)),
        ]))),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
  );

  Widget _infoRow(String label, String value, {bool highlight = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: highlight ? Colors.red[700] : null))),
      ],
    ),
  );

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case '微信': return Icons.chat;
      case 'QQ': return Icons.chat_bubble;
      case '手机': return Icons.phone;
      case '邮箱': return Icons.email;
      default: return Icons.contact_page;
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

class _RelationshipTab extends StatelessWidget {
  final Contact contact;
  const _RelationshipTab({required this.contact});

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
      builder: (context, provider, _) {
        return FutureBuilder<List<RelationshipChange>>(
          future: provider.getRelationshipTimeline(contact.id),
          builder: (context, snapshot) {
            final changes = snapshot.data ?? [];
            final progress = contact.level.index / ContactLevel.core.index;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _levelColor(contact.level).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _levelName(contact.level),
                                style: TextStyle(
                                  color: _levelColor(contact.level),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (contact.goalRelation != null)
                              Expanded(
                                child: Text(
                                  '目标: ${contact.goalRelation}',
                                  style: const TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _levelColor(contact.level),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '关系进度: ${contact.level.index} / ${ContactLevel.core.index}（${_levelName(contact.level)} → 核心）',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLevelChangeDialog(context, contact, provider),
                    icon: const Icon(Icons.trending_up),
                    label: const Text('调整关系层级'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '关系演进时间线',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                if (changes.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        '暂无关系变更记录',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...changes.map((c) => _buildTimelineItem(c)).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineItem(RelationshipChange change) {
    final color = change.isPromotion
        ? Colors.green
        : change.isDemotion
            ? Colors.orange
            : Colors.grey;
    final icon = change.isPromotion
        ? Icons.arrow_upward
        : change.isDemotion
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
          '${_levelName(change.fromLevel)} → ${_levelName(change.toLevel)}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(change.reason),
            const SizedBox(height: 4),
            Text(
              '${change.typeName} · ${DateFormat('yyyy-MM-dd HH:mm').format(change.changedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showLevelChangeDialog(
    BuildContext context,
    Contact contact,
    ContactProvider provider,
  ) {
    ContactLevel selected = contact.level;
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('调整关系层级'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ContactLevel>(
                  value: selected,
                  decoration: const InputDecoration(labelText: '新层级'),
                  items: ContactLevel.values.map((l) {
                    return DropdownMenuItem(
                      value: l,
                      child: Text(_levelName(l)),
                    );
                  }).toList(),
                  onChanged: (v) => setSt(() => selected = v!),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: '变更原因',
                    hintText: '如: 完成3次深度交流、共同完成项目',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final newLevel = selected;
                RelationshipChangeType type;
                if (newLevel.index > contact.level.index) {
                  type = RelationshipChangeType.promote;
                } else if (newLevel.index < contact.level.index) {
                  type = RelationshipChangeType.demote;
                } else {
                  type = RelationshipChangeType.manual;
                }
                provider.changeContactLevel(
                  contact.id,
                  newLevel,
                  reasonController.text,
                  type: type,
                );
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
