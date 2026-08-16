import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/contact_provider.dart';
import 'core/providers/task_provider.dart';
import 'core/providers/ai_provider.dart';
import 'core/providers/atmosphere_provider.dart';
import 'core/utils/app_update_service.dart';
import 'ui/pages/splash_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/contacts_page.dart';
import 'ui/pages/tasks_page.dart';
import 'ui/pages/ai_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/pages/contact_detail_page.dart';
import 'ui/pages/ai_chat_page.dart';
import 'ui/pages/external_ai_page.dart';
import 'ui/pages/about_page.dart';
import 'ui/pages/atmosphere_config_page.dart';
import 'ui/pages/privacy_settings_page.dart';
import 'ui/pages/notification_settings_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化通知服务
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  
  // 检查应用更新
  _checkForUpdate();
  
  runApp(const MyApp());
}

Future<void> _checkForUpdate() async {
  try {
    final outcome = await AppUpdateService.checkForUpdate();
    if (outcome.result == UpdateCheckResult.hasUpdate) {
      debugPrint('发现新版本: ${outcome.releaseInfo?.version}');
    }
  } catch (e) {
    debugPrint('检查更新失败: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => AtmosphereProvider()),
      ],
      child: MaterialApp(
        title: '社交塔子',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Color(0xFF6366F1),
            unselectedItemColor: Colors.grey,
          ),
        ),
        home: const SplashPage(),
        routes: {
          '/home': (context) => const HomePage(),
          '/contacts': (context) => const ContactsPage(),
          '/tasks': (context) => const TasksPage(),
          '/ai': (context) => const AIPage(),
          '/settings': (context) => const SettingsPage(),
          '/contact': (context) => const ContactDetailPage(),
          '/ai-chat': (context) => const AIChatPage(),
          '/external-ai': (context) => const ExternalAIPage(),
          '/about': (context) => const AboutPage(),
          '/atmosphere-config': (context) => const AtmosphereConfigPage(),
          '/privacy-settings': (context) => const PrivacySettingsPage(),
          '/notification-settings': (context) => const NotificationSettingsPage(),
        },
      ),
    );
  }
}
