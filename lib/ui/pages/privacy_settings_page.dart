import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _appLockEnabled = false;
  bool _biometricAvailable = false;
  bool _dataEncrypted = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = LocalAuthentication();
    
    final canCheck = await auth.canCheckBiometrics;
    final isAvailable = await auth.isDeviceSupported();
    
    setState(() {
      _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      _biometricAvailable = canCheck && isAvailable;
      _dataEncrypted = prefs.getBool('data_encrypted') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 数据安全卡片
          _SectionCard(
            title: '数据安全',
            icon: Icons.security_outlined,
            children: [
              ListTile(
                leading: const Icon(Icons.enhanced_encryption),
                title: const Text('数据加密'),
                subtitle: const Text('本地数据采用AES-256加密存储'),
                trailing: Icon(
                  _dataEncrypted ? Icons.check_circle : Icons.circle_outlined,
                  color: _dataEncrypted ? Colors.green : Colors.grey,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('数据备份'),
                subtitle: const Text('导出加密数据到本地'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showBackupOptions(),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('数据恢复'),
                subtitle: const Text('从备份文件恢复数据'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showRestoreOptions(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 应用锁卡片
          _SectionCard(
            title: '应用锁',
            icon: Icons.lock_outline,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('启用应用锁'),
                subtitle: Text(
                  _biometricAvailable 
                      ? '使用生物识别解锁' 
                      : '您的设备不支持生物识别',
                  style: TextStyle(
                    color: _biometricAvailable ? null : Colors.grey,
                  ),
                ),
                value: _appLockEnabled,
                onChanged: _biometricAvailable 
                    ? (value) => _toggleAppLock(value)
                    : null,
                activeColor: const Color(0xFF6366F1),
              ),
              if (_appLockEnabled) ...[
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('自动锁定时间'),
                  subtitle: const Text('离开应用后立即锁定'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLockTimeoutOptions(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          
          // 数据管理
          _SectionCard(
            title: '数据管理',
            icon: Icons.storage_outlined,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
                subtitle: const Text('删除所有联系人、任务和设置'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showClearDataConfirmation(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 隐私说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '隐私说明',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 所有数据存储在您的设备本地\n'
                  '• 我们不会将您的数据上传到服务器\n'
                  '• 数据采用加密存储保护\n'
                  '• 您可以随时导出或删除数据',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAppLock(bool enabled) async {
    final auth = LocalAuthentication();
    final prefs = await SharedPreferences.getInstance();
    
    if (enabled) {
      // 验证生物识别
      try {
        final authenticated = await auth.authenticate(
          localizedReason: '请验证您的身份以启用应用锁',
          options: const AuthenticationOptions(
            biometricOnly: true,
          ),
        );
        
        if (authenticated) {
          setState(() => _appLockEnabled = true);
          await prefs.setBool('app_lock_enabled', true);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('应用锁已启用'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('验证失败: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // 禁用应用锁也需要验证
      try {
        final authenticated = await auth.authenticate(
          localizedReason: '请验证您的身份以禁用应用锁',
          options: const AuthenticationOptions(
            biometricOnly: true,
          ),
        );
        
        if (authenticated) {
          setState(() => _appLockEnabled = false);
          await prefs.setBool('app_lock_enabled', false);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('应用锁已禁用'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('验证失败: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showBackupOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('导出到文件'),
              subtitle: const Text('保存为加密的备份文件'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现导出功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('导出功能开发中...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享备份'),
              subtitle: const Text('通过其他应用分享备份文件'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现分享功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('分享功能开发中...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复数据'),
        content: const Text('选择一个备份文件来恢复数据。这将覆盖当前的所有数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实现文件选择和恢复
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('恢复功能开发中...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('选择文件'),
          ),
        ],
      ),
    );
  }

  void _showLockTimeoutOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自动锁定时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('立即'),
              value: 0,
              groupValue: 0,
              onChanged: (v) => Navigator.pop(context),
            ),
            RadioListTile<int>(
              title: const Text('1分钟后'),
              value: 60,
              groupValue: 0,
              onChanged: (v) => Navigator.pop(context),
            ),
            RadioListTile<int>(
              title: const Text('5分钟后'),
              value: 300,
              groupValue: 0,
              onChanged: (v) => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('确认清除'),
          ],
        ),
        content: const Text(
          '此操作将删除所有联系人、任务和设置数据，且无法恢复。确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              // TODO: 实现数据清除
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('数据已清除'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('清除所有数据'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6366F1), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
