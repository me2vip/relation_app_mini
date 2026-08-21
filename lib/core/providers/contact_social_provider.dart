import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/contact_social.dart';

class ContactSocialProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  static const String _socialKey = 'contact_social_';
  static const String _logsKey = 'interaction_logs_';

  final Map<String, ContactSocial> _socials = {};
  final Map<String, List<InteractionLog>> _logs = {};
  bool _isLoading = false;

  Map<String, ContactSocial> get socials => _socials;
  Map<String, List<InteractionLog>> get logs => _logs;
  bool get isLoading => _isLoading;

  ContactSocialProvider() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_socialKey)) {
          final contactId = key.substring(_socialKey.length);
          final json = prefs.getString(key);
          if (json != null) {
            _socials[contactId] = ContactSocial.fromJson(
              Map<String, dynamic>.from(
                Map<String, dynamic>.from(
                  json as Map<String, dynamic>,
                ),
              ),
            );
          }
        } else if (key.startsWith(_logsKey)) {
          final contactId = key.substring(_logsKey.length);
          final jsonList = prefs.getStringList(key);
          if (jsonList != null) {
            _logs[contactId] = jsonList
                .map((j) => InteractionLog.fromJson(
                      Map<String, dynamic>.from(
                        Map<String, dynamic>.from(
                          j as Map<String, dynamic>,
                        ),
                      ),
                    ))
                .toList();
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  ContactSocial getSocial(String contactId) {
    return _socials.putIfAbsent(
      contactId,
      () => ContactSocial.createDefault(contactId),
    );
  }

  List<InteractionLog> getLogsForContact(String contactId) {
    return _logs[contactId] ?? [];
  }

  Future<void> updateSocial({
    required String contactId,
    SocialDirection? direction,
    RelationshipStage? currentStage,
    RelationshipStage? targetStage,
    String? directionNote,
    List<String>? outlineTopics,
    List<String>? avoidTopics,
    String? customOutline,
    int? warmthLevel,
  }) async {
    final old = getSocial(contactId);
    final updated = old.copyWith(
      direction: direction,
      currentStage: currentStage,
      targetStage: targetStage,
      directionNote: directionNote,
      outlineTopics: outlineTopics,
      avoidTopics: avoidTopics,
      customOutline: customOutline,
      warmthLevel: warmthLevel,
      updatedAt: DateTime.now(),
    );

    _socials[contactId] = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_socialKey$contactId',
      updated.toJson().toString(),
    );

    notifyListeners();
  }

  Future<void> applyTemplate({
    required String contactId,
    required SocialOutlineTemplate template,
  }) async {
    await updateSocial(
      contactId: contactId,
      direction: template.direction,
      outlineTopics: template.topics,
      directionNote: template.description,
    );
  }

  Future<void> addInteractionLog({
    required String contactId,
    required String contactName,
    required String title,
    required String content,
    String? emotionalTone,
    String? topicArea,
    InteractionLogType source = InteractionLogType.manual,
    String? aiAnalysis,
    String? relatedTaskId,
    List<String> tags = const [],
    DateTime? occurredAt,
  }) async {
    final log = InteractionLog(
      id: _uuid.v4(),
      contactId: contactId,
      contactName: contactName,
      title: title,
      content: content,
      emotionalTone: emotionalTone,
      topicArea: topicArea,
      source: source,
      aiAnalysis: aiAnalysis,
      relatedTaskId: relatedTaskId,
      tags: tags,
      occurredAt: occurredAt ?? DateTime.now(),
      createdAt: DateTime.now(),
    );

    final list = _logs.putIfAbsent(contactId, () => []);
    list.insert(0, log);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_logsKey$contactId',
      list.map((l) => l.toJson().toString()).toList(),
    );

    notifyListeners();
  }

  Future<void> removeInteractionLog({
    required String contactId,
    required String logId,
  }) async {
    final list = _logs[contactId];
    if (list != null) {
      list.removeWhere((l) => l.id == logId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        '$_logsKey$contactId',
        list.map((l) => l.toJson().toString()).toList(),
      );
      notifyListeners();
    }
  }

  Future<void> analyzeInteractionWithAI({
    required String contactId,
    required String contactName,
    required String content,
  }) async {
    final aiResult = _performSimpleAnalysis(content);

    await addInteractionLog(
      contactId: contactId,
      contactName: contactName,
      title: 'AI分析: ${content.substring(0, content.length > 20 ? 20 : content.length)}...',
      content: content,
      emotionalTone: aiResult['emotionalTone'],
      topicArea: aiResult['topicArea'],
      source: InteractionLogType.internalAI,
      aiAnalysis: aiResult['analysis'],
      tags: List<String>.from(aiResult['tags'] ?? []),
    );

    final social = getSocial(contactId);
    final warmthChange = aiResult['warmthChange'] as int? ?? 0;
    if (warmthChange != 0) {
      final newWarmth = (social.warmthLevel + warmthChange).clamp(1, 10);
      await updateSocial(
        contactId: contactId,
        warmthLevel: newWarmth,
      );
    }
  }

  Map<String, dynamic> _performSimpleAnalysis(String content) {
    final lower = content.toLowerCase();

    String emotionalTone = '中性';
    if (lower.contains('开心') || lower.contains('高兴') || lower.contains('喜欢') ||
        lower.contains('哈哈') || lower.contains('😊') || lower.contains('👍')) {
      emotionalTone = '积极';
    } else if (lower.contains('难过') || lower.contains('生气') || lower.contains('讨厌') ||
        lower.contains('烦') || lower.contains('😞') || lower.contains('😠')) {
      emotionalTone = '消极';
    }

    String topicArea = '生活';
    if (lower.contains('工作') || lower.contains('公司') || lower.contains('项目') ||
        lower.contains('老板') || lower.contains('同事')) {
      topicArea = '工作';
    } else if (lower.contains('喜欢') || lower.contains('爱') || lower.contains('约会') ||
        lower.contains('浪漫') || lower.contains('对象')) {
      topicArea = '情感';
    } else if (lower.contains('游戏') || lower.contains('电影') || lower.contains('音乐') ||
        lower.contains('美食') || lower.contains('旅行')) {
      topicArea = '兴趣';
    }

    final tags = <String>[emotionalTone, topicArea];

    int warmthChange = 0;
    if (emotionalTone == '积极') warmthChange = 1;
    if (emotionalTone == '消极') warmthChange = -1;

    final analysis = '''
【互动分析】
- 情绪基调: $emotionalTone
- 话题领域: $topicArea
- 关系温度变化: ${warmthChange >= 0 ? '+' : ''}$warmthChange
- 建议: 根据此次互动情况，${warmthChange > 0 ? '关系有所升温' : warmthChange < 0 ? '需要加强联系修复关系' : '保持当前频率即可'}
''';

    return {
      'emotionalTone': emotionalTone,
      'topicArea': topicArea,
      'tags': tags,
      'warmthChange': warmthChange,
      'analysis': analysis.trim(),
    };
  }

  int getInteractionCount(String contactId) {
    return _logs[contactId]?.length ?? 0;
  }

  DateTime? getLastInteractionDate(String contactId) {
    final list = _logs[contactId];
    if (list == null || list.isEmpty) return null;
    return list.first.occurredAt;
  }
}
