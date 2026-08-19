import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/storage_service.dart';
import '../../core/providers/app_provider.dart';
import '../../models/contact.dart';
import '../../models/contact_group.dart';
import '../../models/persona.dart';
import '../../models/task.dart';
import '../../models/dynamic_post.dart';
import '../../models/temp_material.dart';
import '../../models/channel.dart';
import '../../models/ai_config.dart';

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
              onTap: () async {
                Navigator.pop(context);
                await _exportToFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享备份'),
              subtitle: const Text('通过其他应用分享备份文件'),
              onTap: () async {
                Navigator.pop(context);
                await _shareBackup();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToFile() async {
    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 收集所有数据
      final backupData = await _collectBackupData();
      
      // 生成备份文件名
      final now = DateTime.now();
      final fileName = 'relation_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';
      
      // 让用户选择保存位置
      String? outputPath = await FilePicker.platform.getDirectoryPath();
      
      if (outputPath == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      
      final file = File('$outputPath/$fileName');
      await file.writeAsString(jsonEncode(backupData));
      
      if (mounted) {
        Navigator.pop(context); // 关闭加载指示器
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份已保存到: $fileName'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '打开',
              onPressed: () => _openFileLocation(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareBackup() async {
    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 收集所有数据
      final backupData = await _collectBackupData();
      
      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName = 'relation_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonEncode(backupData));
      
      if (mounted) {
        Navigator.pop(context); // 关闭加载指示器
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: '社交塔子数据备份',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _collectBackupData() async {
    final contacts = await DatabaseService.getAllContacts();
    final groups = await DatabaseService.getAllContactGroups();
    final personas = await DatabaseService.getAllPersonas();
    final tasks = await DatabaseService.getAllTasks();
    final posts = await DatabaseService.getAllDynamicPosts();
    final materials = await DatabaseService.getAllTempMaterials();
    final channels = await DatabaseService.getAllChannels();
    final aiModels = await DatabaseService.getAllAIModels();
    
    final prefs = await SharedPreferences.getInstance();
    final settings = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith('_internal_')) {
        settings[key] = prefs.get(key);
      }
    }
    
    return {
      'version': '1.5.3',
      'backupTime': DateTime.now().toIso8601String(),
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'groups': groups.map((g) => g.toJson()).toList(),
      'personas': personas.map((p) => p.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'posts': posts.map((p) => p.toJson()).toList(),
      'materials': materials.map((m) => m.toJson()).toList(),
      'channels': channels.map((c) => c.toJson()).toList(),
      'aiModels': aiModels.map((m) => m.toJson()).toList(),
      'settings': settings,
    };
  }

  void _openFileLocation(String path) {
    // 简单提示路径
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('文件保存在: $path'),
        behavior: SnackBarBehavior.floating,
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
            onPressed: () async {
              Navigator.pop(context);
              await _restoreFromFile();
            },
            child: const Text('选择文件'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.isEmpty) return;
      
      final filePath = result.files.first.path;
      if (filePath == null) return;
      
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final file = File(filePath);
      final content = await file.readAsString();
      final backupData = jsonDecode(content) as Map<String, dynamic>;
      
      // 验证备份文件格式
      if (backupData['version'] == null || backupData['contacts'] == null) {
        throw Exception('无效的备份文件格式');
      }
      
      // 恢复数据
      await _restoreBackupData(backupData);
      
      if (mounted) {
        Navigator.pop(context); // 关闭加载指示器
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据恢复成功！请重启应用以生效。'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackupData(Map<String, dynamic> backupData) async {
    final db = await DatabaseService.database;
    
    // 清空现有数据
    await db.delete('contacts');
    await db.delete('contact_methods');
    await db.delete('interactions');
    await db.delete('tasks');
    await db.delete('contact_groups');
    await db.delete('personas');
    await db.delete('dynamic_posts');
    await db.delete('temp_materials');
    await db.delete('channels');
    await db.delete('ai_models');
    await db.delete('relationship_changes');
    
    // 恢复联系人
    for (final contactJson in backupData['contacts'] as List) {
      final contact = Contact.fromJson(contactJson as Map<String, dynamic>);
      await DatabaseService.saveContact(contact);
    }
    
    // 恢复分组
    if (backupData['groups'] != null) {
      for (final groupJson in backupData['groups'] as List) {
        final group = ContactGroup.fromJson(groupJson as Map<String, dynamic>);
        await DatabaseService.saveContactGroup(group);
      }
    }
    
    // 恢复人设
    if (backupData['personas'] != null) {
      for (final personaJson in backupData['personas'] as List) {
        final persona = Persona.fromJson(personaJson as Map<String, dynamic>);
        await DatabaseService.savePersona(persona);
      }
    }
    
    // 恢复任务
    if (backupData['tasks'] != null) {
      for (final taskJson in backupData['tasks'] as List) {
        final task = SocialTask.fromJson(taskJson as Map<String, dynamic>);
        await DatabaseService.saveTask(task);
      }
    }
    
    // 恢复动态
    if (backupData['posts'] != null) {
      for (final postJson in backupData['posts'] as List) {
        final post = DynamicPost.fromJson(postJson as Map<String, dynamic>);
        await DatabaseService.saveDynamicPost(post);
      }
    }
    
    // 恢复临时素材
    if (backupData['materials'] != null) {
      for (final materialJson in backupData['materials'] as List) {
        final material = TempMaterial.fromJson(materialJson as Map<String, dynamic>);
        await DatabaseService.saveTempMaterial(material);
      }
    }
    
    // 恢复渠道
    if (backupData['channels'] != null) {
      for (final channelJson in backupData['channels'] as List) {
        final channel = SocialChannel.fromJson(channelJson as Map<String, dynamic>);
        await DatabaseService.saveChannel(channel);
      }
    }
    
    // 恢复AI模型
    if (backupData['aiModels'] != null) {
      for (final modelJson in backupData['aiModels'] as List) {
        final model = AIModel.fromJson(modelJson as Map<String, dynamic>);
        await DatabaseService.saveAIModel(model);
      }
    }
    
    // 恢复设置
    if (backupData['settings'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      final settings = backupData['settings'] as Map<String, dynamic>;
      for (final entry in settings.entries) {
        if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value as bool);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value as int);
        } else if (entry.value is double) {
          await prefs.setDouble(entry.key, entry.value as double);
        } else if (entry.value is String) {
          await prefs.setString(entry.key, entry.value as String);
        } else if (entry.value is List) {
          await prefs.setStringList(entry.key, (entry.value as List).cast<String>());
        }
      }
    }
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
              
              // 清除数据库
              final db = await DatabaseService.database;
              await db.delete('contacts');
              await db.delete('contact_methods');
              await db.delete('interactions');
              await db.delete('tasks');
              await db.delete('contact_groups');
              await db.delete('personas');
              await db.delete('dynamic_posts');
              await db.delete('temp_materials');
              await db.delete('channels');
              await db.delete('ai_models');
              await db.delete('relationship_changes');
              
              // 清除设置
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('所有数据已清除，请重启应用'),
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
