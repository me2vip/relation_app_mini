/// 关系阶段
enum RelationshipStage {
  stranger, // 陌生人
  acquaintance, // 熟人
  friend, // 朋友
  closeFriend, // 好友
  bestFriend, // 挚友
  confidant, // 知己
  intimate, // 亲密
}

/// 社交航向类型
enum SocialDirection {
  maintain, // 维持现状
  deepen, // 深化关系
  repair, // 修复关系
  transition, // 转变关系
  casual, // 轻松社交
  business, // 业务社交
}

/// 联系人社交配置 - 包含社交航向和大纲
class ContactSocial {
  final String id;
  final String contactId;

  // ===== 社交航向 =====
  final SocialDirection direction;
  final RelationshipStage currentStage;
  final RelationshipStage targetStage;
  final String? directionNote; // 对航向的补充说明

  // ===== 社交大纲 =====
  final List<String> outlineTopics; // 话题大纲
  final List<String> avoidTopics; // 应避免的话题
  final String? customOutline; // 自定义大纲

  // ===== 近期关系状态 =====
  final int warmthLevel; // 温度1-10
  final int lastInteractionDays; // 上次互动天数

  // ===== 信任度 =====
  final int taTrustLevel; // TA对我的信任度（1-10）
  final int myTrustLevel; // 我对TA的信任度（1-10）

  final DateTime createdAt;
  final DateTime updatedAt;

  ContactSocial({
    required this.id,
    required this.contactId,
    this.direction = SocialDirection.maintain,
    this.currentStage = RelationshipStage.acquaintance,
    this.targetStage = RelationshipStage.friend,
    this.directionNote,
    this.outlineTopics = const [],
    this.avoidTopics = const [],
    this.customOutline,
    this.warmthLevel = 5,
    this.lastInteractionDays = 0,
    this.taTrustLevel = 5,
    this.myTrustLevel = 5,
    required this.createdAt,
    required this.updatedAt,
  });

