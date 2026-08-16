import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ai_provider.dart';
import '../../models/ai_config.dart' show AIModelProvider, AIModel, AIConversation, AIMessage, AIFile;

class AIPage extends StatelessWidget {
  const AIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI配置'),
      ),
      body: Consumer<AIProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '内部AI模型',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              ...provider.internalModels.map((model) {
                return _ModelCard(
                  model: model,
                  isSelected: provider.currentModel?.id == model.id,
                  onTap: () => provider.selectModel(model),
                  onEdit: () => _showEditModelDialog(context, model),
                );
              }),
              const SizedBox(height: 30),
              const Text(
                '外部AI模式',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _ExternalAICard(),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _showAddModelDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('添加自定义模型'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddModelDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final keyController = TextEditingController();
    var selectedProvider = AIModelProvider.openai;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加自定义模型'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '模型名称',
                        hintText: '如: gpt-4',
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<AIModelProvider>(
                      value: selectedProvider,
                      decoration: const InputDecoration(
                        labelText: 'AI提供商',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: AIModelProvider.openai,
                          child: Text('OpenAI'),
                        ),
                        DropdownMenuItem(
                          value: AIModelProvider.claude,
                          child: Text('Claude'),
                        ),
                        DropdownMenuItem(
                          value: AIModelProvider.dashscope,
                          child: Text('通义千问'),
                        ),
                        DropdownMenuItem(
                          value: AIModelProvider.local,
                          child: Text('本地LLM'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedProvider = value);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'API地址',
                        hintText: 'https://api.openai.com/v1',
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: 'API密钥',
                        hintText: 'sk-...',
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        urlController.text.isNotEmpty) {
                      final provider = context.read<AIProvider>();
                      provider.addModel(AIModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        provider: selectedProvider,
                        apiUrl: urlController.text,
                        apiKey: keyController.text.isEmpty
                            ? null
                            : keyController.text,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditModelDialog(BuildContext context, AIModel model) {
    final nameController = TextEditingController(text: model.name);
    final urlController = TextEditingController(text: model.apiUrl);
    final keyController = TextEditingController(text: model.apiKey ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑模型'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '模型名称'),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'API地址'),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(labelText: 'API密钥'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final provider = context.read<AIProvider>();
                provider.updateModel(model.copyWith(
                  name: nameController.text,
                  apiUrl: urlController.text,
                  apiKey: keyController.text.isEmpty ? null : keyController.text,
                ));
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}

class _ModelCard extends StatelessWidget {
  final AIModel model;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ModelCard({
    required this.model,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getProviderColor(model.provider).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getProviderIcon(model.provider),
                  color: _getProviderColor(model.provider),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          model.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (model.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '默认',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      model.providerName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF6366F1)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProviderIcon(AIModelProvider provider) {
    switch (provider) {
      case AIModelProvider.openai:
        return Icons.psychology;
      case AIModelProvider.claude:
        return Icons.smart_toy;
      case AIModelProvider.dashscope:
        return Icons.auto_awesome;
      case AIModelProvider.local:
        return Icons.computer;
      case AIModelProvider.external:
        return Icons.public;
    }
  }

  Color _getProviderColor(AIModelProvider provider) {
    switch (provider) {
      case AIModelProvider.openai:
        return Colors.green;
      case AIModelProvider.claude:
        return Colors.orange;
      case AIModelProvider.dashscope:
        return Colors.blue;
      case AIModelProvider.local:
        return Colors.purple;
      case AIModelProvider.external:
        return Colors.grey;
    }
  }
}

class _ExternalAICard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/external-ai');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDF导出模式',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '生成PDF与千问、豆包等AI交互',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
