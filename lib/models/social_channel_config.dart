import 'package:flutter/material.dart';

/// 社交途径层级模型
///
/// 平台 (SocialPlatform) → 子渠道 (ChannelFeatureConfig) → 互动类型 (InteractionMode)

enum SocialPlatform {
  wechat,
  qq,
  douyin,
  kuaishou,
  xiaohongshu,
  weibo,
  bilibili,
  wangzhe,
  pubg,
  offline,
  phone,
  sms,
  custom;
}

class PlatformConfig {
  final SocialPlatform platform;
  final String name;
  final String emoji;
  final Color color;
  final List<ChannelFeatureConfig> features;

  const PlatformConfig({
    required this.platform,
    required this.name,
    required this.emoji,
    required this.color,
    required this.features,
  });
}

enum ChannelFeature {
  privateChat,
  groupChat,
  moments,
  daily,
  space,
  feed,
  offlineMeetup,
  customFeature;
}

class ChannelFeatureConfig {
  final ChannelFeature feature;
  final String name;
  final String emoji;
  final List<InteractionMode> supportedModes;

  const ChannelFeatureConfig({
    required this.feature,
    required this.name,
    required this.emoji,
    required this.supportedModes,
  });
}

enum InteractionMode {
  textMessage,
  voiceMessage,
  emojiSticker,
  voiceCall,
  videoCall,
  videoShare,
  locationShare,
  offlineMeeting,
  groupActivity,
  giftSend,
  customMode;
}

class InteractionModeConfig {
  final InteractionMode mode;
  final String name;
  final String emoji;

  const InteractionModeConfig({
    required this.mode,
    required this.name,
    required this.emoji,
  });
}

class ContactChannelConfig {
  final String id;
  final String contactId;
  final String channelId; // 关联 SocialChannel.id
  final SocialPlatform platform;
  final String? account;
  final String? remark;
  final List<ChannelFeature> enabledFeatures;
  final List<InteractionMode> preferredModes;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContactChannelConfig({
    required this.id,
    required this.contactId,
    this.channelId = '',
    required this.platform,
    this.account,
    this.remark,
    this.enabledFeatures = const [],
    this.preferredModes = const [],
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
  });

