import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../models/task.dart';
import '../models/ai_config.dart';
import '../models/user_profile.dart';
import '../models/contact_social.dart';
import '../models/social_channel_config.dart';
import 'ai_service.dart';

class TaskGeneratorService {
  static const _uuid = Uuid();

  static Future<List<SocialTask>> generateTasks({
    required Contact contact,
    required AIModel model,
    String? systemPrompt,
    int days = 7,
    UserProfile? userProfile,
    ContactSocial? contactSocial,
    List<InteractionLog>? interactionLogs,
    List<ContactChannelConfig>? channelConfigs,
  }) async {
    if (contact.goalRelation == null || contact.goalRelation!.isEmpty) {
      return [];
    }

    final prompt = _buildTaskGenerationPrompt(
      contact,
      days,
      userProfile: userProfile,
      contactSocial: contactSocial,
      interactionLogs: interactionLogs,
      channelConfigs: channelConfigs,
    );
    
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

  static String _buildTaskGenerationPrompt(
    Contact contact,
    int days, {
    UserProfile? userProfile,
    ContactSocial? contactSocial,
    List<InteractionLog>? interactionLogs,
    List<ContactChannelConfig>? channelConfigs,
  }) {
    final goal = contact.goalRelation ?? '普通朋友';
    
    final buffer = StringBuffer();
    buffer.writeln('请为联系人生成$days天的社交任务计划。');
    buffer.writeln('');

    // 用户画像
    if (userProfile != null) {
      buffer.writeln('## 执行者画像');
      buffer.writeln('- 性格: ${userProfile.personalityTraits.join('、')}');
      buffer.writeln('- 沟通风格: ${userProfile.communicationStyle}');
      buffer.writeln('- 社交能量: ${userProfile.socialEnergy}/100');
      buffer.writeln('- 短信意愿: ${userProfile.opennessToTexting}/5');
      buffer.writeln('- 电话意愿: ${userProfile.opennessToCalling}/5');
      buffer.writeln('- 见面意愿: ${userProfile.opennessToMeeting}/5');
      buffer.writeln('- 状态: ${userProfile.statusTags.join('、')}');
      buffer.writeln('');
      buffer.writeln('注意：任务需匹配执行者画像。社恐→文字交流为主；能量低→轻松社交；委婉型→柔和措辞。');
      buffer.writeln('');
    }

    // 联系人画像
    buffer.writeln('## 联系人画像');
    final profile = StringBuffer();
    profile.writeln('姓名：${contact.name}');
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
    buffer.write(profile.toString());

    // 社交大纲
    if (contactSocial != null) {
      buffer.writeln('');
      buffer.writeln('## 社交大纲');
      buffer.writeln('- 社交航向: ${contactSocial.directionName}');
      buffer.writeln('- 关系阶段: ${contactSocial.currentStageName} → ${contactSocial.targetStageName}');
      buffer.writeln('- 关系温度: ${contactSocial.warmthLevel}/10');
      if (contactSocial.outlineTopics.isNotEmpty) {
        buffer.writeln('- 推荐话题: ${contactSocial.outlineTopics.join('、')}');
      }
      if (contactSocial.avoidTopics.isNotEmpty) {
        buffer.writeln('- 避免话题: ${contactSocial.avoidTopics.join('、')}');
      }
      if (contactSocial.customOutline != null && contactSocial.customOutline!.isNotEmpty) {
        buffer.writeln('- 自定义大纲: ${contactSocial.customOutline}');
      }
      if (contactSocial.directionNote != null && contactSocial.directionNote!.isNotEmpty) {
        buffer.writeln('- 航向说明: ${contactSocial.directionNote}');
      }
    }

    // 近期互动
    if (interactionLogs != null && interactionLogs.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('## 近期互动记录');
      for (final log in interactionLogs.take(5)) {
        buffer.writeln('- [${log.sourceName}] ${log.title} (情绪:${log.emotionalTone ?? '中性'})');
      }
    }

    // 可用社交途径
    if (channelConfigs != null && channelConfigs.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('## 可用社交途径');
      for (final config in channelConfigs) {
        final platformCfg = getPlatformConfig(config.platform);
        buffer.writeln('- ${platformCfg.emoji} ${platformCfg.name}');
        if (config.account != null && config.account!.isNotEmpty) {
          buffer.writeln('  账号: ${config.account}');
        }
        if (config.enabledFeatures.isNotEmpty) {
          final featureNames = config.enabledFeatures.map((f) {
            final fc = platformCfg.features.where((ff) => ff.feature == f).first;
            return '${fc.emoji}${fc.name}';
          }).join('、');
          buffer.writeln('  可用功能: $featureNames');
        }
        if (config.preferredModes.isNotEmpty) {
          final modeNames = config.preferredModes.map((m) => getModeConfig(m).map((mc) => '${mc.emoji}${mc.name}').join('、');
          buffer.writeln('  偏好方式: $modeNames');
        }
      }
      buffer.writeln('注意：生成的任务应优先使用上述可用的社交途径和功能。');
    }

    buffer.writeln('');
    buffer.writeln('## 任务要求');
    buffer.writeln('请生成具体的、可执行的社交任务，包括：');
    buffer.writeln('1. 具体的行动（匹配执行者沟通风格和社交意愿）');
    buffer.writeln('2. 话题切入点（参考推荐话题，避开避免话题）');
    buffer.writeln('3. 任务时间和频率（匹配关系温度和阶段）');
    buffer.writeln('4. 每个任务包含3-5个执行步骤的详细指导');
    buffer.writeln('');
    buffer.writeln('请用JSON格式返回，格式如下：');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "tasks": [');
    buffer.writeln('    {');
    buffer.writeln('      "title": "任务标题",');
    buffer.writeln('      "description": "任务详细描述（含开场白、话题切入、注意事项）",');
    buffer.writeln('      "type": "sendMessage|greeting|phoneCall|socialInteraction|other",');
    buffer.writeln('      "priority": 1-5,');
    buffer.writeln('      "scheduled_days": [1, 2, 3],');
    buffer.writeln('      "scheduled_hour": 9-21,');
    buffer.writeln('      "steps": ["步骤1: 具体执行指导", "步骤2: 具体执行指导", ...]');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln('');
    buffer.writeln('注意：');
    buffer.writeln('- 任务要符合目标关系和社交大纲');
    buffer.writeln('- 频率要适中，既要保持联系又不要过于频繁');
    buffer.writeln('- 优先选择对方可能方便的时段');
    buffer.writeln('- 考虑双方性格和兴趣，选择合适的话题切入点');
    buffer.writeln('- 注意大忌，绝对不要涉及那些雷区');
    buffer.writeln('- 任务内容应细化为可执行的大纲，具体到要说的话和要做的事');
    
    return buffer.toString();
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
