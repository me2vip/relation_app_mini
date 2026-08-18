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
    try {
      await DatabaseService.saveChannel(channel);
      _channels = await DatabaseService.getAllChannels();
      notifyListeners();
      return channel;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 更新途径（改名/换图标）
  Future<void> updateChannel(SocialChannel channel) async {
    try {
      await DatabaseService.saveChannel(
        channel.copyWith(updatedAt: DateTime.now()),
      );
      _channels = await DatabaseService.getAllChannels();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 删除途径（同时删除关联）
  Future<void> deleteChannel(String channelId) async {
    try {
      await DatabaseService.deleteChannel(channelId);
      _channels = await DatabaseService.getAllChannels();
      notifyListeners();
    } catch (e) {
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
    final existing = getLinksByContact(contactId)
        .where((l) => l.channelId == channelId)
        .toList();
    final link = ContactChannelLink(
      id: existing.isNotEmpty ? existing.first.id : _uuid.v4(),
      contactId: contactId,
      channelId: channelId,
      account: account,
      remark: remark,
      createdAt: existing.isNotEmpty ? existing.first.createdAt : now,
    );
    try {
      await DatabaseService.saveContactChannelLink(link);
      await loadContactLinks(contactId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 删除联系人与途径的关联
  Future<void> removeContactLink(String linkId, String contactId) async {
    try {
      await DatabaseService.deleteContactChannelLink(linkId);
      await loadContactLinks(contactId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
