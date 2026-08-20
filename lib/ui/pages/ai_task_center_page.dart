import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../models/task.dart';
import '../../models/contact.dart';

class _TaskCenterData extends ChangeNotifier {
  String sourceText = '';
  String instructionText = '';
  List<String> contactIds = [];
  List<String> days = ['7天'];
  int priority = 3;

  void updateSource(String v) {
    sourceText = v;
    notifyListeners();
  }

  void updateInstruction(String v) {
    instructionText = v;
    notifyListeners();
  }

  void setContactIds(List<String> ids) {
    contactIds = ids;
    notifyListeners();
  }

  void setDays(List<String> d) {
    days = d;
    notifyListeners();
  }

  void setPriority(int p) {
    priority = p;
    notifyListeners();
  }

  String getDaysText() {
    if (days.isEmpty) return '一周';
    return days.join('、');
  }
}

class AiTaskCenterPage extends StatefulWidget {
  const AiTaskCenterPage({super.key});

  @override
  State<AiTaskCenterPage> createState() => _AiTaskCenterPageState();
}

class _AiTaskCenterPageState extends State<AiTaskCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late _TaskCenterData _data;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _data = _TaskCenterData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _data,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI任务中心'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '1. 生成素材'),
              Tab(text: '2. 导出PDF'),
              Tab(text: '3. 粘贴结果'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _MaterialTab(onNext: () => _tabController.animateTo(1)),
            _ExportTab(onNext: () => _tabController.animateTo(2)),
            const _PasteResultTab(),
          ],
        ),
      ),
    );
  }
}

class _MaterialTab extends StatefulWidget {
  final VoidCallback onNext;
  const _MaterialTab({required this.onNext});

  @override
  State<_MaterialTab> createState() => _MaterialTabState();
}

class _MaterialTabState extends State<_MaterialTab> {
  late final TextEditingController _sourceController;
  late final TextEditingController _instructionController;

