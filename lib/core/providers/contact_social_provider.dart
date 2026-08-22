import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/contact_social.dart';
import '../../models/user_profile.dart';

class ContactSocialProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  static const String _socialKey = 'contact_social_';
  static const String _logsKey = 'interaction_logs_';
  static const String _trustKey = 'trust_change_';

  final Map<String, ContactSocial> _socials = {};
  final Map<String, List<InteractionLog>> _logs = {};
  final Map<String, List<TrustChangeRecord>> _trustRecords = {};
  bool _isLoading = false;

  Map<String, ContactSocial> get socials => _socials;
  Map<String, List<InteractionLog>> get logs => _logs;
  Map<String, List<TrustChangeRecord>> get trustRecords => _trustRecords;
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
                json as Map,
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
                        j as Map,
                      ),
                    ))
                .toList();
          }
        } else if (key.startsWith(_trustKey)) {
          final contactId = key.substring(_trustKey.length);
          final jsonList = prefs.getStringList(key);
          if (jsonList != null) {
            _trustRecords[contactId] = jsonList
                .map((j) => TrustChangeRecord.fromJson(
                      Map<String, dynamic>.from(
                        j as Map,
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
    int? taTrustLevel,
    int? myTrustLevel,
    String? trustChangeReason,
    String? trustChangeDetail,
    TrustChangeSource trustChangeSource = TrustChangeSource.manual,
  }) async {
    final old = getSocial(contactId);
    final newTaTrust = taTrustLevel ?? old.taTrustLevel;
    final newMyTrust = myTrustLevel ?? old.myTrustLevel;
    final updated = old.copyWith(
      direction: direction,
      currentStage: currentStage,
      targetStage: targetStage,
      directionNote: directionNote,
      outlineTopics: outlineTopics,
      avoidTopics: avoidTopics,
      customOutline: customOutline,
      warmthLevel: warmthLevel,
      taTrustLevel: newTaTrust,
      myTrustLevel: newMyTrust,
      updatedAt: DateTime.now(),
    );

    _socials[contactId] = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_socialKey$contactId',
      updated.toJson().toString(),
    );

    // 如果信任度有变化，记录变化
    final taChanged = taTrustLevel != null && taTrustLevel != old.taTrustLevel;
    final myChanged = myTrustLevel != null && myTrustLevel != old.myTrustLevel;
    if (taChanged || myChanged) {
      await _addTrustChangeRecord(
        contactId: contactId,
        oldTa: old.taTrustLevel,
        oldMy: old.myTrustLevel,
        newTa: newTaTrust,
        newMy: newMyTrust,
        reason: trustChangeReason ?? '手动调整信任度',
        detail: trustChangeDetail,
        source: trustChangeSource,
      );
    }

    notifyListeners();
  }

  // ============ 信任度变化记录 ============

  List<TrustChangeRecord> getTrustRecords(String contactId) {
    return _trustRecords[contactId] ?? [];
  }

  Future<void> _addTrustChangeRecord({
    required String contactId,
    required int oldTa,
    required int oldMy,
    required int newTa,
    required int newMy,
    required String reason,
    String? detail,
    required TrustChangeSource source,
    String? relatedLogId,
  }) async {
    final record = TrustChangeRecord(
      id: _uuid.v4(),
      contactId: contactId,
      oldTaTrustLevel: oldTa,
      oldMyTrustLevel: oldMy,
      newTaTrustLevel: newTa,
      newMyTrustLevel: newMy,
      reason: reason,
      detail: detail,
      source: source,
      relatedLogId: relatedLogId,
      createdAt: DateTime.now(),
    );

    final list = _trustRecords.putIfAbsent(contactId, () => []);
    list.insert(0, record);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_trustKey$contactId',
      list.map((r) => r.toJson().toString()).toList(),
    );
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

  // ============== AI 信任度分析 ==============

  bool _isAnalyzingTrust = false;
  bool get isAnalyzingTrust => _isAnalyzingTrust;

  /// 内部AI基于互动反馈+已有数据分析信任度
  /// 返回：{taTrustLevel, myTrustLevel, reason, detail}
  Map<String, dynamic> analyzeTrustWithInternalAI({
    required Contact contact,
    required ContactSocial social,
    required InteractionFeedback feedback,
    UserProfile? userProfile,
  }) {
    final logs = getLogsForContact(contact.id);
    final oldTa = social.taTrustLevel;
    final oldMy = social.myTrustLevel;

    // ===== TA对我的信任度变化计算 =====
    int taDelta = 0;
    // 满意度影响
    taDelta += (feedback.satisfaction - 3); // 3为中性，5+2，1-2
    // 情绪影响
    if (feedback.emotionalTone == '积极') taDelta += 1;
    if (feedback.emotionalTone == '消极') taDelta -= 1;
    // 关键事件
    if (feedback.sharedSecret == true) taDelta += 2; // 分享秘密，说明信任
    if (feedback.helpedEachOther == true) taDelta += 1; // 互相帮助，增进信任
    if (feedback.hadConflict == true) taDelta -= 2; // 矛盾冲突，降低信任
    if (feedback.keptPromise == true) taDelta += 1; // 信守承诺，增加信任
    if (feedback.keptPromise == false) taDelta -= 2; // 违背承诺，严重降低

    // 根据历史互动记录调整：互动越多且积极，信任变化的可靠性越高
    final positiveLogs = logs.where((l) => l.emotionalTone == '积极').length;
    final negativeLogs = logs.where((l) => l.emotionalTone == '消极').length;
    final balance = positiveLogs - negativeLogs;
    if (balance > 3 && taDelta > 0) taDelta += 1;
    if (balance < -3 && taDelta < 0) taDelta -= 1;

    // ===== 我对TA的信任度变化 =====
    int myDelta = taDelta; // 初始参考TA的变化
    // 用户画像影响：谨慎的人信任增长慢
    if (userProfile != null && userProfile.personalityTraits.contains('谨慎')) {
      if (myDelta > 0) myDelta = (myDelta * 0.6).round(); // 正向增长打6折
    }
    // 满意度对我的信任影响更大
    if (feedback.satisfaction <= 1) myDelta -= 1;
    if (feedback.satisfaction >= 5) myDelta += 1;
    // 被背叛/矛盾对我的信任影响更大
    if (feedback.hadConflict == true) myDelta -= 1;
    if (feedback.keptPromise == false) myDelta -= 1;

    // 确保在1-10范围内
    final newTa = (oldTa + taDelta).clamp(1, 10);
    final newMy = (oldMy + myDelta).clamp(1, 10);

    // ===== 生成原因和分析 =====
    final factors = <String>[];
    if (feedback.satisfaction >= 4) factors.add('互动满意度高');
    if (feedback.satisfaction <= 2) factors.add('互动满意度低');
    if (feedback.emotionalTone == '积极') factors.add('对方情绪积极');
    if (feedback.emotionalTone == '消极') factors.add('对方情绪消极');
    if (feedback.sharedSecret == true) factors.add('分享了私人信息');
    if (feedback.helpedEachOther == true) factors.add('互相帮助');
    if (feedback.hadConflict == true) factors.add('发生矛盾');
    if (feedback.keptPromise == true) factors.add('信守承诺');
    if (feedback.keptPromise == false) factors.add('违背承诺');
    if (factors.isEmpty) factors.add('常规互动');

    final reason = factors.join('、');
    final detail = '''
【信任度AI分析报告 - ${contact.name}】

一、互动概况
• 满意度: ${feedback.satisfaction}/5
• 情绪基调: ${feedback.emotionalTone ?? '未标注'}
• 关键事件: ${_buildKeyEventsText(feedback)}

二、TA对我的信任度
• 原值: $oldTa/10 → 新值: $newTa/10 (${taDelta >= 0 ? '+' : ''}$taDelta)
• 依据: $reason

三、我对TA的信任度
• 原值: $oldMy/10 → 新值: $newMy/10 (${myDelta >= 0 ? '+' : ''}$myDelta)
• 依据: ${userProfile != null && userProfile.personalityTraits.contains('谨慎') ? '考虑到谨慎性格，信任增长较为保守；' : ''}$reason

四、后续建议
${_buildTrustAdvice(newTa, newMy, social.currentStage, feedback)}

五、历史互动参考
• 总互动次数: ${logs.length}
• 积极互动: $positiveLogs次
• 消极互动: $negativeLogs次
• 净积极指数: ${balance >= 0 ? '+' : ''}$balance
''';

    return {
      'taTrustLevel': newTa,
      'myTrustLevel': newMy,
      'taDelta': taDelta,
      'myDelta': myDelta,
      'reason': reason,
      'detail': detail.trim(),
    };
  }

  String _buildKeyEventsText(InteractionFeedback f) {
    final events = <String>[];
    if (f.sharedSecret == true) events.add('分享秘密');
    if (f.helpedEachOther == true) events.add('互相帮助');
    if (f.hadConflict == true) events.add('产生矛盾');
    if (f.keptPromise == true) events.add('信守承诺');
    if (f.keptPromise == false) events.add('违背承诺');
    if (f.tags.isNotEmpty) events.addAll(f.tags);
    return events.isEmpty ? '无特殊标记' : events.join('、');
  }

  String _buildTrustAdvice(int taTrust, int myTrust, RelationshipStage stage, InteractionFeedback fb) {
    final avg = (taTrust + myTrust) / 2;
    final stageText = _stageToText(stage);
    final advice = <String>[];

    if (taTrust <= 3) {
      advice.add('• TA对您信任度偏低，建议：从小事做起，信守承诺，逐步积累信任；避免轻易许诺。');
    } else if (taTrust >= 8) {
      advice.add('• TA对您信任度很高，建议：珍惜这份信任，不要过度消费；在重要事情上继续保持可靠。');
    }

    if (myTrust <= 3) {
      advice.add('• 您对TA信任度偏低，建议：给彼此一些时间，观察对方的实际行动；不要过早下结论。');
    } else if (myTrust >= 8) {
      advice.add('• 您对TA信任度很高，建议：保持独立判断力，信任也要有边界。');
    }

    if ((taTrust - myTrust).abs() >= 3) {
      advice.add('• 双方信任度差距较大，建议：通过坦诚沟通缩小认知差距；避免单方面过度投入。');
    }

    if (fb.hadConflict == true) {
      advice.add('• 近期发生矛盾，建议：适当冷静后主动沟通，坦诚表达感受，避免积累心结。');
    }

    if (fb.sharedSecret == true) {
      advice.add('• 对方分享了私人信息，建议：妥善保密，这是增进信任的重要契机。');
    }

    if (avg >= 7 && stage.index < RelationshipStage.closeFriend.index) {
      advice.add('• 信任基础良好，可以尝试推进关系阶段（如从朋友→好友）。');
    }

    if (advice.isEmpty) {
      advice.add('• 信任度处于正常范围，继续正常互动即可。');
    }

    return advice.join('\n');
  }

  String _stageToText(RelationshipStage s) {
    switch (s) {
      case RelationshipStage.stranger: return '陌生人';
      case RelationshipStage.acquaintance: return '熟人';
      case RelationshipStage.friend: return '朋友';
      case RelationshipStage.closeFriend: return '好友';
      case RelationshipStage.bestFriend: return '挚友';
      case RelationshipStage.confidant: return '知己';
      case RelationshipStage.intimate: return '亲密关系';
    }
  }

  /// 生成用于外部AI调用的信任度分析提示词
  String buildExternalAITrustPrompt({
    required Contact contact,
    required ContactSocial social,
    required InteractionFeedback feedback,
    UserProfile? userProfile,
  }) {
    final logs = getLogsForContact(contact.id);
    final buf = StringBuffer();
    buf.writeln('请基于以下信息分析并更新双方信任度：');
    buf.writeln('');
    buf.writeln('【联系人信息】');
    buf.writeln('姓名: ${contact.name}');
    buf.writeln('性别/年龄: ${contact.genderName}${contact.age != null ? ' / ${contact.age}岁' : ''}');
    if (contact.tags.isNotEmpty) buf.writeln('标签: ${contact.tags.join('、')}');
    buf.writeln('');
    buf.writeln('【当前信任度】');
    buf.writeln('TA对我的信任度: ${social.taTrustLevel}/10');
    buf.writeln('我对TA的信任度: ${social.myTrustLevel}/10');
    buf.writeln('关系阶段: ${_stageToText(social.currentStage)}');
    buf.writeln('关系温度: ${social.warmthLevel}/10');
    buf.writeln('');
    buf.writeln('【本次用户反馈的互动情况】');
    buf.writeln('互动描述: ${feedback.content}');
    buf.writeln('满意度: ${feedback.satisfaction}/5 (1很不满意，5非常满意)');
    if (feedback.emotionalTone != null) buf.writeln('对方情绪基调: ${feedback.emotionalTone}');
    buf.writeln('关键事件标记:');
    if (feedback.sharedSecret == true) buf.writeln('  ✓ 对方分享了秘密/隐私给我');
    if (feedback.helpedEachOther == true) buf.writeln('  ✓ 我们互相帮助了');
    if (feedback.hadConflict == true) buf.writeln('  ✓ 这次产生了矛盾/误解');
    if (feedback.keptPromise == true) buf.writeln('  ✓ 对方信守了承诺');
    if (feedback.keptPromise == false) buf.writeln('  ✗ 对方违背了承诺');
    if (feedback.tags.isNotEmpty) buf.writeln('额外标签: ${feedback.tags.join('、')}');
    buf.writeln('');
    buf.writeln('【近期互动历史（供参考）】');
    if (logs.isEmpty) {
      buf.writeln('（暂无历史记录）');
    } else {
      for (final l in logs.take(10)) {
        final tone = l.emotionalTone ?? '中性';
        final date = '${l.occurredAt.month}/${l.occurredAt.day}';
        buf.writeln('• $date [$tone] ${l.title}');
      }
    }
    buf.writeln('');
    if (userProfile != null) {
      buf.writeln('【用户画像（我）】');
      buf.writeln('性格: ${userProfile.personalityTraits.join('、')}');
      buf.writeln('沟通风格: ${userProfile.communicationStyle}');
      buf.writeln('社交能量: ${userProfile.socialEnergy}/100');
      buf.writeln('说明：如果用户性格偏"谨慎"，则我对TA的信任增长应更保守。');
      buf.writeln('');
    }
    buf.writeln('【输出格式】');
    buf.writeln('```json');
    buf.writeln('{');
    buf.writeln('  "taTrustLevel": 新的TA信任度整数1-10,');
    buf.writeln('  "myTrustLevel": 新的我的信任度整数1-10,');
    buf.writeln('  "reason": "一句话概括信任度变化的原因",');
    buf.writeln('  "detail": "详细的分析报告，分点说明双方信任度变化依据，并给出后续建议"');
    buf.writeln('}');
    buf.writeln('```');
    buf.writeln('');
    buf.writeln('要求：');
    buf.writeln('1. 信任度变化幅度一般在-3到+3之间，极端情况可以更大');
    buf.writeln('2. TA对我的信任度主要看：对方的态度、是否分享隐私、是否信守承诺、是否帮助我');
    buf.writeln('3. 我对TA的信任度主要看：我的满意度、对方是否可靠、是否产生矛盾、我的谨慎程度');
    buf.writeln('4. detail应给出具体的后续建议，不少于100字');
    return buf.toString();
  }

  /// 应用AI生成的信任度分析结果
  Future<void> applyAnalyzedTrust({
    required String contactId,
    required int taTrustLevel,
    required int myTrustLevel,
    required String reason,
    String? detail,
    TrustChangeSource source = TrustChangeSource.internalAI,
  }) async {
    await updateSocial(
      contactId: contactId,
      taTrustLevel: taTrustLevel,
      myTrustLevel: myTrustLevel,
      trustChangeReason: reason,
      trustChangeDetail: detail,
      trustChangeSource: source,
    );
  }

  /// 仅基于已有互动记录和Contact模型数据重新评估信任度（无用户主动反馈时使用）
  Map<String, dynamic> reevaluateTrustFromExistingData({
    required Contact contact,
    required ContactSocial social,
  }) {
    final logs = getLogsForContact(contact.id);
    final oldTa = social.taTrustLevel;
    final oldMy = social.myTrustLevel;

    // 使用Contact中的历史信任度作为参考锚点
    final anchorTa = contact.taTrustLevel;
    final anchorMy = contact.myTrustLevel;

    // 基于互动日志计算调整
    final positiveLogs = logs.where((l) => l.emotionalTone == '积极').length;
    final negativeLogs = logs.where((l) => l.emotionalTone == '消极').length;
    final total = logs.length;
    final avgTone = total == 0 ? 0 : (positiveLogs - negativeLogs) / total;

    // 轻微调整（不超过±2）
    int taDelta = (avgTone * 2).round().clamp(-2, 2);
    int myDelta = taDelta;

    // 如果Contact中的信任度与当前差距太大，向锚点靠拢
    final taGap = anchorTa - oldTa;
    final myGap = anchorMy - oldMy;
    if (taDelta == 0 && taGap.abs() >= 3) {
      taDelta = (taGap * 0.3).round(); // 向锚点靠近30%
    }
    if (myDelta == 0 && myGap.abs() >= 3) {
      myDelta = (myGap * 0.3).round();
    }

    final newTa = (oldTa + taDelta).clamp(1, 10);
    final newMy = (oldMy + myDelta).clamp(1, 10);

    final reason = total == 0
        ? '基于历史档案校准'
        : '基于$total次历史互动记录（积极$positiveLogs/消极$negativeLogs）重新评估';

    final detail = '''
【信任度自动重评估 - ${contact.name}】

• 参考档案信任度: TA $anchorTa/10，我 $anchorMy/10
• 历史互动统计: 共$total次（积极$positiveLogs，消极$negativeLogs）
• 综合情绪指数: ${avgTone.toStringAsFixed(2)}

变化说明：
• TA对我的信任度: $oldTa → $newTa (${taDelta >= 0 ? '+' : ''}$taDelta)
• 我对TA的信任度: $oldMy → $newMy (${myDelta >= 0 ? '+' : ''}$myDelta)

建议：定期补充互动反馈，可以获得更精准的信任度分析。
''';

    return {
      'taTrustLevel': newTa,
      'myTrustLevel': newMy,
      'taDelta': taDelta,
      'myDelta': myDelta,
      'reason': reason,
      'detail': detail.trim(),
    };
  }

  void setAnalyzingTrust(bool v) {
    _isAnalyzingTrust = v;
    notifyListeners();
  }
}
