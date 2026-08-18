import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../models/task.dart';
import '../models/ai_config.dart';
import 'ai_service.dart';

class TaskGeneratorService {
  static const _uuid = Uuid();

  /// 根据联系人目标关系自动生成社交任务
  static Future<List<SocialTask>> generateTasks({
    required Contact contact,
    required AIModel model,
    String? systemPrompt,
    int days = 7,
  }) async {
    if (contact.goalRelation == null || contact.goalRelation!.isEmpty) {
      return [];
    }

    final prompt = _buildTaskGenerationPrompt(contact, days);
    
    final messages = [
      AIMessage(
        id: _uuid.v4(),
        role: 'user',
        content: prompt,
        createdAt: DateTime.now(),
      ),
    ];

    try {
      final response = await AIService.chat(
        model: model,
        messages: messages,
        systemPrompt: systemPrompt ?? _defaultSystemPrompt,
      );

      return _parseTasksFromResponse(response.content, contact);
    } catch (e) {
      return _generateFallbackTasks(contact, days);
    }
  }

  static String _buildTaskGenerationPrompt(Contact contact, int days) {
    final goal = contact.goalRelation ?? '普通朋友';
    // 构造详细人物画像供 AI 参考
    final profile = StringBuffer();
    profile.writeln('联系人姓名：${contact.name}');
    profile.writeln('当前关系：${_getRelationshipDescription(contact.level)}');
    profile.writeln('目标关系：$goal');
    if (contact.gender != Gender.unknown) profile.writeln('性别：${contact.genderName}');
    if (contact.age != null) profile.writeln('年龄：${contact.age}岁');
    if (contact.maritalStatus != MaritalStatus.unknown) profile.writeln('婚姻状况：${contact.maritalStatusName}');
    if (contact.educationLevel != EducationLevel.unknown) profile.writeln('学历：${contact.educationLevelName}');
    if (contact.school != null) profile.writeln('学校：${contact.school}');
    if (contact.industry != null) profile.writeln('行业：${contact.industry}');
    if (contact.company != null) profile.writeln('公司：${contact.company}');
    if (contact.position != null) profile.writeln('职位：${contact.position}');
    if (contact.personalityTags != null) profile.writeln('性格标签：${contact.personalityTags}');
    if (contact.personalityDesc != null) profile.writeln('性格描述：${contact.personalityDesc}');
    if (contact.hobbies != null) profile.writeln('兴趣爱好：${contact.hobbies}');
    if (contact.strengths != null) profile.writeln('优点：${contact.strengths}');
    if (contact.weaknesses != null) profile.writeln('缺点：${contact.weaknesses}');
    if (contact.fears != null) profile.writeln('恐惧：${contact.fears}');
    if (contact.desires != null) profile.writeln('渴望：${contact.desires}');
    if (contact.skills != null) profile.writeln('技能：${contact.skills}');
    if (contact.tastePreferences != null) profile.writeln('口味偏好：${contact.tastePreferences}');
    if (contact.familyEconomicStatus != null) profile.writeln('家庭经济状况：${contact.familyEconomicStatus}');
    if (contact.currentStatus != null) profile.writeln('目前现状：${contact.currentStatus}');
    profile.writeln('TA对我的信任度：${contact.taTrustLevel}/10');
    profile.writeln('我对TA的信任度：${contact.myTrustLevel}/10');
    if (contact.moneyDesireLevel != null) profile.writeln('挣钱欲望：${contact.moneyDesireLevel}/5');
    if (contact.ambitionLevel != null) profile.writeln('上进心：${contact.ambitionLevel}/5');
    if (contact.shortTermGoals != null) profile.writeln('短期目标：${contact.shortTermGoals}');
    if (contact.longTermGoals != null) profile.writeln('长期目标：${contact.longTermGoals}');
    if (contact.socialCircles != null) profile.writeln('所交往圈子：${contact.socialCircles}');
    if (contact.taboos != null) profile.writeln('大忌（绝对不要踩）：${contact.taboos}');
    if (contact.values != null) profile.writeln('价值观：${contact.values}');

    return '''
请为以下联系人生成$days天的社交任务计划，充分利用人物画像信息使任务贴合此人特点：

【人物画像】
${profile.toString()}

请生成具体的、可执行的社交任务，包括：
1. 具体的行动（如：发消息、打电话、约见面、送礼物等）
2. 任务时间和频率
3. 简要的任务描述

请用JSON格式返回，格式如下：
{
  "tasks": [
    {
      "title": "任务标题",
      "description": "任务详细描述（包含如何切入话题的建议）",
      "type": "sendMessage|greeting|phoneCall|socialInteraction|gift|other",
      "priority": 1-5,
      "scheduled_days": [1, 2, 3],
      "scheduled_hour": 9-21
    }
  ]
}

注意：
- 任务要符合目标关系，不要过于亲密或疏远
- 频率要适中，既要保持联系又不要过于频繁
- 优先选择对方可能方便的时段
- 考虑对方的兴趣爱好和性格，选择合适的话题切入点
- 注意大忌，绝对不要在任务中涉及那些雷区
- 话题可以围绕对方的工作、兴趣、职业发展、家庭等展开
''';
  }

