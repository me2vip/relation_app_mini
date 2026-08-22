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
            _configs[contactId] = jsonList
                .map((j) => ContactChannelConfig.fromJson(
                      Map<String, dynamic>.from(j as Map),
                    ))
                .toList();
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
      list.map((c) => c.toJson().toString()).toList(),
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

  Future<void> addConfig({
    required String contactId,
    required SocialPlatform platform,
    String? account,
    String? remark,
    List<ChannelFeature> enabledFeatures = const [],
    List<InteractionMode> preferredModes = const [],
    bool isPrimary = false,
  }) async {
    final now = DateTime.now();
    final config = ContactChannelConfig(
      id: _uuid.v4(),
      contactId: contactId,
      platform: platform,
      account: account,
      remark: remark,
      enabledFeatures: enabledFeatures,
      preferredModes: preferredModes,
      isPrimary: isPrimary,
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
    String? account,
    String? remark,
    List<ChannelFeature>? enabledFeatures,
    List<InteractionMode>? preferredModes,
    bool? isPrimary,
  }) async {
    final list = List<ContactChannelConfig>.from(_configs[contactId] ?? []);
    final index = list.indexWhere((c) => c.id == configId);
    if (index == -1) return;

    final updated = list[index].copyWith(
      account: account,
      remark: remark,
      enabledFeatures: enabledFeatures,
      preferredModes: preferredModes,
      isPrimary: isPrimary,
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
