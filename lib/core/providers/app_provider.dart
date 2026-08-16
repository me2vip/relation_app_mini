import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_update_service.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _hasUpdate = false;
  GithubReleaseInfo? _latestRelease;
  String _currentVersion = '1.0.0';
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get hasUpdate => _hasUpdate;
  GithubReleaseInfo? get latestRelease => _latestRelease;
  String get currentVersion => _currentVersion;
  String? get errorMessage => _errorMessage;

  AppProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 获取当前版本
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      // 检查更新
      await checkForUpdate();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkForUpdate() async {
    try {
      final outcome = await AppUpdateService.checkForUpdate();
      if (outcome.result == UpdateCheckResult.hasUpdate) {
        _hasUpdate = true;
        _latestRelease = outcome.releaseInfo;
      } else {
        _hasUpdate = false;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearError() async {
    _errorMessage = null;
    notifyListeners();
  }
}
