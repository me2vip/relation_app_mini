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

/// 社交人设 + 临时素材 + 动态任务管理
///
/// 1. 人设 = 信息暴露方案（工作/学习/公司/薪资等），可增删改查
/// 2. 分组 = 联系人分组，可绑定人设
/// 3. 临时素材 = 用户照片/文字 → 判断可暴露分组 → 分别为每组配文案 → 生成发圈任务
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

  List<ContactGroup> getGroupsByIds(List<String> groupIds) {
    return _groups.where((g) => groupIds.contains(g.id)).toList();
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

  ContactGroup createEmptyGroup() {
    final now = DateTime.now();
    return ContactGroup(
      id: _uuid.v4(),
      name: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  // ========== 人设管理（信息暴露方案） ==========

  Persona? getPersonaById(String personaId) {
    try {
      return _personas.firstWhere((p) => p.id == personaId);
    } catch (_) {
      return null;
    }
  }

  /// 获取某分组绑定的人设
  Persona? getPersonaByGroupId(String groupId) {
    try {
      return _personas.firstWhere((p) => p.groupId == groupId);
    } catch (_) {
      return null;
    }
  }

  /// 全局人设（无分组）
  List<Persona> get globalPersonas =>
      _personas.where((p) => p.groupId == null || p.groupId!.isEmpty).toList();

  Future<Persona> addPersona({
    required String name,
    String? groupId,
    String? description,
  }) async {
    final now = DateTime.now();
    final persona = Persona(
      id: _uuid.v4(),
      name: name,
      description: description,
      groupId: groupId,
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

  Persona createEmptyPersona({String? groupId}) {
    final now = DateTime.now();
    return Persona(
      id: _uuid.v4(),
      name: '',
      groupId: groupId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 为人设添加/更新信息项
  Future<PersonaInfoItem> saveInfoItem(PersonaInfoItem item) async {
    try {
      final now = DateTime.now();
      final saved = item.id.isEmpty
          ? item.copyWith(
              id: _uuid.v4(),
              createdAt: now,
              updatedAt: now,
            )
          : item.copyWith(updatedAt: now);
      await DatabaseService.savePersonaInfoItem(saved);
      await loadAll();
      return saved;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 删除人设信息项
  Future<void> deleteInfoItem(String itemId) async {
    try {
      await DatabaseService.deletePersonaInfoItem(itemId);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ========== 联系人-人设关联 ==========

  /// 为联系人设置人设（重要等级管理用）
  Future<void> setContactPersona(String contactId, String personaId) async {
    final link = ContactPersonaLink(
      id: _uuid.v4(),
      contactId: contactId,
      personaId: personaId,
      updatedAt: DateTime.now(),
    );
    try {
      await DatabaseService.saveContactPersonaLink(link);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<ContactPersonaLink?> getContactPersona(String contactId) async {
    try {
      return await DatabaseService.getContactPersonaLink(contactId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ========== 人设动态管理 ==========

  List<DynamicPost> getPostsByPersona(String personaId) {
    return _dynamicPosts.where((p) => p.personaId == personaId).toList();
  }

  List<DynamicPost> getPostsByGroup(String groupId) {
    return _dynamicPosts.where((p) => p.groupIds.contains(groupId)).toList();
  }

  /// 全局动态（无指定分组）
  List<DynamicPost> get globalPosts =>
      _dynamicPosts.where((p) => p.groupIds.isEmpty).toList();

  Future<DynamicPost> addDynamicPost({
    String? personaId,
    List<String> groupIds = const [],
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
      groupIds: groupIds,
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
    required List<String> groupIds,
    required TempMaterialType materialType,
    List<String> filePaths = const [],
    String? textContent,
  }) async {
    final material = TempMaterial(
      id: _uuid.v4(),
      groupIds: groupIds,
      materialType: materialType,
      filePaths: filePaths,
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

  /// 更新临时素材（用于用户编辑文案后写回）
  Future<void> updateTempMaterial(TempMaterial material) async {
    try {
      await DatabaseService.saveTempMaterial(material);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 返回 groupId -> caption 的映射
  /// 如果没有配置内置AI模型，返回空Map并设置errorMessage。
  /// 注意：外部AI流程不通过本方法，用户应走 AI任务中心（导出PDF粘贴结果）。
  Future<Map<String, String>> generateCaptionsForMaterial(
      String materialId) async {
    final material = _tempMaterials.firstWhere(
      (m) => m.id == materialId,
      orElse: () => throw StateError('未找到素材记录，请返回重试'),
    );
    final model = await DatabaseService.getDefaultAIModel();
    if (model == null || model.isExternal) {
      _errorMessage = '未配置内置AI模型：可前往【我的→AI设置】添加API；或使用【AI任务中心】导出PDF，用外部AI（千问/豆包等）生成后粘贴回APP，无需配置密钥';
      notifyListeners();
      return {};
    }

    _isGenerating = true;
    notifyListeners();

    final captions = <String, String>{};
    try {
      for (final groupId in material.groupIds) {
        final group = getGroupById(groupId);
        final persona = getPersonaByGroupId(groupId);
        final systemPrompt =
            persona?.buildSystemPrompt(groupName: group?.name) ??
                '你是一个朋友圈文案助手，请根据用户提供的素材写一条自然真实的朋友圈文案。';

        final parts = <String>[];
        if (material.textContent != null && material.textContent!.isNotEmpty) {
          parts.add('素材内容：${material.textContent}');
        }
        if (material.filePaths.isNotEmpty) {
          parts.add('素材包含 ${material.filePaths.length} 张图片');
        }
        final userPrompt = parts.isEmpty
            ? '请根据这个素材写一条发朋友圈的文案。'
            : '${parts.join('\n')}\n\n请根据以上素材，写一条发朋友圈的文案。';

        // 图片素材且模型支持视觉时，附上第一张图片
        final attachments = <AIFile>[];
        if (material.materialType == TempMaterialType.image &&
            material.filePaths.isNotEmpty &&
            model.supportsVision) {
          attachments.add(AIFile(
            id: _uuid.v4(),
            name: 'material_${material.id}_$groupId.jpg',
            type: 'image',
            path: material.filePaths.first,
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
        captions[groupId] = aiMessage.content.trim();
      }

      final updated = material.copyWith(
        captionsByGroup: captions,
        aiCaption: captions.values.firstOrNull,
        status: TempMaterialStatus.captioned,
      );
      await DatabaseService.saveTempMaterial(updated);
      await loadAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
    return captions;
  }

  // ========== 生成发朋友圈任务 ==========

  /// 从已有的动态直接生成发圈任务
  Future<bool> createTaskFromPost(DynamicPost post) async {
    final groupName = post.groupIds.isEmpty
        ? '全部联系人'
        : getGroupsByIds(post.groupIds).map((g) => g.name).join('、');
    final now = DateTime.now();
    try {
      final task = SocialTask(
        id: _uuid.v4(),
        contactId: 'group:${post.groupIds.isEmpty ? 'global' : post.groupIds.first}',
        contactName: groupName,
        title: '发圈：${post.content.length > 12 ? post.content.substring(0, 12) : post.content}',
        description: post.content,
        type: TaskType.socialInteraction,
        status: TaskStatus.pending,
        scheduledAt: post.scheduledAt ?? now.add(const Duration(hours: 1)),
        priority: 0,
        metadata: {
          'personaId': post.personaId,
          'groupIds': post.groupIds,
          'dynamicPostId': post.id,
        },
      );
      await DatabaseService.saveTask(task);
      await updateDynamicPost(
        post.copyWith(status: DynamicPostStatus.taskCreated, updatedAt: now),
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 将已配文案的素材生成为发圈任务
  /// 每个分组生成一个任务（文案各自不同）
  Future<(List<DynamicPost>, List<SocialTask>)> generatePostingTasks(
    String materialId, {
    DateTime? scheduledAt,
  }) async {
    final material = _tempMaterials.firstWhere((m) => m.id == materialId);
    if (material.status != TempMaterialStatus.captioned ||
        material.captionsByGroup.isEmpty) {
      _errorMessage = '请先为素材生成文案';
      notifyListeners();
      return (<DynamicPost>[], <SocialTask>[]);
    }

    final posts = <DynamicPost>[];
    final tasks = <SocialTask>[];
    final now = DateTime.now();
    try {
      for (final groupId in material.groupIds) {
        final caption = material.captionsByGroup[groupId];
        if (caption == null || caption.isEmpty) continue;
        final group = getGroupById(groupId);
        final persona = getPersonaByGroupId(groupId);

        final contentType = material.materialType == TempMaterialType.text
            ? DynamicContentType.text
            : material.materialType == TempMaterialType.image
                ? DynamicContentType.image
                : DynamicContentType.video;

        // 1. 创建动态
        final post = DynamicPost(
          id: _uuid.v4(),
          personaId: persona?.id,
          groupIds: [groupId],
          contentType: contentType,
          content: caption,
          mediaPaths: material.filePaths,
          status: DynamicPostStatus.taskCreated,
          scheduledAt: scheduledAt,
          createdAt: now,
          updatedAt: now,
        );
        await DatabaseService.saveDynamicPost(post);
        posts.add(post);

        // 2. 生成任务
        final task = SocialTask(
          id: _uuid.v4(),
          contactId: 'group:$groupId',
          contactName: group?.name ?? '分组',
          title: '人设发圈：${persona?.name ?? '通用'}',
          description: caption,
          type: TaskType.socialInteraction,
          status: TaskStatus.pending,
          scheduledAt: scheduledAt ?? now.add(const Duration(hours: 1)),
          priority: 0,
          metadata: {
            'personaId': persona?.id,
            'groupId': groupId,
            'dynamicPostId': post.id,
            'materialId': material.id,
          },
        );
        await DatabaseService.saveTask(task);
        tasks.add(task);
      }

      // 3. 更新素材状态
      final updated = material.copyWith(status: TempMaterialStatus.taskCreated);
      await DatabaseService.saveTempMaterial(updated);
      await loadAll();
      return (posts, tasks);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return (<DynamicPost>[], <SocialTask>[]);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
