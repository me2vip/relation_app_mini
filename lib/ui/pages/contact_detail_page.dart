import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/contact_social_provider.dart';
import '../../core/providers/channel_config_provider.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../models/contact.dart';
import '../../models/task.dart';
import '../../models/ai_config.dart';
import '../../models/social_channel_config.dart';
import 'package:intl/intl.dart';
import 'contact_edit_page.dart';
import 'contact_social_page.dart';

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

        final levelColor = _getLevelColor(contact.level);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [levelColor.withOpacity(0.08), Colors.white],
              ),
            ),
            child: Column(
              children: [
                _buildAppBar(context, contact, levelColor),
                _buildHeroHeader(contact, levelColor),
                _buildModernTabBar(levelColor),
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
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Contact contact, Color levelColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor, _getLightenColor(levelColor)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ContactEditPage(contact: contact)),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除联系人'),
                      ],
                    ),
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
        ),
      ),
    );
  }

  Widget _buildHeroHeader(Contact contact, Color levelColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getLightenColor(levelColor), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Transform.translate(
            offset: const Offset(0, -30),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: levelColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [levelColor, _getLightenColor(levelColor)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          contact.name.isNotEmpty ? contact.name[0] : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [levelColor, _getLightenColor(levelColor)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: levelColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        contact.levelName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (contact.goalRelation != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '目标: ${contact.goalRelation}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildQuickActions(contact, levelColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Contact contact, Color levelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _quickAction(
            icon: Icons.chat_bubble_outline,
            label: '聊天',
            color: levelColor,
            onTap: () {},
          ),
          _quickAction(
            icon: Icons.phone_outlined,
            label: '通话',
            color: levelColor,
            onTap: () {},
          ),
          _quickAction(
            icon: Icons.videocam_outlined,
            label: '视频',
            color: levelColor,
            onTap: () {},
          ),
          _quickAction(
            icon: Icons.share_outlined,
            label: '分享',
            color: levelColor,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar(Color levelColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [levelColor, _getLightenColor(levelColor)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: levelColor.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: '信息'),
          Tab(text: '互动'),
          Tab(text: '任务'),
          Tab(text: '关系'),
        ],
      ),
    );
  }

  Color _getLevelColor(ContactLevel level) {
    switch (level) {
      case ContactLevel.unimportant:
        return const Color(0xFF9E9E9E);
      case ContactLevel.normal:
        return const Color(0xFF2196F3);
      case ContactLevel.important:
        return const Color(0xFFFF9800);
      case ContactLevel.core:
        return const Color(0xFFE53935);
    }
  }

  Color _getLightenColor(Color color) {
    return Color.lerp(color, Colors.white, 0.35) ?? color;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        _buildContactMethods(context),
        if (contact.methods.isNotEmpty) const SizedBox(height: 20),
        _sectionTitle('基本信息', Icons.person),
        _infoCard([
          _infoRow(Icons.transgender, '性别', contact.genderName),
          if (contact.age != null || contact.birthday != null)
            _infoRow(
                Icons.cake,
                '年龄/生日',
                '${contact.age ?? '未知'}${contact.birthday != null ? ' (${DateFormat('yyyy-MM-dd').format(contact.birthday!)})' : ''}'),
          if (contact.ethnicity != null)
            _infoRow(Icons.people, '民族', contact.ethnicity!),
          if (contact.religion != null)
            _infoRow(Icons.self_improvement, '宗教', contact.religion!),
          if (contact.politicalAffiliation != null)
            _infoRow(
                Icons.account_balance, '政治面貌', contact.politicalAffiliation!),
          _infoRow(Icons.favorite, '婚姻状况', contact.maritalStatusName),
        ]),
        const SizedBox(height: 20),
        if (contact.educationLevel != EducationLevel.unknown ||
            contact.school != null ||
            contact.major != null) ...[
          _sectionTitle('教育背景', Icons.school),
          _infoCard([
            _infoRow(Icons.developer_board, '学历', contact.educationLevelName),
            if (contact.school != null)
              _infoRow(Icons.account_balance, '学校', contact.school!),
            if (contact.major != null)
              _infoRow(Icons.menu_book, '专业', contact.major!),
          ]),
          const SizedBox(height: 20),
        ],
        if (contact.industry != null ||
            contact.company != null ||
            contact.position != null ||
            contact.workExperience != null) ...[
          _sectionTitle('职业信息', Icons.work),
          _infoCard([
            if (contact.industry != null)
              _infoRow(Icons.business, '行业', contact.industry!),
            if (contact.company != null)
              _infoRow(Icons.apartment, '公司', contact.company!),
            if (contact.position != null)
              _infoRow(Icons.badge, '职位', contact.position!),
            if (contact.workExperience != null)
              _infoRow(
                  Icons.timeline, '过往经历', contact.workExperience!),
          ]),
          const SizedBox(height: 20),
        ],
        _sectionTitle('个性与价值观', Icons.auto_awesome),
        _infoCard([
          if (contact.personalityTags != null)
            _infoRow(Icons.face, '性格标签', contact.personalityTags!),
          if (contact.personalityDesc != null)
            _infoRow(
                Icons.description, '性格描述', contact.personalityDesc!),
          if (contact.characterTags != null)
            _infoRow(Icons.verified_user, '人品标签', contact.characterTags!),
          if (contact.taboos != null)
            _infoRow(Icons.block, '大忌', contact.taboos!,
                highlight: true),
          if (contact.values != null)
            _infoRow(Icons.lightbulb, '价值观', contact.values!),
        ]),
        const SizedBox(height: 20),
        if (contact.hobbies != null ||
            contact.strengths != null ||
            contact.weaknesses != null ||
            contact.fears != null ||
            contact.desires != null ||
            contact.skills != null ||
            contact.tastePreferences != null) ...[
          _sectionTitle('个人特质', Icons.extension),
          _infoCard([
            if (contact.hobbies != null)
              _infoRow(Icons.sports_basketball, '兴趣爱好', contact.hobbies!),
            if (contact.strengths != null)
              _infoRow(Icons.thumb_up, '优点', contact.strengths!),
            if (contact.weaknesses != null)
              _infoRow(Icons.thumb_down, '缺点', contact.weaknesses!),
            if (contact.fears != null)
              _infoRow(Icons.warning, '恐惧', contact.fears!,
                  highlight: true),
            if (contact.desires != null)
              _infoRow(Icons.flare, '渴望', contact.desires!),
            if (contact.skills != null)
              _infoRow(Icons.build, '技能', contact.skills!),
            if (contact.tastePreferences != null)
              _infoRow(
                  Icons.restaurant, '口味偏好', contact.tastePreferences!),
          ]),
          const SizedBox(height: 20),
        ],
        if (contact.homeAddress != null ||
            contact.familySituation != null ||
            contact.familyEconomicStatus != null ||
            contact.familyEmotionalStatus != null) ...[
          _sectionTitle('家庭信息', Icons.home),
          _infoCard([
            if (contact.homeAddress != null)
              _infoRow(Icons.location_on, '家庭住址', contact.homeAddress!),
            if (contact.familySituation != null)
              _infoRow(Icons.family_restroom, '家庭情况',
                  contact.familySituation!),
            if (contact.familyEconomicStatus != null)
              _infoRow(Icons.account_balance_wallet, '经济状况',
                  contact.familyEconomicStatus!),
            if (contact.familyEmotionalStatus != null)
              _infoRow(Icons.favorite, '感情状况',
                  contact.familyEmotionalStatus!),
          ]),
          const SizedBox(height: 20),
        ],
        _sectionTitle('信任与关系', Icons.shield),
        _infoCard([
          _infoRow(Icons.people, 'TA对我的信任度',
              '${contact.taTrustLevel}/10'),
          _infoRow(Icons.person_add, '我对TA的信任度',
              '${contact.myTrustLevel}/10'),
          if (contact.socialCircles != null)
            _infoRow(Icons.group, '所交往圈子', contact.socialCircles!),
          if (contact.currentStatus != null)
            _infoRow(Icons.public, '目前现状', contact.currentStatus!),
        ]),
        const SizedBox(height: 20),
        if (contact.moneyDesireLevel != null ||
            contact.ambitionLevel != null ||
            contact.shortTermGoals != null ||
            contact.longTermGoals != null ||
            contact.goalRelation != null) ...[
          _sectionTitle('目标与欲望', Icons.rocket_launch),
          _infoCard([
            if (contact.moneyDesireLevel != null)
              _infoRow(Icons.attach_money, '挣钱欲望',
                  contact.moneyDesireLevel!),
            if (contact.ambitionLevel != null)
              _infoRow(Icons.emoji_events, '上进心',
                  contact.ambitionLevel!),
            if (contact.shortTermGoals != null)
              _infoRow(Icons.flash_on, '短期目标',
                  contact.shortTermGoals!),
            if (contact.longTermGoals != null)
              _infoRow(Icons.auto_graph, '长期目标',
                  contact.longTermGoals!),
            if (contact.goalRelation != null)
              _infoRow(Icons.flag, '目标关系', contact.goalRelation!),
          ]),
          const SizedBox(height: 20),
        ],
        Consumer<ChannelConfigProvider>(
          builder: (context, channelProvider, _) {
            final configs = channelProvider.getConfigsForContact(contact.id);
            if (configs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('社交途径', Icons.hub),
                ...configs.map((config) {
                  final platformConfig = getPlatformConfig(config.platform);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          platformConfig.color.withOpacity(0.1),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: platformConfig.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  platformConfig.emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          platformConfig.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (config.isPrimary) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: platformConfig.color,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              '主要',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (config.account != null)
                                      Text(
                                        config.account!,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (config.enabledFeatures.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  config.enabledFeatures.map((feature) {
                                final featureConfig =
                                    getFeatureConfig(feature);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        platformConfig.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(featureConfig.emoji,
                                          style: const TextStyle(fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Text(
                                        featureConfig.name,
                                        style: TextStyle(
                                          color: platformConfig.color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          if (config.preferredModes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  config.preferredModes.map((mode) {
                                final modeConfig = getModeConfig(mode);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${modeConfig.emoji} ${modeConfig.name}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          if (config.remark != null &&
                              config.remark!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.note,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      config.remark!,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (contact.tags.isNotEmpty) ...[
          _sectionTitle('标签', Icons.label),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: contact.tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        _sectionTitle('系统信息', Icons.info_outline),
        _infoCard([
          _infoRow(Icons.add_circle, '添加时间',
              DateFormat('yyyy-MM-dd HH:mm').format(contact.createdAt)),
          _infoRow(Icons.update, '更新时间',
              DateFormat('yyyy-MM-dd HH:mm').format(contact.updatedAt)),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildContactMethods(BuildContext context) {
    if (contact.methods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('联系方式', Icons.phone_android),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: contact.methods.length,
            itemBuilder: (context, index) {
              final method = contact.methods[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPlatformColor(method.platform),
                      _getPlatformColor(method.platform).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getPlatformColor(method.platform)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getPlatformIcon(method.platform),
                          color: Colors.white, size: 22),
                      const SizedBox(height: 8),
                      Text(
                        method.platform,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        method.account,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            overflow: TextOverflow.ellipsis),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case '微信':
        return const Color(0xFF07C160);
      case 'QQ':
        return const Color(0xFF12B7F5);
      case '手机':
        return const Color(0xFF2196F3);
      case '邮箱':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  Widget _sectionTitle(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );

  Widget _infoCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      );

  Widget _infoRow(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: highlight
                  ? Colors.red.withOpacity(0.1)
                  : const Color(0xFFFF6B6B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 16,
                color: highlight ? Colors.red : const Color(0xFFFF6B6B)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13,
                  color: highlight ? Colors.red[700] : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case '微信':
        return Icons.chat;
      case 'QQ':
        return Icons.chat_bubble;
      case '手机':
        return Icons.phone;
      case '邮箱':
        return Icons.email;
      default:
        return Icons.contact_page;
    }
  }
}

class _InteractionTab extends StatelessWidget {
  final Contact contact;

  const _InteractionTab({required this.contact});

  @override
  Widget build(BuildContext context) {
    if (contact.interactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text('还没有互动记录',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    final interactions = contact.interactions;
    final colors = <Color>[
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFFEAA7),
      const Color(0xFFDDA0DD),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: interactions.length,
      itemBuilder: (context, index) {
        final interaction = interactions[index];
        final color = colors[index % colors.length];
        final icon = _getTypeIcon(interaction.type);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (index < interactions.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, colors[(index + 1) % colors.length]],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              interaction.typeName,
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(interaction.occurredAt),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        interaction.content,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.task_alt,
                        size: 60, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text('还没有任务',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _generateAITasks(context, contact),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('AI生成任务'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B6B),
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/ai-task-center'),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('AI任务中心'),
                  ),
                ],
              ),
            ),
          );
        }

        final pendingTasks = tasks.where((t) => t.status == TaskStatus.pending).toList();
        final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            if (pendingTasks.isNotEmpty) ...[
              _buildTaskSection('待完成', pendingTasks, provider),
              const SizedBox(height: 20),
            ],
            if (completedTasks.isNotEmpty) ...[
              _buildTaskSection('已完成', completedTasks, provider),
            ],
            const SizedBox(height: 30),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _generateAITasks(context, contact),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI生成更多任务'),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _buildTaskSection(String title, List<SocialTask> tasks, TaskProvider provider) {
    final isCompleted = title == '已完成';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? const [Color(0xFF4CAF50), Color(0xFF81C784)]
                        : const [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.pending,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$title (${tasks.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((task) => _buildTaskCard(task, provider, isCompleted)),
      ],
    );
  }

  Widget _buildTaskCard(SocialTask task, TaskProvider provider, bool isCompleted) {
    final iconData = _getTaskIcon(task.type);
    final accentColor = isCompleted
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF6B6B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MM-dd HH:mm').format(task.scheduledAt),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!isCompleted)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                  onPressed: () => provider.completeTask(task.id),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '已完成',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
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

Future<void> _generateAITasks(BuildContext context, Contact contact) async {
  final aiProvider = context.read<AIProvider>();
  final models = aiProvider.models;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('选择 AI 调用方式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading:
                const Icon(Icons.smart_toy, color: Color(0xFF6366F1)),
            title: const Text('内部 AI'),
            subtitle: Text(
              models.isEmpty
                  ? '未配置模型，请先在设置中添加'
                  : '使用已配置的模型直接生成',
              style: TextStyle(
                color: models.isEmpty ? Colors.red : null,
              ),
            ),
            enabled: models.isNotEmpty,
            onTap: () => Navigator.pop(context, 'internal'),
          ),
          ListTile(
            leading:
                const Icon(Icons.description_outlined, color: Colors.orange),
            title: const Text('外部 AI'),
            subtitle: const Text('导出提示词和素材为 PDF'),
            onTap: () => Navigator.pop(context, 'external'),
          ),
        ],
      ),
    ),
  );

  if (result == null) return;

  if (result == 'internal') {
    await _generateWithInternalAI(context, contact, models);
  } else if (result == 'external') {
    Navigator.pushNamed(context, '/ai-task-center');
  }
}

Future<void> _generateWithInternalAI(
  BuildContext context,
  Contact contact,
  List<AIModel> models,
) async {
  AIModel? selectedModel = models.first;

  if (models.length > 1) {
    selectedModel = await showDialog<AIModel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择模型'),
        children: models.map((m) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, m),
            child: ListTile(
              leading: Icon(_getModelIcon(m.provider)),
              title: Text(m.name),
              subtitle: Text(m.providerName),
            ),
          );
        }).toList(),
      ),
    );

    if (selectedModel == null) return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final taskProvider = context.read<TaskProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final socialProvider = context.read<ContactSocialProvider>();

    final social = socialProvider.getSocial(contact.id);
    final logs = socialProvider.getLogsForContact(contact.id);

    await taskProvider.generateTasksForContact(
      contact: contact,
      model: selectedModel,
      days: 7,
      userProfile: profileProvider.profile,
      contactSocial: social,
      interactionLogs: logs,
    );

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI 任务已生成！'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成失败: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

Future<void> _generateWithExternalAI(BuildContext context, Contact contact) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final profileProvider = context.read<ProfileProvider>();
    final socialProvider = context.read<ContactSocialProvider>();
    final userProfile = profileProvider.profile;
    final social = socialProvider.getSocial(contact.id);
    final logs = socialProvider.getLogsForContact(contact.id);

    final buffer = StringBuffer();
    buffer.writeln('请为联系人「${contact.name}」生成未来7天的社交任务建议。');
    buffer.writeln('');

    if (userProfile != null) {
      buffer.writeln('## 执行者画像');
      buffer.writeln('- 性格: ${userProfile.personalityTraits.join('、')}');
      buffer.writeln('- 沟通风格: ${userProfile.communicationStyle}');
      buffer.writeln('- 社交能量: ${userProfile.socialEnergy}/100');
      buffer.writeln('- 短信意愿: ${userProfile.opennessToTexting}/5');
      buffer.writeln('- 见面意愿: ${userProfile.opennessToMeeting}/5');
      buffer.writeln('');
    }

    buffer.writeln('## 联系人信息');
    buffer.writeln('- 姓名：${contact.name}');
    buffer.writeln('- 关系层级：${contact.levelName}');
    if (contact.goalRelation != null) buffer.writeln('- 目标关系：${contact.goalRelation}');
    if (contact.tags.isNotEmpty) buffer.writeln('- 标签：${contact.tags.join('、')}');

    buffer.writeln('');
    buffer.writeln('## 社交大纲');
    buffer.writeln('- 社交航向: ${social.directionName}');
    buffer.writeln('- 关系阶段: ${social.currentStageName} → ${social.targetStageName}');
    buffer.writeln('- 关系温度: ${social.warmthLevel}/10');
    if (social.outlineTopics.isNotEmpty) {
      buffer.writeln('- 推荐话题: ${social.outlineTopics.join('、')}');
    }
    if (social.avoidTopics.isNotEmpty) {
      buffer.writeln('- 避免话题: ${social.avoidTopics.join('、')}');
    }
    if (social.customOutline != null && social.customOutline!.isNotEmpty) {
      buffer.writeln('- 自定义大纲: ${social.customOutline}');
    }

    if (logs.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('## 近期互动');
      for (final log in logs.take(3)) {
        buffer.writeln('- ${log.title} (${log.emotionalToneEmoji}${log.emotionalTone ?? '中性'})');
      }
    }

    buffer.writeln('');
    buffer.writeln('请根据以上信息，生成具体可执行的社交任务，包括：');
    buffer.writeln('1. 开场白建议（匹配执行者沟通风格）');
    buffer.writeln('2. 任务类型（如：发消息、打电话、社交互动等）');
    buffer.writeln('3. 任务标题和具体描述');
    buffer.writeln('4. 建议执行时间和频率');
    buffer.writeln('5. 优先级（高/中/低）');
    buffer.writeln('6. 3-5个具体执行步骤指导');

    final prompt = buffer.toString();

    final file = await PdfExporter.exportExternalAIPdf(
      title: '为 ${contact.name} 生成社交任务',
      prompt: prompt,
      contactName: contact.name,
    );

    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '为 ${contact.name} 生成社交任务',
        text: '请将此 PDF 发送给外部 AI（千问、豆包等），让 AI 按文档要求生成任务建议',
      );
    }
  } catch (e) {
    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }
}

IconData _getModelIcon(AIModelProvider provider) {
  switch (provider) {
    case AIModelProvider.openai:
      return Icons.smart_toy;
    case AIModelProvider.claude:
      return Icons.psychology;
    case AIModelProvider.dashscope:
      return Icons.auto_awesome;
    case AIModelProvider.local:
      return Icons.computer;
    case AIModelProvider.external:
      return Icons.description_outlined;
  }
}

class _RelationshipTab extends StatelessWidget {
  final Contact contact;
  const _RelationshipTab({required this.contact});

  Color _levelColor(ContactLevel level) {
    switch (level) {
      case ContactLevel.unimportant:
        return const Color(0xFF9E9E9E);
      case ContactLevel.normal:
        return const Color(0xFF2196F3);
      case ContactLevel.important:
        return const Color(0xFFFF9800);
      case ContactLevel.core:
        return const Color(0xFFE53935);
    }
  }

  Color _lightenColor(Color color) {
    return Color.lerp(color, Colors.white, 0.35) ?? color;
  }

  String _levelName(ContactLevel level) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, provider, _) {
        return FutureBuilder<List<RelationshipChange>>(
          future: provider.getRelationshipTimeline(contact.id),
          builder: (context, snapshot) {
            final changes = snapshot.data ?? [];
            final progress = contact.level.index / ContactLevel.core.index;
            final levelColor = _levelColor(contact.level);

            return ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [levelColor, _lightenColor(levelColor)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: levelColor.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _levelName(contact.level),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (contact.goalRelation != null)
                              Expanded(
                                child: Text(
                                  '目标: ${contact.goalRelation}',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: progress,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '关系进度: ${contact.level.index} / ${ContactLevel.core.index}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '当前层级 → 核心',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              _showLevelChangeDialog(context, contact, provider),
                          icon: const Icon(Icons.trending_up, size: 20),
                          label: const Text('调整关系层级',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: levelColor,
                          side: BorderSide(color: levelColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/contact-social',
                            arguments: contact,
                          );
                        },
                        icon: const Icon(Icons.flag, size: 20),
                        label: const Text('社交管理',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.timeline,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '关系演进时间线',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (changes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.timeline,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          '暂无关系变更记录',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ...changes
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key;
                        final change = entry.value;
                        return _buildTimelineItem(change,
                            index: index, total: changes.length);
                      }),
                const SizedBox(height: 30),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineItem(RelationshipChange change,
      {required int index, required int total}) {
    final color = change.isPromotion
        ? const Color(0xFF4CAF50)
        : change.isDemotion
            ? const Color(0xFFFF9800)
            : const Color(0xFF9E9E9E);
    final icon = change.isPromotion
        ? Icons.arrow_upward
        : change.isDemotion
            ? Icons.arrow_downward
            : Icons.remove;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (index < total - 1)
              Container(
                width: 2,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_levelName(change.fromLevel)} → ${_levelName(change.toLevel)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm')
                          .format(change.changedAt),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  change.reason,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  change.typeName,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
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
                  decoration: const InputDecoration(
                    labelText: '新层级'),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
              ),
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