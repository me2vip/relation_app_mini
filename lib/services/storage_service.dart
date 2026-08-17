import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import '../models/persona.dart';
import '../models/dynamic_post.dart';
import '../models/temp_material.dart';
import '../models/task.dart';
import '../models/ai_config.dart';
import '../models/atmosphere.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'relation_app_mini.db';
  static const int _dbVersion = 3;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 联系人表
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar TEXT,
        level INTEGER NOT NULL DEFAULT 1,
        tags TEXT,
        atmosphere_profile TEXT,
        goal_relation TEXT,
        group_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 联系方式表
    await db.execute('''
      CREATE TABLE contact_methods (
        id TEXT PRIMARY KEY,
        contact_id TEXT NOT NULL,
        platform TEXT NOT NULL,
        account TEXT NOT NULL,
        remark TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
      )
    ''');

    // 互动记录表
    await db.execute('''
      CREATE TABLE interactions (
        id TEXT PRIMARY KEY,
        contact_id TEXT NOT NULL,
        type INTEGER NOT NULL,
        content TEXT NOT NULL,
        occurred_at TEXT NOT NULL,
        metadata TEXT,
        FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
      )
    ''');

    // 社交任务表
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        contact_id TEXT NOT NULL,
        contact_name TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        scheduled_at TEXT NOT NULL,
        completed_at TEXT,
        priority INTEGER DEFAULT 0,
        goal_relation TEXT,
        metadata TEXT,
        FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
      )
    ''');

    // AI模型配置表
    await db.execute('''
      CREATE TABLE ai_models (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        provider INTEGER NOT NULL,
        api_url TEXT NOT NULL,
        api_key TEXT,
        max_tokens INTEGER,
        temperature REAL,
        supports_vision INTEGER DEFAULT 0,
        supports_file_upload INTEGER DEFAULT 0,
        is_default INTEGER DEFAULT 0
      )
    ''');

    // AI对话记录表
    await db.execute('''
      CREATE TABLE ai_conversations (
        id TEXT PRIMARY KEY,
        contact_id TEXT,
        model_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // AI消息表
    await db.execute('''
      CREATE TABLE ai_messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        attachments TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES ai_conversations(id) ON DELETE CASCADE
      )
    ''');

    // 氛围配置表
    await db.execute('''
      CREATE TABLE atmosphere_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        items TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 联系人氛围设置表
    await db.execute('''
      CREATE TABLE contact_atmosphere (
        id TEXT PRIMARY KEY,
        contact_id TEXT NOT NULL UNIQUE,
        profile_id TEXT NOT NULL,
        exposed_fields TEXT NOT NULL,
        hidden_fields TEXT NOT NULL,
        use_custom_settings INTEGER DEFAULT 0,
        FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
      )
    ''');

    // 任务调度表
    await db.execute('''
      CREATE TABLE task_schedules (
        id TEXT PRIMARY KEY,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        weekdays TEXT,
        enabled INTEGER DEFAULT 1
      )
    ''');

    // 关系变化（升迁）跟踪表
    await db.execute('''
      CREATE TABLE relationship_changes (
        id TEXT PRIMARY KEY,
        contact_id TEXT NOT NULL,
        from_level INTEGER NOT NULL,
        to_level INTEGER NOT NULL,
        type INTEGER NOT NULL,
        reason TEXT NOT NULL,
        changed_at TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
      )
    ''');

    // 联系人分组表
    await db.execute('''
      CREATE TABLE contact_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        color INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 人设表
    await db.execute('''
      CREATE TABLE personas (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        group_id TEXT NOT NULL,
        role_description TEXT NOT NULL,
        traits TEXT,
        posting_style TEXT,
        content_themes TEXT,
        tone_guidelines TEXT,
        forbidden_topics TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES contact_groups(id) ON DELETE CASCADE
      )
    ''');

    // 人设动态表
    await db.execute('''
      CREATE TABLE dynamic_posts (
        id TEXT PRIMARY KEY,
        persona_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        content_type INTEGER NOT NULL,
        content TEXT NOT NULL,
        media_paths TEXT,
        status INTEGER NOT NULL DEFAULT 0,
        scheduled_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (persona_id) REFERENCES personas(id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES contact_groups(id) ON DELETE CASCADE
      )
    ''');

    // 临时素材表
    await db.execute('''
      CREATE TABLE temp_materials (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        persona_id TEXT,
        material_type INTEGER NOT NULL,
        file_path TEXT,
        text_content TEXT,
        ai_caption TEXT,
        status INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES contact_groups(id) ON DELETE CASCADE
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_contact_methods_contact_id ON contact_methods(contact_id)');
    await db.execute('CREATE INDEX idx_interactions_contact_id ON interactions(contact_id)');
    await db.execute('CREATE INDEX idx_tasks_contact_id ON tasks(contact_id)');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_scheduled_at ON tasks(scheduled_at)');
    await db.execute('CREATE INDEX idx_ai_messages_conversation_id ON ai_messages(conversation_id)');
    await db.execute('CREATE INDEX idx_relationship_changes_contact_id ON relationship_changes(contact_id)');
    await db.execute('CREATE INDEX idx_personas_group_id ON personas(group_id)');
    await db.execute('CREATE INDEX idx_dynamic_posts_persona_id ON dynamic_posts(persona_id)');
    await db.execute('CREATE INDEX idx_dynamic_posts_group_id ON dynamic_posts(group_id)');
    await db.execute('CREATE INDEX idx_temp_materials_group_id ON temp_materials(group_id)');
    await db.execute('CREATE INDEX idx_temp_materials_status ON temp_materials(status)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS relationship_changes (
          id TEXT PRIMARY KEY,
          contact_id TEXT NOT NULL,
          from_level INTEGER NOT NULL,
          to_level INTEGER NOT NULL,
          type INTEGER NOT NULL,
          reason TEXT NOT NULL,
          changed_at TEXT NOT NULL,
          FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_relationship_changes_contact_id ON relationship_changes(contact_id)');
    }
    if (oldVersion < 3) {
      // contacts 表加 group_id 列
      await db.execute('ALTER TABLE contacts ADD COLUMN group_id TEXT');

      // 联系人分组表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS contact_groups (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          icon TEXT,
          color INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // 人设表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS personas (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          group_id TEXT NOT NULL,
          role_description TEXT NOT NULL,
          traits TEXT,
          posting_style TEXT,
          content_themes TEXT,
          tone_guidelines TEXT,
          forbidden_topics TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (group_id) REFERENCES contact_groups(id) ON DELETE CASCADE
        )
      ''');

      // 人设动态表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dynamic_posts (
          id TEXT PRIMARY KEY,
          persona_id TEXT NOT NULL,
          group_id TEXT NOT NULL,
          content_type INTEGER NOT NULL,
          content TEXT NOT NULL,
          media_paths TEXT,
          status INTEGER NOT NULL DEFAULT 0,
          scheduled_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (persona_id) REFERENCES personas(id) ON DELETE CASCADE,
          FOREIGN KEY (group_id) REFERENCES contact_groups(id) ON DELETE CASCADE
        )
      ''');

      // 临时素材表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS temp_materials (
          id TEXT PRIMARY KEY,
          group_id TEXT NOT NULL,
          persona_id TEXT,
          material_type INTEGER NOT NULL,
          file_path TEXT,
          text_content TEXT,
          ai_caption TEXT,
          status INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (group_id) REFERENCES contact_groups(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_personas_group_id ON personas(group_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_dynamic_posts_persona_id ON dynamic_posts(persona_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_dynamic_posts_group_id ON dynamic_posts(group_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_temp_materials_group_id ON temp_materials(group_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_temp_materials_status ON temp_materials(status)');
    }
  }

  // ========== 联系人操作 ==========
  
  static Future<List<Contact>> getAllContacts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      orderBy: 'updated_at DESC',
    );
    
    final contacts = <Contact>[];
    for (final map in maps) {
      final methods = await getContactMethods(map['id'] as String);
      final interactions = await getContactInteractions(map['id'] as String);
      contacts.add(Contact(
        id: map['id'] as String,
        name: map['name'] as String,
        avatar: map['avatar'] as String?,
        level: ContactLevel.values[map['level'] as int],
        methods: methods,
        tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
        atmosphereProfile: map['atmosphere_profile'] as String?,
        goalRelation: map['goal_relation'] as String?,
        groupId: map['group_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        interactions: interactions,
      ));
    }
    return contacts;
  }

  static Future<Contact?> getContact(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    
    final map = maps.first;
    final methods = await getContactMethods(id);
    final interactions = await getContactInteractions(id);
    
    return Contact(
      id: map['id'] as String,
      name: map['name'] as String,
      avatar: map['avatar'] as String?,
      level: ContactLevel.values[map['level'] as int],
      methods: methods,
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      atmosphereProfile: map['atmosphere_profile'] as String?,
      goalRelation: map['goal_relation'] as String?,
      groupId: map['group_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      interactions: interactions,
    );
  }

  static Future<void> saveContact(Contact contact) async {
    final db = await database;
    await db.insert(
      'contacts',
      {
        'id': contact.id,
        'name': contact.name,
        'avatar': contact.avatar,
        'level': contact.level.index,
        'tags': contact.tags.join(','),
        'atmosphere_profile': contact.atmosphereProfile,
        'goal_relation': contact.goalRelation,
        'group_id': contact.groupId,
        'created_at': contact.createdAt.toIso8601String(),
        'updated_at': contact.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取某个分组的联系人列表
  static Future<List<Contact>> getContactsByGroupId(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      orderBy: 'updated_at DESC',
    );
    final contacts = <Contact>[];
    for (final map in maps) {
      final groupIds = (map['group_id'] as String?)?.split(',').where((g) => g.isNotEmpty).toList() ?? [];
      if (!groupIds.contains(groupId)) continue;
      final methods = await getContactMethods(map['id'] as String);
      final interactions = await getContactInteractions(map['id'] as String);
      contacts.add(Contact(
        id: map['id'] as String,
        name: map['name'] as String,
        avatar: map['avatar'] as String?,
        level: ContactLevel.values[map['level'] as int],
        methods: methods,
        tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
        atmosphereProfile: map['atmosphere_profile'] as String?,
        goalRelation: map['goal_relation'] as String?,
        groupId: map['group_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        interactions: interactions,
      ));
    }
    return contacts;
  }

  static Future<void> deleteContact(String id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 联系方式操作 ==========
  
  static Future<List<ContactMethod>> getContactMethods(String contactId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contact_methods',
      where: 'contact_id = ?',
      whereArgs: [contactId],
    );
    return maps.map((m) => ContactMethod(
      id: m['id'] as String,
      platform: m['platform'] as String,
      account: m['account'] as String,
      remark: m['remark'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
    )).toList();
  }

  static Future<void> saveContactMethod(ContactMethod method) async {
    final db = await database;
    await db.insert(
      'contact_methods',
      {
        'id': method.id,
        'contact_id': method.id, // 会话外层传入
        'platform': method.platform,
        'account': method.account,
        'remark': method.remark,
        'created_at': method.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========== 互动记录操作 ==========
  
  static Future<List<Interaction>> getContactInteractions(String contactId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'interactions',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'occurred_at DESC',
    );
    return maps.map((m) => Interaction(
      id: m['id'] as String,
      contactId: m['contact_id'] as String,
      type: InteractionType.values[m['type'] as int],
      content: m['content'] as String,
      occurredAt: DateTime.parse(m['occurred_at'] as String),
      metadata: m['metadata'] != null ? jsonDecode(m['metadata'] as String) : null,
    )).toList();
  }

  static Future<void> saveInteraction(Interaction interaction) async {
    final db = await database;
    await db.insert(
      'interactions',
      {
        'id': interaction.id,
        'contact_id': interaction.contactId,
        'type': interaction.type.index,
        'content': interaction.content,
        'occurred_at': interaction.occurredAt.toIso8601String(),
        'metadata': interaction.metadata != null ? jsonEncode(interaction.metadata) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========== 关系变化（升迁）跟踪操作 ==========

  static Future<void> saveRelationshipChange(RelationshipChange change) async {
    final db = await database;
    await db.insert(
      'relationship_changes',
      {
        'id': change.id,
        'contact_id': change.contactId,
        'from_level': change.fromLevel.index,
        'to_level': change.toLevel.index,
        'type': change.type.index,
        'reason': change.reason,
        'changed_at': change.changedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<RelationshipChange>> getRelationshipChanges(String contactId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'relationship_changes',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'changed_at DESC',
    );
    return maps.map((m) => RelationshipChange(
      id: m['id'] as String,
      contactId: m['contact_id'] as String,
      fromLevel: ContactLevel.values[m['from_level'] as int],
      toLevel: ContactLevel.values[m['to_level'] as int],
      type: RelationshipChangeType.values[m['type'] as int],
      reason: m['reason'] as String,
      changedAt: DateTime.parse(m['changed_at'] as String),
    )).toList();
  }

  static Future<List<RelationshipChange>> getAllRelationshipChanges() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'relationship_changes',
      orderBy: 'changed_at DESC',
    );
    return maps.map((m) => RelationshipChange(
      id: m['id'] as String,
      contactId: m['contact_id'] as String,
      fromLevel: ContactLevel.values[m['from_level'] as int],
      toLevel: ContactLevel.values[m['to_level'] as int],
      type: RelationshipChangeType.values[m['type'] as int],
      reason: m['reason'] as String,
      changedAt: DateTime.parse(m['changed_at'] as String),
    )).toList();
  }

  // ========== 任务操作 ==========
  
  static Future<List<SocialTask>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'scheduled_at ASC',
    );
    return maps.map((m) => SocialTask(
      id: m['id'] as String,
      contactId: m['contact_id'] as String,
      contactName: m['contact_name'] as String,
      title: m['title'] as String,
      description: m['description'] as String,
      type: TaskType.values[m['type'] as int],
      status: TaskStatus.values[m['status'] as int],
      scheduledAt: DateTime.parse(m['scheduled_at'] as String),
      completedAt: m['completed_at'] != null 
          ? DateTime.parse(m['completed_at'] as String) 
          : null,
      priority: m['priority'] as int? ?? 0,
      goalRelation: m['goal_relation'] as String?,
      metadata: m['metadata'] != null ? jsonDecode(m['metadata'] as String) : null,
    )).toList();
  }

  static Future<List<SocialTask>> getPendingTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'status = ?',
      whereArgs: [TaskStatus.pending.index],
      orderBy: 'priority DESC, scheduled_at ASC',
    );
    return maps.map((m) => SocialTask(
      id: m['id'] as String,
      contactId: m['contact_id'] as String,
      contactName: m['contact_name'] as String,
      title: m['title'] as String,
      description: m['description'] as String,
      type: TaskType.values[m['type'] as int],
      status: TaskStatus.values[m['status'] as int],
      scheduledAt: DateTime.parse(m['scheduled_at'] as String),
      completedAt: null,
      priority: m['priority'] as int? ?? 0,
      goalRelation: m['goal_relation'] as String?,
    )).toList();
  }

  static Future<void> saveTask(SocialTask task) async {
    final db = await database;
    await db.insert(
      'tasks',
      {
        'id': task.id,
        'contact_id': task.contactId,
        'contact_name': task.contactName,
        'title': task.title,
        'description': task.description,
        'type': task.type.index,
        'status': task.status.index,
        'scheduled_at': task.scheduledAt.toIso8601String(),
        'completed_at': task.completedAt?.toIso8601String(),
        'priority': task.priority,
        'goal_relation': task.goalRelation,
        'metadata': task.metadata != null ? jsonEncode(task.metadata) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateTaskStatus(String id, TaskStatus status) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        'status': status.index,
        'completed_at': status == TaskStatus.completed 
            ? DateTime.now().toIso8601String() 
            : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== AI模型操作 ==========
  
  static Future<List<AIModel>> getAllAIModels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('ai_models');
    return maps.map((m) => AIModel(
      id: m['id'] as String,
      name: m['name'] as String,
      provider: AIModelProvider.values[m['provider'] as int],
      apiUrl: m['api_url'] as String,
      apiKey: m['api_key'] as String?,
      maxTokens: m['max_tokens'] as int?,
      temperature: (m['temperature'] as num?)?.toDouble(),
      supportsVision: (m['supports_vision'] as int?) == 1,
      supportsFileUpload: (m['supports_file_upload'] as int?) == 1,
      isDefault: (m['is_default'] as int?) == 1,
    )).toList();
  }

  static Future<AIModel?> getDefaultAIModel() async {
    final models = await getAllAIModels();
    return models.isEmpty ? null : models.firstWhere(
      (m) => m.isDefault, 
      orElse: () => models.first,
    );
  }

  static Future<void> saveAIModel(AIModel model) async {
    final db = await database;
    await db.insert(
      'ai_models',
      {
        'id': model.id,
        'name': model.name,
        'provider': model.provider.index,
        'api_url': model.apiUrl,
        'api_key': model.apiKey,
        'max_tokens': model.maxTokens,
        'temperature': model.temperature,
        'supports_vision': model.supportsVision ? 1 : 0,
        'supports_file_upload': model.supportsFileUpload ? 1 : 0,
        'is_default': model.isDefault ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========== 氛围配置操作 ==========
  
  static Future<List<AtmosphereProfile>> getAllAtmosphereProfiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'atmosphere_profiles',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) {
      final itemsJson = jsonDecode(m['items'] as String) as Map<String, dynamic>;
      final items = itemsJson.map(
        (k, v) => MapEntry(k, (v as List).map((i) => AtmosphereItem.fromJson(i)).toList()),
      );
      return AtmosphereProfile(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        items: items,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
    }).toList();
  }

  static Future<void> saveAtmosphereProfile(AtmosphereProfile profile) async {
    final db = await database;
    await db.insert(
      'atmosphere_profiles',
      {
        'id': profile.id,
        'name': profile.name,
        'description': profile.description,
        'items': jsonEncode(profile.items.map(
          (k, v) => MapEntry(k, v.map((i) => i.toJson()).toList()),
        )),
        'created_at': profile.createdAt.toIso8601String(),
        'updated_at': profile.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<ContactAtmosphereSetting?> getContactAtmosphere(String contactId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contact_atmosphere',
      where: 'contact_id = ?',
      whereArgs: [contactId],
    );
    if (maps.isEmpty) return null;
    final m = maps.first;
    return ContactAtmosphereSetting(
      id: m['id'] as String,
      contactId: m['contact_id'] as String,
      profileId: m['profile_id'] as String,
      exposedFields: List<String>.from(jsonDecode(m['exposed_fields'] as String)),
      hiddenFields: List<String>.from(jsonDecode(m['hidden_fields'] as String)),
      useCustomSettings: (m['use_custom_settings'] as int?) == 1,
    );
  }

  static Future<void> saveContactAtmosphere(ContactAtmosphereSetting setting) async {
    final db = await database;
    await db.insert(
      'contact_atmosphere',
      {
        'id': setting.id,
        'contact_id': setting.contactId,
        'profile_id': setting.profileId,
        'exposed_fields': jsonEncode(setting.exposedFields),
        'hidden_fields': jsonEncode(setting.hiddenFields),
        'use_custom_settings': setting.useCustomSettings ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========== 任务调度操作 ==========
  
  static Future<List<TaskSchedule>> getTaskSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('task_schedules');
    return maps.map((m) => TaskSchedule(
      id: m['id'] as String,
      hour: m['hour'] as int,
      minute: m['minute'] as int,
      weekdays: (m['weekdays'] as String?)?.split(',').where((w) => w.isNotEmpty).map((w) => int.parse(w)).toList() ?? [],
      enabled: (m['enabled'] as int?) == 1,
    )).toList();
  }

  static Future<void> saveTaskSchedule(TaskSchedule schedule) async {
    final db = await database;
    await db.insert(
      'task_schedules',
      {
        'id': schedule.id,
        'hour': schedule.hour,
        'minute': schedule.minute,
        'weekdays': schedule.weekdays.join(','),
        'enabled': schedule.enabled ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========== 联系人分组操作 ==========

  static Future<List<ContactGroup>> getAllContactGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contact_groups',
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => ContactGroup(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String?,
      icon: m['icon'] as String?,
      color: m['color'] as int?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    )).toList();
  }

  static Future<ContactGroup?> getContactGroup(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contact_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final m = maps.first;
    return ContactGroup(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String?,
      icon: m['icon'] as String?,
      color: m['color'] as int?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }

  static Future<void> saveContactGroup(ContactGroup group) async {
    final db = await database;
    await db.insert(
      'contact_groups',
      {
        'id': group.id,
        'name': group.name,
        'description': group.description,
        'icon': group.icon,
        'color': group.color,
        'created_at': group.createdAt.toIso8601String(),
        'updated_at': group.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteContactGroup(String id) async {
    final db = await database;
    await db.delete('contact_groups', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 人设操作 ==========

  static Future<List<Persona>> getAllPersonas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'personas',
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => _personaFromMap(m)).toList();
  }

  static Future<Persona?> getPersona(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'personas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _personaFromMap(maps.first);
  }

  static Future<Persona?> getPersonaByGroupId(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'personas',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    if (maps.isEmpty) return null;
    return _personaFromMap(maps.first);
  }

  static Persona _personaFromMap(Map<String, dynamic> m) => Persona(
    id: m['id'] as String,
    name: m['name'] as String,
    description: m['description'] as String?,
    groupId: m['group_id'] as String,
    roleDescription: m['role_description'] as String,
    traits: (m['traits'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
    postingStyle: m['posting_style'] as String? ?? '',
    contentThemes: (m['content_themes'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
    toneGuidelines: m['tone_guidelines'] as String? ?? '',
    forbiddenTopics: (m['forbidden_topics'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );

  static Future<void> savePersona(Persona persona) async {
    final db = await database;
    await db.insert(
      'personas',
      {
        'id': persona.id,
        'name': persona.name,
        'description': persona.description,
        'group_id': persona.groupId,
        'role_description': persona.roleDescription,
        'traits': persona.traits.join(','),
        'posting_style': persona.postingStyle,
        'content_themes': persona.contentThemes.join(','),
        'tone_guidelines': persona.toneGuidelines,
        'forbidden_topics': persona.forbiddenTopics.join(','),
        'created_at': persona.createdAt.toIso8601String(),
        'updated_at': persona.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deletePersona(String id) async {
    final db = await database;
    await db.delete('personas', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 人设动态操作 ==========

  static Future<List<DynamicPost>> getAllDynamicPosts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dynamic_posts',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => _dynamicPostFromMap(m)).toList();
  }

  static Future<DynamicPost?> getDynamicPost(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dynamic_posts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _dynamicPostFromMap(maps.first);
  }

  static Future<List<DynamicPost>> getDynamicPostsByPersona(String personaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dynamic_posts',
      where: 'persona_id = ?',
      whereArgs: [personaId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => _dynamicPostFromMap(m)).toList();
  }

  static Future<List<DynamicPost>> getDynamicPostsByGroup(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dynamic_posts',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => _dynamicPostFromMap(m)).toList();
  }

  static DynamicPost _dynamicPostFromMap(Map<String, dynamic> m) => DynamicPost(
    id: m['id'] as String,
    personaId: m['persona_id'] as String,
    groupId: m['group_id'] as String,
    contentType: DynamicContentType.values[m['content_type'] as int],
    content: m['content'] as String,
    mediaPaths: (m['media_paths'] as String?)?.split('\n').where((p) => p.isNotEmpty).toList() ?? [],
    status: DynamicPostStatus.values[m['status'] as int],
    scheduledAt: m['scheduled_at'] != null
        ? DateTime.parse(m['scheduled_at'] as String)
        : null,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );

  static Future<void> saveDynamicPost(DynamicPost post) async {
    final db = await database;
    await db.insert(
      'dynamic_posts',
      {
        'id': post.id,
        'persona_id': post.personaId,
        'group_id': post.groupId,
        'content_type': post.contentType.index,
        'content': post.content,
        'media_paths': post.mediaPaths.join('\n'),
        'status': post.status.index,
        'scheduled_at': post.scheduledAt?.toIso8601String(),
        'created_at': post.createdAt.toIso8601String(),
        'updated_at': post.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteDynamicPost(String id) async {
    final db = await database;
    await db.delete('dynamic_posts', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 临时素材操作 ==========

  static Future<List<TempMaterial>> getAllTempMaterials() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'temp_materials',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => _tempMaterialFromMap(m)).toList();
  }

  static Future<TempMaterial?> getTempMaterial(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'temp_materials',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _tempMaterialFromMap(maps.first);
  }

  static Future<List<TempMaterial>> getTempMaterialsByGroup(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'temp_materials',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => _tempMaterialFromMap(m)).toList();
  }

  static Future<List<TempMaterial>> getTempMaterialsByStatus(TempMaterialStatus status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'temp_materials',
      where: 'status = ?',
      whereArgs: [status.index],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => _tempMaterialFromMap(m)).toList();
  }

  static TempMaterial _tempMaterialFromMap(Map<String, dynamic> m) => TempMaterial(
    id: m['id'] as String,
    groupId: m['group_id'] as String,
    personaId: m['persona_id'] as String?,
    materialType: TempMaterialType.values[m['material_type'] as int],
    filePath: m['file_path'] as String?,
    textContent: m['text_content'] as String?,
    aiCaption: m['ai_caption'] as String?,
    status: TempMaterialStatus.values[m['status'] as int],
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  static Future<void> saveTempMaterial(TempMaterial material) async {
    final db = await database;
    await db.insert(
      'temp_materials',
      {
        'id': material.id,
        'group_id': material.groupId,
        'persona_id': material.personaId,
        'material_type': material.materialType.index,
        'file_path': material.filePath,
        'text_content': material.textContent,
        'ai_caption': material.aiCaption,
        'status': material.status.index,
        'created_at': material.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteTempMaterial(String id) async {
    final db = await database;
    await db.delete('temp_materials', where: 'id = ?', whereArgs: [id]);
  }
}
