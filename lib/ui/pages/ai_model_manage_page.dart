import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ai_provider.dart';
import '../../models/ai_config.dart';
import '../../services/ai_service.dart';

class AIModelManagePage extends StatefulWidget {
  const AIModelManagePage({super.key});

  @override
  State<AIModelManagePage> createState() => _AIModelManagePageState();
}

class _AIModelManagePageState extends State<AIModelManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 模型管理'),
      ),
      body: Consumer<AIProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final models = provider.models;

          if (models.isEmpty) {
            return const Center(
              child: Text('暂无模型配置'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return _ModelCard(
                model: model,
                isDefault: model.isDefault,
                onEdit: () => _editModel(context, provider, model),
                onDelete: model.isExternal 
                    ? null 
                    : () => _deleteModel(context, provider, model),
                onSetDefault: () => _setDefaultModel(context, provider, model),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addModel(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editModel(BuildContext context, AIProvider provider, AIModel model) {
    showDialog(
      context: context,
      builder: (ctx) => _ModelEditDialog(
        provider: provider,
        model: model,
        isEdit: true,
      ),
    );
  }

  void _deleteModel(BuildContext context, AIProvider provider, AIModel model) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除模型'),
        content: Text('确定要删除模型「${model.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteModel(model.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('模型已删除')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _setDefaultModel(BuildContext context, AIProvider provider, AIModel model) async {
    await provider.setDefaultModel(model.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已将「${model.name}」设为默认模型')),
      );
    }
  }

  void _addModel(BuildContext context) {
    final provider = context.read<AIProvider>();
    showDialog(
      context: context,
      builder: (ctx) => _ModelEditDialog(
        provider: provider,
        model: provider.createEmptyModel(),
        isEdit: false,
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final AIModel model;
  final bool isDefault;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const _ModelCard({
    required this.model,
    required this.isDefault,
    this.onEdit,
    this.onDelete,
    this.onSetDefault,
  });

  IconData _getModelIcon(AIModelProvider provider) {
    switch (provider) {
      case AIModelProvider.openai:
        return Icons.smart_toy;
      case AIModelProvider.claude:
        return Icons.psychology;
      case AIModelProvider.dashscope:
        return Icons.auto_awesome;
      case AIModelProvider.local:
        return Icons.computer;
      case AIModelProvider.external:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getModelIcon(model.provider),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Text(model.name),
            if (isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '默认',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model.providerName),
            if (model.apiKey != null && model.apiKey!.isNotEmpty)
              Text(
                'API Key: ${model.apiKey!.substring(0, 8)}...',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit?.call();
                break;
              case 'delete':
                onDelete?.call();
                break;
              case 'default':
                onSetDefault?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('编辑'),
              ),
            ),
            if (!isDefault)
              const PopupMenuItem(
                value: 'default',
                child: ListTile(
                  leading: Icon(Icons.check_circle),
                  title: Text('设为默认'),
                ),
              ),
            if (onDelete != null)
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('删除'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// AI模型编辑/添加对话框
class _ModelEditDialog extends StatefulWidget {
  final AIProvider provider;
  final AIModel model;
  final bool isEdit;

  const _ModelEditDialog({
    required this.provider,
    required this.model,
    required this.isEdit,
  });

  @override
  State<_ModelEditDialog> createState() => _ModelEditDialogState();
}

class _ModelEditDialogState extends State<_ModelEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _apiUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _maxTokensCtrl;
  late TextEditingController _temperatureCtrl;
  late AIModelProvider _selectedProvider;
  bool _supportsVision = false;
  bool _supportsFileUpload = false;
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final m = widget.model;
    _nameCtrl = TextEditingController(text: m.name);
    _apiUrlCtrl = TextEditingController(text: m.apiUrl);
    _apiKeyCtrl = TextEditingController(text: m.apiKey ?? '');
    _maxTokensCtrl = TextEditingController(text: m.maxTokens?.toString() ?? '');
    _temperatureCtrl = TextEditingController(text: m.temperature?.toString() ?? '');
    _selectedProvider = m.provider;
    _supportsVision = m.supportsVision;
    _supportsFileUpload = m.supportsFileUpload;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _apiUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _maxTokensCtrl.dispose();
    _temperatureCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? '编辑AI模型' : '添加AI模型'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 模型名称
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  hintText: '如 gpt-4o-mini, qwen-plus',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // 供应商
              DropdownButtonFormField<AIModelProvider>(
                value: _selectedProvider,
                decoration: const InputDecoration(
                  labelText: 'AI供应商',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: AIModelProvider.openai, child: Text('OpenAI兼容')),
                  DropdownMenuItem(value: AIModelProvider.claude, child: Text('Claude')),
                  DropdownMenuItem(value: AIModelProvider.dashscope, child: Text('通义千问')),
                  DropdownMenuItem(value: AIModelProvider.local, child: Text('本地LLM')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedProvider = v;
                      // 自动填充默认API URL
                      if (_apiUrlCtrl.text.isEmpty) {
                        switch (v) {
                          case AIModelProvider.openai:
                            _apiUrlCtrl.text = 'https://api.openai.com/v1';
                            break;
                          case AIModelProvider.claude:
                            _apiUrlCtrl.text = 'https://api.anthropic.com/v1';
                            break;
                          case AIModelProvider.dashscope:
                            _apiUrlCtrl.text = 'https://dashscope.aliyuncs.com/compatible-mode/v1';
                            break;
                          case AIModelProvider.local:
                            _apiUrlCtrl.text = 'http://localhost:11434/v1';
                            break;
                          case AIModelProvider.external:
                            break;
                        }
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              // API URL
              TextField(
                controller: _apiUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'API地址',
                  hintText: 'https://api.example.com/v1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // API Key
              TextField(
                controller: _apiKeyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // 最大Token和温度
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _maxTokensCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '最大Token',
                        hintText: '4096',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _temperatureCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '温度',
                        hintText: '0.7',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 能力开关
              SwitchListTile(
                title: const Text('支持图片识别'),
                contentPadding: EdgeInsets.zero,
                value: _supportsVision,
                onChanged: (v) => setState(() => _supportsVision = v),
              ),
              SwitchListTile(
                title: const Text('支持文件上传'),
                contentPadding: EdgeInsets.zero,
                value: _supportsFileUpload,
                onChanged: (v) => setState(() => _supportsFileUpload = v),
              ),
              const SizedBox(height: 8),
              // 测试连接按钮
              OutlinedButton.icon(
                onPressed: _isTesting
                    ? null
                    : () async {
                        setState(() {
                          _isTesting = true;
                          _testResult = null;
                        });
                        final testModel = AIModel(
                          id: widget.model.id,
                          name: _nameCtrl.text.trim(),
                          provider: _selectedProvider,
                          apiUrl: _apiUrlCtrl.text.trim(),
                          apiKey: _apiKeyCtrl.text.trim(),
                        );
                        final ok = await AIService.testConnection(testModel);
                        setState(() {
                          _isTesting = false;
                          _testResult = ok ? '连接成功 ✓' : '连接失败，请检查配置';
                        });
                      },
                icon: _isTesting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_find),
                label: const Text('测试连接'),
              ),
              if (_testResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _testResult!.contains('成功') ? Colors.green : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_nameCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入模型名称')),
              );
              return;
            }
            final updatedModel = widget.model.copyWith(
              name: _nameCtrl.text.trim(),
              provider: _selectedProvider,
              apiUrl: _apiUrlCtrl.text.trim().isEmpty ? 'https://api.openai.com/v1' : _apiUrlCtrl.text.trim(),
              apiKey: _apiKeyCtrl.text.trim().isEmpty ? null : _apiKeyCtrl.text.trim(),
              maxTokens: int.tryParse(_maxTokensCtrl.text.trim()),
              temperature: double.tryParse(_temperatureCtrl.text.trim()),
              supportsVision: _supportsVision,
              supportsFileUpload: _supportsFileUpload,
            );
            await widget.provider.updateModel(updatedModel);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(widget.isEdit ? '模型已更新 ✓' : '模型已添加 ✓')),
              );
            }
          },
          child: Text(widget.isEdit ? '保存' : '添加'),
        ),
      ],
    );
  }
}
