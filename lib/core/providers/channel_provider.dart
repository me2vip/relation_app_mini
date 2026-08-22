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

  /// 全部途径（含父途径 + 子途径）
  List<SocialChannel> get channels => _channels;
  /// 仅根（父）途径
  List<SocialChannel> get parentChannels => _channels.where((c) => !c.isSubChannel).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 获取指定父途径下的全部子途径（空列表而非 null）
  List<SocialChannel> subChannelsOf(String parentId) =>
      _channels.where((c) => c.parentId == parentId).toList();

  /// 找一个途径的父途径；本身为根时返回自身
  SocialChannel? findParentOf(SocialChannel child) {
    if (!child.isSubChannel) return child;
    for (final c in _channels) {
      if (c.id == child.parentId) return c;
    }
    return null;
  }

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
        bool migrated = false;
        final now = DateTime.now();
        // 1. 迁移：旧渠道可能没有 platformKey，按名称回写并持久化
        for (int i = 0; i < _channels.length; i++) {
          final c = _channels[i];
          if ((c.platformKey == 'custom' || c.platformKey.isEmpty) && !c.isSubChannel) {
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
        // 2. 补齐缺失的默认父途径（用户升级后新加入的默认项）
        final addedIds = <String, String>{}; // platformKey -> 新建父途径id
        for (final def in defaultChannels) {
          final exists = _channels.any((c) => !c.isSubChannel && c.name == def['name']);
          if (!exists) {
            final id = _uuid.v4();
            final pKey = def['platformKey'] ?? 'custom';
            addedIds[pKey] = id;
            final ch = SocialChannel(
              id: id,
              name: def['name']!,
              icon: def['icon']!,
              isDefault: true,
              platformKey: pKey,
              createdAt: now,
              updatedAt: now,
            );
            await DatabaseService.saveChannel(ch);
          }
        }
        // 3. 为已有默认父途径补齐默认子类型（若该父途径尚无子途径）
        final parents = [...parentChannels];
        for (final parent in parents) {
          final subs = subChannelsOf(parent.id);
          if (subs.isNotEmpty) continue;
          final pKey = parent.platformKey;
          final defs = defaultSubChannels[pKey];
          if (defs == null || defs.isEmpty) continue;
          for (final s in defs) {
            final sub = SocialChannel(
              id: _uuid.v4(),
              name: s['name']!,
              icon: s['icon'] ?? '🔖',
              description: s['description'],
              isDefault: true,
              platformKey: pKey,
              parentId: parent.id,
              createdAt: now,
              updatedAt: now,
            );
            await DatabaseService.saveChannel(sub);
          }
        }
        _channels = await DatabaseService.getAllChannels();
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
    // 父途径 id 记录，用于随后创建子途径
    final platformKeyToId = <String, String>{};
    for (final entry in defaultChannels) {
      final id = _uuid.v4();
      if (entry['platformKey'] != null) {
        platformKeyToId[entry['platformKey']!] = id;
      }
      final channel = SocialChannel(
        id: id,
        name: entry['name']!,
        icon: entry['icon']!,
        isDefault: true,
        platformKey: entry['platformKey'] ?? 'custom',
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseService.saveChannel(channel);
    }
    // 为常见父途径插入默认子类型示例（如微信→私聊/朋友圈/微信群）
    defaultSubChannels.forEach((pKey, subs) async {
      final parentId = platformKeyToId[pKey];
      if (parentId == null) return;
      for (final s in subs) {
        final sub = SocialChannel(
          id: _uuid.v4(),
          name: s['name']!,
          icon: s['icon'] ?? '🔖',
          description: s['description'],
          isDefault: true,
          platformKey: pKey, // 子途径继承父的 platformKey 方便平台功能映射
          parentId: parentId,
          createdAt: now,
          updatedAt: now,
        );
        await DatabaseService.saveChannel(sub);
      }
    });
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

  /// 新增自定义途径（父 or 子）
  ///
  /// 不传 [parentId] = 新增父途径；传 [parentId] = 在该父途径下新增子途径。
  /// 新增子途径时自动继承父途径的 [platformKey]。
  Future<SocialChannel> addChannel({
    required String name,
    String icon = '🔗',
    String? description,
    String platformKey = 'custom',
    String? parentId,
  }) async {
    // 子途径继承父的 platformKey 保证平台功能映射一致
    String effectiveKey = platformKey;
    if (parentId != null && parentId.isNotEmpty) {
      final parent = getChannelById(parentId);
      if (parent != null) effectiveKey = parent.platformKey;
    }
    final now = DateTime.now();
    final channel = SocialChannel(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      description: description,
      isDefault: false,
      platformKey: effectiveKey,
      parentId: parentId,
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

  /// 在指定父途径下新增子途径（便捷方法）
  Future<SocialChannel> addSubChannel({
    required String parentId,
    required String name,
    String icon = '🔖',
    String? description,
  }) =>
      addChannel(
        name: name,
        icon: icon,
        description: description,
        parentId: parentId,
      );

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
  ///
  /// 删除父途径时级联删除内存+DB中的全部子途径。
  Future<void> deleteChannel(String channelId) async {
    final target = getChannelById(channelId);
    if (target == null) return;

    // 要删的 ids（级联：父途径 → 所有子途径）
    final idsToRemove = <String>{channelId};
    if (!target.isSubChannel) {
      idsToRemove.addAll(subChannelsOf(channelId).map((s) => s.id));
    }
    final snapshot = List<SocialChannel>.from(_channels);
    _channels.removeWhere((c) => idsToRemove.contains(c.id));
    notifyListeners();
    try {
      await DatabaseService.deleteChannel(channelId);
    } catch (e) {
      // 失败回滚：恢复快照
      _channels = snapshot;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
