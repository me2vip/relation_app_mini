import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/atmosphere.dart';
import '../../services/storage_service.dart';

class AtmosphereProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  
  List<AtmosphereProfile> _profiles = [];
  Map<String, ContactAtmosphereSetting> _contactSettings = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<AtmosphereProfile> get profiles => _profiles;
  Map<String, ContactAtmosphereSetting> get contactSettings => _contactSettings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AtmosphereProvider() {
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profiles = await DatabaseService.getAllAtmosphereProfiles();
      
      // 如果没有预设，创建默认配置
      if (_profiles.isEmpty) {
        await _createDefaultProfiles();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createDefaultProfiles() async {
    final now = DateTime.now();
    
    final defaultProfile = AtmosphereProfile(
      id: _uuid.v4(),
      name: '默认配置',
      description: '适用于一般社交关系',
      items: {
        '基本信息': [
          AtmosphereItem(id: _uuid.v4(), category: '基本信息', label: '姓名', value: '真实姓名', displayOrder: 1),
          AtmosphereItem(id: _uuid.v4(), category: '基本信息', label: '年龄', value: '年龄范围', displayOrder: 2),
          AtmosphereItem(id: _uuid.v4(), category: '基本信息', label: '职业', value: '职业身份', displayOrder: 3),
          AtmosphereItem(id: _uuid.v4(), category: '基本信息', label: '所在地', value: '城市地区', displayOrder: 4),
        ],
        '工作信息': [
          AtmosphereItem(id: _uuid.v4(), category: '工作信息', label: '公司', value: '工作单位', displayOrder: 1),
          AtmosphereItem(id: _uuid.v4(), category: '工作信息', label: '职位', value: '职位级别', displayOrder: 2),
          AtmosphereItem(id: _uuid.v4(), category: '工作信息', label: '收入', value: '收入水平', displayOrder: 3),
        ],
        '财务信息': [
          AtmosphereItem(id: _uuid.v4(), category: '财务信息', label: '存款', value: '存款情况', displayOrder: 1),
          AtmosphereItem(id: _uuid.v4(), category: '财务信息', label: '房产', value: '房产情况', displayOrder: 2),
          AtmosphereItem(id: _uuid.v4(), category: '财务信息', label: '车辆', value: '车辆情况', displayOrder: 3),
        ],
        '社交关系': [
          AtmosphereItem(id: _uuid.v4(), category: '社交关系', label: '家庭', value: '家庭状况', displayOrder: 1),
          AtmosphereItem(id: _uuid.v4(), category: '社交关系', label: '恋爱', value: '感情状态', displayOrder: 2),
          AtmosphereItem(id: _uuid.v4(), category: '社交关系', label: '朋友圈', value: '社交圈子', displayOrder: 3),
        ],
        '兴趣爱好': [
          AtmosphereItem(id: _uuid.v4(), category: '兴趣爱好', label: '爱好', value: '兴趣爱好', displayOrder: 1),
          AtmosphereItem(id: _uuid.v4(), category: '兴趣爱好', label: '娱乐', value: '娱乐方式', displayOrder: 2),
        ],
        '生活习惯': [
          AtmosphereItem(id: _uuid.v4(), category: '生活习惯', label: '作息', value: '作息时间', displayOrder: 1),
          AtmosphereItem(id: _uuid.v4(), category: '生活习惯', label: '消费', value: '消费习惯', displayOrder: 2),
        ],
        '情感状态': [
          AtmosphereItem(id: _uuid.v4(), category: '情感状态', label: '心情', value: '当前心情', displayOrder: 1),
          AtmosphereItem(id: _uuid.v4(), category: '情感状态', label: '压力', value: '压力状况', displayOrder: 2),
        ],
        '其他': [
          AtmosphereItem(id: _uuid.v4(), category: '其他', label: '其他信息', value: '其他敏感信息', displayOrder: 1),
        ],
      },
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.saveAtmosphereProfile(defaultProfile);
    _profiles = [defaultProfile];
  }

  Future<void> addProfile(AtmosphereProfile profile) async {
    try {
      await DatabaseService.saveAtmosphereProfile(profile);
      await loadProfiles();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfile(AtmosphereProfile profile) async {
    try {
      final updated = profile.copyWith(updatedAt: DateTime.now());
      await DatabaseService.saveAtmosphereProfile(updated);
      await loadProfiles();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProfile(String profileId) async {
    try {
      _profiles.removeWhere((p) => p.id == profileId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> setContactAtmosphere(ContactAtmosphereSetting setting) async {
    try {
      await DatabaseService.saveContactAtmosphere(setting);
      _contactSettings[setting.contactId] = setting;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<ContactAtmosphereSetting?> getContactAtmosphere(String contactId) async {
    try {
      final setting = await DatabaseService.getContactAtmosphere(contactId);
      if (setting != null) {
        _contactSettings[contactId] = setting;
      }
      return setting;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  AtmosphereProfile? getProfileById(String profileId) {
    try {
      return _profiles.firstWhere((p) => p.id == profileId);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  AtmosphereProfile createEmptyProfile() {
    return AtmosphereProfile.empty(
      id: _uuid.v4(),
      name: '',
    );
  }

  ContactAtmosphereSetting createEmptySetting({
    required String contactId,
    required String profileId,
  }) {
    return ContactAtmosphereSetting(
      id: _uuid.v4(),
      contactId: contactId,
      profileId: profileId,
      exposedFields: [],
      hiddenFields: [],
    );
  }
}
