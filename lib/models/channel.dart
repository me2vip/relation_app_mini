/// 社交途径（联系渠道）
///
/// 用户与联系人之间的联系方式，可由用户自行增删改。
/// 默认包含：线下、微信、QQ、快手、抖音、小红书、王者荣耀、和平精英等。
library channel;

import 'social_channel_config.dart';

/// 社交途径定义
class SocialChannel {
  final String id;
  final String name; // 途径名称，如：微信、QQ、线下
  final String icon; // emoji 图标
  final String? description; // 描述
  final bool isDefault; // 是否系统默认
  /// 平台键：系统内置平台对应 SocialPlatform 枚举名，自定义途径为 `custom_{name}`
  final String platformKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SocialChannel({
    required this.id,
    required this.name,
    this.icon = '📱',
    this.description,
    this.isDefault = false,
    this.platformKey = 'custom',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 基于名称映射 SocialPlatform（用于关联 kPlatformConfigs 的颜色/功能）
  SocialPlatform get platform {
    // 先按 platformKey 匹配枚举名
    for (final p in SocialPlatform.values) {
      if (p.name == platformKey) return p;
    }
    // 再按名称兜底映射常见平台
    switch (name) {
      case '微信': return SocialPlatform.wechat;
      case 'QQ': return SocialPlatform.qq;
      case '抖音': return SocialPlatform.douyin;
      case '快手': return SocialPlatform.kuaishou;
      case '小红书': return SocialPlatform.xiaohongshu;
      case '微博': return SocialPlatform.weibo;
      case 'B站': return SocialPlatform.bilibili;
      case '王者荣耀': return SocialPlatform.wangzhe;
      case '和平精英': return SocialPlatform.pubg;
      case '线下': return SocialPlatform.offline;
      case '电话': return SocialPlatform.phone;
      case '短信': return SocialPlatform.sms;
      default: return SocialPlatform.custom;
    }
  }

  SocialChannel copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    bool? isDefault,
    String? platformKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SocialChannel(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        description: description ?? this.description,
        isDefault: isDefault ?? this.isDefault,
        platformKey: platformKey ?? this.platformKey,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
        'isDefault': isDefault,
        'platformKey': platformKey,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SocialChannel.fromJson(Map<String, dynamic> json) => SocialChannel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? '📱',
        description: json['description'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
        platformKey: json['platformKey'] as String? ?? 'custom',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// 默认社交途径列表（含 platformKey，用于映射 SocialPlatform）
const List<Map<String, String>> defaultChannels = [
  {'name': '线下', 'icon': '🤝', 'platformKey': 'offline'},
  {'name': '微信', 'icon': '💬', 'platformKey': 'wechat'},
  {'name': 'QQ', 'icon': '🐧', 'platformKey': 'qq'},
  {'name': '快手', 'icon': '🎬', 'platformKey': 'kuaishou'},
  {'name': '抖音', 'icon': '🎵', 'platformKey': 'douyin'},
  {'name': '小红书', 'icon': '📕', 'platformKey': 'xiaohongshu'},
  {'name': '王者荣耀', 'icon': '⚔️', 'platformKey': 'wangzhe'},
  {'name': '和平精英', 'icon': '🔫', 'platformKey': 'pubg'},
  {'name': '电话', 'icon': '📞', 'platformKey': 'phone'},
  {'name': '短信', 'icon': '✉️', 'platformKey': 'sms'},
  {'name': '微博', 'icon': '📰', 'platformKey': 'weibo'},
  {'name': 'B站', 'icon': '📺', 'platformKey': 'bilibili'},
];


