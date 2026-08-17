class Persona {
  final String id;
  final String name;
  final String? description;
  final String groupId; // 关联到 ContactGroup，每组一个人设
  final String roleDescription; // 人设角色描述，如"职场精英"、"文艺青年"
  final List<String> traits; // 性格特征标签
  final String postingStyle; // 发圈风格指导，如"简洁专业、偶尔幽默"
  final List<String> contentThemes; // 内容主题，如"工作成就、行业见解、偶尔生活感悟"
  final String toneGuidelines; // 语气指导
  final List<String> forbiddenTopics; // 禁忌话题
  final DateTime createdAt;
  final DateTime updatedAt;

  Persona({
    required this.id,
    required this.name,
    this.description,
    required this.groupId,
    required this.roleDescription,
    this.traits = const [],
    this.postingStyle = '',
    this.contentThemes = const [],
    this.toneGuidelines = '',
    this.forbiddenTopics = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Persona copyWith({
    String? id,
    String? name,
    String? description,
    String? groupId,
    String? roleDescription,
    List<String>? traits,
    String? postingStyle,
    List<String>? contentThemes,
    String? toneGuidelines,
    List<String>? forbiddenTopics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Persona(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        groupId: groupId ?? this.groupId,
        roleDescription: roleDescription ?? this.roleDescription,
        traits: traits ?? this.traits,
        postingStyle: postingStyle ?? this.postingStyle,
        contentThemes: contentThemes ?? this.contentThemes,
        toneGuidelines: toneGuidelines ?? this.toneGuidelines,
        forbiddenTopics: forbiddenTopics ?? this.forbiddenTopics,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'groupId': groupId,
        'roleDescription': roleDescription,
        'traits': traits,
        'postingStyle': postingStyle,
        'contentThemes': contentThemes,
        'toneGuidelines': toneGuidelines,
        'forbiddenTopics': forbiddenTopics,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Persona.fromJson(Map<String, dynamic> json) => Persona(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        groupId: json['groupId'] as String,
        roleDescription: json['roleDescription'] as String,
        traits: List<String>.from(json['traits'] as List? ?? []),
        postingStyle: json['postingStyle'] as String? ?? '',
        contentThemes: List<String>.from(json['contentThemes'] as List? ?? []),
        toneGuidelines: json['toneGuidelines'] as String? ?? '',
        forbiddenTopics: List<String>.from(json['forbiddenTopics'] as List? ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// 构建人设提示词（用于 AI 配文案 / 生成动态）
  String buildSystemPrompt({String? groupName}) {
    final buffer = StringBuffer();
    buffer.writeln('你正在以"$name"这个人设进行表达。');
    buffer.writeln('角色定位：$roleDescription');
    if (groupName != null && groupName.isNotEmpty) {
      buffer.writeln('面向的受众分组：$groupName');
    }
    if (traits.isNotEmpty) {
      buffer.writeln('性格特征：${traits.join('、')}');
    }
    if (postingStyle.isNotEmpty) {
      buffer.writeln('发圈风格：$postingStyle');
    }
    if (contentThemes.isNotEmpty) {
      buffer.writeln('内容主题：${contentThemes.join('、')}');
    }
    if (toneGuidelines.isNotEmpty) {
      buffer.writeln('语气指导：$toneGuidelines');
    }
    if (forbiddenTopics.isNotEmpty) {
      buffer.writeln('禁忌话题（绝对不要提及）：${forbiddenTopics.join('、')}');
    }
    return buffer.toString();
  }
}
