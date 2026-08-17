class ContactGroup {
  final String id;
  final String name;
  final String? description;
  final String? icon; // emoji string
  final int? color; // int color value
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactGroup({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  ContactGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ContactGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ContactGroup.fromJson(Map<String, dynamic> json) => ContactGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        color: json['color'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}