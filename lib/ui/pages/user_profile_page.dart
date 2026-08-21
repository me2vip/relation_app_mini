import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../models/user_profile.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('我的画像'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '画像设置'),
            Tab(text: '变更记录'),
          ],
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          final profile = provider.profile;
          if (profile == null || provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(profile),
              _buildHistoryTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileTab(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(profile),
          const SizedBox(height: 16),
          _buildPersonalitySection(profile),
          const SizedBox(height: 16),
          _buildCommunicationSection(profile),
          const SizedBox(height: 16),
          _buildSocialEnergySection(profile),
          const SizedBox(height: 16),
          _buildStatusSection(profile),
          const SizedBox(height: 16),
          _buildStatsCard(profile),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(UserProfile profile) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              child: const Icon(Icons.person, size: 40, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 12),
            Text(
              profile.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              profile.summary,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalitySection(UserProfile profile) {
    final allTraits = [
      '社恐', '内向', '外向', '活泼', '慢热', '直接', '委婉', '幽默', '理性', '感性',
      '热情', '保守', '开朗', '谨慎', '善解人意', '独立自主',
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '性格特征',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '选择最符合你的性格标签（可多选）',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTraits.map((trait) {
                final selected = profile.personalityTraits.contains(trait);
                return GestureDetector(
                  onTap: () {
                    final newTraits = List<String>.from(profile.personalityTraits);
                    if (selected) {
                      newTraits.remove(trait);
                    } else {
                      newTraits.add(trait);
                    }
                    context.read<ProfileProvider>().updateProfile(
                      personalityTraits: newTraits,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF6366F1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF6366F1)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      trait,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationSection(UserProfile profile) {
    final styles = ['委婉型', '直接型', '幽默型', '理性型', '感性型', '热情型'];
    final labels = ['发短信意愿', '打电话意愿', '见面意愿'];
    final values = [profile.opennessToTexting, profile.opennessToCalling, profile.opennessToMeeting];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '沟通风格',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: styles.map((style) {
                final selected = profile.communicationStyle == style;
                return GestureDetector(
                  onTap: () {
                    context.read<ProfileProvider>().updateProfile(
                      communicationStyle: style,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF6366F1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      style,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${labels[i]} (${values[i]}/5)',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Slider(
                      value: values[i].toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: values[i].toString(),
                      onChanged: (v) {
                        final newVal = v.round();
                        final provider = context.read<ProfileProvider>();
                        if (i == 0) provider.updateProfile(opennessToTexting: newVal);
                        if (i == 1) provider.updateProfile(opennessToCalling: newVal);
                        if (i == 2) provider.updateProfile(opennessToMeeting: newVal);
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialEnergySection(UserProfile profile) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.battery_charging_full, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text(
                  '社交能量',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEnergyColor(profile.socialEnergy),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${profile.socialEnergy}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: profile.socialEnergy / 100,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(_getEnergyColor(profile.socialEnergy)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEnergyDescription(profile.socialEnergy),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEnergyColor(int energy) {
    if (energy >= 70) return Colors.green;
    if (energy >= 40) return Colors.blue;
    if (energy >= 20) return Colors.orange;
    return Colors.red;
  }

  String _getEnergyDescription(int energy) {
    if (energy >= 70) return '社交活跃期，适合主动出击';
    if (energy >= 40) return '社交正常期，保持日常联系';
    if (energy >= 20) return '社交低潮期，建议轻松社交';
    return '社恐状态，建议文字交流为主';
  }

  Widget _buildStatusSection(UserProfile profile) {
    final options = ['社恐内向', '稳定社交', '积极社交', '追求中', '稳定关系', '单身中', '专注事业'];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '状态标签',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '反映你当前的社交状态',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final selected = profile.statusTags.contains(opt);
                return GestureDetector(
                  onTap: () {
                    final newTags = List<String>.from(profile.statusTags);
                    if (selected) {
                      newTags.remove(opt);
                    } else {
                      newTags.add(opt);
                    }
                    context.read<ProfileProvider>().updateProfile(
                      statusTags: newTags,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF6366F1).withOpacity(0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? const Color(0xFF6366F1) : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: selected ? const Color(0xFF6366F1) : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserProfile profile) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '统计数据',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('已完成任务', '${profile.totalTasksCompleted}'),
                _buildStatItem('互动次数', '${profile.totalInteractions}'),
                _buildStatItem('完成率', '${(profile.taskCompletionRate * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHistoryTab(ProfileProvider provider) {
    final logs = provider.changeLogs;
    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无变更记录', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '全部变更记录 (${logs.length})',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                TextButton(
                  onPressed: () {
                    provider.clearChangeLogs();
                  },
                  child: const Text('清空', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }

        final log = logs[index - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.edit_note, size: 16, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log.fieldName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: log.reason.contains('自动')
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        log.reason,
                        style: TextStyle(
                          fontSize: 11,
                          color: log.reason.contains('自动') ? Colors.orange : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.oldValue.isEmpty ? '(空)' : log.oldValue,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.newValue,
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(log.changedAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
