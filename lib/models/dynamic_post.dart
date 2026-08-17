/// 人设动态内容类型
enum DynamicContentType {
  /// 纯文字
  text,
  /// 图片
  image,
  /// 视频
  video,
  /// 图文混合
  mixed,
}

/// 人设动态状态
enum DynamicPostStatus {
  /// 草稿
  draft,
  /// 已发布
  published,
  /// 已生成任务
  taskCreated,
}

/// 人设动态（用户按照人设发布的朋友圈/说说/动态）
class DynamicPost {
  final String id;
  final String personaId;
  final String groupId;
  final DynamicContentType contentType;
  final String content; // 文案
  final List<String> mediaPaths; // 图片/视频路径
  final DynamicPostStatus status;
  final DateTime? scheduledAt; // 计划发布时间
  final DateTime createdAt;
  final DateTime updatedAt;

  DynamicPost({
    required this.id,
    required this.personaId,
    required this.groupId,
    required this.contentType,
    required this.content,
    this.mediaPaths = const [],
    this.status = DynamicPostStatus.draft,
    this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  DynamicPost copyWith({
    String? id,
    String? personaId,
    String? groupId,
    DynamicContentType? contentType,
    String? content,
    List<String>? mediaPaths,
    DynamicPostStatus? status,
    DateTime? scheduledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DynamicPost(
        id: id ?? this.id,
        personaId: personaId ?? this.personaId,
        groupId: groupId ?? this.groupId,
        contentType: contentType ?? this.contentType,
        content: content ?? this.content,
        mediaPaths: mediaPaths ?? this.mediaPaths,
        status: status ?? this.status,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'personaId': personaId,
        'groupId': groupId,
        'contentType': contentType.index,
        'content': content,
        'mediaPaths': mediaPaths,
        'status': status.index,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DynamicPost.fromJson(Map<String, dynamic> json) => DynamicPost(
        id: json['id'] as String,
        personaId: json['personaId'] as String,
        groupId: json['groupId'] as String,
        contentType: DynamicContentType.values[json['contentType'] as int],
        content: json['content'] as String,
        mediaPaths: List<String>.from(json['mediaPaths'] as List? ?? []),
        status: DynamicPostStatus.values[json['status'] as int],
        scheduledAt: json['scheduledAt'] != null
            ? DateTime.parse(json['scheduledAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  String get contentTypeName {
    switch (contentType) {
      case DynamicContentType.text: return '文字';
      case DynamicContentType.image: return '图片';
      case DynamicContentType.video: return '视频';
      case DynamicContentType.mixed: return '图文';
    }
  }

  String get statusName {
    switch (status) {
      case DynamicPostStatus.draft: return '草稿';
      case DynamicPostStatus.published: return '已发布';
      case DynamicPostStatus.taskCreated: return '已生成任务';
    }
  }
}