/// 社交途径（联系渠道）
///
/// 用户与联系人之间的联系方式，可由用户自行增删改。
/// 默认包含：线下、微信、QQ、快手、抖音、小红书、王者荣耀、和平精英等。
library channel;

import 'social_channel_config.dart';

/// 社交途径定义
///
/// 支持两级结构：
/// - 父途径：parentId == null（如「微信」「QQ」）
/// - 子途径：parentId == 父途径 id（如「微信 → 朋友圈 / 私聊 / 微信群」）
class SocialChannel {
  final String id;
  final String name; // 途径名称，如：微信、QQ、线下
  final String icon; // emoji 图标
  final String? description; // 描述
  final bool isDefault; // 是否系统默认
  /// 平台键：系统内置平台对应 SocialPlatform 枚举名，自定义途径为 `custom_{name}`
  final String platformKey;
  /// 父途径 id：null=根途径(父)，非null=子途径
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSubChannel => parentId != null && parentId!.isNotEmpty;

  const SocialChannel({
    required this.id,
    required this.name,
    this.icon = '📱',
    this.description,
    this.isDefault = false,
    this.platformKey = 'custom',
    this.parentId,
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
    String? parentId,
    bool resetParentId = false,
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
        parentId: resetParentId ? null : (parentId ?? this.parentId),
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
        'parentId': parentId,
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
        parentId: json['parentId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// 为常见父途径预置的默认子类型（首次加载时若父途径尚无子途径则自动插入）
/// 结构: {父途径platformKey: [子途径名, emoji, 描述]}
const Map<String, List<Map<String, String>>> defaultSubChannels = {
  'offline': [
    {'name': '面对面互动', 'icon': '🤝', 'description': '线下面对面聊天、见面聚会'},
  ],
  'wechat': [
    {'name': '私聊', 'icon': '💬', 'description': '一对一微信私聊'},
    {'name': '群聊', 'icon': '👥', 'description': '微信群共同聊天互动'},
    {'name': '朋友圈', 'icon': '📸', 'description': '朋友圈点赞/评论/发圈互动'},
  ],
  'qq': [
    {'name': '私聊', 'icon': '💬', 'description': '一对一QQ私聊'},
    {'name': '群聊', 'icon': '👥', 'description': 'QQ群聊互动'},
    {'name': '动态', 'icon': '🌌', 'description': 'QQ空间动态点赞/评论互动'},
  ],
  'phone': [
    {'name': '语音', 'icon': '📞', 'description': '语音电话沟通'},
    {'name': '视频', 'icon': '🎥', 'description': '视频电话沟通'},
    {'name': '短信', 'icon': '✉️', 'description': '手机短信往来'},
  ],
  'douyin': [
    {'name': '私聊', 'icon': '✉️', 'description': '抖音私信聊天'},
    {'name': '日常', 'icon': '🎬', 'description': '日常视频/评论区互动'},
  ],
  'kuaishou': [
    {'name': '私聊', 'icon': '✉️', 'description': '快手私信聊天'},
    {'name': '日常', 'icon': '🎬', 'description': '日常短视频/评论区互动'},
  ],
  'xiaohongshu': [
    {'name': '私信', 'icon': '✉️', 'description': '小红书私信聊天'},
    {'name': '笔记评论', 'icon': '📝', 'description': '笔记评论区点赞/互动'},
  ],
  'weibo': [
    {'name': '私信', 'icon': '✉️', 'description': '微博私信聊天'},
    {'name': '微博互动', 'icon': '📰', 'description': '发博/转发/评论/点赞互动'},
  ],
  'bilibili': [
    {'name': '私信', 'icon': '✉️', 'description': 'B站私信聊天'},
    {'name': '弹幕评论', 'icon': '📺', 'description': '视频弹幕/评论区互动'},
    {'name': '动态', 'icon': '✨', 'description': 'UP主动态互动'},
  ],
  'wangzhe': [
    {'name': '组队开黑', 'icon': '⚔️', 'description': '一起组队打王者'},
    {'name': '游戏内聊天', 'icon': '💬', 'description': '王者荣耀内置聊天'},
  ],
  'pubg': [
    {'name': '组队吃鸡', 'icon': '🔫', 'description': '一起组队打和平精英'},
    {'name': '游戏内聊天', 'icon': '💬', 'description': '和平精英内置聊天'},
  ],
  'sms': [
    {'name': '节日祝福', 'icon': '🎉', 'description': '节假日问候短信'},
    {'name': '日常提醒', 'icon': '⏰', 'description': '事项/约会提醒短信'},
  ],
};

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


