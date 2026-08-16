import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/ai_config.dart';
import '../../services/storage_service.dart';
import '../../services/ai_service.dart';

class AIProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  
  List<AIModel> _models = [];
  List<AIConversation> _conversations = [];
  AIModel? _currentModel;
  AIConversation? _currentConversation;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;

  List<AIModel> get models => _models;
  List<AIModel> get internalModels => 
      _models.where((m) => !m.isExternal).toList();
  List<AIConversation> get conversations => _conversations;
  AIModel? get currentModel => _currentModel;
  AIConversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;

  AIProvider() {
    loadModels();
  }

  Future<void> loadModels() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _models = await DatabaseService.getAllAIModels();
      
      // 如果没有模型，添加默认模型
      if (_models.isEmpty) {
        await _addDefaultModels();
      }
      
      _currentModel = await DatabaseService.getDefaultAIModel();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _addDefaultModels() async {
    final defaultModels = [
      AIModel(
        id: _uuid.v4(),
        name: 'gpt-4o-mini',
        provider: AIProvider.openai,
        apiUrl: 'https://api.openai.com/v1',
        maxTokens: 4096,
        temperature: 0.7,
        supportsVision: true,
        supportsFileUpload: true,
        isDefault: true,
      ),
      AIModel(
        id: _uuid.v4(),
        name: 'claude-3-haiku',
        provider: AIProvider.claude,
        apiUrl: 'https://api.anthropic.com/v1',
        maxTokens: 4096,
        temperature: 0.7,
        supportsVision: true,
        supportsFileUpload: false,
      ),
      AIModel(
        id: _uuid.v4(),
        name: 'qwen-plus',
        provider: AIProvider.dashscope,
        apiUrl: 'https://dashscope.aliyuncs.com/api/v1',
        maxTokens: 8192,
        temperature: 0.7,
        supportsVision: false,
        supportsFileUpload: true,
      ),
      AIModel(
        id: _uuid.v4(),
        name: 'external',
        provider: AIProvider.external,
        apiUrl: '',
        isDefault: false,
      ),
    ];

    for (final model in defaultModels) {
      await DatabaseService.saveAIModel(model);
    }
    
    _models = defaultModels;
  }

  Future<void> addModel(AIModel model) async {
    try {
      await DatabaseService.saveAIModel(model);
      await loadModels();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateModel(AIModel model) async {
    try {
      await DatabaseService.saveAIModel(model);
      await loadModels();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteModel(String modelId) async {
    try {
      _models.removeWhere((m) => m.id == modelId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> setDefaultModel(String modelId) async {
    try {
      for (final model in _models) {
        final updated = model.copyWith(isDefault: model.id == modelId);
        await DatabaseService.saveAIModel(updated);
      }
      await loadModels();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void selectModel(AIModel model) {
    _currentModel = model;
    notifyListeners();
  }

  Future<void> createConversation({String? contactId}) async {
    if (_currentModel == null || _currentModel!.isExternal) return;

    final now = DateTime.now();
    _currentConversation = AIConversation(
      id: _uuid.v4(),
      contactId: contactId,
      modelId: _currentModel!.id,
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
    notifyListeners();
  }

  Future<void> sendMessage(String content, {List<AIFile>? attachments}) async {
    if (_currentModel == null || _currentConversation == null) return;
    if (_currentModel!.isExternal) {
      _errorMessage = '请使用PDF导出功能与外部AI交互';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    notifyListeners();

    try {
      // 添加用户消息
      final userMessage = AIMessage(
        id: _uuid.v4(),
        role: 'user',
        content: content,
        attachments: attachments,
        createdAt: DateTime.now(),
      );
      _currentConversation!.messages.add(userMessage);

      // 获取AI响应
      final aiMessage = await AIService.chat(
        model: _currentModel!,
        messages: _currentConversation!.messages,
      );
      _currentConversation!.messages.add(aiMessage);

      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> testConnection(AIModel model) async {
    try {
      final success = await AIService.testConnection(model);
      if (!success) {
        _errorMessage = '连接失败，请检查API配置';
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearConversation() {
    _currentConversation = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  AIModel createEmptyModel() {
    return AIModel(
      id: _uuid.v4(),
      name: '',
      provider: AIProvider.openai,
      apiUrl: 'https://api.openai.com/v1',
    );
  }
}
