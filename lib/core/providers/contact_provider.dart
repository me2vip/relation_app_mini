import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/contact.dart';
import '../../services/storage_service.dart';

class ContactProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  
  List<Contact> _contacts = [];
  Contact? _selectedContact;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Contact> get contacts => _contacts;
  Contact? get selectedContact => _selectedContact;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 按分层筛选
  List<Contact> getContactsByLevel(ContactLevel level) {
    return _contacts.where((c) => c.level == level).toList();
  }

  // 按标签筛选
  List<Contact> getContactsByTag(String tag) {
    return _contacts.where((c) => c.tags.contains(tag)).toList();
  }

  // 获取所有标签
  List<String> get allTags {
    final tags = <String>{};
    for (final contact in _contacts) {
      tags.addAll(contact.tags);
    }
    return tags.toList()..sort();
  }

  // 获取分层统计
  Map<ContactLevel, int> get levelStats {
    final stats = <ContactLevel, int>{};
    for (final level in ContactLevel.values) {
      stats[level] = _contacts.where((c) => c.level == level).length;
    }
    return stats;
  }

  ContactProvider() {
    loadContacts();
  }

  Future<void> loadContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contacts = await DatabaseService.getAllContacts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContact(Contact contact) async {
    try {
      await DatabaseService.saveContact(contact);
      // 记录初始关系层级（关系跟踪起点）
      final initial = RelationshipChange(
        id: _uuid.v4(),
        contactId: contact.id,
        fromLevel: contact.level,
        toLevel: contact.level,
        type: RelationshipChangeType.initial,
        reason: '创建联系人',
        changedAt: DateTime.now(),
      );
      await DatabaseService.saveRelationshipChange(initial);
      await loadContacts();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateContact(Contact contact) async {
    try {
      final updated = contact.copyWith(updatedAt: DateTime.now());
      await DatabaseService.saveContact(updated);
      
      // 更新联系方式
      for (final method in contact.methods) {
        await DatabaseService.saveContactMethod(method);
      }
      
      await loadContacts();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      await DatabaseService.deleteContact(id);
      if (_selectedContact?.id == id) {
        _selectedContact = null;
      }
      await loadContacts();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void selectContact(Contact? contact) {
    _selectedContact = contact;
    notifyListeners();
  }

  Future<void> addInteraction(String contactId, Interaction interaction) async {
    try {
      await DatabaseService.saveInteraction(interaction);
      await loadContacts();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 调整联系人层级并记录变化（跟踪关系升迁）
  Future<void> changeContactLevel(String contactId, ContactLevel newLevel, String reason, {RelationshipChangeType type = RelationshipChangeType.manual}) async {
    final contact = _contacts.firstWhere((c) => c.id == contactId);
    if (contact.level == newLevel) return;
    final change = RelationshipChange(
      id: _uuid.v4(),
      contactId: contactId,
      fromLevel: contact.level,
      toLevel: newLevel,
      type: type,
      reason: reason.isEmpty ? '调整关系层级' : reason,
      changedAt: DateTime.now(),
    );
    await DatabaseService.saveRelationshipChange(change);
    await updateContact(contact.copyWith(level: newLevel));
  }

  Future<void> updateContactLevel(String contactId, ContactLevel newLevel) async {
    await changeContactLevel(contactId, newLevel, '', type: RelationshipChangeType.manual);
  }

  /// 获取联系人关系升迁时间线（按时间倒序）
  Future<List<RelationshipChange>> getRelationshipTimeline(String contactId) async {
    try {
      return await DatabaseService.getRelationshipChanges(contactId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> updateContactTags(String contactId, List<String> tags) async {
    final contact = _contacts.firstWhere((c) => c.id == contactId);
    final updated = contact.copyWith(tags: tags, updatedAt: DateTime.now());
    await updateContact(updated);
  }

  Future<void> updateContactGoal(String contactId, String? goalRelation) async {
    final contact = _contacts.firstWhere((c) => c.id == contactId);
    final updated = contact.copyWith(goalRelation: goalRelation, updatedAt: DateTime.now());
    await updateContact(updated);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Contact createEmptyContact() {
    final now = DateTime.now();
    return Contact(
      id: _uuid.v4(),
      name: '',
      level: ContactLevel.normal,
      methods: [],
      tags: [],
      createdAt: now,
      updatedAt: now,
    );
  }
}