  @override
  void initState() {
    super.initState();
    final data = context.read<_TaskCenterData>();
    _sourceController = TextEditingController(text: data.sourceText);
    _instructionController = TextEditingController(text: data.instructionText);
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<_TaskCenterData>();
    final contactProvider = context.watch<ContactProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepCard(
          step: 1,
          title: '添加素材',
          subtitle: '描述最近发生的事情、心情、活动等',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _sourceController,
                onChanged: data.updateSource,
                decoration: const InputDecoration(
                  labelText: '素材内容',
                  hintText: '例如：本周我参加了一个行业峰会，认识了几位新朋友...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 12),
              const Text(
                '💡 你可以描述任何素材：经历、心情、活动、想法等',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StepCard(
          step: 2,
          title: '选择关联联系人',
          subtitle: '选择哪些联系人参与此次任务生成',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contactProvider.contacts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '暂无联系人，请先添加',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          data.setContactIds(
                            contactProvider.contacts.map((c) => c.id).toList(),
                          );
                        },
                        child: const Text('全选'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => data.setContactIds([]),
                        child: const Text('清空'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...contactProvider.contacts.map((contact) {
                  final selected = data.contactIds.contains(contact.id);
                  return CheckboxListTile(
                    dense: true,
                    title: Text(contact.name),
                    subtitle: Text(
                      '${contact.levelName}${contact.goalRelation != null ? ' · 目标：${contact.goalRelation}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: selected,
                    onChanged: (v) {
                      final ids = List<String>.from(data.contactIds);
                      if (v == true) {
                        ids.add(contact.id);
                      } else {
                        ids.remove(contact.id);
                      }
                      data.setContactIds(ids);
                    },
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StepCard(
          step: 3,
          title: '设置生成范围',
          subtitle: '选择生成多少天的任务',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('生成周期'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildDayChip('3天', data),
                  _buildDayChip('7天', data),
                  _buildDayChip('14天', data),
                  _buildDayChip('30天', data),
                ],
              ),
              const SizedBox(height: 16),
              const Text('默认优先级'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < data.priority ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => data.setPriority(i + 1),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StepCard(
          step: 4,
          title: '自定义指令（可选）',
          subtitle: '添加额外的要求或约束',
          child: TextField(
            controller: _instructionController,
            onChanged: data.updateInstruction,
            decoration: const InputDecoration(
              labelText: '额外指令',
              hintText: '例如：不要在周末安排、优先选择下午时段...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 16),
        _PromptPreviewCard(data: data),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: data.contactIds.isEmpty ? null : widget.onNext,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('下一步：导出PDF'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayChip(String label, _TaskCenterData data) {
    final selected = data.days.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        if (v) {
          data.setDays([label]);
        } else {
          data.setDays([]);
        }
      },
    );
  }
}

class _PromptPreviewCard extends StatelessWidget {
  final _TaskCenterData data;
  const _PromptPreviewCard({required this.data});

  String _buildPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('请根据以下素材，为选定的联系人生成未来 ${data.getDaysText()} 的社交任务计划。');
    buffer.writeln('');
    buffer.writeln('## 素材内容');
    buffer.writeln(data.sourceText.isEmpty ? '（暂无素材）' : data.sourceText);
    buffer.writeln('');
    buffer.writeln('## 输出要求');
    buffer.writeln('请为每位联系人生成具体可执行的社交任务，用JSON格式返回：');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "tasks": [');
    buffer.writeln('    {');
    buffer.writeln('      "contact_name": "联系人姓名",');
    buffer.writeln('      "title": "任务标题",');
    buffer.writeln('      "description": "任务详细描述",');
    buffer.writeln('      "type": "sendMessage|greeting|phoneCall|socialInteraction|other",');
    buffer.writeln('      "priority": 1-5,');
    buffer.writeln('      "scheduled_offset_days": 0-30,');
    buffer.writeln('      "scheduled_hour": 8-21');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF6366F1).withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.preview, color: Color(0xFF6366F1)),
                SizedBox(width: 8),
                Text(
                  'AI提示词预览',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  _buildPrompt(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportTab extends StatefulWidget {
  final VoidCallback onNext;
  const _ExportTab({required this.onNext});

  @override
  State<_ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends State<_ExportTab> {
  bool _isExporting = false;
  String? _pdfPath;

  String _buildPrompt(_TaskCenterData data, ContactProvider contactProvider) {
    final contacts = data.contactIds
        .map((id) => contactProvider.contacts.where((c) => c.id == id).firstOrNull)
        .whereType<Contact>()
        .toList();

    final contactsInfo = contacts.isEmpty
        ? '所有联系人'
        : contacts.map((c) {
            final parts = [
              c.name,
              c.levelName,
              if (c.goalRelation != null) '目标:${c.goalRelation}',
            ];
            return '  - ${parts.join(' · ')}';
          }).join('\n');

    final buffer = StringBuffer();
    buffer.writeln('请根据以下素材，为选定的联系人生成未来 ${data.getDaysText()} 的社交任务计划。');
    buffer.writeln('');
    buffer.writeln('## 素材内容');
    buffer.writeln(data.sourceText.isEmpty ? '（暂无素材）' : data.sourceText);
    buffer.writeln('');
    buffer.writeln('## 目标联系人');
    buffer.writeln(contactsInfo);
    buffer.writeln('');
    if (data.instructionText.isNotEmpty) {
      buffer.writeln('## 额外要求');
      buffer.writeln(data.instructionText);
      buffer.writeln('');
    }
    buffer.writeln('## 输出要求');
    buffer.writeln('请为每位联系人生成具体可执行的社交任务，用JSON格式返回：');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "tasks": [');
    buffer.writeln('    {');
    buffer.writeln('      "contact_name": "联系人姓名",');
    buffer.writeln('      "title": "任务标题",');
    buffer.writeln('      "description": "任务详细描述",');
    buffer.writeln('      "type": "sendMessage|greeting|phoneCall|socialInteraction|other",');
    buffer.writeln('      "priority": 1-5,');
    buffer.writeln('      "scheduled_offset_days": 0-30,');
    buffer.writeln('      "scheduled_hour": 8-21');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```');
    return buffer.toString();
  }

  Future<void> _exportAndShare() async {
    setState(() => _isExporting = true);
    try {
      final data = context.read<_TaskCenterData>();
      final contactProvider = context.read<ContactProvider>();
      final contacts = data.contactIds
          .map((id) =>
              contactProvider.contacts.where((c) => c.id == id).firstOrNull)
          .whereType<Contact>()
          .toList();

      final prompt = _buildPrompt(data, contactProvider);

      final file = await PdfExporter.exportExternalAIPdf(
        title: '社交任务生成素材 - ${DateFormat('MM月dd日').format(DateTime.now())}',
        prompt: prompt,
        contactName: contacts.isEmpty ? null : '${contacts.length}位联系人',
        context: data.sourceText,
      );

      setState(() => _pdfPath = file.path);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: '社交任务AI素材 - ${DateFormat('MM月dd日').format(DateTime.now())}',
          text: '请将此PDF发送给外部AI，让AI按文档要求生成任务建议',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<_TaskCenterData>();
    final contactProvider = context.watch<ContactProvider>();
    final prompt = _buildPrompt(data, contactProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF6366F1).withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF6366F1)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '点击下方按钮导出PDF，将PDF发给外部AI（千问、豆包等），然后将AI回复粘贴回APP',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '已选 ${data.contactIds.length} 位联系人 · ${data.getDaysText()}周期',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Icon(
                        data.contactIds.isNotEmpty
                            ? Icons.check_circle
                            : Icons.warning,
                        color: data.contactIds.isNotEmpty
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ExportCard(
          title: '📋 AI提示词内容',
          content: prompt,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _exportAndShare,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isExporting ? '导出中...' : '导出PDF并分享'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_pdfPath != null) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('PDF已生成'),
              subtitle: Text(_pdfPath!),
              trailing: IconButton(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  await Share.shareXFiles(
                    [XFile(_pdfPath!)],
                    subject: '社交任务AI素材',
                  );
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: widget.onNext,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('下一步：粘贴AI结果'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6366F1),
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: Color(0xFF6366F1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasteResultTab extends StatefulWidget {
  const _PasteResultTab();

  @override
  State<_PasteResultTab> createState() => _PasteResultTabState();
}

class _PasteResultTabState extends State<_PasteResultTab> {
  final _resultController = TextEditingController();
  bool _isParsing = false;

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _parseAndCreateTasks() async {
    if (_resultController.text.trim().isEmpty) return;
    setState(() => _isParsing = true);

    try {
      final taskProvider = context.read<TaskProvider>();
      final tasks = _parseAIImage(_resultController.text);

      if (tasks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未能解析出有效任务，请检查AI回复格式'),
            ),
          );
        }
        return;
      }

      for (final task in tasks) {
        taskProvider.addTask(task);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功创建 ${tasks.length} 个任务！'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解析失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isParsing = false);
    }
  }

  List<SocialTask> _parseAIImage(String aiResponse) {
    final uuid = const Uuid();
    final contactProvider = context.read<ContactProvider>();
    final now = DateTime.now();

    List<Map<String, dynamic>> taskDataList = [];

    try {
      final jsonMatch = RegExp(r'\{[\s\S]*"tasks"[\s\S]*\}').firstMatch(aiResponse);
      if (jsonMatch != null) {
        String jsonStr = jsonMatch.group(0)!;
        jsonStr = jsonStr
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final tasksMatch =
            RegExp(r'"tasks"\s*:\s*(\[[\s\S]*\])').firstMatch(jsonStr);
        if (tasksMatch != null) {
          try {
            final listStr = tasksMatch.group(1)!;
            taskDataList = _tryParseJsonArray(listStr);
          } catch (_) {}
        }

        if (taskDataList.isEmpty) {
          try {
            final allTasks = RegExp(
                    r'\{[^{}]*"title"[^{}]*"type"[^{}]*"priority"[^{}]*\}',
                    multiLine: true)
                .all(jsonStr);
            for (final match in allTasks) {
              try {
                taskDataList.add(_parseSingleTaskJson(match.group(0)!));
              } catch (_) {}
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    if (taskDataList.isEmpty) {
      taskDataList = _fallbackParse(aiResponse);
    }

    final tasks = <SocialTask>[];
    for (final data in taskDataList) {
      final contactName = data['contact_name'] as String? ?? '';
      final contact = contactName.isNotEmpty
          ? contactProvider.contacts
              .where((c) => c.name == contactName)
              .firstOrNull
          : null;

      final typeStr = (data['type'] as String?)?.toLowerCase() ?? 'other';
      TaskType type;
      switch (typeStr) {
        case 'sendmessage':
        case 'send_message':
          type = TaskType.sendMessage;
          break;
        case 'greeting':
          type = TaskType.greeting;
          break;
        case 'phonecall':
        case 'phone_call':
          type = TaskType.phoneCall;
          break;
        case 'socialinteraction':
        case 'social_interaction':
          type = TaskType.socialInteraction;
          break;
        case 'sendvideo':
        case 'send_video':
          type = TaskType.sendVideo;
          break;
        default:
          type = TaskType.other;
      }

      final priority = (data['priority'] as int?)?.clamp(1, 5) ?? 3;
      final offsetDays = (data['scheduled_offset_days'] as int?) ?? 1;
      final hour = (data['scheduled_hour'] as int?)?.clamp(8, 21) ?? 10;
      final scheduledAt = DateTime(
        now.year,
        now.month,
        now.day + offsetDays,
        hour,
        0,
      );

      tasks.add(SocialTask(
        id: uuid.v4(),
        contactId: contact?.id ?? '',
        contactName:
            contact?.name ?? (contactName.isNotEmpty ? contactName : '全局'),
        title: data['title'] as String? ?? '社交任务',
        description: data['description'] as String? ?? '',
        type: type,
        status: TaskStatus.pending,
        scheduledAt: scheduledAt,
        priority: priority,
        goalRelation: contact?.goalRelation,
      ));
    }

    return tasks;
  }

  List<Map<String, dynamic>> _tryParseJsonArray(String str) {
    final results = <Map<String, dynamic>>[];
    try {
      final cleaned = str.trim();
      int depth = 0;
      int start = -1;
      for (int i = 0; i < cleaned.length; i++) {
        if (cleaned[i] == '{') {
          if (depth == 0) start = i;
          depth++;
        } else if (cleaned[i] == '}') {
          depth--;
          if (depth == 0 && start >= 0) {
            try {
              results.add(_parseSingleTaskJson(cleaned.substring(start, i + 1)));
            } catch (_) {}
            start = -1;
          }
        }
      }
    } catch (_) {}
    return results;
  }

  Map<String, dynamic> _parseSingleTaskJson(String json) {
    final result = <String, dynamic>{};
    try {
      final pairs = RegExp(
              r'"([^"]+)"\s*:\s*("[^"]*"|[\d]+|\[[^\]]*\]|\{[^}]*\})')
          .all(json);
      for (final pair in pairs) {
        final key = pair.group(1)!;
        var value = pair.group(2)!;
        if (value.startsWith('"')) {
          value = value.substring(1, value.length - 1);
        } else if (value.startsWith('[')) {
          value = value.substring(1, value.length - 1).trim();
        } else if (value.startsWith('{')) {
          value = '';
        }
        result[key] = value;
      }
    } catch (_) {}
    return result;
  }

  List<Map<String, dynamic>> _fallbackParse(String text) {
    final results = <Map<String, dynamic>>[];
    final lines = text.split('\n');
    var current = <String, dynamic>{};
    var inTask = false;

    for (final line in lines) {
      final trimmed = line.trim();
      final titleMatch = RegExp(r'(?:标题|title)[:：]\s*(.+)', caseSensitive: false)
          .firstMatch(trimmed);
      final descMatch = RegExp(r'(?:描述|description|详情)[:：]\s*(.+)', caseSensitive: false)
          .firstMatch(trimmed);
      final contactMatch = RegExp(r'(?:联系人|contact)[:：]\s*(.+)', caseSensitive: false)
          .firstMatch(trimmed);
      final typeMatch = RegExp(r'(?:类型|type)[:：]\s*(.+)', caseSensitive: false)
          .firstMatch(trimmed);
      final priorityMatch = RegExp(r'(?:优先级|priority)[:：]\s*(\d)', caseSensitive: false)
          .firstMatch(trimmed);

      if (titleMatch != null) {
        if (inTask && current.isNotEmpty) {
          results.add(current);
          current = {};
        }
        inTask = true;
        current['title'] = titleMatch.group(1)!.trim();
      } else if (descMatch != null) {
        current['description'] = descMatch.group(1)!.trim();
      } else if (contactMatch != null) {
        current['contact_name'] = contactMatch.group(1)!.trim();
      } else if (typeMatch != null) {
        current['type'] = typeMatch.group(1)!.trim().toLowerCase();
      } else if (priorityMatch != null) {
        current['priority'] = int.tryParse(priorityMatch.group(1)!) ?? 3;
      }
    }

    if (inTask && current.isNotEmpty) {
      results.add(current);
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF6366F1).withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.paste, color: Color(0xFF6366F1)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '粘贴AI回复，一键生成任务',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '将外部AI的完整回复粘贴到下方输入框，APP将自动解析并生成任务。',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _resultController,
          decoration: InputDecoration(
            labelText: 'AI回复内容',
            hintText: '在此粘贴AI的完整回复...',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _resultController.clear(),
            ),
          ),
          maxLines: 15,
          minLines: 8,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isParsing ? null : _parseAndCreateTasks,
                icon: _isParsing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isParsing ? '解析中...' : '解析并创建任务'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ExpansionTile(
            title: const Text('支持的AI回复格式'),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅ JSON格式（推荐）'),
                    const SizedBox(height: 4),
                    const Text(
                      '包含 tasks 数组的JSON，每个任务含 title、description、type、priority等字段',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ 文本格式'),
                    const SizedBox(height: 4),
                    const Text(
                      '包含"标题"、"描述"、"类型"、"优先级"等关键词的结构化文本',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final String title;
  final String content;

  const _ExportCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已复制')),
                    );
                  },
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
