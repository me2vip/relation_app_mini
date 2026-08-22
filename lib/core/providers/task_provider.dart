import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/task.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/task_generator_service.dart';
import '../../models/ai_config.dart';
import '../../models/contact.dart';
import '../../models/user_profile.dart';
import '../../models/contact_social.dart';
import '../../models/social_channel_config.dart';

class TaskProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  
  List<SocialTask> _tasks = [];
  List<TaskSchedule> _schedules = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SocialTask> get tasks => _tasks;
  List<SocialTask> get pendingTasks => 
      _tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<SocialTask> get completedTasks => 
      _tasks.where((t) => t.status == TaskStatus.completed).toList();
  List<SocialTask> get overdueTasks => 
      pendingTasks.where((t) => t.isOverdue).toList();
  List<TaskSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TaskProvider() {
    loadTasks();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await DatabaseService.getAllTasks();
      _schedules = await DatabaseService.getTaskSchedules();
      
      // 检查并更新过期任务
      await _updateExpiredTasks();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateExpiredTasks() async {
    final now = DateTime.now();
    for (final task in _tasks) {
      if (task.status == TaskStatus.pending && 
          task.scheduledAt.isBefore(now)) {
        await updateTaskStatus(task.id, TaskStatus.expired);
      }
    }
  }

  Future<void> addTask(SocialTask task) async {
    _tasks.insert(0, task);
    notifyListeners();
    try {
      await DatabaseService.saveTask(task);
      if (task.scheduledAt.isAfter(DateTime.now())) {
        await NotificationService.scheduleTaskReminder(task);
      }
    } catch (e) {
      _tasks.removeWhere((t) => t.id == task.id);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTask(SocialTask task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    final original = idx >= 0 ? _tasks[idx] : null;
    if (idx >= 0) {
      _tasks[idx] = task;
      notifyListeners();
    }
    try {
      await DatabaseService.saveTask(task);
      await NotificationService.cancelNotification(task.id.hashCode);
      if (task.status == TaskStatus.pending &&
          task.scheduledAt.isAfter(DateTime.now())) {
        await NotificationService.scheduleTaskReminder(task);
      }
    } catch (e) {
      if (original != null && idx >= 0) _tasks[idx] = original;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    SocialTask? original;
    if (idx >= 0) {
      original = _tasks[idx];
      _tasks[idx] = original.copyWith(
        status: status,
        completedAt: status == TaskStatus.completed ? DateTime.now() : null,
      );
      notifyListeners();
    }
    try {
      await DatabaseService.updateTaskStatus(taskId, status);
      if (status != TaskStatus.pending) {
        await NotificationService.cancelNotification(taskId.hashCode);
      }
    } catch (e) {
      if (original != null && idx >= 0) _tasks[idx] = original;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> completeTask(String taskId) async {
    await updateTaskStatus(taskId, TaskStatus.completed);
  }

  Future<void> skipTask(String taskId) async {
    await updateTaskStatus(taskId, TaskStatus.skipped);
  }

  Future<void> deleteTask(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    final removed = idx >= 0 ? _tasks.removeAt(idx) : null;
    if (idx >= 0) notifyListeners();
    try {
      await NotificationService.cancelNotification(taskId.hashCode);
      await DatabaseService.deleteTask(taskId);
    } catch (e) {
      if (removed != null) {
        _tasks.insert(idx, removed);
        notifyListeners();
      }
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // AI生成任务
  Future<void> generateTasksForContact({
    required Contact contact,
    required AIModel model,
    String? systemPrompt,
    int days = 7,
    UserProfile? userProfile,
    ContactSocial? contactSocial,
    List<InteractionLog>? interactionLogs,
    List<ContactChannelConfig>? channelConfigs,
  }) async {
    try {
      final tasks = await TaskGeneratorService.generateTasks(
        contact: contact,
        model: model,
        systemPrompt: systemPrompt,
        days: days,
        userProfile: userProfile,
        contactSocial: contactSocial,
        interactionLogs: interactionLogs,
        channelConfigs: channelConfigs,
      );

      for (final task in tasks) {
        await addTask(task);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // 获取联系人的任务
  List<SocialTask> getTasksForContact(String contactId) {
    return _tasks.where((t) => t.contactId == contactId).toList();
  }

  // 添加任务调度
  Future<void> addSchedule(TaskSchedule schedule) async {
    try {
      await DatabaseService.saveTaskSchedule(schedule);
      await loadTasks();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // 删除任务调度
  Future<void> deleteSchedule(String scheduleId) async {
    final idx = _schedules.indexWhere((s) => s.id == scheduleId);
    final removed = idx >= 0 ? _schedules.removeAt(idx) : null;
    if (idx >= 0) notifyListeners();
    try {
      await DatabaseService.deleteTaskSchedule(scheduleId);
    } catch (e) {
      if (removed != null) {
        _schedules.insert(idx, removed);
        notifyListeners();
      }
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // 发送每日汇总
  Future<void> sendDailySummary() async {
    await NotificationService.showDailyTaskSummary(_tasks);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  SocialTask createTask({
    required String contactId,
    required String contactName,
    required String title,
    required String description,
    required TaskType type,
    DateTime? scheduledAt,
    int priority = 3,
  }) {
    return SocialTask(
      id: _uuid.v4(),
      contactId: contactId,
      contactName: contactName,
      title: title,
      description: description,
      type: type,
      status: TaskStatus.pending,
      scheduledAt: scheduledAt ?? DateTime.now().add(const Duration(hours: 1)),
      priority: priority,
    );
  }
}
