import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/channel.dart';
import '../../services/storage_service.dart';

/// 社交途径管理
///
/// 管理联系渠道（微信/QQ/线下/抖音等）的增删改查。
/// 联系人与渠道的关联统一通过 [ChannelConfigProvider] 使用
/// ContactChannelConfig（含 channelId）进行管理。
class ChannelProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<SocialChannel> _channels = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SocialChannel> get channels => _channels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ChannelProvider() {
    loadAll();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _channels = await DatabaseService.getAllChannels();
      if (_channels.isEmpty) {
        await _createDefaultChannels();
      } else {
        // 迁移：旧渠道可能没有 platformKey（均为 'custom'），按名称回写并持久化一次
        bool migrated = false;
        final now = DateTime.now();
        for (int i = 0; i < _channels.length; i++) {
          final c = _channels[i];
          if (c.platformKey == 'custom' || c.platformKey.isEmpty) {
            final defaults = defaultChannels;
            final match = defaults.firstWhere(
              (d) => d['name'] == c.name,
              orElse: () => const {},
            );
            if (match.containsKey('platformKey')) {
              _channels[i] = c.copyWith(platformKey: match['platformKey'], updatedAt: now);
              await DatabaseService.saveChannel(_channels[i]);
              migrated = true;
            }
          }
        }
        if (migrated) {
          _channels = await DatabaseService.getAllChannels();
        }
        // 补齐缺失的默认渠道（若用户升级后有新增默认项）
        for (final def in defaultChannels) {
          final exists = _channels.any((c) => c.name == def['name']);
          if (!exists) {
            final ch = SocialChannel(
              id: _uuid.v4(),
              name: def['name']!,
              icon: def['icon']!,
              isDefault: true,
              platformKey: def['platformKey'] ?? 'custom',
              createdAt: now,
              updatedAt: now,
            );
            await DatabaseService.saveChannel(ch);
          }
        }
        if (_channels.length != defaultChannels.length) {
          _channels = await DatabaseService.getAllChannels();
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createDefaultChannels() async {
    final now = DateTime.now();
    for (final entry in defaultChannels) {
      final channel = SocialChannel(
        id: _uuid.v4(),
        name: entry['name']!,
        icon: entry['icon']!,
        isDefault: true,
        platformKey: entry['platformKey'] ?? 'custom',
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseService.saveChannel(channel);
    }
    _channels = await DatabaseService.getAllChannels();
  }

  /// 基于名称查找已存在的渠道；找不到返回 null（用于新建默认缺失项）
  SocialChannel? findByName(String name) {
    for (final c in _channels) {
      if (c.name == name) return c;
    }
    return null;
  }

  /// 基于 platformKey 查找已存在的渠道
  SocialChannel? findByPlatformKey(String key) {
    for (final c in _channels) {
      if (c.platformKey == key) return c;
    }
    return null;
  }

  SocialChannel? getChannelById(String id) {
    try {
      return _channels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 新增自定义途径
  Future<SocialChannel> addChannel({
    required String name,
    String icon = '🔗',
    String? description,
    String platformKey = 'custom',
  }) async {
    final now = DateTime.now();
    final channel = SocialChannel(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      description: description,
      isDefault: false,
      platformKey: platformKey,
      createdAt: now,
      updatedAt: now,
    );
    _channels.add(channel);
    notifyListeners();
    try {
      await DatabaseService.saveChannel(channel);
      return channel;
    } catch (e) {
      _channels.removeWhere((c) => c.id == channel.id);
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 更新途径（改名/换图标）
  Future<void> updateChannel(SocialChannel channel) async {
    final idx = _channels.indexWhere((c) => c.id == channel.id);
    final original = idx >= 0 ? _channels[idx] : null;
    final updated = channel.copyWith(updatedAt: DateTime.now());
    if (idx >= 0) {
      _channels[idx] = updated;
      notifyListeners();
    }
    try {
      await DatabaseService.saveChannel(updated);
    } catch (e) {
      if (original != null && idx >= 0) _channels[idx] = original;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 删除途径
  Future<void> deleteChannel(String channelId) async {
    final idx = _channels.indexWhere((c) => c.id == channelId);
    final removed = idx >= 0 ? _channels.removeAt(idx) : null;
    if (idx >= 0) notifyListeners();
    try {
      await DatabaseService.deleteChannel(channelId);
    } catch (e) {
      if (removed != null) {
        _channels.insert(idx, removed);
        notifyListeners();
      }
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
