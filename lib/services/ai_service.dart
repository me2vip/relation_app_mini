import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_config.dart';

class AIService {
  static final _uuid = Uuid();
  static final _dio = Dio();

  /// 调用AI进行对话
  static Future<AIMessage> chat({
    required AIModel model,
    required List<AIMessage> messages,
    String? systemPrompt,
  }) async {
    if (model.isExternal) {
      throw Exception('外部AI模式不支持直接调用，请使用PDF导出功能');
    }

    final requestMessages = <Map<String, dynamic>>[];
    
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      requestMessages.add({
        'role': 'system',
        'content': systemPrompt,
      });
    }
    
    for (final msg in messages) {
      final msgMap = <String, dynamic>{
        'role': msg.role,
        'content': msg.content,
      };
      
      if (msg.attachments != null && msg.attachments!.isNotEmpty) {
        if (model.supportsVision) {
          msgMap['content'] = [
            {'type': 'text', 'text': msg.content},
            ...msg.attachments!.map((a) => {
              'type': 'image_url',
              'image_url': {'url': a.url ?? a.path},
            }),
          ];
        }
      }
      
      requestMessages.add(msgMap);
    }

    try {
      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
      };
      
      if (model.apiKey != null && model.apiKey!.isNotEmpty) {
        if (model.provider == AIModelProvider.openai) {
          headers['Authorization'] = 'Bearer ${model.apiKey}';
        }
      }

      final data = <String, dynamic>{
        'model': model.name,
        'messages': requestMessages,
      };

      if (model.maxTokens != null) {
        data['max_tokens'] = model.maxTokens;
      }
      if (model.temperature != null) {
        data['temperature'] = model.temperature;
      }

      final response = await _dio.post(
        '${model.apiUrl}/chat/completions',
        data: data,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'] as String;
        return AIMessage(
          id: _uuid.v4(),
          role: 'assistant',
          content: content,
          createdAt: DateTime.now(),
        );
      } else {
        throw Exception('AI请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 流式调用AI
  static Stream<String> chatStream({
    required AIModel model,
    required List<AIMessage> messages,
    String? systemPrompt,
  }) async* {
    if (model.isExternal) {
      throw Exception('外部AI模式不支持直接调用');
    }

    final requestMessages = <Map<String, dynamic>>[];
    
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      requestMessages.add({
        'role': 'system',
        'content': systemPrompt,
      });
    }
    
    for (final msg in messages) {
      requestMessages.add({
        'role': msg.role,
        'content': msg.content,
      });
    }

    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
    };
    
    if (model.apiKey != null && model.apiKey!.isNotEmpty) {
      if (model.provider == AIModelProvider.openai) {
        headers['Authorization'] = 'Bearer ${model.apiKey}';
      }
    }

    final data = <String, dynamic>{
      'model': model.name,
      'messages': requestMessages,
      'stream': true,
    };

    if (model.maxTokens != null) {
      data['max_tokens'] = model.maxTokens;
    }
    if (model.temperature != null) {
      data['temperature'] = model.temperature;
    }

    try {
      final response = await _dio.post(
        '${model.apiUrl}/chat/completions',
        data: data,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        
        final lines = buffer.split('\n');
        buffer = lines.removeLast();
        
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;
            
            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'];
              if (content != null) {
                yield content as String;
              }
            } catch (_) {}
          }
        }
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 测试AI连接
  static Future<bool> testConnection(AIModel model) async {
    if (model.isExternal) return true;
    
    try {
      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
      };
      
      if (model.apiKey != null && model.apiKey!.isNotEmpty) {
        if (model.provider == AIModelProvider.openai) {
          headers['Authorization'] = 'Bearer ${model.apiKey}';
        }
      }

      await _dio.get(
        model.apiUrl,
        options: Options(headers: headers),
        queryParameters: {'dummy': 'test'},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('连接超时，请检查网络');
      case DioExceptionType.connectionError:
        return Exception('网络连接失败');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return Exception('API密钥无效');
        } else if (statusCode == 403) {
          return Exception('没有访问权限');
        } else if (statusCode == 429) {
          return Exception('请求过于频繁，请稍后再试');
        }
        return Exception('服务器错误: $statusCode');
      default:
        return Exception('请求失败: ${e.message}');
    }
  }
}
