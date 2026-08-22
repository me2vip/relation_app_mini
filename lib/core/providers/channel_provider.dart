import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/channel.dart';
import '../../services/storage_service.dart';

/// 社交途径管理
///
/// 管理联系渠道（微信/QQ/线下/抖音等）的增删改查，
/// 以及联系人与渠道的关联关系。
class ChannelProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<SocialChannel> _channels = [];
  Map<String, List<ContactChannelLink>> _contactLinks = {}; // contactId -> links
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
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseService.saveChannel(channel);
    }
    _channels = await DatabaseService.getAllChannels();
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
  }) async {
    final now = DateTime.now();
    final channel = SocialChannel(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      description: description,
      isDefault: false,
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

  /// 删除途径（同时删除关联）
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

  // ========== 联系人-途径关联 ==========

  /// 获取某联系人的所有关联
  List<ContactChannelLink> getLinksByContact(String contactId) {
    return _contactLinks[contactId] ?? [];
  }

  /// 加载某联系人的关联（缓存）
  Future<void> loadContactLinks(String contactId) async {
    try {
      final links = await DatabaseService.getContactChannelLinks(contactId);
      _contactLinks[contactId] = links;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 添加/更新联系人与途径的关联
  Future<void> saveContactLink({
    required String contactId,
    required String channelId,
    required String account,
    String? remark,
  }) async {
    final now = DateTime.now();
    final current = List<ContactChannelLink>.from(_contactLinks[contactId] ?? []);
    final existingIdx = current.indexWhere((l) => l.channelId == channelId);
    final original = existingIdx >= 0 ? current[existingIdx] : null;
    final link = ContactChannelLink(
      id: original?.id ?? _uuid.v4(),
      contactId: contactId,
      channelId: channelId,
      account: account,
      remark: remark,
      createdAt: original?.createdAt ?? now,
    );
    if (existingIdx >= 0) {
      current[existingIdx] = link;
    } else {
      current.add(link);
    }
    _contactLinks[contactId] = current;
    notifyListeners();
    try {
      await DatabaseService.saveContactChannelLink(link);
    } catch (e) {
      if (original != null && existingIdx >= 0) {
        current[existingIdx] = original;
      } else {
        current.removeWhere((l) => l.id == link.id);
      }
      _contactLinks[contactId] = current;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 删除联系人与途径的关联
  Future<void> removeContactLink(String linkId, String contactId) async {
    final current = List<ContactChannelLink>.from(_contactLinks[contactId] ?? []);
    final idx = current.indexWhere((l) => l.id == linkId);
    final removed = idx >= 0 ? current.removeAt(idx) : null;
    if (idx >= 0) {
      _contactLinks[contactId] = current;
      notifyListeners();
    }
    try {
      await DatabaseService.deleteContactChannelLink(linkId);
    } catch (e) {
      if (removed != null) {
        current.insert(idx, removed);
        _contactLinks[contactId] = current;
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
