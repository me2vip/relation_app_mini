import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/providers/app_provider.dart';
import 'package:provider/provider.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 应用图标和名称
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '社交塔子',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'v$_version ($_buildNumber)',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // 版本信息卡片
          _InfoCard(
            icon: Icons.info_outline,
            title: '版本信息',
            children: [
              _InfoRow('当前版本', 'v$_version'),
              _InfoRow('构建号', _buildNumber),
              Consumer<AppProvider>(
                builder: (context, app, _) {
                  if (app.hasUpdate && app.latestRelease != null) {
                    return _InfoRow(
                      '最新版本',
                      'v${app.latestRelease!.version}',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '有更新',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }
                  return _InfoRow('最新版本', 'v$_version (已是最新)');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 使用条款
          _InfoCard(
            icon: Icons.description_outlined,
            title: '使用条款',
            onTap: () => _showTerms(context),
          ),
          const SizedBox(height: 16),
          
          // 隐私政策
          _InfoCard(
            icon: Icons.privacy_tip_outlined,
            title: '隐私政策',
            onTap: () => _showPrivacy(context),
          ),
          const SizedBox(height: 16),
          
          // 开源许可
          _InfoCard(
            icon: Icons.code,
            title: '开源许可证',
            onTap: () => showLicensePage(context),
          ),
          const SizedBox(height: 40),
          
          // 版权信息
          Center(
            child: Column(
              children: [
                const Text(
                  '© 2024 社交塔子团队',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showContactUs(context),
                  child: const Text('联系我们'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '使用条款',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: const [
                    Text(
                      '欢迎使用社交塔子！\n\n'
                      '在使用本应用之前，请仔细阅读以下条款：\n\n'
                      '1. 服务说明\n'
                      '社交塔子是一款智能社交管理工具，帮助您管理社交关系和任务。我们保留随时修改或终止服务的权利。\n\n'
                      '2. 用户责任\n'
                      '您应妥善保管账户信息，对账户下的所有活动负责。您同意不会利用本应用从事任何违法或不当活动。\n\n'
                      '3. 隐私保护\n'
                      '我们重视您的隐私。有关我们如何收集、使用和保护您的个人信息，请参阅我们的隐私政策。\n\n'
                      '4. 知识产权\n'
                      '本应用中的所有内容，包括但不限于文字、图片、软件代码等，均受知识产权法保护。\n\n'
                      '5. 免责声明\n'
                      '本应用按"现状"提供服务，我们不对服务的准确性、可靠性或完整性作任何保证。\n\n'
                      '6. 条款修改\n'
                      '我们保留随时修改本条款的权利。修改后的条款将在应用内公布，继续使用即表示您接受修改后的条款。\n\n'
                      '如有任何疑问，请通过应用内的联系方式与我们取得联系。',
                      style: TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '隐私政策',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: const [
                    Text(
                      '社交塔子隐私政策\n\n'
                      '最后更新日期：2024年1月\n\n'
                      '我们深知个人信息对您的重要性，并会尽全力保护您的个人信息安全。我们致力于维持您对我们的信任，恪守以下原则，保护您的个人信息：\n\n'
                      '1. 信息收集\n'
                      '我们收集的信息包括：\n'
                      '• 联系人信息（由您主动添加）\n'
                      '• 任务和提醒信息\n'
                      '• 应用设置偏好\n'
                      '• 设备信息（用于检查更新）\n\n'
                      '2. 信息使用\n'
                      '我们使用收集的信息用于：\n'
                      '• 提供社交管理服务\n'
                      '• 生成任务提醒\n'
                      '• 改进产品体验\n'
                      '• 检查应用更新\n\n'
                      '3. 信息存储\n'
                      '• 所有数据存储在您的设备本地\n'
                      '• 我们不会将您的数据上传到远程服务器\n'
                      '• 数据采用加密存储保护\n\n'
                      '4. 信息安全\n'
                      '我们采取以下安全措施：\n'
                      '• 本地数据加密\n'
                      '• 应用锁保护\n'
                      '• 安全的网络通信\n\n'
                      '5. 您的权利\n'
                      '您有权：\n'
                      '• 查看和修改您的数据\n'
                      '• 导出您的数据\n'
                      '• 删除您的数据\n'
                      '• 关闭特定功能\n\n'
                      '6. 未成年人保护\n'
                      '我们不向14周岁以下的未成年人提供服务。\n\n'
                      '7. 政策更新\n'
                      '我们可能会不时更新本隐私政策。更新后的政策将在应用内公布。\n\n'
                      '如需帮助，请通过应用内的联系方式与我们取得联系。',
                      style: TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactUs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('联系我们'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text('邮箱'),
              subtitle: Text('support@shejiaotazi.com'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.code),
              title: Text('GitHub'),
              subtitle: Text('github.com/me2vip/relation_app_mini'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget>? children;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.title,
    this.children,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon, color: const Color(0xFF6366F1)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: const Color(0xFF6366F1)),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (children != null) ...[
                    const Divider(height: 24),
                    ...children!,
                  ],
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow(this.label, this.value, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Row(
            children: [
              Text(value),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
