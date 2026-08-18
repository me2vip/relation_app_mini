import 'dart:convert';

/// 联系人重要层级
enum ContactLevel {
  /// 不重要
  unimportant,
  /// 一般
  normal,
  /// 重要
  important,
  /// 核心
  core,
}

/// 性别
enum Gender {
  unknown,
  male,
  female,
}

/// 婚姻状况
enum MaritalStatus {
  unknown,
  single,
  married,
  divorced,
  widowed,
  inRelationship,
}

/// 学历
enum EducationLevel {
  unknown,
  highSchool,
  vocational,
  associate,
  bachelor,
  master,
  doctoral,
}

enum InteractionType {
  /// 文字聊天
  textChat,
  /// 语音聊天
  voiceChat,
  /// 视频通话
  videoCall,
  /// 分享短视频
  shareVideo,
  /// 社交媒体互动(抖音/快手/小红书等)
  socialMedia,
  /// 其他
  other,
}

class ContactMethod {
  final String id;
  final String platform;
  final String account;
  final String? remark;
  final DateTime createdAt;

  ContactMethod({
    required this.id,
    required this.platform,
    required this.account,
    this.remark,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform,
    'account': account,
    'remark': remark,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ContactMethod.fromJson(Map<String, dynamic> json) => ContactMethod(
    id: json['id'] as String,
    platform: json['platform'] as String,
    account: json['account'] as String,
    remark: json['remark'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class Interaction {
  final String id;
  final String contactId;
  final InteractionType type;
  final String content;
  final DateTime occurredAt;
  final Map<String, dynamic>? metadata;

  Interaction({
    required this.id,
    required this.contactId,
    required this.type,
    required this.content,
    required this.occurredAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'type': type.index,
    'content': content,
    'occurredAt': occurredAt.toIso8601String(),
    'metadata': metadata,
  };

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
    id: json['id'] as String,
    contactId: json['contactId'] as String,
    type: InteractionType.values[json['type'] as int],
    content: json['content'] as String,
    occurredAt: DateTime.parse(json['occurredAt'] as String),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );

  String get typeName {
    switch (type) {
      case InteractionType.textChat: return '文字聊天';
      case InteractionType.voiceChat: return '语音聊天';
      case InteractionType.videoCall: return '视频通话';
      case InteractionType.shareVideo: return '分享视频';
      case InteractionType.socialMedia: return '社交媒体';
      case InteractionType.other: return '其他';
    }
  }
}

/// 联系人完整信息模型
///
/// 字段分组：
/// - [basicInfo]      基本信息（姓名/性别/生日等）
/// - [educationInfo]  教育背景（学历/学校/专业）
/// - [careerInfo]     职业信息（行业/公司/职位）
/// - [personalityInfo] 个性与价值观
/// - [personalInfo]   个人特质（爱好/优缺点/恐惧渴望）
/// - [familyInfo]     家庭信息
/// - [financialInfo]   经济状况
/// - [trustInfo]      信任关系
/// - [socialInfo]     社交信息
/// - [goalInfo]       目标与欲望
/// - [socialAppInfo]  社交账号信息
class Contact {
  // ===== 基本信息 =====
  final String id;
  final String name;
  final String? avatar;
  final ContactLevel level;
  final Gender gender;
  final DateTime? birthday;
  final int? age;
  final String? ethnicity;        // 民族
  final String? religion;         // 宗教信仰
  final String? politicalAffiliation; // 政治面貌
  final MaritalStatus maritalStatus;
  final EducationLevel educationLevel;
  final String? school;           // 学校
  final String? major;           // 专业
  final String? personalityTags; // 性格标签（逗号分隔）
  final String? personalityDesc; // 性格详细描述
  final String? characterTags;    // 人品标签（逗号分隔）
  final String? taboos;          // 大忌
  final String? values;          // 价值观
  final String? hobbies;         // 兴趣爱好描述
  final String? strengths;        // 优点
  final String? weaknesses;      // 缺点
  final String? fears;           // 恐惧
  final String? desires;        // 渴望
  final String? skills;         // 技能与能力
  final String? tastePreferences; // 口味偏好

  // ===== 职业 =====
  final String? industry;         // 当前行业
  final String? company;         // 公司
  final String? position;         // 职位
  final String? workExperience;  // 以前做过的行业/经历

  // ===== 家庭 =====
  final String? homeAddress;      // 家庭住址
  final String? familySituation;  // 家庭情况
  final String? familyEconomicStatus;  // 家庭经济状况
  final String? familyEmotionalStatus; // 家庭感情状况

  // ===== 信任与关系 =====
  final int taTrustLevel;   // TA对我的信任度（1-10）
  final int myTrustLevel;   // 我对TA的信任度（1-10）

  // ===== 社交与现状 =====
  final String? socialCircles;   // 所交往圈子（逗号分隔）
  final String? currentStatus;   // 目前现状
  final String? moneyDesireLevel; // 挣钱欲望（1-5）
  final String? ambitionLevel;   // 上进心情况（1-5）
  final String? shortTermGoals; // 短期目标
  final String? longTermGoals;  // 长期目标
  final String? goalRelation;    // 目标关系

  // ===== 系统字段 =====
  final List<ContactMethod> methods;  // 社交账号
  final List<String> tags;           // 自定义标签
  final String? groupId;             // 所属分组ID（逗号分隔）
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Interaction> interactions; // 历史互动记录

  Contact({
    required this.id,
    required this.name,
    this.avatar,
    required this.level,
    this.gender = Gender.unknown,
    this.birthday,
    this.age,
    this.ethnicity,
    this.religion,
    this.politicalAffiliation,
    this.maritalStatus = MaritalStatus.unknown,
    this.educationLevel = EducationLevel.unknown,
    this.school,
    this.major,
    this.personalityTags,
    this.personalityDesc,
    this.characterTags,
    this.taboos,
    this.values,
    this.hobbies,
    this.strengths,
    this.weaknesses,
    this.fears,
    this.desires,
    this.skills,
    this.tastePreferences,
    this.industry,
    this.company,
    this.position,
    this.workExperience,
    this.homeAddress,
    this.familySituation,
    this.familyEconomicStatus,
    this.familyEmotionalStatus,
    this.taTrustLevel = 5,
    this.myTrustLevel = 5,
    this.socialCircles,
    this.currentStatus,
    this.moneyDesireLevel,
    this.ambitionLevel,
    this.shortTermGoals,
    this.longTermGoals,
    this.goalRelation,
    this.methods = const [],
    this.tags = const [],
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.interactions = const [],
  });

  /// 获取联系人所属所有分组ID列表
  List<String> get groupIds {
    if (groupId == null || groupId!.isEmpty) return [];
    return groupId!.split(',').where((g) => g.isNotEmpty).toList();
  }

  Contact copyWith({
    String? id,
    String? name,
    String? avatar,
    ContactLevel? level,
    Gender? gender,
    DateTime? birthday,
    int? age,
    String? ethnicity,
    String? religion,
    String? politicalAffiliation,
    MaritalStatus? maritalStatus,
    EducationLevel? educationLevel,
    String? school,
    String? major,
    String? personalityTags,
    String? personalityDesc,
    String? characterTags,
    String? taboos,
    String? values,
    String? hobbies,
    String? strengths,
    String? weaknesses,
    String? fears,
    String? desires,
    String? skills,
    String? tastePreferences,
    String? industry,
    String? company,
    String? position,
    String? workExperience,
    String? homeAddress,
    String? familySituation,
    String? familyEconomicStatus,
    String? familyEmotionalStatus,
    int? taTrustLevel,
    int? myTrustLevel,
    String? socialCircles,
    String? currentStatus,
    String? moneyDesireLevel,
    String? ambitionLevel,
    String? shortTermGoals,
    String? longTermGoals,
    String? goalRelation,
    List<ContactMethod>? methods,
    List<String>? tags,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Interaction>? interactions,
  }) =>
      Contact(
        id: id ?? this.id,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        level: level ?? this.level,
        gender: gender ?? this.gender,
        birthday: birthday ?? this.birthday,
        age: age ?? this.age,
        ethnicity: ethnicity ?? this.ethnicity,
        religion: religion ?? this.religion,
        politicalAffiliation: politicalAffiliation ?? this.politicalAffiliation,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        educationLevel: educationLevel ?? this.educationLevel,
        school: school ?? this.school,
        major: major ?? this.major,
        personalityTags: personalityTags ?? this.personalityTags,
        personalityDesc: personalityDesc ?? this.personalityDesc,
        characterTags: characterTags ?? this.characterTags,
        taboos: taboos ?? this.taboos,
        values: values ?? this.values,
        hobbies: hobbies ?? this.hobbies,
        strengths: strengths ?? this.strengths,
        weaknesses: weaknesses ?? this.weaknesses,
        fears: fears ?? this.fears,
        desires: desires ?? this.desires,
        skills: skills ?? this.skills,
        tastePreferences: tastePreferences ?? this.tastePreferences,
        industry: industry ?? this.industry,
        company: company ?? this.company,
        position: position ?? this.position,
        workExperience: workExperience ?? this.workExperience,
        homeAddress: homeAddress ?? this.homeAddress,
        familySituation: familySituation ?? this.familySituation,
        familyEconomicStatus: familyEconomicStatus ?? this.familyEconomicStatus,
        familyEmotionalStatus: familyEmotionalStatus ?? this.familyEmotionalStatus,
        taTrustLevel: taTrustLevel ?? this.taTrustLevel,
        myTrustLevel: myTrustLevel ?? this.myTrustLevel,
        socialCircles: socialCircles ?? this.socialCircles,
        currentStatus: currentStatus ?? this.currentStatus,
        moneyDesireLevel: moneyDesireLevel ?? this.moneyDesireLevel,
        ambitionLevel: ambitionLevel ?? this.ambitionLevel,
        shortTermGoals: shortTermGoals ?? this.shortTermGoals,
        longTermGoals: longTermGoals ?? this.longTermGoals,
        goalRelation: goalRelation ?? this.goalRelation,
        methods: methods ?? this.methods,
        tags: tags ?? this.tags,
        groupId: groupId ?? this.groupId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        interactions: interactions ?? this.interactions,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'level': level.index,
    'gender': gender.index,
    'birthday': birthday?.toIso8601String(),
    'age': age,
    'ethnicity': ethnicity,
    'religion': religion,
    'politicalAffiliation': politicalAffiliation,
    'maritalStatus': maritalStatus.index,
    'educationLevel': educationLevel.index,
    'school': school,
    'major': major,
    'personalityTags': personalityTags,
    'personalityDesc': personalityDesc,
    'characterTags': characterTags,
    'taboos': taboos,
    'values': values,
    'hobbies': hobbies,
    'strengths': strengths,
    'weaknesses': weaknesses,
    'fears': fears,
    'desires': desires,
    'skills': skills,
    'tastePreferences': tastePreferences,
    'industry': industry,
    'company': company,
    'position': position,
    'workExperience': workExperience,
    'homeAddress': homeAddress,
    'familySituation': familySituation,
    'familyEconomicStatus': familyEconomicStatus,
    'familyEmotionalStatus': familyEmotionalStatus,
    'taTrustLevel': taTrustLevel,
    'myTrustLevel': myTrustLevel,
    'socialCircles': socialCircles,
    'currentStatus': currentStatus,
    'moneyDesireLevel': moneyDesireLevel,
    'ambitionLevel': ambitionLevel,
    'shortTermGoals': shortTermGoals,
    'longTermGoals': longTermGoals,
    'goalRelation': goalRelation,
    'methods': methods.map((m) => m.toJson()).toList(),
    'tags': tags,
    'groupId': groupId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'interactions': interactions.map((i) => i.toJson()).toList(),
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String,
    name: json['name'] as String,
    avatar: json['avatar'] as String?,
    level: ContactLevel.values[json['level'] as int],
    gender: json['gender'] != null ? Gender.values[json['gender'] as int] : Gender.unknown,
    birthday: json['birthday'] != null ? DateTime.parse(json['birthday'] as String) : null,
    age: json['age'] as int?,
    ethnicity: json['ethnicity'] as String?,
    religion: json['religion'] as String?,
    politicalAffiliation: json['politicalAffiliation'] as String?,
    maritalStatus: json['maritalStatus'] != null ? MaritalStatus.values[json['maritalStatus'] as int] : MaritalStatus.unknown,
    educationLevel: json['educationLevel'] != null ? EducationLevel.values[json['educationLevel'] as int] : EducationLevel.unknown,
    school: json['school'] as String?,
    major: json['major'] as String?,
    personalityTags: json['personalityTags'] as String?,
    personalityDesc: json['personalityDesc'] as String?,
    characterTags: json['characterTags'] as String?,
    taboos: json['taboos'] as String?,
    values: json['values'] as String?,
    hobbies: json['hobbies'] as String?,
    strengths: json['strengths'] as String?,
    weaknesses: json['weaknesses'] as String?,
    fears: json['fears'] as String?,
    desires: json['desires'] as String?,
    skills: json['skills'] as String?,
    tastePreferences: json['tastePreferences'] as String?,
    industry: json['industry'] as String?,
    company: json['company'] as String?,
    position: json['position'] as String?,
    workExperience: json['workExperience'] as String?,
    homeAddress: json['homeAddress'] as String?,
    familySituation: json['familySituation'] as String?,
    familyEconomicStatus: json['familyEconomicStatus'] as String?,
    familyEmotionalStatus: json['familyEmotionalStatus'] as String?,
    taTrustLevel: json['taTrustLevel'] as int? ?? 5,
    myTrustLevel: json['myTrustLevel'] as int? ?? 5,
    socialCircles: json['socialCircles'] as String?,
    currentStatus: json['currentStatus'] as String?,
    moneyDesireLevel: json['moneyDesireLevel'] as String?,
    ambitionLevel: json['ambitionLevel'] as String?,
    shortTermGoals: json['shortTermGoals'] as String?,
    longTermGoals: json['longTermGoals'] as String?,
    goalRelation: json['goalRelation'] as String?,
    methods: (json['methods'] as List?)?.map((m) => ContactMethod.fromJson(m)).toList() ?? [],
    tags: (json['tags'] as List?)?.map((t) => t as String).toList() ?? [],
    groupId: json['groupId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    interactions: (json['interactions'] as List?)?.map((i) => Interaction.fromJson(i)).toList() ?? [],
  );

  /// 层级显示名称
  String get levelName {
    switch (level) {
      case ContactLevel.unimportant: return '不重要';
      case ContactLevel.normal: return '一般';
      case ContactLevel.important: return '重要';
      case ContactLevel.core: return '核心';
    }
  }

  /// 性别显示名称
  String get genderName {
    switch (gender) {
      case Gender.unknown: return '未知';
      case Gender.male: return '男';
      case Gender.female: return '女';
    }
  }

  /// 婚姻状况显示名称
  String get maritalStatusName {
    switch (maritalStatus) {
      case MaritalStatus.unknown: return '未知';
      case MaritalStatus.single: return '单身';
      case MaritalStatus.married: return '已婚';
      case MaritalStatus.divorced: return '离异';
      case MaritalStatus.widowed: return '丧偶';
      case MaritalStatus.inRelationship: return '恋爱中';
    }
  }

  /// 学历显示名称
  String get educationLevelName {
    switch (educationLevel) {
      case EducationLevel.unknown: return '未知';
      case EducationLevel.highSchool: return '高中';
      case EducationLevel.vocational: return '中专/职高';
      case EducationLevel.associate: return '大专';
      case EducationLevel.bachelor: return '本科';
      case EducationLevel.master: return '硕士';
      case EducationLevel.doctoral: return '博士';
    }
  }
}

/// 关系变化类型（跟踪关系升迁）
enum RelationshipChangeType {
  /// 初始设定（创建联系人时）
  initial,
  /// 手动升迁
  promote,
  /// 手动降级
  demote,
  /// 自动调整（任务完成/互动达标触发）
  auto,
  /// 手动调整（无方向性）
  manual,
}

/// 关系变化记录（单次层级变更，用于跟踪关系升迁时间线）
class RelationshipChange {
  final String id;
  final String contactId;
  final ContactLevel fromLevel;
  final ContactLevel toLevel;
  final RelationshipChangeType type;
  final String reason;
  final DateTime changedAt;

  const RelationshipChange({
    required this.id,
    required this.contactId,
    required this.fromLevel,
    required this.toLevel,
    required this.type,
    required this.reason,
    required this.changedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'fromLevel': fromLevel.index,
    'toLevel': toLevel.index,
    'type': type.index,
    'reason': reason,
    'changedAt': changedAt.toIso8601String(),
  };

  factory RelationshipChange.fromJson(Map<String, dynamic> json) => RelationshipChange(
    id: json['id'] as String,
    contactId: json['contactId'] as String,
    fromLevel: ContactLevel.values[json['fromLevel'] as int],
    toLevel: ContactLevel.values[json['toLevel'] as int],
    type: RelationshipChangeType.values[json['type'] as int],
    reason: json['reason'] as String,
    changedAt: DateTime.parse(json['changedAt'] as String),
  );

  String get typeName {
    switch (type) {
      case RelationshipChangeType.initial: return '初始设定';
      case RelationshipChangeType.promote: return '关系升迁';
      case RelationshipChangeType.demote: return '关系降级';
      case RelationshipChangeType.auto: return '自动调整';
      case RelationshipChangeType.manual: return '手动调整';
    }
  }

  /// 是否升迁（层级数值变大）
  bool get isPromotion => toLevel.index > fromLevel.index;
  /// 是否降级（层级数值变小）
  bool get isDemotion => toLevel.index < fromLevel.index;
  /// 距目标层级的进度（0~1），fromLevel 视为起点、toLevel 视为当前
  double get levelProgress {
    final max = ContactLevel.core.index;
    if (max == 0) return 1;
    return toLevel.index / max;
  }
}
