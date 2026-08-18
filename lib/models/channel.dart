/// 社交途径（联系渠道）
///
/// 用户与联系人之间的联系方式，可由用户自行增删改。
/// 默认包含：线下、微信、QQ、快手、抖音、小红书、王者荣耀、和平精英等。
library channel;

/// 社交途径定义
class SocialChannel {
  final String id;
  final String name; // 途径名称，如：微信、QQ、线下
  final String icon; // emoji 图标
  final String? description; // 描述
  final bool isDefault; // 是否系统默认
  final DateTime createdAt;
  final DateTime updatedAt;

  const SocialChannel({
    required this.id,
    required this.name,
    this.icon = '📱',
    this.description,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  SocialChannel copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SocialChannel(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        description: description ?? this.description,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SocialChannel.fromJson(Map<String, dynamic> json) => SocialChannel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? '📱',
        description: json['description'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// 默认社交途径列表
const List<Map<String, String>> defaultChannels = [
  {'name': '线下', 'icon': '🤝'},
  {'name': '微信', 'icon': '💬'},
  {'name': 'QQ', 'icon': '🐧'},
  {'name': '快手', 'icon': '🎬'},
  {'name': '抖音', 'icon': '🎵'},
  {'name': '小红书', 'icon': '📕'},
  {'name': '王者荣耀', 'icon': '⚔️'},
  {'name': '和平精英', 'icon': '🔫'},
  {'name': '电话', 'icon': '📞'},
  {'name': '短信', 'icon': '✉️'},
  {'name': '微博', 'icon': '📰'},
  {'name': 'B站', 'icon': '📺'},
];

/// 联系人与途径的关联（一个联系人可用多个途径）
class ContactChannelLink {
  final String id;
  final String contactId;
  final String channelId;
  final String account; // 该途径下的账号信息
  final String? remark; // 备注
  final DateTime createdAt;

  const ContactChannelLink({
    required this.id,
    required this.contactId,
    required this.channelId,
    required this.account,
    this.remark,
    required this.createdAt,
  });

  ContactChannelLink copyWith({
    String? id,
    String? contactId,
    String? channelId,
    String? account,
    String? remark,
    DateTime? createdAt,
  }) =>
      ContactChannelLink(
        id: id ?? this.id,
        contactId: contactId ?? this.contactId,
        channelId: channelId ?? this.channelId,
        account: account ?? this.account,
        remark: remark ?? this.remark,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactId': contactId,
        'channelId': channelId,
        'account': account,
        'remark': remark,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ContactChannelLink.fromJson(Map<String, dynamic> json) =>
      ContactChannelLink(
        id: json['id'] as String,
        contactId: json['contactId'] as String,
        channelId: json['channelId'] as String,
        account: json['account'] as String,
        remark: json['remark'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
