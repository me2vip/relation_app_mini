class AtmosphereItem {
  final String id;
  final String category;
  final String label;
  final String value;
  final bool enabled;
  final int displayOrder;

  AtmosphereItem({
    required this.id,
    required this.category,
    required this.label,
    required this.value,
    this.enabled = true,
    this.displayOrder = 0,
  });

  AtmosphereItem copyWith({
    String? id,
    String? category,
    String? label,
    String? value,
    bool? enabled,
    int? displayOrder,
  }) => AtmosphereItem(
    id: id ?? this.id,
    category: category ?? this.category,
    label: label ?? this.label,
    value: value ?? this.value,
    enabled: enabled ?? this.enabled,
    displayOrder: displayOrder ?? this.displayOrder,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'label': label,
    'value': value,
    'enabled': enabled,
    'displayOrder': displayOrder,
  };

  factory AtmosphereItem.fromJson(Map<String, dynamic> json) => AtmosphereItem(
    id: json['id'] as String,
    category: json['category'] as String,
    label: json['label'] as String,
    value: json['value'] as String,
    enabled: json['enabled'] as bool? ?? true,
    displayOrder: json['displayOrder'] as int? ?? 0,
  );
}

class AtmosphereProfile {
  final String id;
  final String name;
  final String? description;
  final Map<String, List<AtmosphereItem>> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  AtmosphereProfile({
    required this.id,
    required this.name,
    this.description,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  AtmosphereProfile copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, List<AtmosphereItem>>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AtmosphereProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    items: items ?? this.items,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'items': items.map((k, v) => MapEntry(k, v.map((i) => i.toJson()).toList())),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AtmosphereProfile.fromJson(Map<String, dynamic> json) => AtmosphereProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    items: (json['items'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as List).map((i) => AtmosphereItem.fromJson(i)).toList()),
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  /// 默认氛围分类
  static const List<String> defaultCategories = [
    '基本信息',
    '工作信息',
    '财务信息',
    '社交关系',
    '兴趣爱好',
    '生活习惯',
    '情感状态',
    '其他',
  ];

  /// 创建空配置
  factory AtmosphereProfile.empty({
    required String id,
    required String name,
  }) {
    final now = DateTime.now();
    final items = <String, List<AtmosphereItem>>{};
    for (var i = 0; i < defaultCategories.length; i++) {
      items[defaultCategories[i]] = [];
    }
    return AtmosphereProfile(
      id: id,
      name: name,
      items: items,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class ContactAtmosphereSetting {
  final String id;
  final String contactId;
  final String profileId;
  final List<String> exposedFields;
  final List<String> hiddenFields;
  final bool useCustomSettings;

  ContactAtmosphereSetting({
    required this.id,
    required this.contactId,
    required this.profileId,
    required this.exposedFields,
    required this.hiddenFields,
    this.useCustomSettings = false,
  });

  ContactAtmosphereSetting copyWith({
    String? id,
    String? contactId,
    String? profileId,
    List<String>? exposedFields,
    List<String>? hiddenFields,
    bool? useCustomSettings,
  }) => ContactAtmosphereSetting(
    id: id ?? this.id,
    contactId: contactId ?? this.contactId,
    profileId: profileId ?? this.profileId,
    exposedFields: exposedFields ?? this.exposedFields,
    hiddenFields: hiddenFields ?? this.hiddenFields,
    useCustomSettings: useCustomSettings ?? this.useCustomSettings,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'profileId': profileId,
    'exposedFields': exposedFields,
    'hiddenFields': hiddenFields,
    'useCustomSettings': useCustomSettings,
  };

  factory ContactAtmosphereSetting.fromJson(Map<String, dynamic> json) =>
      ContactAtmosphereSetting(
        id: json['id'] as String,
        contactId: json['contactId'] as String,
        profileId: json['profileId'] as String,
        exposedFields: List<String>.from(json['exposedFields'] as List),
        hiddenFields: List<String>.from(json['hiddenFields'] as List),
        useCustomSettings: json['useCustomSettings'] as bool? ?? false,
      );
}
