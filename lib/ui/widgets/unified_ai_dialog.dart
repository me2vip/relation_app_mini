import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ai_provider.dart';
import '../../models/ai_config.dart';
import '../../services/ai_service.dart';

/// 统一AI调用对话框
///
/// 所有需要AI调用的地方都使用此组件，统一两种调用方式：
/// - 内部AI：使用配置好的API Token直接请求
/// - 外部AI：使用AI任务中心标准方式（复制提示词 → 粘贴结果）
///
/// 使用方式：
/// ```dart
/// final result = await UnifiedAIDialog.show(
///   context,
///   title: 'AI社交大纲生成',
///   prompt: '请生成社交大纲...',
///   parseResult: (text) => jsonDecode(text),
/// );
/// ```
class UnifiedAIDialog extends StatefulWidget {
  final String title;
  final String prompt;
  final String? systemPrompt;
  final String resultHint;
  final String? resultPlaceholder;

  /// 解析外部AI返回的结果（用户粘贴的文本）
  /// 返回null表示解析失败，返回非null表示解析成功
  final Map<String, dynamic>? Function(String text)? parseResult;

  /// 内部AI调用的自定义处理函数
  /// 如果提供，则使用此函数替代默认的AIService.chat调用
  /// 返回需要解析的文本结果
  final Future<String> Function(AIModel model)? internalAICall;

  const UnifiedAIDialog({
    super.key,
    required this.title,
    required this.prompt,
    this.systemPrompt,
    this.resultHint = '粘贴AI返回的结果',
    this.resultPlaceholder,
    this.parseResult,
    this.internalAICall,
  });

  /// 显示统一AI对话框，返回解析后的结果
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String title,
    required String prompt,
    String? systemPrompt,
    String resultHint = '粘贴AI返回的结果',
    String? resultPlaceholder,
    Map<String, dynamic>? Function(String text)? parseResult,
    Future<String> Function(AIModel model)? internalAICall,
  }) {
    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => UnifiedAIDialog(
        title: title,
        prompt: prompt,
        systemPrompt: systemPrompt,
        resultHint: resultHint,
        resultPlaceholder: resultPlaceholder,
        parseResult: parseResult,
        internalAICall: internalAICall,
      ),
    );
  }

  @override
  State<UnifiedAIDialog> createState() => _UnifiedAIDialogState();
}

class _UnifiedAIDialogState extends State<UnifiedAIDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pasteController = TextEditingController();
  bool _isProcessing = false;
  String? _internalResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  // ===== 内部AI调用 =====
  Future<void> _callInternalAI() async {
    final aiProvider = context.read<AIProvider>();
    final model = aiProvider.currentModel ?? aiProvider.internalModels.firstOrNull;

    if (model == null || model.isExternal) {
      setState(() {
        _errorMessage = '未配置内部AI模型，请前往【设置→AI模型管理】添加并配置API Key';
      });
      return;
    }

    if (model.apiKey == null || model.apiKey!.isEmpty) {
      setState(() {
        _errorMessage = '当前模型未配置API Key，请前往【设置→AI模型管理】填写';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _internalResult = null;
    });

    try {
      String resultText;
      if (widget.internalAICall != null) {
        resultText = await widget.internalAICall!(model);
      } else {
        final messages = [
          AIMessage(
            id: '',
            role: 'user',
            content: widget.prompt,
            createdAt: DateTime.now(),
          ),
        ];
        final response = await AIService.chat(
          model: model,
          messages: messages,
          systemPrompt: widget.systemPrompt,
        );
        resultText = response.content;
      }

      setState(() {
        _isProcessing = false;
        _internalResult = resultText;
      });

      // 尝试自动解析
      if (widget.parseResult != null) {
        final parsed = widget.parseResult!(resultText);
        if (parsed != null) {
          if (mounted) Navigator.pop(context, parsed);
          return;
        }
      }

      // 解析失败，切换到结果Tab让用户确认
      _pasteController.text = resultText;
      _tabController.animateTo(1);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'AI调用失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.read<AIProvider>();
    final hasInternalModel = aiProvider.internalModels.isNotEmpty;
    final currentModel = aiProvider.currentModel;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.psychology_alt, color: Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 模型状态指示
            if (currentModel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      currentModel.isExternal ? Icons.description_outlined : Icons.bolt,
                      size: 16,
                      color: currentModel.isExternal ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '当前模型: ${currentModel.name}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (!currentModel.isExternal && (currentModel.apiKey == null || currentModel.apiKey!.isEmpty)) ...[
                      const SizedBox(width: 6),
                      const Text('（未配置Key）', style: TextStyle(fontSize: 10, color: Colors.red)),
                    ],
                  ],
                ),
              ),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.bolt, size: 18), text: '内部AI'),
                Tab(icon: Icon(Icons.open_in_new, size: 18), text: '外部AI'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ===== 内部AI Tab =====
                  _buildInternalAITab(hasInternalModel),
                  // ===== 外部AI Tab =====
                  _buildExternalAITab(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  // ===== 内部AI Tab =====
  Widget _buildInternalAITab(bool hasModel) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasModel
                        ? '点击下方按钮，APP将使用已配置的API Key直接调用AI，无需手动复制粘贴。'
                        : '暂无内部AI模型，请先前往【设置→AI模型管理】添加模型并配置API Key。',
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 提示词预览
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: SelectableText(
                widget.prompt,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_errorMessage!, style: TextStyle(fontSize: 12, color: Colors.red[700])),
            ),
          if (_isProcessing)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_internalResult != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: SelectableText(_internalResult!, style: const TextStyle(fontSize: 12, height: 1.4)),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                onPressed: _callInternalAI,
                icon: const Icon(Icons.bolt),
                label: const Text('调用内部AI'),
              ),
            ),
          if (_internalResult != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _internalResult = null;
                        _errorMessage = null;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重新调用'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      if (widget.parseResult != null) {
                        final parsed = widget.parseResult!(_internalResult!);
                        if (parsed != null) {
                          Navigator.pop(context, parsed);
                          return;
                        }
                      }
                      // 没有解析器或解析失败，返回原始文本
                      Navigator.pop(context, {'rawResult': _internalResult});
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('应用结果'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===== 外部AI Tab =====
  Widget _buildExternalAITab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '① 复制提示词 → ② 粘贴到外部AI（千问/豆包/ChatGPT等）→ ③ 将AI返回结果粘贴回下方 → ④ 点击应用',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 提示词
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: SelectableText(
                widget.prompt,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.3),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.prompt));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('提示词已复制 ✓'), duration: Duration(seconds: 1)),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('复制提示词'),
            ),
          ),
          const SizedBox(height: 14),
          // 粘贴结果
          Text(widget.resultHint, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _pasteController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: widget.resultPlaceholder ?? '在此粘贴AI返回的完整内容...',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                final text = _pasteController.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请先粘贴AI返回结果')),
                  );
                  return;
                }
                if (widget.parseResult != null) {
                  final parsed = widget.parseResult!(text);
                  if (parsed != null) {
                    Navigator.pop(context, parsed);
                    return;
                  }
                  // 解析失败提示
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('解析失败'),
                      content: const Text('无法解析粘贴的内容，请确认格式正确。也可直接应用原始文本。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('重新粘贴'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context, {'rawResult': text});
                          },
                          child: const Text('直接应用原文'),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.pop(context, {'rawResult': text});
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('应用结果'),
            ),
          ),
        ],
      ),
    );
  }
}
