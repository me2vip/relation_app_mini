import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/social_channel_config.dart';

class ChannelConfigProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  static const String _configsKey = 'channel_config_';

  final Map<String, List<ContactChannelConfig>> _configs = {};
  final Map<String, List<ContactChannelConfig>> _deletedConfigs = {};
  bool _loaded = false;

  List<ContactChannelConfig> getConfigsForContact(String contactId) {
    if (!_loaded) _loadAll();
    return List.unmodifiable(_configs[contactId] ?? []);
  }

  Map<String, dynamic>? _parseConfigString(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {}
    // 兼容旧的 {id: xx, contactId: yy, ...} .toString() 格式
    try {
      s = s.trim();
      if (s.startsWith('{') && s.endsWith('}')) {
        final inner = s.substring(1, s.length - 1);
        final out = <String, dynamic>{};
        // 简单匹配 key: value 对，支持字符串和整数/列表
        final re = RegExp(r'(\w+):\s*(.*?)(?=,\s*\w+:|$)');
        final matches = re.allMatches(inner);
        for (final m in matches) {
          final key = m.group(1)!;
          String val = m.group(2)!.trim();
          // list -> parse indices
          if (val.startsWith('[') && val.endsWith(']')) {
            final items = val.substring(1, val.length - 1).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            if (items.isEmpty) {
              out[key] = <int>[];
            } else {
              out[key] = items.map((e) {
                final n = int.tryParse(e);
                return n ?? 0;
              }).toList();
            }
          } else if (val == 'null' || val.isEmpty) {
            out[key] = null;
          } else if (val == 'true') {
            out[key] = true;
          } else if (val == 'false') {
            out[key] = false;
          } else {
            // int？
            final n = int.tryParse(val);
            if (n != null) {
              out[key] = n;
            } else {
              out[key] = val;
            }
          }
        }
        if (out.isNotEmpty && out.containsKey('id') && out.containsKey('contactId')) {
          return out;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadAll() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_configsKey)) {
          final contactId = key.substring(_configsKey.length);
          final jsonList = prefs.getStringList(key);
          if (jsonList != null) {
            final parsed = <ContactChannelConfig>[];
            for (final j in jsonList) {
              final map = _parseConfigString(j);
              if (map != null) {
                try {
                  parsed.add(ContactChannelConfig.fromJson(map));
                } catch (_) {}
              }
            }
            _configs[contactId] = parsed;
          }
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist(String contactId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _configs[contactId] ?? [];
    await prefs.setStringList(
      '$_configsKey$contactId',
      list.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<void> _clearPersisted(String contactId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_configsKey$contactId');
  }

  ContactChannelConfig? getConfig(String contactId, String configId) {
    final list = _configs[contactId] ?? [];
    try {
      return list.firstWhere((c) => c.id == configId);
    } catch (_) {
      return null;
    }
  }

  /// 统计指定 channelId 被多少个联系人使用
  int contactCountByChannelId(String channelId) {
    if (!_loaded) _loadAll();
    if (channelId.isEmpty) return 0;
    int cnt = 0;
    for (final entry in _configs.entries) {
      for (final c in entry.value) {
        if (c.channelId == channelId) cnt++;
      }
    }
    return cnt;
  }

  /// 统计指定 SocialPlatform 被多少个联系人使用（含 channelId 空值兜底匹配）
  int contactCountByPlatform(SocialPlatform platform, {String? channelName}) {
    if (!_loaded) _loadAll();
    final counts = <String>{};
    for (final entry in _configs.entries) {
      for (final c in entry.value) {
        final match1 = c.platform == platform;
        // 兜底：按名称与 platform 名称映射比较
        bool match2 = false;
        if (!match1 && channelName != null) {
          switch (channelName) {
            case '微信': match2 = c.platform == SocialPlatform.wechat; break;
            case 'QQ': match2 = c.platform == SocialPlatform.qq; break;
            case '抖音': match2 = c.platform == SocialPlatform.douyin; break;
            case '快手': match2 = c.platform == SocialPlatform.kuaishou; break;
            case '小红书': match2 = c.platform == SocialPlatform.xiaohongshu; break;
            case '微博': match2 = c.platform == SocialPlatform.weibo; break;
            case 'B站': match2 = c.platform == SocialPlatform.bilibili; break;
            case '王者荣耀': match2 = c.platform == SocialPlatform.wangzhe; break;
            case '和平精英': match2 = c.platform == SocialPlatform.pubg; break;
            case '线下': match2 = c.platform == SocialPlatform.offline; break;
            case '电话': match2 = c.platform == SocialPlatform.phone; break;
            case '短信': match2 = c.platform == SocialPlatform.sms; break;
          }
        }
        if (match1 || match2) counts.add(entry.key);
      }
    }
    return counts.length;
  }

  /// 统计该 channelId + platform 被多少个联系人使用（双重匹配，考虑旧配置无 channelId 场景）
  int contactCountForChannel(String channelId, SocialPlatform platform, String channelName) {
    final byId = contactCountByChannelId(channelId);
    if (byId > 0) return byId;
    return contactCountByPlatform(platform, channelName: channelName);
  }

  /// 统计指定 subChannelId 被多少个联系人使用（精确匹配）
  int contactCountBySubChannelId(String? subChannelId) {
    if (!_loaded) _loadAll();
    if (subChannelId == null || subChannelId.isEmpty) return 0;
    int cnt = 0;
    for (final entry in _configs.entries) {
      for (final c in entry.value) {
        if (c.subChannelId == subChannelId) cnt++;
      }
    }
    return cnt;
  }

  Future<void> addConfig({
    required String contactId,
    String channelId = '',
    required SocialPlatform platform,
    String? account,
    String? remark,
    List<ChannelFeature> enabledFeatures = const [],
    List<InteractionMode> preferredModes = const [],
    bool isPrimary = false,
    String? subChannelId,
    String? subChannelName,
  }) async {
    final now = DateTime.now();
    final config = ContactChannelConfig(
      id: _uuid.v4(),
      contactId: contactId,
      channelId: channelId,
      platform: platform,
      account: account,
      remark: remark,
      enabledFeatures: enabledFeatures,
      preferredModes: preferredModes,
      isPrimary: isPrimary,
      subChannelId: subChannelId,
      subChannelName: subChannelName,
      createdAt: now,
      updatedAt: now,
    );
    final list = List<ContactChannelConfig>.from(_configs[contactId] ?? []);
    list.add(config);
    _configs[contactId] = list;
    notifyListeners();
    _persist(contactId);
  }

  Future<void> updateConfig({
    required String contactId,
    required String configId,
    String? channelId,
    String? account,
    String? remark,
    List<ChannelFeature>? enabledFeatures,
    List<InteractionMode>? preferredModes,
    bool? isPrimary,
    String? subChannelId,
    bool resetSubChannelId = false,
    String? subChannelName,
    bool resetSubChannelName = false,
  }) async {
    final list = List<ContactChannelConfig>.from(_configs[contactId] ?? []);
    final index = list.indexWhere((c) => c.id == configId);
    if (index == -1) return;

    final updated = list[index].copyWith(
      channelId: channelId,
      account: account,
      remark: remark,
      enabledFeatures: enabledFeatures,
      preferredModes: preferredModes,
      isPrimary: isPrimary,
      subChannelId: subChannelId,
      resetSubChannelId: resetSubChannelId,
      subChannelName: subChannelName,
      resetSubChannelName: resetSubChannelName,
      updatedAt: DateTime.now(),
    );
    list[index] = updated;
    _configs[contactId] = list;
    notifyListeners();
    _persist(contactId);
  }

  Future<void> removeConfig(String contactId, String configId) async {
    final list = List<ContactChannelConfig>.from(_configs[contactId] ?? []);
    final i = list.indexWhere((c) => c.id == configId);
    if (i < 0) return;
    final config = list[i];
    _deletedConfigs.putIfAbsent(contactId, () => []).add(config);
    list.removeAt(i);
    _configs[contactId] = list;
    notifyListeners();
    _persist(contactId);
  }

  Future<void> setEnabledFeatures({
    required String contactId,
    required String configId,
    required List<ChannelFeature> features,
  }) async {
    await updateConfig(
      contactId: contactId,
      configId: configId,
      enabledFeatures: features,
    );
  }

  Future<void> setPreferredModes({
    required String contactId,
    required String configId,
    required List<InteractionMode> modes,
  }) async {
    await updateConfig(
      contactId: contactId,
      configId: configId,
      preferredModes: modes,
    );
  }

  List<SocialPlatform> getAvailablePlatforms(String contactId) {
    final configs = _configs[contactId] ?? [];
    return configs.map((c) => c.platform).toList();
  }

  List<ChannelFeature> getAllEnabledFeatures(String contactId) {
    final configs = _configs[contactId] ?? [];
    final features = <ChannelFeature>{};
    for (final c in configs) {
      features.addAll(c.enabledFeatures);
    }
    return features.toList();
  }

  List<InteractionMode> getAllPreferredModes(String contactId) {
    final configs = _configs[contactId] ?? [];
    final modes = <InteractionMode>{};
    for (final c in configs) {
      modes.addAll(c.preferredModes);
    }
    if (modes.isEmpty) {
      return const [InteractionMode.textMessage];
    }
    return modes.toList();
  }

  void clearCacheForContact(String contactId) {
    _configs.remove(contactId);
    _clearPersisted(contactId);
  }
}