  ContactChannelConfig copyWith({
    String? id,
    String? contactId,
    String? channelId,
    SocialPlatform? platform,
    String? account,
    String? remark,
    List<ChannelFeature>? enabledFeatures,
    List<InteractionMode>? preferredModes,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ContactChannelConfig(
    id: id ?? this.id,
    contactId: contactId ?? this.contactId,
    channelId: channelId ?? this.channelId,
    platform: platform ?? this.platform,
    account: account ?? this.account,
    remark: remark ?? this.remark,
    enabledFeatures: enabledFeatures ?? this.enabledFeatures,
    preferredModes: preferredModes ?? this.preferredModes,
    isPrimary: isPrimary ?? this.isPrimary,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'channelId': channelId,
    'platform': platform.index,
    'account': account,
    'remark': remark,
    'enabledFeatures': enabledFeatures.map((f) => f.index).toList(),
    'preferredModes': preferredModes.map((m) => m.index).toList(),
    'isPrimary': isPrimary,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ContactChannelConfig.fromJson(Map<String, dynamic> json) => ContactChannelConfig(
    id: json['id'] as String,
    contactId: json['contactId'] as String,
    channelId: json['channelId'] as String? ?? '',
    platform: SocialPlatform.values[json['platform'] as int? ?? 0],
    account: json['account'] as String?,
    remark: json['remark'] as String?,
    enabledFeatures: (json['enabledFeatures'] as List?)
        ?.map((f) => ChannelFeature.values[f as int])
        .toList() ?? [],
    preferredModes: (json['preferredModes'] as List?)
        ?.map((m) => InteractionMode.values[m as int])
        .toList() ?? [],
    isPrimary: json['isPrimary'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

// ==================== 默认配置 ====================

const List<PlatformConfig> kPlatformConfigs = [
  PlatformConfig(
    platform: SocialPlatform.wechat,
    name: '微信',
    emoji: '💚',
    color: Color(0xFF07C160),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.privateChat, name: '私聊', emoji: '💬',
          supportedModes: [InteractionMode.textMessage, InteractionMode.voiceMessage, InteractionMode.emojiSticker, InteractionMode.voiceCall, InteractionMode.videoCall]),
      ChannelFeatureConfig(feature: ChannelFeature.groupChat, name: '群聊', emoji: '👥',
          supportedModes: [InteractionMode.textMessage, InteractionMode.voiceMessage, InteractionMode.emojiSticker]),
      ChannelFeatureConfig(feature: ChannelFeature.moments, name: '朋友圈', emoji: '📸',
          supportedModes: [InteractionMode.videoShare, InteractionMode.textMessage]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.qq,
    name: 'QQ',
    emoji: '🐧',
    color: Color(0xFF12B7F5),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.privateChat, name: '私聊', emoji: '💬',
          supportedModes: [InteractionMode.textMessage, InteractionMode.voiceMessage, InteractionMode.emojiSticker, InteractionMode.voiceCall, InteractionMode.videoCall]),
      ChannelFeatureConfig(feature: ChannelFeature.groupChat, name: '群聊', emoji: '👥',
          supportedModes: [InteractionMode.textMessage, InteractionMode.voiceMessage, InteractionMode.emojiSticker]),
      ChannelFeatureConfig(feature: ChannelFeature.space, name: 'QQ空间', emoji: '🌌',
          supportedModes: [InteractionMode.videoShare, InteractionMode.textMessage]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.douyin,
    name: '抖音',
    emoji: '🎵',
    color: Color(0xFF000000),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.privateChat, name: '私信', emoji: '💬',
          supportedModes: [InteractionMode.textMessage, InteractionMode.emojiSticker, InteractionMode.voiceCall, InteractionMode.videoCall]),
      ChannelFeatureConfig(feature: ChannelFeature.daily, name: '日常', emoji: '📸',
          supportedModes: [InteractionMode.videoShare, InteractionMode.textMessage]),
      ChannelFeatureConfig(feature: ChannelFeature.feed, name: '视频分享', emoji: '🎬',
          supportedModes: [InteractionMode.videoShare]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.kuaishou,
    name: '快手',
    emoji: '🎬',
    color: Color(0xFFFF6600),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.privateChat, name: '私信', emoji: '💬',
          supportedModes: [InteractionMode.textMessage, InteractionMode.emojiSticker, InteractionMode.voiceCall, InteractionMode.videoCall]),
      ChannelFeatureConfig(feature: ChannelFeature.daily, name: '日常', emoji: '📸',
          supportedModes: [InteractionMode.videoShare, InteractionMode.textMessage]),
      ChannelFeatureConfig(feature: ChannelFeature.feed, name: '视频分享', emoji: '🎬',
          supportedModes: [InteractionMode.videoShare]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.xiaohongshu,
    name: '小红书',
    emoji: '📕',
    color: Color(0xFFFE2C55),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.privateChat, name: '私信', emoji: '💬',
          supportedModes: [InteractionMode.textMessage, InteractionMode.emojiSticker]),
      ChannelFeatureConfig(feature: ChannelFeature.feed, name: '笔记分享', emoji: '📝',
          supportedModes: [InteractionMode.videoShare, InteractionMode.textMessage]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.weibo,
    name: '微博',
    emoji: '📰',
    color: Color(0xFFE6162D),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.privateChat, name: '私信', emoji: '💬',
          supportedModes: [InteractionMode.textMessage, InteractionMode.emojiSticker]),
      ChannelFeatureConfig(feature: ChannelFeature.feed, name: '动态', emoji: '📰',
          supportedModes: [InteractionMode.videoShare, InteractionMode.textMessage]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.bilibili,
    name: 'B站',
    emoji: '📺',
    color: Color(0xFF00AEEC),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.privateChat, name: '私信', emoji: '💬',
          supportedModes: [InteractionMode.textMessage]),
      ChannelFeatureConfig(feature: ChannelFeature.feed, name: '视频', emoji: '📺',
          supportedModes: [InteractionMode.videoShare]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.wangzhe,
    name: '王者荣耀',
    emoji: '⚔️',
    color: Color(0xFFD4A017),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.groupChat, name: '组队聊天', emoji: '👥',
          supportedModes: [InteractionMode.voiceCall, InteractionMode.textMessage, InteractionMode.groupActivity]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.pubg,
    name: '和平精英',
    emoji: '🔫',
    color: Color(0xFF4A90D9),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.groupChat, name: '组队聊天', emoji: '👥',
          supportedModes: [InteractionMode.voiceCall, InteractionMode.textMessage, InteractionMode.groupActivity]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.offline,
    name: '线下',
    emoji: '🤝',
    color: Color(0xFF27AE60),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.offlineMeetup, name: '面对面互动', emoji: '😀',
          supportedModes: [InteractionMode.offlineMeeting, InteractionMode.groupActivity, InteractionMode.giftSend]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.phone,
    name: '电话',
    emoji: '📞',
    color: Color(0xFF2C3E50),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.privateChat, name: '语音通话', emoji: '📞',
          supportedModes: [InteractionMode.voiceCall, InteractionMode.videoCall, InteractionMode.voiceMessage]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.sms,
    name: '短信',
    emoji: '✉️',
    color: Color(0xFF2980B9),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.privateChat, name: '文字短信', emoji: '💬',
          supportedModes: [InteractionMode.textMessage]),
    ],
  ),
  PlatformConfig(
    platform: SocialPlatform.custom,
    name: '自定义',
    emoji: '🔗',
    color: Color(0xFF9B59B6),
    features: [
      ChannelFeatureConfig(feature: ChannelFeature.customFeature, name: '自定义', emoji: '✨',
          supportedModes: [InteractionMode.textMessage, InteractionMode.voiceMessage, InteractionMode.voiceCall, InteractionMode.videoCall]),
    ],
  ),
];

const List<InteractionModeConfig> kInteractionModeConfigs = [
  InteractionModeConfig(mode: InteractionMode.textMessage, name: '文字消息', emoji: '💬'),
  InteractionModeConfig(mode: InteractionMode.voiceMessage, name: '语音消息', emoji: '🎙️'),
  InteractionModeConfig(mode: InteractionMode.emojiSticker, name: '表情/贴纸', emoji: '😊'),
  InteractionModeConfig(mode: InteractionMode.voiceCall, name: '语音对话', emoji: '📞'),
  InteractionModeConfig(mode: InteractionMode.videoCall, name: '视频对话', emoji: '📹'),
  InteractionModeConfig(mode: InteractionMode.videoShare, name: '分享视频', emoji: '🎬'),
  InteractionModeConfig(mode: InteractionMode.locationShare, name: '位置共享', emoji: '📍'),
  InteractionModeConfig(mode: InteractionMode.offlineMeeting, name: '线下见面', emoji: '🤝'),
  InteractionModeConfig(mode: InteractionMode.groupActivity, name: '群体活动', emoji: '🎉'),
  InteractionModeConfig(mode: InteractionMode.giftSend, name: '送礼', emoji: '🎁'),
  InteractionModeConfig(mode: InteractionMode.customMode, name: '自定义', emoji: '✨'),
];

PlatformConfig getPlatformConfig(SocialPlatform platform) {
  return kPlatformConfigs.firstWhere(
    (p) => p.platform == platform,
    orElse: () => kPlatformConfigs.last,
  );
}

ChannelFeatureConfig getFeatureConfig(ChannelFeature feature) {
  for (final platform in kPlatformConfigs) {
    for (final f in platform.features) {
      if (f.feature == feature) return f;
    }
  }
  return const ChannelFeatureConfig(
    feature: ChannelFeature.customFeature,
    name: '自定义',
    emoji: '✨',
    supportedModes: [],
  );
}

InteractionModeConfig getModeConfig(InteractionMode mode) {
  return kInteractionModeConfigs.firstWhere(
    (m) => m.mode == mode,
    orElse: () => kInteractionModeConfigs.last,
  );
}

/// 自定义平台默认色（当 platform == custom 时使用，按 customColorIdx 轮换）
const List<Color> kCustomPlatformColors = [
  Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFF59E0B),
  Color(0xFF10B981), Color(0xFF8B5CF6), Color(0xFF14B8A6),
  Color(0xFFEF4444), Color(0xFF06B6D4),
];

/// 根据 platform + name 获取平台配置；对于 SocialPlatform.custom 生成一个动态的 PlatformConfig
PlatformConfig resolvePlatformConfig(SocialPlatform platform, String channelName, String channelIcon) {
  if (platform != SocialPlatform.custom) {
    return getPlatformConfig(platform);
  }
  // 使用名称字符串哈希稳定选择颜色
  final idx = channelName.hashCode.abs() % kCustomPlatformColors.length;
  final color = kCustomPlatformColors[idx];
  return PlatformConfig(
    platform: SocialPlatform.custom,
    name: channelName,
    emoji: channelIcon,
    color: color,
    features: const [
      ChannelFeatureConfig(
        feature: ChannelFeature.privateChat,
        name: '私聊',
        emoji: '💬',
        supportedModes: [InteractionMode.textMessage, InteractionMode.voiceMessage, InteractionMode.voiceCall, InteractionMode.videoCall],
      ),
      ChannelFeatureConfig(
        feature: ChannelFeature.customFeature,
        name: '自定义',
        emoji: '✨',
        supportedModes: [InteractionMode.textMessage, InteractionMode.voiceMessage, InteractionMode.emojiSticker],
      ),
    ],
  );
}
