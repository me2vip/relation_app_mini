import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/contact_provider.dart';
import 'core/providers/task_provider.dart';
import 'models/task.dart';
import 'core/providers/ai_provider.dart';
import 'core/providers/persona_provider.dart';
import 'core/providers/channel_provider.dart';
import 'ui/pages/splash_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/contacts_page.dart';
import 'ui/pages/tasks_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/pages/contact_detail_page.dart';
import 'ui/pages/about_page.dart';
import 'ui/pages/notification_settings_page.dart';
import 'ui/pages/privacy_settings_page.dart';
import 'ui/pages/persona_page.dart';
import 'ui/pages/group_edit_page.dart';
import 'ui/pages/persona_edit_page.dart';
import 'ui/pages/temp_material_page.dart';
import 'ui/pages/dynamic_post_page.dart';
import 'ui/pages/channel_manage_page.dart';
import 'ui/pages/ai_model_manage_page.dart';
import 'ui/pages/ai_task_center_page.dart';
import 'ui/pages/task_detail_page.dart';
import 'services/notification_service.dart';

// GlobalKey 用于访问 MyApp 状态
final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  // 获取主题设置
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('dark_mode') ?? false;

  runApp(MyApp(key: myAppKey, isDarkMode: isDarkMode));
}

void toggleAppTheme(bool value) {
  myAppKey.currentState?._toggleTheme(value);
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;

  const MyApp({super.key, this.isDarkMode = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => _isDarkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => PersonaProvider()),
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
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
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
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
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashPage(),
        onGenerateRoute: (settings) {
          if (settings.name == '/task-detail') {
            final task = settings.arguments;
            if (task is SocialTask) {
              return MaterialPageRoute(
                builder: (context) => TaskDetailPage(task: task),
              );
            }
          }
          return null;
        },
        routes: {
          '/home': (context) => const HomePage(),
          '/contacts': (context) => const ContactsPage(),
          '/tasks': (context) => const TasksPage(),
          '/settings': (context) => const SettingsPage(),
          '/contact': (context) => const ContactDetailPage(),
          '/about': (context) => const AboutPage(),
          '/privacy-settings': (context) => const PrivacySettingsPage(),
          '/notification-settings': (context) => const NotificationSettingsPage(),
          '/persona': (context) => const PersonaPage(),
          '/group-edit': (context) => const GroupEditRoutePage(),
          '/persona-edit': (context) => const PersonaEditRoutePage(),
          '/temp-material': (context) => const TempMaterialPage(),
          '/dynamic-post': (context) => const DynamicPostPage(),
          '/channels': (context) => const ChannelManagePage(),
          '/ai-models': (context) => const AIModelManagePage(),
          '/ai-task-center': (context) => const AiTaskCenterPage(),
        },
      ),
    );
  }
}
