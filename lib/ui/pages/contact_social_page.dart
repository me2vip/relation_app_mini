import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../core/providers/contact_social_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../models/contact.dart';
import '../../models/contact_social.dart';

class ContactSocialPage extends StatefulWidget {
  final Contact contact;

  const ContactSocialPage({super.key, required this.contact});

  @override
  State<ContactSocialPage> createState() => _ContactSocialPageState();
}

class _ContactSocialPageState extends State<ContactSocialPage>
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
        title: Text('${widget.contact.name} · 社交管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '社交航向'),
            Tab(text: '互动记录'),
            Tab(text: '大纲设置'),
          ],
        ),
      ),
      body: Consumer<ContactSocialProvider>(
        builder: (context, provider, _) {
          final social = provider.getSocial(widget.contact.id);
          final logs = provider.getLogsForContact(widget.contact.id);
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDirectionTab(provider, social),
              _buildLogsTab(provider, logs),
              _buildOutlineTab(provider, social),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLogDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('添加互动'),
      ),
    );
  }

  Widget _buildDirectionTab(ContactSocialProvider provider, ContactSocial social) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDirectionCard(provider, social),
          const SizedBox(height: 16),
          _buildStageCard(provider, social),
          const SizedBox(height: 16),
          _buildWarmthCard(provider, social),
          const SizedBox(height: 16),
          _buildTemplateCard(provider, social),
        ],
      ),
    );
  }

  Widget _buildDirectionCard(ContactSocialProvider provider, ContactSocial social) {
    final directions = [
      SocialDirection.maintain,
      SocialDirection.deepen,
      SocialDirection.repair,
      SocialDirection.transition,
      SocialDirection.casual,
      SocialDirection.business,
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '社交航向',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '选择你与${widget.contact.name}的社交发展方向',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: directions.map((d) {
                final selected = social.direction == d;
                return GestureDetector(
                  onTap: () {
                    provider.updateSocial(
                      contactId: widget.contact.id,
                      direction: d,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF6366F1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? const Color(0xFF6366F1) : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      _directionName(d),
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: social.directionNote,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '补充说明',
                hintText: '描述你对这段关系的期望...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                provider.updateSocial(
                  contactId: widget.contact.id,
                  directionNote: v,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _directionName(SocialDirection d) {
    switch (d) {
      case SocialDirection.maintain: return '维持现状';
      case SocialDirection.deepen: return '深化关系';
      case SocialDirection.repair: return '修复关系';
      case SocialDirection.transition: return '转变关系';
      case SocialDirection.casual: return '轻松社交';
      case SocialDirection.business: return '业务社交';
    }
  }

  Widget _buildStageCard(ContactSocialProvider provider, ContactSocial social) {
    final stages = RelationshipStage.values;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关系阶段',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('当前阶段', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<RelationshipStage>(
                        value: social.currentStage,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: stages.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(_stageName(s)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            provider.updateSocial(
                              contactId: widget.contact.id,
                              currentStage: v,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Colors.grey),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('目标阶段', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<RelationshipStage>(
                        value: social.targetStage,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: stages.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(_stageName(s)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            provider.updateSocial(
                              contactId: widget.contact.id,
                              targetStage: v,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, size: 16, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '进度: ${social.currentStageName} → ${social.targetStageName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stageName(RelationshipStage s) {
    switch (s) {
      case RelationshipStage.stranger: return '陌生人';
      case RelationshipStage.acquaintance: return '熟人';
      case RelationshipStage.friend: return '朋友';
      case RelationshipStage.closeFriend: return '好友';
      case RelationshipStage.bestFriend: return '挚友';
      case RelationshipStage.confidant: return '知己';
      case RelationshipStage.intimate: return '亲密';
    }
  }

  Widget _buildWarmthCard(ContactSocialProvider provider, ContactSocial social) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '关系温度',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getWarmthColor(social.warmthLevel),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${social.warmthLevel}/10',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: social.warmthLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                provider.updateSocial(
                  contactId: widget.contact.id,
                  warmthLevel: v.round(),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('冷淡', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('适中', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('热烈', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getWarmthColor(int level) {
    if (level >= 8) return Colors.red;
    if (level >= 5) return Colors.orange;
    if (level >= 3) return Colors.yellow;
    return Colors.blue;
  }

  Widget _buildTemplateCard(ContactSocialProvider provider, ContactSocial social) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '快速模板',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '选择预设模板快速配置社交航向',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...kSocialOutlineTemplates.map((t) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    provider.applyTemplate(
                      contactId: widget.contact.id,
                      template: t,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已应用模板：${t.name}')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF6366F1)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                t.description,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTab(ContactSocialProvider provider, List<InteractionLog> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无互动记录', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              '点击右下角按钮添加首次互动',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogItem(provider, log);
      },
    );
  }

  Widget _buildLogItem(ContactSocialProvider provider, InteractionLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  log.emotionalToneEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getSourceColor(log.source),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    log.sourceName,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              log.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            if (log.aiAnalysis != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'AI分析',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.aiAnalysis!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (log.topicArea != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(log.topicArea!, style: const TextStyle(fontSize: 11)),
                  ),
                if (log.emotionalTone != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getEmotionColor(log.emotionalTone!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(log.emotionalTone!, style: const TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDateTime(log.occurredAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () {
                    provider.removeInteractionLog(
                      contactId: log.contactId,
                      logId: log.id,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSourceColor(InteractionLogType s) {
    switch (s) {
      case InteractionLogType.manual: return Colors.grey;
      case InteractionLogType.internalAI: return Colors.blue;
      case InteractionLogType.externalAI: return Colors.purple;
    }
  }

  Color _getEmotionColor(String tone) {
    switch (tone) {
      case '积极': return Colors.green;
      case '消极': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildOutlineTab(ContactSocialProvider provider, ContactSocial social) {
    final allTopics = [
      '日常问候', '近期生活', '工作近况', '兴趣爱好', '共同回忆',
      '未来计划', '情感话题', '热点话题', '美食分享', '旅行见闻',
      '运动健身', '娱乐八卦', '学习成长', '家庭近况', '朋友圈动态',
      '自我介绍', '共同朋友', '生活趣事', '稳定话题', '深度交流',
      '职业成长', '行业动态', '合作机会', '资源分享', '娱乐分享',
    ];
    final avoidList = [
      '负面情绪', '敏感话题', '前任', '金钱', '政治', '宗教',
      '隐私问题', '家庭矛盾', '过去矛盾', '私人八卦', '感情问题',
      '公开活动', '多人聚会', '演讲发言',
    ];
    final profileProvider = context.read<ProfileProvider>();
    final userProfile = profileProvider.profile;
    final isGenerating = provider.isGeneratingOutline;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== AI 生成入口 =====
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'AI 生成社交大纲',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '基于社交航向、关系阶段和你的用户画像，智能生成推荐话题和社交策略。生成后仍可手动修改。',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.bolt, size: 18),
                        label: const Text('内部AI生成', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: isGenerating
                            ? null
                            : () async {
                          provider.setGeneratingOutline(true);
                          try {
                            await Future.delayed(const Duration(milliseconds: 500));
                            final result = provider.generateOutlineWithInternalAI(
                              contact: widget.contact,
                              social: social,
                              userProfile: userProfile,
                            );
                            await provider.applyGeneratedOutline(
                              contactId: widget.contact.id,
                              outlineTopics: List<String>.from(result['outlineTopics']),
                              avoidTopics: List<String>.from(result['avoidTopics']),
                              customOutline: result['customOutline'] as String,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('社交大纲已生成 ✓')),
                              );
                            }
                          } finally {
                            provider.setGeneratingOutline(false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('外部AI生成', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: isGenerating
                            ? null
                            : () => _showExternalAIOutlineDialog(provider, social),
                      ),
                    ),
                  ],
                ),
                if (isGenerating) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ===== 推荐话题 =====
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.thumb_up, color: Color(0xFF6366F1), size: 20),
                      SizedBox(width: 6),
                      Text(
                        '推荐话题',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Tooltip(
                        message: '可多选，AI生成任务时优先从已选话题入手',
                        child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AI生成任务时优先考虑的话题方向（已选中为你当前的推荐）',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allTopics.map((t) {
                      final selected = social.outlineTopics.contains(t);
                      return GestureDetector(
                        onTap: () {
                          final newList = List<String>.from(social.outlineTopics);
                          if (selected) {
                            newList.remove(t);
                          } else {
                            newList.add(t);
                          }
                          provider.updateSocial(
                            contactId: widget.contact.id,
                            outlineTopics: newList,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF6366F1).withOpacity(0.2)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF6366F1)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              color: selected ? const Color(0xFF6366F1) : Colors.black87,
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ===== 避免话题 =====
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.block, color: Colors.redAccent, size: 20),
                      SizedBox(width: 6),
                      Text(
                        '避免话题',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '与${widget.contact.name}应避免的话题',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: avoidList.map((t) {
                      final selected = social.avoidTopics.contains(t);
                      return GestureDetector(
                        onTap: () {
                          final newList = List<String>.from(social.avoidTopics);
                          if (selected) {
                            newList.remove(t);
                          } else {
                            newList.add(t);
                          }
                          provider.updateSocial(
                            contactId: widget.contact.id,
                            avoidTopics: newList,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? Colors.red : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              color: selected ? Colors.red : Colors.black87,
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ===== 自定义大纲 =====
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.edit_note, color: Color(0xFFF59E0B), size: 22),
                      SizedBox(width: 6),
                      Text(
                        '自定义大纲',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '描述具体的社交计划和大纲（建议用AI生成后再微调）',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: social.customOutline,
                    maxLines: 10,
                    minLines: 5,
                    decoration: const InputDecoration(
                      hintText: '例如：\n• 社交航向：深化关系\n• 关系阶段：朋友 → 好友\n• 执行建议：\n  1. 每周主动聊1-2次\n  2. 优先选择兴趣爱好话题\n  3. 重要日期提前准备心意...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (v) {
                      provider.updateSocial(
                        contactId: widget.contact.id,
                        customOutline: v,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 外部AI生成社交大纲对话框 =====
  Future<void> _showExternalAIOutlineDialog(
    ContactSocialProvider provider,
    ContactSocial social,
  ) async {
    final profileProvider = context.read<ProfileProvider>();
    final userProfile = profileProvider.profile;
    final prompt = provider.buildExternalAIOutlinePrompt(
      contact: widget.contact,
      social: social,
      userProfile: userProfile,
    );
    final pasteController = TextEditingController();
    final tabController = TabController(length: 2, vsync: this);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('外部AI生成社交大纲'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: tabController,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: '① 复制提示词'),
                  Tab(text: '② 粘贴结果'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    // ===== Tab 1: 提示词复制 =====
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '将以下内容复制到任意 AI App（千问/豆包/ChatGPT等）：',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: SelectableText(
                              prompt,
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: prompt));
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('提示词已复制 ✓')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('复制提示词'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ===== Tab 2: 粘贴结果 =====
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '粘贴 AI 返回的 JSON 结果：',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: pasteController,
                            maxLines: 12,
                            decoration: const InputDecoration(
                              hintText: '粘贴AI返回的JSON，例如：\n{\n  "outlineTopics": [...],\n  "avoidTopics": [...],\n  "customOutline": "..."\n}',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = pasteController.text.trim();
              if (text.isEmpty) {
                tabController.animateTo(1);
                return;
              }
              try {
                final parsed = jsonDecode(text) as Map<String, dynamic>;
                final List<String> outlineTopics = (parsed['outlineTopics'] as List?)
                    ?.map((e) => e.toString()).toList() ?? [];
                final List<String> avoidTopics = (parsed['avoidTopics'] as List?)
                    ?.map((e) => e.toString()).toList() ?? [];
                final String? customOutline = parsed['customOutline'] as String?;

                if (outlineTopics.isEmpty && avoidTopics.isEmpty &&
                    (customOutline == null || customOutline.isEmpty)) {
                  throw Exception('内容为空');
                }

                await provider.applyGeneratedOutline(
                  contactId: widget.contact.id,
                  outlineTopics: outlineTopics,
                  avoidTopics: avoidTopics,
                  customOutline: customOutline,
                );
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('社交大纲已应用 ✓')),
                  );
                  Navigator.pop(ctx, true);
                }
              } catch (e) {
                showDialog(
                  context: ctx,
                  builder: (ctx2) => AlertDialog(
                    title: const Text('解析失败'),
                    content: Text('无法解析返回结果，请确认是合法的JSON格式。\n\n错误：$e'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2),
                        child: const Text('好的'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('应用结果'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddLogDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String emotionalTone = '中性';
    String topicArea = '生活';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('添加互动记录'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      hintText: '简要描述这次互动',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '详细内容',
                      hintText: '描述互动的具体内容和感受',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: emotionalTone,
                    decoration: const InputDecoration(labelText: '情绪基调'),
                    items: const ['积极', '中性', '消极']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => emotionalTone = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: topicArea,
                    decoration: const InputDecoration(labelText: '话题领域'),
                    items: const ['生活', '工作', '情感', '兴趣', '其他']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => topicArea = v);
                      }
                    },
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
                  if (titleController.text.trim().isEmpty) return;
                  Navigator.pop(ctx, {
                    'title': titleController.text.trim(),
                    'content': contentController.text.trim(),
                    'emotionalTone': emotionalTone,
                    'topicArea': topicArea,
                  });
                },
                child: const Text('保存'),
              ),
              OutlinedButton(
                onPressed: () async {
                  if (contentController.text.trim().isEmpty) return;
                  final len = contentController.text.length;
                  final endIndex = len > 20 ? 20 : len;
                  Navigator.pop(ctx, {
                    'title': titleController.text.trim().isEmpty
                        ? 'AI分析: ${contentController.text.substring(0, endIndex)}'
                        : titleController.text.trim(),
                    'content': contentController.text.trim(),
                    'useAI': true,
                  });
                },
                child: const Text('AI分析'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      final provider = context.read<ContactSocialProvider>();

      if (result['useAI'] == true) {
        await provider.analyzeInteractionWithAI(
          contactId: widget.contact.id,
          contactName: widget.contact.name,
          content: result['content'] as String,
        );
      } else {
        await provider.addInteractionLog(
          contactId: widget.contact.id,
          contactName: widget.contact.name,
          title: result['title'] as String,
          content: result['content'] as String,
          emotionalTone: result['emotionalTone'] as String?,
          topicArea: result['topicArea'] as String?,
        );
      }

      if (mounted) {
        context.read<ProfileProvider>().incrementInteractions();
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
