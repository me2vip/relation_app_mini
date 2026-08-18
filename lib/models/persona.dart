/// 社交人设（信息暴露）模型
///
/// 人设 = 用户可以向联系人暴露的所有信息的集合。
/// 每个人设定义一组信息项（工作、学习、公司、薪资等），
/// 不同联系人通过关联不同的人设，看到同一信息项的不同内容。
library persona;

/// 信息项分类常量
const List<String> kInfoCategories = [
  '工作',
  '学习',
  '环境',
  '公司位置',
  '公司文化',
  '公司招人计划',
  '薪资待遇',
  '家庭',
  '情感',
  '兴趣',
  '其他',
];

/// 人设信息项（一个信息维度，如"工作"）
class PersonaInfoItem {
  final String id;
  final String personaId; // 所属人设
  final String category; // 信息分类：工作/学习/薪资待遇…
  final String label; // 显示标签，如"我的工作"
  final String content; // 该人设下向联系人暴露的内容，如"互联网大厂程序员"
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonaInfoItem({
    required this.id,
    required this.personaId,
    required this.category,
    required this.label,
    required this.content,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  PersonaInfoItem copyWith({
    String? id,
    String? personaId,
    String? category,
    String? label,
    String? content,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PersonaInfoItem(
        id: id ?? this.id,
        personaId: personaId ?? this.personaId,
        category: category ?? this.category,
        label: label ?? this.label,
        content: content ?? this.content,
        displayOrder: displayOrder ?? this.displayOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'personaId': personaId,
        'category': category,
        'label': label,
        'content': content,
        'displayOrder': displayOrder,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PersonaInfoItem.fromJson(Map<String, dynamic> json) =>
      PersonaInfoItem(
        id: json['id'] as String,
        personaId: json['personaId'] as String,
        category: json['category'] as String,
        label: json['label'] as String,
        content: json['content'] as String,
        displayOrder: json['displayOrder'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// 社交人设（面向某类联系人的信息暴露方案）
class Persona {
  final String id;
  final String name; // 人设名称，如"同事看到的我"
  final String? description;
  final String? groupId; // 关联分组（可选，支持无分组全局人设）
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 信息项（工作/学习/薪资等，每项内容随人设不同而不同）
  final List<PersonaInfoItem> infoItems;

  const Persona({
    required this.id,
    required this.name,
    this.description,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.infoItems = const [],
  });

  Persona copyWith({
    String? id,
    String? name,
    String? description,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PersonaInfoItem>? infoItems,
  }) =>
      Persona(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        groupId: groupId ?? this.groupId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        infoItems: infoItems ?? this.infoItems,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'groupId': groupId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'infoItems': infoItems.map((i) => i.toJson()).toList(),
      };

  factory Persona.fromJson(Map<String, dynamic> json) => Persona(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        groupId: json['groupId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        infoItems: (json['infoItems'] as List?)
                ?.map((i) => PersonaInfoItem.fromJson(
                    Map<String, dynamic>.from(i as Map)))
                .toList() ??
            const [],
      );

  /// 按分类取信息项
  Map<String, List<PersonaInfoItem>> get itemsByCategory {
    final map = <String, List<PersonaInfoItem>>{};
    for (final item in infoItems) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  /// 构建 AI 配文案用的信息摘要
  String get infoSummary {
    final buffer = StringBuffer();
    for (final cat in kInfoCategories) {
      final items = infoItems.where((i) => i.category == cat).toList();
      if (items.isEmpty) continue;
      buffer.writeln('【$cat】');
      for (final item in items) {
        buffer.writeln('- ${item.label}：${item.content}');
      }
    }
    return buffer.toString().trim();
  }

  /// 构建人设系统提示词（供 AI 为素材配文案）
  String buildSystemPrompt({String? groupName}) {
    final buffer = StringBuffer();
    buffer.writeln('你现在要扮演用户在其社交圈中的一个人设："$name"。');
    buffer.writeln('请严格按照这个人设可暴露的信息来撰写内容，不要泄露人设之外的信息。');
    if (groupName != null && groupName.isNotEmpty) {
      buffer.writeln('该内容的可见受众分组：$groupName（只给这个分组的人看到）。');
    }
    buffer.writeln('');
    buffer.writeln('该人设可暴露的信息如下（写文案时可自然引用，但不要过度堆砌）：');
    final summary = infoSummary;
    buffer.writeln(summary.isEmpty ? '（该人设尚未定义信息项）' : summary);
    buffer.writeln('');
    buffer.writeln('要求：');
    buffer.writeln('1. 文案自然真实，符合朋友圈/说说/动态的语感');
    buffer.writeln('2. 只能使用上述人设信息，绝不透露人设之外的真实信息');
    buffer.writeln('3. 长度适中（50-150字），可配 emoji，风格轻松');
    return buffer.toString();
  }
}

/// 联系人-人设关联（每个联系人对应一个人设）
class ContactPersonaLink {
  final String id;
  final String contactId;
  final String personaId;
  final DateTime updatedAt;

  const ContactPersonaLink({
    required this.id,
    required this.contactId,
    required this.personaId,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactId': contactId,
        'personaId': personaId,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ContactPersonaLink.fromJson(Map<String, dynamic> json) =>
      ContactPersonaLink(
        id: json['id'] as String,
        contactId: json['contactId'] as String,
        personaId: json['personaId'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
