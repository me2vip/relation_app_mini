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

/// 临时素材（用户拍照/添加内容 → APP 识别分组和人设 → 配文案 → 生成发圈任务）
class TempMaterial {
  final String id;
  final String groupId;
  final String? personaId; // 识别出的人设，未识别时为 null
  final TempMaterialType materialType;
  final String? filePath; // 图片/视频本地路径
  final String? textContent; // 文字素材
  final String? aiCaption; // AI 配的文案
  final TempMaterialStatus status;
  final DateTime createdAt;

  TempMaterial({
    required this.id,
    required this.groupId,
    this.personaId,
    required this.materialType,
    this.filePath,
    this.textContent,
    this.aiCaption,
    this.status = TempMaterialStatus.pending,
    required this.createdAt,
  });

  TempMaterial copyWith({
    String? id,
    String? groupId,
    String? personaId,
    TempMaterialType? materialType,
    String? filePath,
    String? textContent,
    String? aiCaption,
    TempMaterialStatus? status,
    DateTime? createdAt,
  }) =>
      TempMaterial(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        personaId: personaId ?? this.personaId,
        materialType: materialType ?? this.materialType,
        filePath: filePath ?? this.filePath,
        textContent: textContent ?? this.textContent,
        aiCaption: aiCaption ?? this.aiCaption,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'personaId': personaId,
        'materialType': materialType.index,
        'filePath': filePath,
        'textContent': textContent,
        'aiCaption': aiCaption,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TempMaterial.fromJson(Map<String, dynamic> json) => TempMaterial(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        personaId: json['personaId'] as String?,
        materialType: TempMaterialType.values[json['materialType'] as int],
        filePath: json['filePath'] as String?,
        textContent: json['textContent'] as String?,
        aiCaption: json['aiCaption'] as String?,
        status: TempMaterialStatus.values[json['status'] as int],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get materialTypeName {
    switch (materialType) {
      case TempMaterialType.image: return '图片';
      case TempMaterialType.text: return '文字';
      case TempMaterialType.video: return '视频';
    }
  }

  String get statusName {
    switch (status) {
      case TempMaterialStatus.pending: return '待处理';
      case TempMaterialStatus.captioned: return '已配文案';
      case TempMaterialStatus.taskCreated: return '已生成任务';
    }
  }
}