  ContactSocial copyWith({
    String? id,
    String? contactId,
    SocialDirection? direction,
    RelationshipStage? currentStage,
    RelationshipStage? targetStage,
    String? directionNote,
    List<String>? outlineTopics,
    List<String>? avoidTopics,
    String? customOutline,
    int? warmthLevel,
    int? lastInteractionDays,
    int? taTrustLevel,
    int? myTrustLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ContactSocial(
    id: id ?? this.id,
    contactId: contactId ?? this.contactId,
    direction: direction ?? this.direction,
    currentStage: currentStage ?? this.currentStage,
    targetStage: targetStage ?? this.targetStage,
    directionNote: directionNote ?? this.directionNote,
    outlineTopics: outlineTopics ?? this.outlineTopics,
    avoidTopics: avoidTopics ?? this.avoidTopics,
    customOutline: customOutline ?? this.customOutline,
    warmthLevel: warmthLevel ?? this.warmthLevel,
    lastInteractionDays: lastInteractionDays ?? this.lastInteractionDays,
    taTrustLevel: taTrustLevel ?? this.taTrustLevel,
    myTrustLevel: myTrustLevel ?? this.myTrustLevel,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'direction': direction.index,
    'currentStage': currentStage.index,
    'targetStage': targetStage.index,
    'directionNote': directionNote,
    'outlineTopics': outlineTopics,
    'avoidTopics': avoidTopics,
    'customOutline': customOutline,
    'warmthLevel': warmthLevel,
    'lastInteractionDays': lastInteractionDays,
    'taTrustLevel': taTrustLevel,
    'myTrustLevel': myTrustLevel,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ContactSocial.fromJson(Map<String, dynamic> json) => ContactSocial(
    id: json['id'] as String,
    contactId: json['contactId'] as String,
    direction: SocialDirection.values[json['direction'] as int? ?? 0],
    currentStage: RelationshipStage.values[json['currentStage'] as int? ?? 1],
    targetStage: RelationshipStage.values[json['targetStage'] as int? ?? 2],
    directionNote: json['directionNote'] as String?,
    outlineTopics: List<String>.from(json['outlineTopics'] as List? ?? []),
    avoidTopics: List<String>.from(json['avoidTopics'] as List? ?? []),
    customOutline: json['customOutline'] as String?,
    warmthLevel: json['warmthLevel'] as int? ?? 5,
    lastInteractionDays: json['lastInteractionDays'] as int? ?? 0,
    taTrustLevel: json['taTrustLevel'] as int? ?? 5,
    myTrustLevel: json['myTrustLevel'] as int? ?? 5,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static ContactSocial createDefault(String contactId) => ContactSocial(
    id: 'social_$contactId',
    contactId: contactId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  String get directionName {
    switch (direction) {
      case SocialDirection.maintain: return '维持现状';
      case SocialDirection.deepen: return '深化关系';
      case SocialDirection.repair: return '修复关系';
      case SocialDirection.transition: return '转变关系';
      case SocialDirection.casual: return '轻松社交';
      case SocialDirection.business: return '业务社交';
    }
  }

  String get currentStageName {
    switch (currentStage) {
      case RelationshipStage.stranger: return '陌生人';
      case RelationshipStage.acquaintance: return '熟人';
      case RelationshipStage.friend: return '朋友';
      case RelationshipStage.closeFriend: return '好友';
      case RelationshipStage.bestFriend: return '挚友';
      case RelationshipStage.confidant: return '知己';
      case RelationshipStage.intimate: return '亲密';
    }
  }

  String get targetStageName {
    switch (targetStage) {
      case RelationshipStage.stranger: return '陌生人';
      case RelationshipStage.acquaintance: return '熟人';
      case RelationshipStage.friend: return '朋友';
      case RelationshipStage.closeFriend: return '好友';
      case RelationshipStage.bestFriend: return '挚友';
      case RelationshipStage.confidant: return '知己';
      case RelationshipStage.intimate: return '亲密';
    }
  }

  double get warmthPercent => warmthLevel / 10.0;

  String get stageProgress {
    final stages = RelationshipStage.values;
    final currentIdx = currentStage.index;
    final targetIdx = targetStage.index;
    if (targetIdx <= currentIdx) return '已达目标';
    return '进度 ${currentIdx + 1}/${targetIdx + 1} (${(currentIdx / targetIdx * 100).toStringAsFixed(0)}%)';
  }
}

/// 互动记录类型
enum InteractionLogType {
  manual, // 手动添加
  internalAI, // APP内部AI分析
  externalAI, // 外部AI分析
}

/// 联系人互动日志 - 用户与联系人之间的互动记录
class InteractionLog {
  final String id;
  final String contactId;
  final String contactName;

  // ===== 互动内容 =====
  final String title;
  final String content;
  final String? emotionalTone; // 情绪基调：积极/中性/消极
  final String? topicArea; // 话题领域：生活/工作/情感/兴趣

  // ===== 来源 =====
  final InteractionLogType source;
  final String? aiAnalysis; // AI分析结果

  // ===== 关联 =====
  final String? relatedTaskId;
  final List<String> tags;

  final DateTime occurredAt;
  final DateTime createdAt;

  InteractionLog({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.title,
    required this.content,
    this.emotionalTone,
    this.topicArea,
    this.source = InteractionLogType.manual,
    this.aiAnalysis,
    this.relatedTaskId,
    this.tags = const [],
    required this.occurredAt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'contactName': contactName,
    'title': title,
    'content': content,
    'emotionalTone': emotionalTone,
    'topicArea': topicArea,
    'source': source.index,
    'aiAnalysis': aiAnalysis,
    'relatedTaskId': relatedTaskId,
    'tags': tags,
    'occurredAt': occurredAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory InteractionLog.fromJson(Map<String, dynamic> json) => InteractionLog(
    id: json['id'] as String,
    contactId: json['contactId'] as String,
    contactName: json['contactName'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    emotionalTone: json['emotionalTone'] as String?,
    topicArea: json['topicArea'] as String?,
    source: InteractionLogType.values[json['source'] as int? ?? 0],
    aiAnalysis: json['aiAnalysis'] as String?,
    relatedTaskId: json['relatedTaskId'] as String?,
    tags: List<String>.from(json['tags'] as List? ?? []),
    occurredAt: DateTime.parse(json['occurredAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  String get sourceName {
    switch (source) {
      case InteractionLogType.manual: return '手动记录';
      case InteractionLogType.internalAI: return 'AI分析';
      case InteractionLogType.externalAI: return '外部AI';
    }
  }

  String get emotionalToneEmoji {
    switch (emotionalTone) {
      case '积极': return '😊';
      case '消极': return '😟';
      case '中性': return '😐';
      default: return '📝';
    }
  }
}

/// 社交大纲模板 - 预设大纲供快速创建
class SocialOutlineTemplate {
  final String id;
  final String name;
  final SocialDirection direction;
  final List<String> topics;
  final String description;

  const SocialOutlineTemplate({
    required this.id,
    required this.name,
    required this.direction,
    required this.topics,
    this.description = '',
  });
}

const List<SocialOutlineTemplate> kSocialOutlineTemplates = [
  SocialOutlineTemplate(
    id: 'deepen_friendship',
    name: '深化友谊',
    direction: SocialDirection.deepen,
    topics: ['近期生活', '共同回忆', '兴趣爱好', '未来计划'],
    description: '通过共享经历和深度交流，逐步深化友谊',
  ),
  SocialOutlineTemplate(
    id: 'repair_relationship',
    name: '修复关系',
    direction: SocialDirection.repair,
    topics: ['情绪疏通', '道歉与原谅', '重建信任', '重新连接'],
    description: '针对疏远或矛盾，主动修复关系',
  ),
  SocialOutlineTemplate(
    id: 'casual_chat',
    name: '轻松社交',
    direction: SocialDirection.casual,
    topics: ['日常问候', '热点话题', '分享生活', '轻松调侃'],
    description: '保持轻松愉快的社交氛围',
  ),
  SocialOutlineTemplate(
    id: 'business_contact',
    name: '业务社交',
    direction: SocialDirection.business,
    topics: ['行业动态', '合作机会', '资源互换', '专业交流'],
    description: '建立和维护业务联系',
  ),
  SocialOutlineTemplate(
    id: 'romance_pursuit',
    name: '追求发展',
    direction: SocialDirection.transition,
    topics: ['情感话题', '约会邀约', '共同活动', '深度了解'],
    description: '从普通朋友向恋爱方向发展',
  ),
  SocialOutlineTemplate(
    id: 'maintain_contact',
    name: '维持联系',
    direction: SocialDirection.maintain,
    topics: ['节日问候', '近况更新', '简单关心', '保持频率'],
    description: '保持适度频率的联系，维护现有关系',
  ),
];

/// 信任度变化来源
enum TrustChangeSource {
  manual, // 手动编辑
  internalAI, // 内部AI分析
  externalAI, // 外部AI分析
  interaction, // 互动记录自动更新
}

/// 信任度变化记录 - 追踪每次信任度的变动
class TrustChangeRecord {
  final String id;
  final String contactId;

  // 变动前的值
  final int oldTaTrustLevel;
  final int oldMyTrustLevel;
  // 变动后的值
  final int newTaTrustLevel;
  final int newMyTrustLevel;

  // 变动原因
  final String reason; // 简要原因
  final String? detail; // 详细说明（AI分析结果或用户备注）

  // 来源
  final TrustChangeSource source;
  final String? relatedLogId; // 关联的互动记录ID

  final DateTime createdAt;

  TrustChangeRecord({
    required this.id,
    required this.contactId,
    required this.oldTaTrustLevel,
    required this.oldMyTrustLevel,
    required this.newTaTrustLevel,
    required this.newMyTrustLevel,
    required this.reason,
    this.detail,
    this.source = TrustChangeSource.manual,
    this.relatedLogId,
    required this.createdAt,
  });

  int get taTrustDelta => newTaTrustLevel - oldTaTrustLevel;
  int get myTrustDelta => newMyTrustLevel - oldMyTrustLevel;

  String get sourceName {
    switch (source) {
      case TrustChangeSource.manual: return '手动调整';
      case TrustChangeSource.internalAI: return 'AI分析';
      case TrustChangeSource.externalAI: return '外部AI';
      case TrustChangeSource.interaction: return '互动记录';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'oldTaTrustLevel': oldTaTrustLevel,
    'oldMyTrustLevel': oldMyTrustLevel,
    'newTaTrustLevel': newTaTrustLevel,
    'newMyTrustLevel': newMyTrustLevel,
    'reason': reason,
    'detail': detail,
    'source': source.index,
    'relatedLogId': relatedLogId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TrustChangeRecord.fromJson(Map<String, dynamic> json) => TrustChangeRecord(
    id: json['id'] as String,
    contactId: json['contactId'] as String,
    oldTaTrustLevel: json['oldTaTrustLevel'] as int? ?? 5,
    oldMyTrustLevel: json['oldMyTrustLevel'] as int? ?? 5,
    newTaTrustLevel: json['newTaTrustLevel'] as int? ?? 5,
    newMyTrustLevel: json['newMyTrustLevel'] as int? ?? 5,
    reason: json['reason'] as String? ?? '未说明',
    detail: json['detail'] as String?,
    source: TrustChangeSource.values[json['source'] as int? ?? 0],
    relatedLogId: json['relatedLogId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// 用户反馈的互动情况 - 用于AI分析信任度
class InteractionFeedback {
  final String contactId;
  final String content; // 互动情况描述
  final int satisfaction; // 满意度 1-5
  final String? emotionalTone; // 对方情绪：积极/中性/消极
  final bool? sharedSecret; // 是否分享了秘密/隐私
  final bool? helpedEachOther; // 是否互相帮助
  final bool? hadConflict; // 是否产生矛盾
  final bool? keptPromise; // 是否信守承诺
  final List<String> tags; // 额外标签

  InteractionFeedback({
    required this.contactId,
    required this.content,
    this.satisfaction = 3,
    this.emotionalTone,
    this.sharedSecret,
    this.helpedEachOther,
    this.hadConflict,
    this.keptPromise,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() => {
    'contactId': contactId,
    'content': content,
    'satisfaction': satisfaction,
    'emotionalTone': emotionalTone,
    'sharedSecret': sharedSecret,
    'helpedEachOther': helpedEachOther,
    'hadConflict': hadConflict,
    'keptPromise': keptPromise,
    'tags': tags,
  };
}
