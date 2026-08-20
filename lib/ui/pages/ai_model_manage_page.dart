import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ai_provider.dart';
import '../../models/ai_config.dart';

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
    // TODO: 实现编辑模型
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中')),
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
    // TODO: 实现添加模型
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('添加功能开发中')),
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