  static List<SocialTask> _parseTasksFromResponse(
    String content,
    Contact contact,
  ) {
    try {
      // 提取JSON部分
      String jsonStr = content;
      final jsonMatch = RegExp(r'\{[\s\S]*"tasks"[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }

      // 解析JSON
      final data = _parseJsonSafely(jsonStr);
      if (data == null || data['tasks'] == null) {
        return _generateFallbackTasks(contact, 7);
      }

      final tasks = <SocialTask>[];
      final now = DateTime.now();

      for (final taskData in data['tasks'] as List) {
        final scheduledDays = (taskData['scheduled_days'] as List?)?.cast<int>() ?? [1];
        final scheduledHour = (taskData['scheduled_hour'] as int?) ?? 10;

        for (final day in scheduledDays) {
          final scheduledAt = DateTime(
            now.year,
            now.month,
            now.day + day,
            scheduledHour.clamp(8, 21),
            0,
          );

          final type = _parseTaskType(taskData['type'] as String?);
          final priority = (taskData['priority'] as int?)?.clamp(0, 5) ?? 3;

          tasks.add(SocialTask(
            id: _uuid.v4(),
            contactId: contact.id,
            contactName: contact.name,
            title: taskData['title'] as String? ?? '社交任务',
            description: taskData['description'] as String? ?? '',
            type: type,
            status: scheduledAt.isBefore(now) 
                ? TaskStatus.completed 
                : TaskStatus.pending,
            scheduledAt: scheduledAt,
            priority: priority,
            goalRelation: contact.goalRelation,
          ));
        }
      }

      return tasks;
    } catch (e) {
      return _generateFallbackTasks(contact, 7);
    }
  }

  static Map<String, dynamic>? _parseJsonSafely(String jsonStr) {
    try {
      // 清理JSON字符串
      jsonStr = jsonStr.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      int depth = 0;
      int start = -1;
      for (int i = 0; i < jsonStr.length; i++) {
        if (jsonStr[i] == '{') {
          if (depth == 0) start = i;
          depth++;
        } else if (jsonStr[i] == '}') {
          depth--;
          if (depth == 0 && start >= 0) {
            jsonStr = jsonStr.substring(start, i + 1);
            break;
          }
        }
      }

      return Map<String, dynamic>.from(
        RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr)?.group(0) != null
            ? _evalJson(jsonStr)
            : {},
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _evalJson(String json) {
    // 简单的JSON解析
    final result = <String, dynamic>{};
    json = json.trim();
    if (!json.startsWith('{') || !json.endsWith('}')) {
      return result;
    }

    int i = 1;
    while (i < json.length - 1) {
      // 跳过空白
      while (i < json.length - 1 && json[i] == ' ') i++;
      if (json[i] == '"') {
        // 解析字符串键
        final keyEnd = json.indexOf('"', i + 1);
        final key = json.substring(i + 1, keyEnd);
        i = keyEnd + 1;
        
        // 找冒号
        while (i < json.length && json[i] != ':') i++;
        i++;
        
        // 解析值
        while (i < json.length && json[i] == ' ') i++;
        
        if (json[i] == '"') {
          // 字符串值
          final valueEnd = json.indexOf('"', i + 1);
          result[key] = json.substring(i + 1, valueEnd);
          i = valueEnd + 1;
        } else if (json[i] == '[') {
          // 数组值
          final valueEnd = _findMatchingBracket(json, i);
          result[key] = _parseJsonArray(json.substring(i, valueEnd + 1));
          i = valueEnd + 1;
        } else if (json[i] == '{') {
          // 对象值
          final valueEnd = _findMatchingBracket(json, i);
          result[key] = _evalJson(json.substring(i, valueEnd + 1));
          i = valueEnd + 1;
        } else {
          // 数字或布尔值
          final valueEnd = json.indexOf(RegExp(r'[,}\[\]]'), i);
          if (valueEnd > i) {
            final valueStr = json.substring(i, valueEnd).trim();
            if (valueStr == 'true') {
              result[key] = true;
            } else if (valueStr == 'false') {
              result[key] = false;
            } else {
              result[key] = num.tryParse(valueStr) ?? valueStr;
            }
            i = valueEnd;
          }
        }
      }
      while (i < json.length && json[i] != ',') i++;
      i++;
    }
    return result;
  }

  static int _findMatchingBracket(String json, int start) {
    if (json[start] == '[') {
      int depth = 0;
      bool inString = false;
      for (int i = start; i < json.length; i++) {
        if (json[i] == '"' && (i == 0 || json[i - 1] != '\\')) {
          inString = !inString;
        }
        if (!inString) {
          if (json[i] == '[') depth++;
          if (json[i] == ']') {
            depth--;
            if (depth == 0) return i;
          }
        }
      }
    } else if (json[start] == '{') {
      int depth = 0;
      bool inString = false;
      for (int i = start; i < json.length; i++) {
        if (json[i] == '"' && (i == 0 || json[i - 1] != '\\')) {
          inString = !inString;
        }
        if (!inString) {
          if (json[i] == '{') depth++;
          if (json[i] == '}') {
            depth--;
            if (depth == 0) return i;
          }
        }
      }
    }
    return json.length - 1;
  }

  static List<dynamic> _parseJsonArray(String arrayStr) {
    final result = <dynamic>[];
    if (arrayStr.length < 2) return result;
    
    arrayStr = arrayStr.trim();
    if (arrayStr.startsWith('[') && arrayStr.endsWith(']')) {
      arrayStr = arrayStr.substring(1, arrayStr.length - 1);
    }

    int i = 0;
    while (i < arrayStr.length) {
      while (i < arrayStr.length && arrayStr[i] == ' ') i++;
      if (i >= arrayStr.length) break;
      
      if (arrayStr[i] == '"') {
        final end = arrayStr.indexOf('"', i + 1);
        if (end > i) {
          result.add(arrayStr.substring(i + 1, end));
          i = end + 1;
        }
      } else if (arrayStr[i] == '[') {
        final end = _findMatchingBracket(arrayStr, i);
        result.add(_parseJsonArray(arrayStr.substring(i, end + 1)));
        i = end + 1;
      } else if (arrayStr[i] == '{') {
        final end = _findMatchingBracket(arrayStr, i);
        result.add(_evalJson(arrayStr.substring(i, end + 1)));
        i = end + 1;
      } else {
        final end = arrayStr.indexOf(RegExp(r'[,}\[\]]'), i);
        if (end > i) {
          final valueStr = arrayStr.substring(i, end).trim();
          if (valueStr.isNotEmpty) {
            if (valueStr == 'true') {
              result.add(true);
            } else if (valueStr == 'false') {
              result.add(false);
            } else {
              result.add(num.tryParse(valueStr) ?? valueStr);
            }
          }
          i = end;
        }
      }
      
      while (i < arrayStr.length && arrayStr[i] != ',') i++;
      i++;
    }
    
    return result;
  }

  static TaskType _parseTaskType(String? type) {
    switch (type?.toLowerCase()) {
      case 'sendmessage':
      case 'send_message':
        return TaskType.sendMessage;
      case 'greeting':
        return TaskType.greeting;
      case 'phonecall':
      case 'phone_call':
        return TaskType.phoneCall;
      case 'socialinteraction':
      case 'social_interaction':
        return TaskType.socialInteraction;
      case 'sendvideo':
      case 'send_video':
        return TaskType.sendVideo;
      default:
        return TaskType.other;
    }
  }

  static String _getRelationshipDescription(ContactLevel level) {
    switch (level) {
      case ContactLevel.unimportant:
        return '不太熟悉';
      case ContactLevel.normal:
        return '普通朋友';
      case ContactLevel.important:
        return '重要朋友';
      case ContactLevel.core:
        return '核心好友';
    }
  }

  static String get _defaultSystemPrompt => '''
你是一个专业的社交策略助手，擅长根据不同的人际关系目标制定社交计划。
你的任务是帮助用户维护和发展与不同联系人的关系。
请保持回复简洁、专业，任务要具体可执行。
''';

  /// 生成默认任务（不依赖AI）
  static List<SocialTask> _generateFallbackTasks(Contact contact, int days) {
    final tasks = <SocialTask>[];
    final now = DateTime.now();

    // 根据关系级别确定任务频率
    int frequency;
    switch (contact.level) {
      case ContactLevel.unimportant:
        frequency = 14; // 两周一次
        break;
      case ContactLevel.normal:
        frequency = 7; // 一周一次
        break;
      case ContactLevel.important:
        frequency = 3; // 三天一次
        break;
      case ContactLevel.core:
        frequency = 1; // 每天
        break;
    }

    for (int day = 1; day <= days; day += frequency) {
      final scheduledAt = DateTime(
        now.year,
        now.month,
        now.day + day,
        10 + (day % 4), // 在10-18点之间变化
        0,
      );

      tasks.add(SocialTask(
        id: _uuid.v4(),
        contactId: contact.id,
        contactName: contact.name,
        title: '保持联系：${contact.name}',
        description: '主动与${contact.name}发一条消息问候',
        type: TaskType.greeting,
        status: TaskStatus.pending,
        scheduledAt: scheduledAt,
        priority: contact.level.index,
        goalRelation: contact.goalRelation,
      ));
    }

    return tasks;
  }
}
