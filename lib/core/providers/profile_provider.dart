import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_profile.dart';
import '../../models/task.dart';

class ProfileProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  static const String _profileKey = 'user_profile';
  static const String _changeLogsKey = 'profile_change_logs';

  UserProfile? _profile;
  List<ProfileChangeLog> _changeLogs = [];
  bool _isLoading = false;

  UserProfile? get profile => _profile;
  List<ProfileChangeLog> get changeLogs => _changeLogs;
  bool get isLoading => _isLoading;

  ProfileProvider() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);

      if (profileJson != null) {
        _profile = UserProfile.fromJson(
          Map<String, dynamic>.from(
            Map<String, dynamic>.from(
              profileJson as Map<String, dynamic>,
            ),
          ),
        );
      } else {
        _profile = UserProfile.createDefault();
        await _saveProfile();
      }

      final logsJson = prefs.getStringList(_changeLogsKey);
      if (logsJson != null) {
        _changeLogs = logsJson
            .map((j) => ProfileChangeLog.fromJson(
                  Map<String, dynamic>.from(
                    Map<String, dynamic>.from(
                      j as Map<String, dynamic>,
                    ),
                  ),
                ))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, _profile!.toJson().toString());
  }

  Future<void> _saveChangeLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _changeLogsKey,
      _changeLogs.map((l) => l.toJson().toString()).toList(),
    );
  }

  Future<void> _addLog({
    required String fieldName,
    required String oldValue,
    required String newValue,
    required String reason,
  }) async {
    if (oldValue == newValue) return;
    _changeLogs.insert(
      0,
      ProfileChangeLog(
        id: _uuid.v4(),
        fieldName: fieldName,
        oldValue: oldValue,
        newValue: newValue,
        reason: reason,
        changedAt: DateTime.now(),
      ),
    );
    if (_changeLogs.length > 100) {
      _changeLogs = _changeLogs.sublist(0, 100);
    }
    await _saveChangeLogs();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? avatar,
    List<String>? personalityTraits,
    String? communicationStyle,
    int? opennessToTexting,
    int? opennessToCalling,
    int? opennessToMeeting,
    int? socialEnergy,
    List<String>? statusTags,
    String? relationshipGoal,
  }) async {
    if (_profile == null) return;

    final oldProfile = _profile!;
    _profile = _profile!.copyWith(
      name: name,
      avatar: avatar,
      personalityTraits: personalityTraits,
      communicationStyle: communicationStyle,
      opennessToTexting: opennessToTexting,
      opennessToCalling: opennessToCalling,
      opennessToMeeting: opennessToMeeting,
      socialEnergy: socialEnergy,
      statusTags: statusTags,
      relationshipGoal: relationshipGoal,
      updatedAt: DateTime.now(),
    );

    if (personalityTraits != null) {
      await _addLog(
        fieldName: '性格特征',
        oldValue: oldProfile.personalityTraits.join(','),
        newValue: personalityTraits.join(','),
        reason: '手动修改',
      );
    }
    if (communicationStyle != null && communicationStyle != oldProfile.communicationStyle) {
      await _addLog(
        fieldName: '沟通风格',
        oldValue: oldProfile.communicationStyle,
        newValue: communicationStyle,
        reason: '手动修改',
      );
    }
    if (statusTags != null) {
      await _addLog(
        fieldName: '状态标签',
        oldValue: oldProfile.statusTags.join(','),
        newValue: statusTags.join(','),
        reason: '手动修改',
      );
    }

    await _saveProfile();
    notifyListeners();
  }

  /// 根据任务执行情况自动更新画像
  Future<void> updateProfileFromTask({
    required bool completed,
    TaskType? taskType,
    String? reason,
  }) async {
    if (_profile == null) return;

    final oldProfile = _profile!;
    final changes = <String>[];

    var updated = _profile!.copyWith(updatedAt: DateTime.now());

    // 任务完成 → 增加社交能量
    if (completed) {
      final newEnergy = (updated.socialEnergy + 3).clamp(0, 100);
      if (newEnergy != updated.socialEnergy) {
        updated = updated.copyWith(socialEnergy: newEnergy);
        changes.add('社交能量: ${updated.socialEnergy} → $newEnergy');
      }

      final completedCount = updated.totalTasksCompleted + 1;
      updated = updated.copyWith(totalTasksCompleted: completedCount);

      // 根据任务类型更新沟通意愿
      if (taskType == TaskType.sendMessage) {
        final newVal = (updated.opennessToTexting + 1).clamp(1, 5);
        if (newVal != updated.opennessToTexting) {
          updated = updated.copyWith(opennessToTexting: newVal);
          changes.add('发短信意愿: ${updated.opennessToTexting} → $newVal');
        }
      } else if (taskType == TaskType.phoneCall) {
        final newVal = (updated.opennessToCalling + 1).clamp(1, 5);
        if (newVal != updated.opennessToCalling) {
          updated = updated.copyWith(opennessToCalling: newVal);
          changes.add('打电话意愿: ${updated.opennessToCalling} → $newVal');
        }
      }

      // 社交能量达到阈值时，自动调整性格标签
      if (updated.socialEnergy >= 70 &&
          updated.personalityTraits.contains('社恐') &&
          updated.personalityTraits.contains('内向')) {
        final newTraits = List<String>.from(updated.personalityTraits);
        newTraits.remove('社恐');
        if (!newTraits.contains('外向')) newTraits.add('外向');
        updated = updated.copyWith(personalityTraits: newTraits);
        changes.add('性格标签: 移除社恐，加入外向');
        await _addLog(
          fieldName: '性格特征',
          oldValue: oldProfile.personalityTraits.join(','),
          newValue: newTraits.join(','),
          reason: '社交能量提升自动调整',
        );
      }
    }

    _profile = updated;
    await _saveProfile();

    if (changes.isNotEmpty) {
      debugPrint('画像自动更新: ${changes.join('; ')}');
    }
    notifyListeners();
  }

  Future<void> incrementInteractions() async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      totalInteractions: _profile!.totalInteractions + 1,
      updatedAt: DateTime.now(),
    );
    await _saveProfile();
    notifyListeners();
  }

  Future<void> clearChangeLogs() async {
    _changeLogs.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_changeLogsKey);
    notifyListeners();
  }

  List<ProfileChangeLog> getRecentLogs({int limit = 10}) {
    return _changeLogs.take(limit).toList();
  }

  List<ProfileChangeLog> getLogsForField(String fieldName) {
    return _changeLogs.where((l) => l.fieldName == fieldName).toList();
  }
}
