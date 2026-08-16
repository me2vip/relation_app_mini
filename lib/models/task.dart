import 'dart:convert';

enum TaskStatus {
  /// 待完成
  pending,
  /// 已完成
  completed,
  /// 已跳过
  skipped,
  /// 已过期
  expired,
}

enum TaskType {
  /// 发消息
  sendMessage,
  /// 发视频
  sendVideo,
  /// 问候
  greeting,
  /// 社交媒体互动
  socialInteraction,
  /// 打电话
  phoneCall,
  /// 其他
  other,
}

class SocialTask {
  final String id;
  final String contactId;
  final String contactName;
  final String title;
  final String description;
  final TaskType type;
  final TaskStatus status;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final int priority;
  final String? goalRelation;
  final Map<String, dynamic>? metadata;

  SocialTask({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.scheduledAt,
    this.completedAt,
    this.priority = 0,
    this.goalRelation,
    this.metadata,
  });

  SocialTask copyWith({
    String? id,
    String? contactId,
    String? contactName,
    String? title,
    String? description,
    TaskType? type,
    TaskStatus? status,
    DateTime? scheduledAt,
    DateTime? completedAt,
    int? priority,
    String? goalRelation,
    Map<String, dynamic>? metadata,
  }) => SocialTask(
    id: id ?? this.id,
    contactId: contactId ?? this.contactId,
    contactName: contactName ?? this.contactName,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    status: status ?? this.status,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    completedAt: completedAt ?? this.completedAt,
    priority: priority ?? this.priority,
    goalRelation: goalRelation ?? this.goalRelation,
    metadata: metadata ?? this.metadata,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'contactName': contactName,
    'title': title,
    'description': description,
    'type': type.index,
    'status': status.index,
    'scheduledAt': scheduledAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'priority': priority,
    'goalRelation': goalRelation,
    'metadata': metadata,
  };

  factory SocialTask.fromJson(Map<String, dynamic> json) => SocialTask(
    id: json['id'] as String,
    contactId: json['contactId'] as String,
    contactName: json['contactName'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    type: TaskType.values[json['type'] as int],
    status: TaskStatus.values[json['status'] as int],
    scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    completedAt: json['completedAt'] != null 
        ? DateTime.parse(json['completedAt'] as String) 
        : null,
    priority: json['priority'] as int? ?? 0,
    goalRelation: json['goalRelation'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );

  String get typeName {
    switch (type) {
      case TaskType.sendMessage: return '发消息';
      case TaskType.sendVideo: return '发视频';
      case TaskType.greeting: return '问候';
      case TaskType.socialInteraction: return '社交互动';
      case TaskType.phoneCall: return '打电话';
      case TaskType.other: return '其他';
    }
  }

  String get statusName {
    switch (status) {
      case TaskStatus.pending: return '待完成';
      case TaskStatus.completed: return '已完成';
      case TaskStatus.skipped: return '已跳过';
      case TaskStatus.expired: return '已过期';
    }
  }

  bool get isOverdue => 
      status == TaskStatus.pending && scheduledAt.isBefore(DateTime.now());
}

class TaskSchedule {
  final String id;
  final int hour;
  final int minute;
  final List<int> weekdays; // 1-7, 空表示每天
  final bool enabled;

  TaskSchedule({
    required this.id,
    required this.hour,
    required this.minute,
    this.weekdays = const [],
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'weekdays': weekdays,
    'enabled': enabled,
  };

  factory TaskSchedule.fromJson(Map<String, dynamic> json) => TaskSchedule(
    id: json['id'] as String,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
    weekdays: List<int>.from(json['weekdays'] as List? ?? []),
    enabled: json['enabled'] as bool? ?? true,
  );
}
