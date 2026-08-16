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

  Future<void> updateContactLevel(String contactId, ContactLevel newLevel) async {
    final contact = _contacts.firstWhere((c) => c.id == contactId);
    final updated = contact.copyWith(level: newLevel, updatedAt: DateTime.now());
    await updateContact(updated);
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
