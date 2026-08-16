import 'dart:convert';

enum ContactLevel {
  /// 不重要
  unimportant,
  /// 一般
  normal,
  /// 重要
  important,
  /// 核心
  core,
}

enum InteractionType {
  /// 文字聊天
  textChat,
  /// 语音聊天
  voiceChat,
  /// 视频通话
  videoCall,
  /// 分享短视频
  shareVideo,
  /// 社交媒体互动(抖音/快手/小红书等)
  socialMedia,
  /// 其他
  other,
}

class ContactMethod {
  final String id;
  final String platform;
  final String account;
  final String? remark;
  final DateTime createdAt;

  ContactMethod({
    required this.id,
    required this.platform,
    required this.account,
    this.remark,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform,
    'account': account,
    'remark': remark,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ContactMethod.fromJson(Map<String, dynamic> json) => ContactMethod(
    id: json['id'] as String,
    platform: json['platform'] as String,
    account: json['account'] as String,
    remark: json['remark'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class Interaction {
  final String id;
  final String contactId;
  final InteractionType type;
  final String content;
  final DateTime occurredAt;
  final Map<String, dynamic>? metadata;

  Interaction({
    required this.id,
    required this.contactId,
    required this.type,
    required this.content,
    required this.occurredAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'type': type.index,
    'content': content,
    'occurredAt': occurredAt.toIso8601String(),
    'metadata': metadata,
  };

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
    id: json['id'] as String,
    contactId: json['contactId'] as String,
    type: InteractionType.values[json['type'] as int],
    content: json['content'] as String,
    occurredAt: DateTime.parse(json['occurredAt'] as String),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );

  String get typeName {
    switch (type) {
      case InteractionType.textChat: return '文字聊天';
      case InteractionType.voiceChat: return '语音聊天';
      case InteractionType.videoCall: return '视频通话';
      case InteractionType.shareVideo: return '分享视频';
      case InteractionType.socialMedia: return '社交媒体';
      case InteractionType.other: return '其他';
    }
  }
}

class Contact {
  final String id;
  final String name;
  final String? avatar;
  final ContactLevel level;
  final List<ContactMethod> methods;
  final List<String> tags;
  final String? atmosphereProfile;
  final String? goalRelation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Interaction> interactions;

  Contact({
    required this.id,
    required this.name,
    this.avatar,
    required this.level,
    required this.methods,
    required this.tags,
    this.atmosphereProfile,
    this.goalRelation,
    required this.createdAt,
    required this.updatedAt,
    this.interactions = const [],
  });

  Contact copyWith({
    String? id,
    String? name,
    String? avatar,
    ContactLevel? level,
    List<ContactMethod>? methods,
    List<String>? tags,
    String? atmosphereProfile,
    String? goalRelation,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Interaction>? interactions,
  }) => Contact(
    id: id ?? this.id,
    name: name ?? this.name,
    avatar: avatar ?? this.avatar,
    level: level ?? this.level,
    methods: methods ?? this.methods,
    tags: tags ?? this.tags,
    atmosphereProfile: atmosphereProfile ?? this.atmosphereProfile,
    goalRelation: goalRelation ?? this.goalRelation,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    interactions: interactions ?? this.interactions,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'level': level.index,
    'methods': methods.map((m) => m.toJson()).toList(),
    'tags': tags,
    'atmosphereProfile': atmosphereProfile,
    'goalRelation': goalRelation,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'interactions': interactions.map((i) => i.toJson()).toList(),
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String,
    name: json['name'] as String,
    avatar: json['avatar'] as String?,
    level: ContactLevel.values[json['level'] as int],
    methods: (json['methods'] as List).map((m) => ContactMethod.fromJson(m)).toList(),
    tags: List<String>.from(json['tags'] as List),
    atmosphereProfile: json['atmosphereProfile'] as String?,
    goalRelation: json['goalRelation'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    interactions: (json['interactions'] as List?)?.map((i) => Interaction.fromJson(i)).toList() ?? [],
  );

  String get levelName {
    switch (level) {
      case ContactLevel.unimportant: return '不重要';
      case ContactLevel.normal: return '一般';
      case ContactLevel.important: return '重要';
      case ContactLevel.core: return '核心';
    }
  }
}

/// 关系变化类型（跟踪关系升迁）
enum RelationshipChangeType {
  /// 初始设定（创建联系人时）
  initial,
  /// 手动升迁
  promote,
  /// 手动降级
  demote,
  /// 自动调整（任务完成/互动达标触发）
  auto,
  /// 手动调整（无方向性）
  manual,
}

/// 关系变化记录（单次层级变更，用于跟踪关系升迁时间线）
class RelationshipChange {
  final String id;
  final String contactId;
  final ContactLevel fromLevel;
  final ContactLevel toLevel;
  final RelationshipChangeType type;
  final String reason;
  final DateTime changedAt;

  const RelationshipChange({
    required this.id,
    required this.contactId,
    required this.fromLevel,
    required this.toLevel,
    required this.type,
    required this.reason,
    required this.changedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'fromLevel': fromLevel.index,
    'toLevel': toLevel.index,
    'type': type.index,
    'reason': reason,
    'changedAt': changedAt.toIso8601String(),
  };

  factory RelationshipChange.fromJson(Map<String, dynamic> json) => RelationshipChange(
    id: json['id'] as String,
    contactId: json['contactId'] as String,
    fromLevel: ContactLevel.values[json['fromLevel'] as int],
    toLevel: ContactLevel.values[json['toLevel'] as int],
    type: RelationshipChangeType.values[json['type'] as int],
    reason: json['reason'] as String,
    changedAt: DateTime.parse(json['changedAt'] as String),
  );

  String get typeName {
    switch (type) {
      case RelationshipChangeType.initial: return '初始设定';
      case RelationshipChangeType.promote: return '关系升迁';
      case RelationshipChangeType.demote: return '关系降级';
      case RelationshipChangeType.auto: return '自动调整';
      case RelationshipChangeType.manual: return '手动调整';
    }
  }

  /// 是否升迁（层级数值变大）
  bool get isPromotion => toLevel.index > fromLevel.index;
  /// 是否降级（层级数值变小）
  bool get isDemotion => toLevel.index < fromLevel.index;
  /// 距目标层级的进度（0~1），fromLevel 视为起点、toLevel 视为当前
  double get levelProgress {
    const max = ContactLevel.core.index;
    if (max == 0) return 1;
    return toLevel.index / max;
  }
}
