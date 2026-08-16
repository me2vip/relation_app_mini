enum AIModelProvider {
  /// 内部AI - OpenAI兼容
  openai,
  /// 内部AI - Claude兼容
  claude,
  /// 内部AI - 阿里通义
  dashscope,
  /// 内部AI - 本地LLM
  local,
  /// 外部AI - PDF导出模式
  external,
}

class AIModel {
  final String id;
  final String name;
  final AIModelProvider provider;
  final String apiUrl;
  final String? apiKey;
  final int? maxTokens;
  final double? temperature;
  final bool supportsVision;
  final bool supportsFileUpload;
  final bool isDefault;

  AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.apiUrl,
    this.apiKey,
    this.maxTokens,
    this.temperature,
    this.supportsVision = false,
    this.supportsFileUpload = false,
    this.isDefault = false,
  });

  AIModel copyWith({
    String? id,
    String? name,
    AIModelProvider? provider,
    String? apiUrl,
    String? apiKey,
    int? maxTokens,
    double? temperature,
    bool? supportsVision,
    bool? supportsFileUpload,
    bool? isDefault,
  }) => AIModel(
    id: id ?? this.id,
    name: name ?? this.name,
    provider: provider ?? this.provider,
    apiUrl: apiUrl ?? this.apiUrl,
    apiKey: apiKey ?? this.apiKey,
    maxTokens: maxTokens ?? this.maxTokens,
    temperature: temperature ?? this.temperature,
    supportsVision: supportsVision ?? this.supportsVision,
    supportsFileUpload: supportsFileUpload ?? this.supportsFileUpload,
    isDefault: isDefault ?? this.isDefault,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'provider': provider.index,
    'apiUrl': apiUrl,
    'apiKey': apiKey,
    'maxTokens': maxTokens,
    'temperature': temperature,
    'supportsVision': supportsVision,
    'supportsFileUpload': supportsFileUpload,
    'isDefault': isDefault,
  };

  factory AIModel.fromJson(Map<String, dynamic> json) => AIModel(
    id: json['id'] as String,
    name: json['name'] as String,
    provider: AIModelProvider.values[json['provider'] as int],
    apiUrl: json['apiUrl'] as String,
    apiKey: json['apiKey'] as String?,
    maxTokens: json['maxTokens'] as int?,
    temperature: (json['temperature'] as num?)?.toDouble(),
    supportsVision: json['supportsVision'] as bool? ?? false,
    supportsFileUpload: json['supportsFileUpload'] as bool? ?? false,
    isDefault: json['isDefault'] as bool? ?? false,
  );

  String get providerName {
    switch (provider) {
      case AIModelProvider.openai: return 'OpenAI';
      case AIModelProvider.claude: return 'Claude';
      case AIModelProvider.dashscope: return '通义千问';
      case AIModelProvider.local: return '本地LLM';
      case AIModelProvider.external: return '外部AI';
    }
  }

  bool get isExternal => provider == AIModelProvider.external;
}

class AIConversation {
  final String id;
  final String? contactId;
  final String modelId;
  final List<AIMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIConversation({
    required this.id,
    this.contactId,
    required this.modelId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'modelId': modelId,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AIConversation.fromJson(Map<String, dynamic> json) => AIConversation(
    id: json['id'] as String,
    contactId: json['contactId'] as String?,
    modelId: json['modelId'] as String,
    messages: (json['messages'] as List).map((m) => AIMessage.fromJson(m)).toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class AIMessage {
  final String id;
  final String role; // user, assistant, system
  final String content;
  final List<AIFile>? attachments;
  final DateTime createdAt;

  AIMessage({
    required this.id,
    required this.role,
    required this.content,
    this.attachments,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    'attachments': attachments?.map((a) => a.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory AIMessage.fromJson(Map<String, dynamic> json) => AIMessage(
    id: json['id'] as String,
    role: json['role'] as String,
    content: json['content'] as String,
    attachments: (json['attachments'] as List?)?.map((a) => AIFile.fromJson(a)).toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class AIFile {
  final String id;
  final String name;
  final String type; // image, document, pdf
  final String path;
  final String? url;

  AIFile({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    this.url,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'path': path,
    'url': url,
  };

  factory AIFile.fromJson(Map<String, dynamic> json) => AIFile(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    path: json['path'] as String,
    url: json['url'] as String?,
  );
}
