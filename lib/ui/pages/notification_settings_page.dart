import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _pushEnabled = true;
  bool _dailySummaryEnabled = true;
  TimeOfDay _summaryTime = const TimeOfDay(hour: 8, minute: 0);
  bool _taskReminderEnabled = true;
  int _reminderMinutesBefore = 30;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('push_notifications') ?? true;
      _dailySummaryEnabled = prefs.getBool('daily_summary') ?? true;
      _taskReminderEnabled = prefs.getBool('task_reminder') ?? true;
      _reminderMinutesBefore = prefs.getInt('reminder_minutes') ?? 30;
      
      final hour = prefs.getInt('summary_hour') ?? 8;
      final minute = prefs.getInt('summary_minute') ?? 0;
      _summaryTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 推送通知设置
          _NotificationCard(
            title: '推送通知',
            icon: Icons.notifications_outlined,
            children: [
              SwitchListTile(
                title: const Text('启用推送通知'),
                subtitle: const Text('接收任务提醒和更新通知'),
                value: _pushEnabled,
                onChanged: (value) {
                  setState(() => _pushEnabled = value);
                  _saveSetting('push_notifications', value);
                  
                  if (value) {
                    NotificationService.requestPermissions();
                  }
                },
                activeColor: const Color(0xFF6366F1),
              ),
              ListTile(
                leading: const Icon(Icons.alarm),
                title: const Text('任务提醒'),
                subtitle: const Text('提前提醒即将到期的任务'),
                trailing: Switch(
                  value: _taskReminderEnabled,
                  onChanged: _pushEnabled 
                      ? (value) {
                          setState(() => _taskReminderEnabled = value);
                          _saveSetting('task_reminder', value);
                        }
                      : null,
                  activeColor: const Color(0xFF6366F1),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('提前提醒时间'),
                subtitle: Text('任务开始前 $_reminderMinutesBefore 分钟提醒'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                enabled: _pushEnabled && _taskReminderEnabled,
                onTap: _showReminderTimeOptions,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 每日汇总设置
          _NotificationCard(
            title: '每日汇总',
            icon: Icons.summarize,
            children: [
              SwitchListTile(
                title: const Text('启用每日汇总'),
                subtitle: const Text('每天发送任务完成情况汇总'),
                value: _dailySummaryEnabled,
                onChanged: (value) {
                  setState(() => _dailySummaryEnabled = value);
                  _saveSetting('daily_summary', value);
                  
                  if (value) {
                    _scheduleDailySummary();
                  } else {
                    _cancelDailySummary();
                  }
                },
                activeColor: const Color(0xFF6366F1),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('发送时间'),
                subtitle: Text('每天 ${_summaryTime.format(context)} 发送'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                enabled: _dailySummaryEnabled,
                onTap: _selectSummaryTime,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 通知预览
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '通知预览',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.people_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '社交塔子',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '今日有 3 个待办任务，点击查看详情',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '刚刚',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 通知权限状态
          FutureBuilder<bool>(
            future: NotificationService.hasPermission(),
            builder: (context, snapshot) {
              final hasPermission = snapshot.data ?? false;
              
              if (!hasPermission) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '通知权限未开启，部分功能可能无法正常使用',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: NotificationService.requestPermissions,
                        child: const Text('开启'),
                      ),
                    ],
                  ),
                );
              }
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Text(
                      '通知权限已开启',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showReminderTimeOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提前提醒时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 10, 15, 30, 60].map((minutes) {
            return RadioListTile<int>(
              title: Text(minutes < 60 ? '$minutes 分钟' : '1 小时'),
              value: minutes,
              groupValue: _reminderMinutesBefore,
              onChanged: (v) async {
                setState(() => _reminderMinutesBefore = v!);
                await _saveSetting('reminder_minutes', v);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _selectSummaryTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _summaryTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              hourMinuteTextColor: Color(0xFF6366F1),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() => _summaryTime = time);
      await _saveSetting('summary_hour', time.hour);
      await _saveSetting('summary_minute', time.minute);
      _scheduleDailySummary();
    }
  }

  Future<void> _scheduleDailySummary() async {
    // 取消之前的定时通知
    await _cancelDailySummary();
    
    // 安排新的每日汇总通知
    await NotificationService.scheduleDailySummary(
      hour: _summaryTime.hour,
      minute: _summaryTime.minute,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已设置每日汇总于 ${_summaryTime.format(context)} 发送'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelDailySummary() async {
    await NotificationService.cancelDailySummary();
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _NotificationCard({
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
