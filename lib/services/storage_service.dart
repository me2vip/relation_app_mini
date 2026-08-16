import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/contact.dart';
import '../models/task.dart';
import '../models/ai_config.dart';
import '../models/atmosphere.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'relation_app_mini.db';
  static const int _dbVersion = 1;

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

    // 创建索引
    await db.execute('CREATE INDEX idx_contact_methods_contact_id ON contact_methods(contact_id)');
    await db.execute('CREATE INDEX idx_interactions_contact_id ON interactions(contact_id)');
    await db.execute('CREATE INDEX idx_tasks_contact_id ON tasks(contact_id)');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_scheduled_at ON tasks(scheduled_at)');
    await db.execute('CREATE INDEX idx_ai_messages_conversation_id ON ai_messages(conversation_id)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 处理数据库升级
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
        'created_at': contact.createdAt.toIso8601String(),
        'updated_at': contact.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
      provider: AIProvider.values[m['provider'] as int],
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
}
