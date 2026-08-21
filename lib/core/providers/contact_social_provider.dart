import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/contact_social.dart';
import '../../models/user_profile.dart';

class ContactSocialProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  static const String _socialKey = 'contact_social_';
  static const String _logsKey = 'interaction_logs_';

  final Map<String, ContactSocial> _socials = {};
  final Map<String, List<InteractionLog>> _logs = {};
  bool _isLoading = false;

  Map<String, ContactSocial> get socials => _socials;
  Map<String, List<InteractionLog>> get logs => _logs;
  bool get isLoading => _isLoading;

  ContactSocialProvider() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_socialKey)) {
          final contactId = key.substring(_socialKey.length);
          final json = prefs.getString(key);
          if (json != null) {
            _socials[contactId] = ContactSocial.fromJson(
              Map<String, dynamic>.from(
                Map<String, dynamic>.from(
                  json as Map<String, dynamic>,
                ),
              ),
            );
          }
        } else if (key.startsWith(_logsKey)) {
          final contactId = key.substring(_logsKey.length);
          final jsonList = prefs.getStringList(key);
          if (jsonList != null) {
            _logs[contactId] = jsonList
                .map((j) => InteractionLog.fromJson(
                      Map<String, dynamic>.from(
                        Map<String, dynamic>.from(
                          j as Map<String, dynamic>,
                        ),
                      ),
                    ))
                .toList();
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  ContactSocial getSocial(String contactId) {
    return _socials.putIfAbsent(
      contactId,
      () => ContactSocial.createDefault(contactId),
    );
  }

  List<InteractionLog> getLogsForContact(String contactId) {
    return _logs[contactId] ?? [];
  }

  Future<void> updateSocial({
    required String contactId,
    SocialDirection? direction,
    RelationshipStage? currentStage,
    RelationshipStage? targetStage,
    String? directionNote,
    List<String>? outlineTopics,
    List<String>? avoidTopics,
    String? customOutline,
    int? warmthLevel,
  }) async {
    final old = getSocial(contactId);
    final updated = old.copyWith(
      direction: direction,
      currentStage: currentStage,
      targetStage: targetStage,
      directionNote: directionNote,
      outlineTopics: outlineTopics,
      avoidTopics: avoidTopics,
      customOutline: customOutline,
      warmthLevel: warmthLevel,
      updatedAt: DateTime.now(),
    );

    _socials[contactId] = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_socialKey$contactId',
      updated.toJson().toString(),
    );

    notifyListeners();
  }

  Future<void> applyTemplate({
    required String contactId,
    required SocialOutlineTemplate template,
  }) async {
    await updateSocial(
      contactId: contactId,
      direction: template.direction,
      outlineTopics: template.topics,
      directionNote: template.description,
    );
  }

  Future<void> addInteractionLog({
    required String contactId,
    required String contactName,
    required String title,
    required String content,
    String? emotionalTone,
    String? topicArea,
    InteractionLogType source = InteractionLogType.manual,
    String? aiAnalysis,
    String? relatedTaskId,
    List<String> tags = const [],
    DateTime? occurredAt,
  }) async {
    final log = InteractionLog(
      id: _uuid.v4(),
      contactId: contactId,
      contactName: contactName,
      title: title,
      content: content,
      emotionalTone: emotionalTone,
      topicArea: topicArea,
      source: source,
      aiAnalysis: aiAnalysis,
      relatedTaskId: relatedTaskId,
      tags: tags,
      occurredAt: occurredAt ?? DateTime.now(),
      createdAt: DateTime.now(),
    );

    final list = _logs.putIfAbsent(contactId, () => []);
    list.insert(0, log);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_logsKey$contactId',
      list.map((l) => l.toJson().toString()).toList(),
    );

    notifyListeners();
  }

  Future<void> removeInteractionLog({
    required String contactId,
    required String logId,
  }) async {
    final list = _logs[contactId];
    if (list != null) {
      list.removeWhere((l) => l.id == logId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        '$_logsKey$contactId',
        list.map((l) => l.toJson().toString()).toList(),
      );
      notifyListeners();
    }
  }

  Future<void> analyzeInteractionWithAI({
    required String contactId,
    required String contactName,
    required String content,
  }) async {
    final aiResult = _performSimpleAnalysis(content);

    await addInteractionLog(
      contactId: contactId,
      contactName: contactName,
      title: 'AI分析: ${content.substring(0, content.length > 20 ? 20 : content.length)}...',
      content: content,
      emotionalTone: aiResult['emotionalTone'],
      topicArea: aiResult['topicArea'],
      source: InteractionLogType.internalAI,
      aiAnalysis: aiResult['analysis'],
      tags: List<String>.from(aiResult['tags'] ?? []),
    );

    final social = getSocial(contactId);
    final warmthChange = aiResult['warmthChange'] as int? ?? 0;
    if (warmthChange != 0) {
      final newWarmth = (social.warmthLevel + warmthChange).clamp(1, 10);
      await updateSocial(
        contactId: contactId,
        warmthLevel: newWarmth,
      );
    }
  }

  Map<String, dynamic> _performSimpleAnalysis(String content) {
    final lower = content.toLowerCase();

    String emotionalTone = '中性';
    if (lower.contains('开心') || lower.contains('高兴') || lower.contains('喜欢') ||
        lower.contains('哈哈') || lower.contains('😊') || lower.contains('👍')) {
      emotionalTone = '积极';
    } else if (lower.contains('难过') || lower.contains('生气') || lower.contains('讨厌') ||
        lower.contains('烦') || lower.contains('😞') || lower.contains('😠')) {
      emotionalTone = '消极';
    }

    String topicArea = '生活';
    if (lower.contains('工作') || lower.contains('公司') || lower.contains('项目') ||
        lower.contains('老板') || lower.contains('同事')) {
      topicArea = '工作';
    } else if (lower.contains('喜欢') || lower.contains('爱') || lower.contains('约会') ||
        lower.contains('浪漫') || lower.contains('对象')) {
      topicArea = '情感';
    } else if (lower.contains('游戏') || lower.contains('电影') || lower.contains('音乐') ||
        lower.contains('美食') || lower.contains('旅行')) {
      topicArea = '兴趣';
    }

    final tags = <String>[emotionalTone, topicArea];

    int warmthChange = 0;
    if (emotionalTone == '积极') warmthChange = 1;
    if (emotionalTone == '消极') warmthChange = -1;

    final analysis = '''
【互动分析】
- 情绪基调: $emotionalTone
- 话题领域: $topicArea
- 关系温度变化: ${warmthChange >= 0 ? '+' : ''}$warmthChange
- 建议: 根据此次互动情况，${warmthChange > 0 ? '关系有所升温' : warmthChange < 0 ? '需要加强联系修复关系' : '保持当前频率即可'}
''';

    return {
      'emotionalTone': emotionalTone,
      'topicArea': topicArea,
      'tags': tags,
      'warmthChange': warmthChange,
      'analysis': analysis.trim(),
    };
  }

  int getInteractionCount(String contactId) {
    return _logs[contactId]?.length ?? 0;
  }

  DateTime? getLastInteractionDate(String contactId) {
    final list = _logs[contactId];
    if (list == null || list.isEmpty) return null;
    return list.first.occurredAt;
  }

  // ============== AI 生成社交大纲 ==============

  bool _isGeneratingOutline = false;
  bool get isGeneratingOutline => _isGeneratingOutline;

  /// 内部AI基于社交航向+用户画像+联系人生成大纲
  /// 返回：{outlineTopics, avoidTopics, customOutline}
  Map<String, dynamic> generateOutlineWithInternalAI({
    required Contact contact,
    required ContactSocial social,
    required UserProfile? userProfile,
  }) {
    final direction = social.direction;
    final stage = social.currentStage;
    final target = social.targetStage;
    final warmth = social.warmthLevel;

    // ===== 推荐话题 =====
    final outlineTopics = <String>[];
    // 基础方向匹配
    switch (direction) {
      case SocialDirection.maintain:
        outlineTopics.addAll(['日常问候', '近况分享', '共同回忆', '稳定话题']);
        break;
      case SocialDirection.deepen:
        outlineTopics.addAll(['兴趣爱好', '内心感受', '未来计划', '生活近况', '共同回忆']);
        break;
      case SocialDirection.repair:
        outlineTopics.addAll(['日常问候', '轻松话题', '过去美好回忆', '共同兴趣']);
        break;
      case SocialDirection.transform:
        outlineTopics.addAll(['情感话题', '兴趣爱好', '未来规划', '约会提议', '生活近况']);
        break;
      case SocialDirection.casual:
        outlineTopics.addAll(['娱乐八卦', '热点话题', '美食分享', '旅行见闻', '生活趣事']);
        break;
      case SocialDirection.business:
        outlineTopics.addAll(['工作近况', '行业动态', '合作机会', '资源分享', '职业成长']);
        break;
    }
    // 阶段匹配
    switch (stage) {
      case RelationshipStage.stranger:
        outlineTopics.removeWhere((t) => t == '内心感受' || t == '情感话题');
        outlineTopics.add('自我介绍');
        break;
      case RelationshipStage.acquaintance:
        outlineTopics.add('共同朋友');
        break;
      case RelationshipStage.friend:
        outlineTopics.add('家庭近况');
        break;
      case RelationshipStage.closeFriend:
      case RelationshipStage.bestFriend:
      case RelationshipStage.soulMate:
      case RelationshipStage.intimate:
        outlineTopics.addAll(['内心感受', '情感话题', '深度交流']);
        break;
    }
    // 温度越高越深入
    if (warmth >= 7) {
      outlineTopics.add('深度交流');
    }
    if (warmth <= 2) {
      outlineTopics.removeWhere((t) => t == '内心感受' || t == '情感话题' || t == '深度交流');
    }
    // 用户画像：社恐偏文字话题
    if (userProfile != null && (userProfile.personalityTraits.contains('社恐') || userProfile.socialEnergy < 40)) {
      outlineTopics.addAll(['生活趣事', '兴趣爱好', '娱乐分享']);
      outlineTopics.removeWhere((t) => t == '约会提议' || t == '深度交流');
    }
    // 去重
    final uniqueTopics = <String>[];
    for (final t in outlineTopics) {
      if (!uniqueTopics.contains(t)) uniqueTopics.add(t);
    }

    // ===== 避免话题 =====
    final avoidTopics = <String>['负面情绪', '敏感话题'];
    switch (stage) {
      case RelationshipStage.stranger:
      case RelationshipStage.acquaintance:
        avoidTopics.addAll(['前任', '金钱', '隐私问题', '家庭矛盾']);
        break;
      case RelationshipStage.stranger:
        break;
      case RelationshipStage.acquaintance:
        break;
      default:
        break;
    }
    switch (direction) {
      case SocialDirection.repair:
        avoidTopics.add('过去矛盾');
        break;
      case SocialDirection.business:
        avoidTopics.addAll(['私人八卦', '感情问题']);
        break;
      default:
        break;
    }
    if (userProfile != null && userProfile.personalityTraits.contains('社恐')) {
      avoidTopics.addAll(['公开活动', '多人聚会', '演讲发言']);
    }
    final uniqueAvoid = <String>[];
    for (final t in avoidTopics) {
      if (!uniqueAvoid.contains(t)) uniqueAvoid.add(t);
    }

    // ===== 自定义大纲 =====
    final stageText = _stageToText(stage);
    final targetText = _stageToText(target);
    final directionText = _directionToText(direction);
    final energyText = userProfile == null
        ? '根据实际情况调整'
        : (userProfile.socialEnergy >= 70 ? '社交能量充足，可安排较密集互动'
            : userProfile.socialEnergy >= 40 ? '社交能量中等，节奏适中即可'
            : '社交能量较低，以轻松文字交流为主');
    final customOutline = '''
【社交大纲 - ${contact.name}】

• 社交航向：$directionText
• 关系阶段：$stageText → $targetText（关系温度 $warmth/10）
• 用户画像适配：$energyText

【执行建议】
1. 话题优先级：从推荐话题中挑选当前最合适的
2. 互动节奏：根据关系温度和阶段调整频率（初期每周1-2次，后期根据实际反馈）
3. 沟通方式：优先选择用户画像偏好的渠道和方式
4. 关系推进：每次互动关注反馈，小步前进，避免尴尬
5. 记录复盘：重要互动后及时记录，供后续任务生成参考

【当前阶段重点】
${_stageFocus(stage, target, direction, contact.name)}
''';

    return {
      'outlineTopics': uniqueTopics,
      'avoidTopics': uniqueAvoid,
      'customOutline': customOutline.trim(),
    };
  }

  String _directionToText(SocialDirection d) {
    switch (d) {
      case SocialDirection.maintain: return '维持现状';
      case SocialDirection.deepen: return '深化关系';
      case SocialDirection.repair: return '修复关系';
      case SocialDirection.transform: return '转变关系';
      case SocialDirection.casual: return '轻松社交';
      case SocialDirection.business: return '业务社交';
    }
  }

  String _stageToText(RelationshipStage s) {
    switch (s) {
      case RelationshipStage.stranger: return '陌生人';
      case RelationshipStage.acquaintance: return '熟人';
      case RelationshipStage.friend: return '朋友';
      case RelationshipStage.closeFriend: return '好友';
      case RelationshipStage.bestFriend: return '挚友';
      case RelationshipStage.soulMate: return '知己';
      case RelationshipStage.intimate: return '亲密关系';
    }
  }

  String _stageFocus(RelationshipStage cur, RelationshipStage target, SocialDirection dir, String name) {
    if (dir == SocialDirection.repair) {
      return '当前处于修复阶段，建议：先简单问候破冰 → 不提过往矛盾 → 选择轻松无压力话题 → 逐步重建信任。不要急于求成。';
    }
    switch (cur) {
      case RelationshipStage.stranger:
        return '当前是陌生人阶段：先礼貌自我介绍 → 寻找共同话题/朋友/兴趣 → 保持轻量简短，避免过度追问 → 几次之后推进到熟人。';
      case RelationshipStage.acquaintance:
        return '当前是熟人阶段：主动发起日常问候 → 聊聊近况和兴趣 → 适度分享自己生活 → 寻找线下见面或活动机会。';
      case RelationshipStage.friend:
        return '当前是朋友阶段：保持定期联系 → 主动关心对方重要时刻（生日、节日、重大事件）→ 讨论共同兴趣 → 可以尝试更深入话题。';
      case RelationshipStage.closeFriend:
      case RelationshipStage.bestFriend:
      case RelationshipStage.soulMate:
      case RelationshipStage.intimate:
        return '当前已是深度关系：维持温度的关键是持续真诚 → 重要时刻必须在线 → 深度情感支持 → 保持适度神秘感和新鲜感。';
    }
  }

  /// 生成用于外部AI调用的提示词（导出给用户复制）
  String buildExternalAIOutlinePrompt({
    required Contact contact,
    required ContactSocial social,
    required UserProfile? userProfile,
  }) {
    final buf = StringBuffer();
    buf.writeln('请为以下联系人制定社交大纲（推荐话题、避免话题、社交计划大纲）：');
    buf.writeln('');
    buf.writeln('【联系人信息】');
    buf.writeln('姓名: ${contact.name}');
    buf.writeln('性别/年龄: ${contact.genderName}${contact.age != null ? ' / ${contact.age}岁' : ''}');
    if (contact.goalRelation != null && contact.goalRelation!.isNotEmpty) {
      buf.writeln('目标关系定位: ${contact.goalRelation}');
    }
    if (contact.occupation != null && contact.occupation!.isNotEmpty) {
      buf.writeln('职业: ${contact.occupation}');
    }
    if (contact.tags.isNotEmpty) buf.writeln('标签: ${contact.tags.join('、')}');
    buf.writeln('');
    buf.writeln('【社交管理】');
    buf.writeln('社交航向: ${_directionToText(social.direction)}');
    buf.writeln('关系阶段: ${_stageToText(social.currentStage)} → ${_stageToText(social.targetStage)}');
    buf.writeln('关系温度: ${social.warmthLevel}/10');
    if (social.directionNote != null && social.directionNote!.isNotEmpty) {
      buf.writeln('航向说明: ${social.directionNote}');
    }
    buf.writeln('');
    if (userProfile != null) {
      buf.writeln('【用户画像（任务执行者）】');
      buf.writeln('性格: ${userProfile.personalityTraits.join('、')}');
      buf.writeln('沟通风格: ${userProfile.communicationStyle}');
      buf.writeln('社交能量: ${userProfile.socialEnergy}/100');
      buf.writeln('短信意愿: ${userProfile.opennessToTexting}/5');
      buf.writeln('电话意愿: ${userProfile.opennessToCalling}/5');
      buf.writeln('见面意愿: ${userProfile.opennessToMeeting}/5');
      if (userProfile.statusTags.isNotEmpty) {
        buf.writeln('状态标签: ${userProfile.statusTags.join('、')}');
      }
      buf.writeln('');
    }
    buf.writeln('【输出格式】');
    buf.writeln('```json');
    buf.writeln('{');
    buf.writeln('  "outlineTopics": ["话题1", "话题2", "话题3", "话题4", "话题5"],');
    buf.writeln('  "avoidTopics": ["避免话题1", "避免话题2"],');
    buf.writeln('  "customOutline": "完整的社交计划大纲，分点描述，包含话题优先级、互动节奏、沟通方式、关系推进策略"');
    buf.writeln('}');
    buf.writeln('```');
    buf.writeln('');
    buf.writeln('要求：');
    buf.writeln('1. 推荐话题5-8个，匹配航向和阶段');
    buf.writeln('2. 避免话题2-5个');
    buf.writeln('3. customOutline应包含执行建议，贴合用户画像');
    return buf.toString();
  }

  /// 应用AI生成结果到社交配置
  Future<void> applyGeneratedOutline({
    required String contactId,
    required List<String> outlineTopics,
    required List<String> avoidTopics,
    String? customOutline,
  }) async {
    await updateSocial(
      contactId: contactId,
      outlineTopics: outlineTopics,
      avoidTopics: avoidTopics,
      customOutline: customOutline,
    );
  }

  void setGeneratingOutline(bool v) {
    _isGeneratingOutline = v;
    notifyListeners();
  }
}
