/// 临时素材类型
enum TempMaterialType {
  /// 图片
  image,
  /// 文字
  text,
  /// 视频
  video,
}

/// 临时素材状态
enum TempMaterialStatus {
  /// 待处理
  pending,
  /// 已配文案
  captioned,
  /// 已生成任务
  taskCreated,
}

/// 临时素材（用户拍照/添加内容 → APP 判断可暴露的分组 → 分别为其配文案 → 生成发圈任务）
class TempMaterial {
  final String id;
  final List<String> groupIds; // 素材可暴露给哪些分组（多分组）
  final TempMaterialType materialType;
  final List<String> filePaths; // 图片/视频本地路径（支持多图）
  final String? textContent; // 文字素材
  final String? aiCaption; // AI 配的文案（统一文案，或第一组文案）
  final Map<String, String> captionsByGroup; // 每个分组的专属文案 groupId -> caption
  final TempMaterialStatus status;
  final DateTime createdAt;

  TempMaterial({
    required this.id,
    required this.groupIds,
    required this.materialType,
    this.filePaths = const [],
    this.textContent,
    this.aiCaption,
    this.captionsByGroup = const {},
    this.status = TempMaterialStatus.pending,
    required this.createdAt,
  });

  TempMaterial copyWith({
    String? id,
    List<String>? groupIds,
    TempMaterialType? materialType,
    List<String>? filePaths,
    String? textContent,
    String? aiCaption,
    Map<String, String>? captionsByGroup,
    TempMaterialStatus? status,
    DateTime? createdAt,
  }) =>
      TempMaterial(
        id: id ?? this.id,
        groupIds: groupIds ?? this.groupIds,
        materialType: materialType ?? this.materialType,
        filePaths: filePaths ?? this.filePaths,
        textContent: textContent ?? this.textContent,
        aiCaption: aiCaption ?? this.aiCaption,
        captionsByGroup: captionsByGroup ?? this.captionsByGroup,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupIds': groupIds,
        'materialType': materialType.index,
        'filePaths': filePaths,
        'textContent': textContent,
        'aiCaption': aiCaption,
        'captionsByGroup': captionsByGroup,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TempMaterial.fromJson(Map<String, dynamic> json) => TempMaterial(
        id: json['id'] as String,
        groupIds: List<String>.from(json['groupIds'] as List? ?? []),
        materialType: TempMaterialType.values[json['materialType'] as int],
        filePaths: List<String>.from(json['filePaths'] as List? ?? []),
        textContent: json['textContent'] as String?,
        aiCaption: json['aiCaption'] as String?,
        captionsByGroup: Map<String, String>.from(
            json['captionsByGroup'] as Map? ?? {}),
        status: TempMaterialStatus.values[json['status'] as int],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get materialTypeName {
    switch (materialType) {
      case TempMaterialType.image:
        return '图片';
      case TempMaterialType.text:
        return '文字';
      case TempMaterialType.video:
        return '视频';
    }
  }

  String get statusName {
    switch (status) {
      case TempMaterialStatus.pending:
        return '待处理';
      case TempMaterialStatus.captioned:
        return '已配文案';
      case TempMaterialStatus.taskCreated:
        return '已生成任务';
    }
  }
}
