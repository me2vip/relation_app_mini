import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/contact.dart';
import '../../models/contact_group.dart';
import '../../models/persona.dart';
import '../../models/dynamic_post.dart';
import '../../models/temp_material.dart';
import '../../models/task.dart';
import '../../models/ai_config.dart';
import '../../services/storage_service.dart';
import '../../services/ai_service.dart';

class PersonaProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<ContactGroup> _groups = [];
  List<Persona> _personas = [];
  List<DynamicPost> _dynamicPosts = [];
  List<TempMaterial> _tempMaterials = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;

  List<ContactGroup> get groups => _groups;
  List<Persona> get personas => _personas;
  List<DynamicPost> get dynamicPosts => _dynamicPosts;
  List<TempMaterial> get tempMaterials => _tempMaterials;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;

  /// 待处理素材（尚未生成任务）
  List<TempMaterial> get pendingMaterials =>
      _tempMaterials.where((m) => m.status == TempMaterialStatus.pending).toList();

  /// 已配文案素材
  List<TempMaterial> get captionedMaterials =>
      _tempMaterials.where((m) => m.status == TempMaterialStatus.captioned).toList();

  PersonaProvider() {
    loadAll();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await DatabaseService.getAllContactGroups();
      _personas = await DatabaseService.getAllPersonas();
      _dynamicPosts = await DatabaseService.getAllDynamicPosts();
      _tempMaterials = await DatabaseService.getAllTempMaterials();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== 分组管理 ==========

  ContactGroup? getGroupById(String groupId) {
    try {
      return _groups.firstWhere((g) => g.id == groupId);
    } catch (_) {
      return null;
    }
  }

  /// 获取分组下的联系人ID列表（由 ContactProvider 注入联系人数据）
  List<String> getContactIdsInGroup(String groupId, List<Contact> contacts) {
    return contacts
        .where((c) => c.groupIds.contains(groupId))
        .map((c) => c.id)
        .toList();
  }

  Future<ContactGroup> addGroup({
    required String name,
    String? description,
    String? icon,
    int? color,
  }) async {
    final now = DateTime.now();
    final group = ContactGroup(
      id: _uuid.v4(),
      name: name,
      description: description,
      icon: icon,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await DatabaseService.saveContactGroup(group);
      await loadAll();
      return group;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGroup(ContactGroup group) async {
    try {
      final updated = group.copyWith(updatedAt: DateTime.now());
      await DatabaseService.saveContactGroup(updated);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await DatabaseService.deleteContactGroup(groupId);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 将联系人移入分组（追加，支持多分组）
  Future<void> addContactToGroup(Contact contact, String groupId) async {
    final existing = contact.groupIds;
    if (existing.contains(groupId)) return;
    final updated = contact.copyWith(
      groupId: [...existing, groupId].join(','),
      updatedAt: DateTime.now(),
    );
    try {
      await DatabaseService.saveContact(updated);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 将联系人移出分组
  Future<void> removeContactFromGroup(Contact contact, String groupId) async {
    final remaining = contact.groupIds.where((g) => g != groupId).toList();
    final updated = contact.copyWith(
      groupId: remaining.isEmpty ? null : remaining.join(','),
      updatedAt: DateTime.now(),
    );
    try {
      await DatabaseService.saveContact(updated);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  ContactGroup createEmptyGroup() {
    final now = DateTime.now();
    return ContactGroup(
      id: _uuid.v4(),
      name: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  // ========== 人设管理 ==========

  Persona? getPersonaById(String personaId) {
    try {
      return _personas.firstWhere((p) => p.id == personaId);
    } catch (_) {
      return null;
    }
  }

  /// 获取某分组的人设（每组一个人设）
  Persona? getPersonaByGroupId(String groupId) {
    try {
      return _personas.firstWhere((p) => p.groupId == groupId);
    } catch (_) {
      return null;
    }
  }

  Future<Persona> addPersona({
    required String name,
    required String groupId,
    required String roleDescription,
    String? description,
    List<String> traits = const [],
    String postingStyle = '',
    List<String> contentThemes = const [],
    String toneGuidelines = '',
    List<String> forbiddenTopics = const [],
  }) async {
    final now = DateTime.now();
    final persona = Persona(
      id: _uuid.v4(),
      name: name,
      description: description,
      groupId: groupId,
      roleDescription: roleDescription,
      traits: traits,
      postingStyle: postingStyle,
      contentThemes: contentThemes,
      toneGuidelines: toneGuidelines,
      forbiddenTopics: forbiddenTopics,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await DatabaseService.savePersona(persona);
      await loadAll();
      return persona;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePersona(Persona persona) async {
    try {
      final updated = persona.copyWith(updatedAt: DateTime.now());
      await DatabaseService.savePersona(updated);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePersona(String personaId) async {
    try {
      await DatabaseService.deletePersona(personaId);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Persona createEmptyPersona(String groupId) {
    final now = DateTime.now();
    return Persona(
      id: _uuid.v4(),
      name: '',
      groupId: groupId,
      roleDescription: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  // ========== 人设动态管理 ==========

  List<DynamicPost> getPostsByPersona(String personaId) {
    return _dynamicPosts.where((p) => p.personaId == personaId).toList();
  }

  List<DynamicPost> getPostsByGroup(String groupId) {
    return _dynamicPosts.where((p) => p.groupId == groupId).toList();
  }

  Future<DynamicPost> addDynamicPost({
    required String personaId,
    required String groupId,
    required DynamicContentType contentType,
    required String content,
    List<String> mediaPaths = const [],
    DynamicPostStatus status = DynamicPostStatus.draft,
    DateTime? scheduledAt,
  }) async {
    final now = DateTime.now();
    final post = DynamicPost(
      id: _uuid.v4(),
      personaId: personaId,
      groupId: groupId,
      contentType: contentType,
      content: content,
      mediaPaths: mediaPaths,
      status: status,
      scheduledAt: scheduledAt,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await DatabaseService.saveDynamicPost(post);
      await loadAll();
      return post;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDynamicPost(DynamicPost post) async {
    try {
      final updated = post.copyWith(updatedAt: DateTime.now());
      await DatabaseService.saveDynamicPost(updated);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDynamicPost(String postId) async {
    try {
      await DatabaseService.deleteDynamicPost(postId);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ========== 临时素材管理 ==========

  Future<TempMaterial> addTempMaterial({
    required String groupId,
    String? personaId,
    required TempMaterialType materialType,
    String? filePath,
    String? textContent,
  }) async {
    // 未指定人设时，自动识别分组对应的人设
    final effectivePersonaId = personaId ?? getPersonaByGroupId(groupId)?.id;
    final material = TempMaterial(
      id: _uuid.v4(),
      groupId: groupId,
      personaId: effectivePersonaId,
      materialType: materialType,
      filePath: filePath,
      textContent: textContent,
      createdAt: DateTime.now(),
    );
    try {
      await DatabaseService.saveTempMaterial(material);
      await loadAll();
      return material;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTempMaterial(String materialId) async {
    try {
      await DatabaseService.deleteTempMaterial(materialId);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// AI 为临时素材配文案（按照对应分组的人设风格）
  Future<String?> generateCaptionForMaterial(String materialId) async {
    final material = _tempMaterials.firstWhere((m) => m.id == materialId);
    final persona = material.personaId != null
        ? getPersonaById(material.personaId!)
        : getPersonaByGroupId(material.groupId);
    if (persona == null) {
      _errorMessage = '该分组尚未配置人设，请先创建人设';
      notifyListeners();
      return null;
    }

    final model = await DatabaseService.getDefaultAIModel();
    if (model == null || model.isExternal) {
      _errorMessage = '请先配置可用的AI模型';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    notifyListeners();

    try {
      final group = getGroupById(material.groupId);
      final systemPrompt = persona.buildSystemPrompt(groupName: group?.name);

      // 组装用户消息：包含素材内容描述
      final contentParts = <String>[];
      if (material.textContent != null && material.textContent!.isNotEmpty) {
        contentParts.add('素材内容：${material.textContent}');
      }
      if (material.filePath != null && material.filePath!.isNotEmpty) {
        contentParts.add('素材文件：${material.filePath}');
      }
      final userPrompt = contentParts.isEmpty
          ? '请根据这个素材，按照人设风格写一条发朋友圈的文案。'
          : '${contentParts.join('\n')}\n\n请根据以上素材，按照人设风格写一条发朋友圈的文案，要求自然真实、符合人设，不要出现任何禁忌话题。';

      // 图片素材且模型支持视觉时，附上图片
      final attachments = <AIFile>[];
      if (material.materialType == TempMaterialType.image &&
          material.filePath != null &&
          model.supportsVision) {
        attachments.add(AIFile(
          id: _uuid.v4(),
          name: 'material_${material.id}.jpg',
          type: 'image',
          path: material.filePath!,
        ));
      }

      final aiMessage = await AIService.chat(
        model: model,
        messages: [
          AIMessage(
            id: _uuid.v4(),
            role: 'user',
            content: userPrompt,
            attachments: attachments.isEmpty ? null : attachments,
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: systemPrompt,
      );

      final caption = aiMessage.content.trim();
      final updated = material.copyWith(
        aiCaption: caption,
        status: TempMaterialStatus.captioned,
      );
      await DatabaseService.saveTempMaterial(updated);
      await loadAll();

      _isGenerating = false;
      notifyListeners();
      return caption;
    } catch (e) {
      _errorMessage = e.toString();
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  /// 为素材重新识别分组和人设
  Future<void> reassignMaterial(String materialId, {required String groupId, String? personaId}) async {
    final material = _tempMaterials.firstWhere((m) => m.id == materialId);
    final updated = material.copyWith(
      groupId: groupId,
      personaId: personaId ?? getPersonaByGroupId(groupId)?.id,
      status: TempMaterialStatus.pending,
      aiCaption: null,
    );
    try {
      await DatabaseService.saveTempMaterial(updated);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ========== 生成发朋友圈任务 ==========

  /// 将已配文案的素材生成为发朋友圈任务
  /// 返回创建的动态和任务；contact 由主界面持有联系人列表，用于任务关联
  Future<(DynamicPost, SocialTask)?> generatePostingTask(
    String materialId, {
    DateTime? scheduledAt,
  }) async {
    final material = _tempMaterials.firstWhere((m) => m.id == materialId);
    if (material.aiCaption == null || material.aiCaption!.isEmpty) {
      _errorMessage = '请先为素材生成文案';
      notifyListeners();
      return null;
    }
    final persona = material.personaId != null
        ? getPersonaById(material.personaId!)
        : getPersonaByGroupId(material.groupId);
    if (persona == null) {
      _errorMessage = '该分组尚未配置人设';
      notifyListeners();
      return null;
    }
    final group = getGroupById(material.groupId);

    try {
      // 1. 创建人设动态
      final now = DateTime.now();
      final contentType = material.materialType == TempMaterialType.text
          ? DynamicContentType.text
          : material.materialType == TempMaterialType.image
              ? DynamicContentType.image
              : DynamicContentType.video;
      final post = DynamicPost(
        id: _uuid.v4(),
        personaId: persona.id,
        groupId: material.groupId,
        contentType: contentType,
        content: material.aiCaption!,
        mediaPaths: material.filePath != null ? [material.filePath!] : [],
        status: DynamicPostStatus.taskCreated,
        scheduledAt: scheduledAt,
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseService.saveDynamicPost(post);

      // 2. 更新素材状态
      final updatedMaterial = material.copyWith(status: TempMaterialStatus.taskCreated);
      await DatabaseService.saveTempMaterial(updatedMaterial);

      // 3. 生成社交任务（发朋友圈任务）
      final task = SocialTask(
        id: _uuid.v4(),
        contactId: 'group:${material.groupId}',
        contactName: group?.name ?? '分组',
        title: '人设发圈：${persona.name}',
        description: material.aiCaption!,
        type: TaskType.socialInteraction,
        status: TaskStatus.pending,
        scheduledAt: scheduledAt ?? now.add(const Duration(hours: 1)),
        priority: 0,
        metadata: {
          'personaId': persona.id,
          'groupId': material.groupId,
          'dynamicPostId': post.id,
          'materialId': material.id,
        },
      );
      await DatabaseService.saveTask(task);

      await loadAll();
      return (post, task);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
