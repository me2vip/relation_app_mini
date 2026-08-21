/// 用户社交画像 - 反映用户性格、沟通风格、社交偏好
/// 系统根据任务执行情况动态更新此画像
class UserProfile {
  final String id;
  final String name;
  final String avatar;
  
  // ===== 性格特征（可多选）=====
  final List<String> personalityTraits; // 社恐/内向/外向/活泼/慢热/直接/委婉/幽默/理性/感性
  
  // ===== 沟通风格 =====
  final String communicationStyle; // 如：委婉型/直接型/幽默型/理性型
  final int opennessToTexting; // 1-5 发短信意愿
  final int opennessToCalling; // 1-5 打电话意愿
  final int opennessToMeeting; // 1-5 见面意愿
  final int socialEnergy; // 1-100 社交能量（动态调整）

  // ===== 当前状态标签 =====
  final List<String> statusTags; // 如：追求中/冷战中/暧昧中/稳定中/单身中

  // ===== 社交目标偏好 =====
  final String relationshipGoal; // 长期关系/短期关系/保持联系/拓展人脉

  // ===== 统计数据 =====
  final int totalTasksCompleted;
  final int totalInteractions;
  final double taskCompletionRate;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.name = '我',
    this.avatar = '',
    this.personalityTraits = const ['社恐', '内向'],
    this.communicationStyle = '委婉型',
    this.opennessToTexting = 3,
    this.opennessToCalling = 2,
    this.opennessToMeeting = 2,
    this.socialEnergy = 30,
    this.statusTags = const ['社恐内向'],
    this.relationshipGoal = '长期关系',
    this.totalTasksCompleted = 0,
    this.totalInteractions = 0,
    this.taskCompletionRate = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? avatar,
    List<String>? personalityTraits,
    String? communicationStyle,
    int? opennessToTexting,
    int? opennessToCalling,
    int? opennessToMeeting,
    int? socialEnergy,
    List<String>? statusTags,
    String? relationshipGoal,
    int? totalTasksCompleted,
    int? totalInteractions,
    double? taskCompletionRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    avatar: avatar ?? this.avatar,
    personalityTraits: personalityTraits ?? this.personalityTraits,
    communicationStyle: communicationStyle ?? this.communicationStyle,
    opennessToTexting: opennessToTexting ?? this.opennessToTexting,
    opennessToCalling: opennessToCalling ?? this.opennessToCalling,
    opennessToMeeting: opennessToMeeting ?? this.opennessToMeeting,
    socialEnergy: socialEnergy ?? this.socialEnergy,
    statusTags: statusTags ?? this.statusTags,
    relationshipGoal: relationshipGoal ?? this.relationshipGoal,
    totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
    totalInteractions: totalInteractions ?? this.totalInteractions,
    taskCompletionRate: taskCompletionRate ?? this.taskCompletionRate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'personalityTraits': personalityTraits,
    'communicationStyle': communicationStyle,
    'opennessToTexting': opennessToTexting,
    'opennessToCalling': opennessToCalling,
    'opennessToMeeting': opennessToMeeting,
    'socialEnergy': socialEnergy,
    'statusTags': statusTags,
    'relationshipGoal': relationshipGoal,
    'totalTasksCompleted': totalTasksCompleted,
    'totalInteractions': totalInteractions,
    'taskCompletionRate': taskCompletionRate,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String? ?? '我',
    avatar: json['avatar'] as String? ?? '',
    personalityTraits: List<String>.from(json['personalityTraits'] as List? ?? ['社恐', '内向']),
    communicationStyle: json['communicationStyle'] as String? ?? '委婉型',
    opennessToTexting: json['opennessToTexting'] as int? ?? 3,
    opennessToCalling: json['opennessToCalling'] as int? ?? 2,
    opennessToMeeting: json['opennessToMeeting'] as int? ?? 2,
    socialEnergy: json['socialEnergy'] as int? ?? 30,
    statusTags: List<String>.from(json['statusTags'] as List? ?? ['社恐内向']),
    relationshipGoal: json['relationshipGoal'] as String? ?? '长期关系',
    totalTasksCompleted: json['totalTasksCompleted'] as int? ?? 0,
    totalInteractions: json['totalInteractions'] as int? ?? 0,
    taskCompletionRate: (json['taskCompletionRate'] as num?)?.toDouble() ?? 0.0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static UserProfile createDefault() => UserProfile(
    id: 'default',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  String get summary {
    final traits = personalityTraits.join('、');
    return '$traits · $communicationStyle · 社交能量$socialEnergy';
  }
}

/// 用户画像变更记录 - 追踪画像的演变过程
class ProfileChangeLog {
  final String id;
  final String fieldName; // 变更的字段名
  final String oldValue;
  final String newValue;
  final String reason; // 变更原因（手动/任务完成/AI分析）
  final DateTime changedAt;

  ProfileChangeLog({
    required this.id,
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    required this.reason,
    required this.changedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fieldName': fieldName,
    'oldValue': oldValue,
    'newValue': newValue,
    'reason': reason,
    'changedAt': changedAt.toIso8601String(),
  };

  factory ProfileChangeLog.fromJson(Map<String, dynamic> json) => ProfileChangeLog(
    id: json['id'] as String,
    fieldName: json['fieldName'] as String,
    oldValue: json['oldValue'] as String,
    newValue: json['newValue'] as String,
    reason: json['reason'] as String,
    changedAt: DateTime.parse(json['changedAt'] as String),
  );
}
