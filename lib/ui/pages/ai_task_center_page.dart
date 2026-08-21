import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../models/task.dart';
import '../../models/contact.dart';

enum MediaType { image, video, audio, file }

class MediaAttachment {
  final String id;
  final MediaType type;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String? description;

  const MediaAttachment({
    required this.id,
    required this.type,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.description,
  });

  MediaAttachment copyWith({
    String? id,
    MediaType? type,
    String? filePath,
    String? fileName,
    int? fileSize,
    String? description,
  }) {
    return MediaAttachment(
      id: id ?? this.id,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      description: description ?? this.description,
    );
  }

  String get typeLabel {
    switch (type) {
      case MediaType.image:
        return '图片';
      case MediaType.video:
        return '视频';
      case MediaType.audio:
        return '音频';
      case MediaType.file:
        return '文件';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case MediaType.image:
        return Icons.image;
      case MediaType.video:
        return Icons.videocam;
      case MediaType.audio:
        return Icons.audiotrack;
      case MediaType.file:
        return Icons.insert_drive_file;
    }
  }
}

class TaskHistory {
  final String id;
  final String sourceText;
  final List<String> contactNames;
  final int taskCount;
  final DateTime createdAt;
  final String prompt;

  TaskHistory({
    required this.id,
    required this.sourceText,
    required this.contactNames,
    required this.taskCount,
    required this.createdAt,
    required this.prompt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceText': sourceText,
    'contactNames': contactNames,
    'taskCount': taskCount,
    'createdAt': createdAt.toIso8601String(),
    'prompt': prompt,
  };

  factory TaskHistory.fromJson(Map<String, dynamic> json) => TaskHistory(
    id: json['id'] as String,
    sourceText: json['sourceText'] as String,
    contactNames: List<String>.from(json['contactNames'] as List),
    taskCount: json['taskCount'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    prompt: json['prompt'] as String,
  );
}

class _TaskCenterData extends ChangeNotifier {
  String sourceText = '';
  String instructionText = '';
  List<String> contactIds = [];
  List<String> days = ['7天'];
  int priority = 3;
  List<MediaAttachment> attachments = [];
  List<TaskHistory> history = [];

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

  void addAttachment(MediaAttachment att) {
    attachments = [...attachments, att];
    notifyListeners();
  }

  void removeAttachment(String id) {
    attachments = attachments.where((a) => a.id != id).toList();
    notifyListeners();
  }

  void updateAttachmentDescription(String id, String desc) {
    attachments = attachments.map((a) {
      if (a.id == id) return a.copyWith(description: desc);
      return a;
    }).toList();
    notifyListeners();
  }

  void addHistory(TaskHistory h) {
    history = [h, ...history].take(20).toList();
    notifyListeners();
  }

  void clearHistory() {
    history = [];
    notifyListeners();
  }

  void removeHistory(String id) {
    history = history.where((h) => h.id != id).toList();
    notifyListeners();
  }

  String getDaysText() {
    if (days.isEmpty) return '一周';
    return days.join('、');
  }

  List<MediaAttachment> get getImages =>
      attachments.where((a) => a.type == MediaType.image).toList();
  List<MediaAttachment> get getVideos =>
      attachments.where((a) => a.type == MediaType.video).toList();
  List<MediaAttachment> get getAudios =>
      attachments.where((a) => a.type == MediaType.audio).toList();
  List<MediaAttachment> get getFiles =>
      attachments.where((a) => a.type == MediaType.file).toList();

  List<String> getAttachmentDescriptions() {
    final result = <String>[];
    for (final att in attachments) {
      final desc = att.description?.trim();
      if (desc != null && desc.isNotEmpty) {
        result.add('${att.typeLabel}: $desc');
      } else {
        result.add('${att.typeLabel}: ${att.fileName}');
      }
    }
    return result;
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
    _tabController = TabController(length: 4, vsync: this);
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
              Tab(text: '1. 素材输入'),
              Tab(text: '2. 导出PDF'),
              Tab(text: '3. 粘贴结果'),
              Tab(text: '📜 历史记录'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _MaterialTab(onNext: () => _tabController.animateTo(1)),
            _ExportTab(onNext: () => _tabController.animateTo(2)),
            const _PasteResultTab(),
            const _HistoryTab(),
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
  final _imagePicker = ImagePicker();
  bool _isPicking = false;

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

  Future<void> _pickImages() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final files = await _imagePicker.pickMultiImage();
      if (files == null || files.isEmpty) return;
      final data = context.read<_TaskCenterData>();
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final att = MediaAttachment(
          id: const Uuid().v4(),
          type: MediaType.image,
          filePath: file.path,
          fileName: file.name,
          fileSize: bytes.length,
          description: '',
        );
        data.addAttachment(att);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final data = context.read<_TaskCenterData>();
      final att = MediaAttachment(
        id: const Uuid().v4(),
        type: MediaType.video,
        filePath: file.path,
        fileName: file.name,
        fileSize: bytes.length,
        description: '',
      );
      data.addAttachment(att);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择视频失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickAudio() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final path = file.path;
      if (path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法获取音频文件路径，请尝试其他文件')),
          );
        }
        return;
      }
      final data = context.read<_TaskCenterData>();
      final att = MediaAttachment(
        id: const Uuid().v4(),
        type: MediaType.audio,
        filePath: path,
        fileName: file.name,
        fileSize: file.size ?? 0,
        description: '',
      );
      data.addAttachment(att);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择音频失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickFile() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;
      final data = context.read<_TaskCenterData>();
      for (final file in result.files) {
        final path = file.path;
        if (path == null) continue;
        final att = MediaAttachment(
          id: const Uuid().v4(),
          type: MediaType.file,
          filePath: path,
          fileName: file.name,
          fileSize: file.size ?? 0,
          description: '',
        );
        data.addAttachment(att);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
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
          title: '文字素材',
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
          title: '多媒体素材',
          subtitle: '添加图片、视频、音频、文档等素材',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MediaAddButton(
                      icon: Icons.image,
                      label: '图片',
                      color: Colors.blue,
                      onTap: _pickImages,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MediaAddButton(
                      icon: Icons.videocam,
                      label: '视频',
                      color: Colors.red,
                      onTap: _pickVideo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MediaAddButton(
                      icon: Icons.audiotrack,
                      label: '音频',
                      color: Colors.green,
                      onTap: _pickAudio,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MediaAddButton(
                      icon: Icons.insert_drive_file,
                      label: '文件',
                      color: Colors.orange,
                      onTap: _pickFile,
                    ),
                  ),
                ],
              ),
              if (_isPicking) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (data.attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '已添加素材 (${data.attachments.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...data.attachments.map((att) => _MediaItemTile(
                      attachment: att,
                      onRemove: () => data.removeAttachment(att.id),
                      onUpdateDesc: (desc) =>
                          data.updateAttachmentDescription(att.id, desc),
                    )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StepCard(
          step: 3,
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
          step: 4,
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
          step: 5,
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

class _MediaAddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaAddButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _MediaItemTile extends StatefulWidget {
  final MediaAttachment attachment;
  final VoidCallback onRemove;
  final Function(String) onUpdateDesc;

  const _MediaItemTile({
    required this.attachment,
    required this.onRemove,
    required this.onUpdateDesc,
  });

  @override
  State<_MediaItemTile> createState() => _MediaItemTileState();
}

class _MediaItemTileState extends State<_MediaItemTile> {
  late final TextEditingController _descController;
  bool _isEditingDesc = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.attachment.description ?? '');
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final att = widget.attachment;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildThumbnail(att),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(att.type).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              att.typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: _getTypeColor(att.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              att.fileName,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatSize(att.fileSize),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_isEditingDesc)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '添加描述（例如：这是上周聚会的合照）',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      style: const TextStyle(fontSize: 12),
                      onSubmitted: (v) {
                        widget.onUpdateDesc(v);
                        setState(() => _isEditingDesc = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.check, size: 18),
                    onPressed: () {
                      widget.onUpdateDesc(_descController.text);
                      setState(() => _isEditingDesc = false);
                    },
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: () => setState(() => _isEditingDesc = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (() {
                      final desc = att.description;
                      return desc != null && desc.isNotEmpty
                          ? desc
                          : '点击添加描述（可选）';
                    })(),
                    style: TextStyle(
                      fontSize: 12,
                      color: (() {
                        final desc = att.description;
                        return desc != null && desc.isNotEmpty
                            ? Colors.black87
                            : Colors.grey.shade500;
                      })(),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(MediaAttachment att) {
    if (att.type == MediaType.image && File(att.filePath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(att.filePath),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 48,
            height: 48,
            color: Colors.blue.shade100,
            child: Icon(Icons.image, size: 24, color: Colors.blue.shade400),
          ),
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getTypeColor(att.type).withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(att.typeIcon, size: 24, color: _getTypeColor(att.type)),
    );
  }

  Color _getTypeColor(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Colors.blue;
      case MediaType.video:
        return Colors.red;
      case MediaType.audio:
        return Colors.green;
      case MediaType.file:
        return Colors.orange;
    }
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
    if (data.attachments.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('## 附加素材');
      for (final desc in data.getAttachmentDescriptions()) {
        buffer.writeln('• $desc');
      }
    }
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
    buffer.writeln('      "steps": ["步骤1的具体执行指导", "步骤2的具体执行指导", ...]');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln('');
    buffer.writeln('重要：每个任务必须包含steps字段，列出3-5个具体可执行的步骤指导。');
    buffer.writeln('步骤指导要具体，包含要说的话、要做的动作、注意事项等。');
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

enum ExportMode { zip, imagePdf, fullPdf }

class _ExportTabState extends State<_ExportTab> {
  bool _isExporting = false;
  String? _pdfPath;
  String? _zipPath;
  ExportMode _exportMode = ExportMode.fullPdf;

  List<String> _buildAttachmentList(_TaskCenterData data) {
    final attachments = <String>[...data.getAttachmentDescriptions()];
    var imageIdx = 1;
    for (final a in data.attachments) {
      if (a.type != MediaType.image) continue;
      final path = a.filePath;
      if (path.isEmpty) continue;
      final desc = (a.description?.trim().isNotEmpty == true)
          ? a.description!.trim()
          : a.fileName;
      attachments.add('![图片素材$imageIdx: $desc]($path)');
      imageIdx++;
    }
    return attachments;
  }

  bool _hasImages(_TaskCenterData data) {
    return data.attachments.any((a) => a.type == MediaType.image && a.filePath.isNotEmpty);
  }

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
    if (data.attachments.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('## 附加素材（已通过PDF附加）');
      for (final desc in data.getAttachmentDescriptions()) {
        buffer.writeln('• $desc');
      }
    }
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
    buffer.writeln('      "steps": ["步骤1的具体执行指导", "步骤2的具体执行指导", ...]');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln('');
    buffer.writeln('重要：每个任务必须包含steps字段，列出3-5个具体可执行的步骤指导。');
    buffer.writeln('步骤指导要具体，包含要说的话、要做的动作、注意事项等。');
    return buffer.toString();
  }

  String _getAiExecutionPrompt() {
    final data = context.read<_TaskCenterData>();
    final buffer = StringBuffer();
    buffer.writeln('【复制以下内容，发送给AI】');
    buffer.writeln('');
    buffer.writeln('请按照我发送的PDF文档要求执行任务。');
    buffer.writeln('');
    buffer.writeln('具体要求：');
    buffer.writeln('1. 阅读PDF文档中的所有素材和指令');
    buffer.writeln('2. 分析每位联系人的特点和关系阶段');
    buffer.writeln('3. 为每位联系人生成${data.getDaysText()}内的社交任务建议');
    buffer.writeln('4. 严格按照PDF中的JSON格式返回结果');
    buffer.writeln('5. 每个任务必须包含：联系人姓名、任务标题、详细描述、任务类型、优先级(1-5)、建议执行天数和时间');
    buffer.writeln('6. 每个任务必须包含steps字段，提供3-5个具体可执行的步骤指导');
    buffer.writeln('');
    buffer.writeln('请确保输出是完整的JSON格式，方便后续解析。');
    return buffer.toString();
  }

  Future<void> _exportAndShare() async {
    switch (_exportMode) {
      case ExportMode.zip:
        await _exportZip();
        break;
      case ExportMode.imagePdf:
        await _exportImagePdf();
        break;
      case ExportMode.fullPdf:
        await _exportFullPdf();
        break;
    }
  }

  Future<void> _exportZip() async {
    setState(() => _isExporting = true);
    try {
      final data = context.read<_TaskCenterData>();
      final contactProvider = context.read<ContactProvider>();
      final contacts = data.contactIds
          .map((id) => contactProvider.contacts.where((c) => c.id == id).firstOrNull)
          .whereType<Contact>()
          .toList();

      final prompt = _buildPrompt(data, contactProvider);
      final attachments = _buildAttachmentList(data);
      final titleStr = '社交任务生成素材 - ${DateFormat('MM月dd日').format(DateTime.now())}';

      final zipFile = await PdfExporter.exportZipWithResources(
        title: titleStr,
        prompt: prompt,
        contactName: contacts.isEmpty ? null : '${contacts.length}位联系人',
        context: data.sourceText,
        attachments: attachments.isNotEmpty ? attachments : null,
      );

      setState(() => _zipPath = zipFile.path);

      await Share.shareXFiles(
        [XFile(zipFile.path)],
        subject: '社交任务AI素材 - ${DateFormat('MM月dd日').format(DateTime.now())}',
        text: '将此ZIP解压后，把Markdown和图片一起发送给AI即可。',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ZIP已生成并分享: ${zipFile.path.split('/').last}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ZIP导出失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportImagePdf() async {
    setState(() => _isExporting = true);
    try {
      final data = context.read<_TaskCenterData>();
      final hasImages = _hasImages(data);

      if (!hasImages) {
        final prompt = _getAiExecutionPrompt();
        await Clipboard.setData(ClipboardData(text: prompt));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无图片素材，已复制AI提示词到剪贴板'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final attachments = _buildAttachmentList(data);
      final titleStr = '社交任务图片素材 - ${DateFormat('MM月dd日').format(DateTime.now())}';

      final imgFile = await PdfExporter.exportImageOnlyPdf(
        title: titleStr,
        attachments: attachments.isNotEmpty ? attachments : null,
      );

      if (imgFile != null) {
        setState(() => _pdfPath = imgFile.path);
        await Share.shareXFiles(
          [XFile(imgFile.path)],
          subject: '社交任务图片素材',
          text: '图片素材，请发送给AI分析。',
        );
      }

      final prompt = _getAiExecutionPrompt();
      await Clipboard.setData(ClipboardData(text: prompt));

      if (mounted) {
        final msg = imgFile != null
            ? '图片PDF已分享，AI提示词已复制到剪贴板'
            : 'AI提示词已复制到剪贴板';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
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

  Future<void> _exportFullPdf() async {
    setState(() => _isExporting = true);
    String phase = '初始化';
    try {
      phase = '读取数据';
      final data = context.read<_TaskCenterData>();
      final contactProvider = context.read<ContactProvider>();
      final contacts = data.contactIds
          .map((id) => contactProvider.contacts.where((c) => c.id == id).firstOrNull)
          .whereType<Contact>()
          .toList();

      phase = '生成PDF';
      final prompt = _buildPrompt(data, contactProvider);
      final attachments = _buildAttachmentList(data);
      final titleStr = '社交任务生成素材 - ${DateFormat('MM月dd日').format(DateTime.now())}';

      final result = await PdfExporter.exportExternalAIPdfEx(
        title: titleStr,
        prompt: prompt,
        contactName: contacts.isEmpty ? null : '${contacts.length}位联系人',
        context: data.sourceText,
        attachments: attachments.isNotEmpty ? attachments : null,
      );

      phase = '分享PDF';
      setState(() => _pdfPath = result.file.path);

      await Share.shareXFiles(
        [XFile(result.file.path)],
        subject: '社交任务AI素材 - ${DateFormat('MM月dd日').format(DateTime.now())}',
        text: '请将此PDF发送给外部AI，让AI按文档要求生成任务建议。AI返回完整回复后，将回复全文复制回APP即可自动保存任务。',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF已生成(${result.level})并分享'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        final buf = StringBuffer();
        buf.writeln('阶段: $phase');
        buf.writeln('异常: $e');
        buf.writeln('堆栈: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _copyExecutionPrompt() async {
    final prompt = _getAiExecutionPrompt();
    await Clipboard.setData(ClipboardData(text: prompt));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提示词已复制到剪贴板')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<_TaskCenterData>();
    final contactProvider = context.watch<ContactProvider>();
    final prompt = _buildPrompt(data, contactProvider);
    final executionPrompt = _getAiExecutionPrompt();
    final hasImages = _hasImages(data);
    final savedPdfPath = _pdfPath;
    final savedZipPath = _zipPath;

    String modeLabel;
    IconData modeIcon;
    switch (_exportMode) {
      case ExportMode.zip:
        modeLabel = '导出ZIP并分享';
        modeIcon = Icons.folder_zip;
        break;
      case ExportMode.imagePdf:
        modeLabel = hasImages ? '导出图片PDF+复制提示词' : '复制AI提示词';
        modeIcon = hasImages ? Icons.image : Icons.content_copy;
        break;
      case ExportMode.fullPdf:
        modeLabel = '导出PDF并分享';
        modeIcon = Icons.picture_as_pdf;
        break;
    }

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
                        '选择导出方式，将素材发送给外部AI分析',
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
                          '已选 ${data.contactIds.length} 位联系人 · ${data.getDaysText()}周期 · ${data.attachments.length} 个素材',
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('选择导出方式', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildModeTile(
                  icon: Icons.folder_zip,
                  title: '方式一：导出ZIP包',
                  subtitle: 'Markdown文档 + 图片资源（相对路径），解压后可直接在支持Markdown的AI工具中使用',
                  selected: _exportMode == ExportMode.zip,
                  onSelect: () => setState(() => _exportMode = ExportMode.zip),
                ),
                const SizedBox(height: 8),
                _buildModeTile(
                  icon: Icons.image,
                  title: '方式二：复制提示词 + 图片PDF',
                  subtitle: hasImages ? '仅导出图片素材PDF（无图片则跳过），自动复制AI调用提示词到剪贴板' : '当前无图片素材，点击后仅复制AI提示词',
                  selected: _exportMode == ExportMode.imagePdf,
                  onSelect: () => setState(() => _exportMode = ExportMode.imagePdf),
                ),
                const SizedBox(height: 8),
                _buildModeTile(
                  icon: Icons.picture_as_pdf,
                  title: '方式三：完整PDF + AI提示词',
                  subtitle: '导出包含提示词和图片的完整PDF，配合第三方AI调用提示词使用',
                  selected: _exportMode == ExportMode.fullPdf,
                  onSelect: () => setState(() => _exportMode = ExportMode.fullPdf),
                ),
              ],
            ),
          ),
        ),
        if (_exportMode == ExportMode.fullPdf) ...[
          const SizedBox(height: 16),
          _ExportCard(
            title: '📋 AI提示词内容（将写入PDF）',
            content: prompt,
          ),
          const SizedBox(height: 16),
          _AiExecutionPromptCard(
            prompt: executionPrompt,
            onCopy: _copyExecutionPrompt,
          ),
        ],
        if (_exportMode == ExportMode.zip) ...[
          const SizedBox(height: 16),
          _ExportCard(
            title: '📋 将打包进ZIP的Markdown内容',
            content: prompt,
          ),
        ],
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
                    : Icon(modeIcon),
                label: Text(_isExporting ? '导出中...' : modeLabel),
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
        if (savedPdfPath != null || savedZipPath != null) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                savedZipPath != null ? Icons.check_circle : Icons.check_circle,
                color: Colors.green,
              ),
              title: Text(savedZipPath != null ? 'ZIP已生成' : 'PDF已生成'),
              subtitle: Text((savedZipPath ?? savedPdfPath) ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  final path = savedZipPath ?? savedPdfPath;
                  if (path != null) {
                    await Share.shareXFiles(
                      [XFile(path)],
                      subject: '社交任务AI素材',
                    );
                  }
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

  Widget _buildModeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? const Color(0xFF6366F1) : Colors.grey, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected ? const Color(0xFF6366F1) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFF6366F1) : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiExecutionPromptCard extends StatelessWidget {
  final String prompt;
  final VoidCallback onCopy;

  const _AiExecutionPromptCard({
    required this.prompt,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFF9800).withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFF9800)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '🎯 第三方AI执行指令（复制发送给AI）',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: onCopy,
                  tooltip: '复制提示词',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Text(
                  prompt,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('一键复制'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(36),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      final data = context.read<_TaskCenterData>();
      final contactProvider = context.read<ContactProvider>();
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

      // 保存到历史记录（闭环）
      final contactNames = data.contactIds
          .map((id) => contactProvider.contacts
              .where((c) => c.id == id)
              .firstOrNull?.name ?? id)
          .toList();
      final prompt = _buildPromptForHistory(data);
      final history = TaskHistory(
        id: const Uuid().v4(),
        sourceText: data.sourceText,
        contactNames: contactNames,
        taskCount: tasks.length,
        createdAt: DateTime.now(),
        prompt: prompt,
      );
      data.addHistory(history);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功创建 ${tasks.length} 个任务！已保存到历史记录'),
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

  String _buildPromptForHistory(_TaskCenterData data) {
    final attachs = data.getAttachmentDescriptions();
    final buffer = StringBuffer();
    buffer.writeln('【任务上下文】${data.sourceText.isEmpty ? '(无)' : data.sourceText}');
    buffer.writeln('【周期】${data.days.join('/')}');
    buffer.writeln('【素材数量】${attachs.length}');
    if (attachs.isNotEmpty) {
      for (var i = 0; i < attachs.length; i++) {
        buffer.writeln('  ${i + 1}. ${attachs[i]}');
      }
    }
    return buffer.toString().trim();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  List<String> _extractSteps(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) return [];
      if (cleaned.startsWith('[') || cleaned.startsWith('[')) {
        try {
          final listStr = cleaned.substring(cleaned.indexOf('[') + 1, cleaned.lastIndexOf(']'));
          final parts = listStr.split(',');
          return parts.map((e) {
            var s = e.trim();
            if (s.startsWith('"')) s = s.substring(1);
            if (s.endsWith('"')) s = s.substring(0, s.length - 1);
            return s;
          }).where((e) => e.isNotEmpty).toList();
        } catch (_) {}
      }
      return cleaned
          .split(RegExp(r'[\n\r]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<SocialTask> _parseAIImage(String aiResponse) {
    final uuid = const Uuid();
    final contactProvider = context.read<ContactProvider>();
    final now = DateTime.now();

    List<Map<String, dynamic>> taskDataList = [];

    try {
      final jsonMatch = RegExp(r'\{[\s\S]*"tasks"[\s\S]*\}').firstMatch(aiResponse);
      if (jsonMatch != null) {
        String jsonStr = jsonMatch.group(0) ?? '';
        jsonStr = jsonStr
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final tasksMatch =
            RegExp(r'"tasks"\s*:\s*(\[[\s\S]*\])').firstMatch(jsonStr);
        if (tasksMatch != null) {
          try {
            final listStr = tasksMatch.group(1) ?? '[]';
            taskDataList = _tryParseJsonArray(listStr);
          } catch (_) {}
        }

        if (taskDataList.isEmpty) {
          try {
            final allTasks = RegExp(
                    r'\{[^{}]*"title"[^{}]*"type"[^{}]*"priority"[^{}]*\}',
                    multiLine: true)
                .allMatches(jsonStr);
            for (final match in allTasks) {
              try {
                final taskJson = match.group(0) ?? '';
                if (taskJson.isNotEmpty) {
                  taskDataList.add(_parseSingleTaskJson(taskJson));
                }
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
    for (final taskData in taskDataList) {
      final contactName = taskData['contact_name'] as String? ?? '';
      final contact = contactName.isNotEmpty
          ? contactProvider.contacts
              .where((c) => c.name == contactName)
              .firstOrNull
          : null;

      final typeStr = (taskData['type'] as String?)?.toLowerCase() ?? 'other';
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

      final priority = _toInt(taskData['priority'])?.clamp(1, 5) ?? 3;
      final offsetDays = _toInt(taskData['scheduled_offset_days']) ?? 1;
      final hour = _toInt(taskData['scheduled_hour'])?.clamp(8, 21) ?? 10;
      final scheduledAt = DateTime(
        now.year,
        now.month,
        now.day + offsetDays,
        hour,
        0,
      );

      final steps = _extractSteps(taskData['steps']);

      tasks.add(SocialTask(
        id: uuid.v4(),
        contactId: contact?.id ?? '',
        contactName:
            contact?.name ?? (contactName.isNotEmpty ? contactName : '全局'),
        title: taskData['title'] as String? ?? '社交任务',
        description: taskData['description'] as String? ?? '',
        type: type,
        status: TaskStatus.pending,
        scheduledAt: scheduledAt,
        priority: priority,
        goalRelation: contact?.goalRelation,
        steps: steps,
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
          .allMatches(json);
      for (final pair in pairs) {
        final key = pair.group(1) ?? '';
        var value = pair.group(2) ?? '';
        if (value.startsWith('"')) {
          value = value.substring(1, value.length - 1);
        } else if (value.startsWith('[')) {
          value = value.substring(1, value.length - 1).trim();
        } else if (value.startsWith('{')) {
          value = '';
        }
        if (key.isNotEmpty) {
          result[key] = value;
        }
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
        current['title'] = titleMatch.group(1)?.trim() ?? '';
      } else if (descMatch != null) {
        current['description'] = descMatch.group(1)?.trim() ?? '';
      } else if (contactMatch != null) {
        current['contact_name'] = contactMatch.group(1)?.trim() ?? '';
      } else if (typeMatch != null) {
        current['type'] = typeMatch.group(1)?.trim().toLowerCase() ?? '';
      } else if (priorityMatch != null) {
        current['priority'] = int.tryParse(priorityMatch.group(1) ?? '3') ?? 3;
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
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已复制到剪贴板')),
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
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Text(
                  content,
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

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<_TaskCenterData>();
    final history = data.history;

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '暂无历史记录',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '完成任务生成后，历史记录会显示在这里',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '历史记录 (${history.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  data.clearHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已清空历史记录')),
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('清空'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _HistoryItem(
                history: item,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: item.prompt));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('提示词已复制')),
                  );
                },
                onDelete: () => data.removeHistory(item.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final TaskHistory history;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _HistoryItem({
    required this.history,
    required this.onCopy,
    required this.onDelete,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inMinutes < 60) return '${difference.inMinutes}分钟前';
    if (difference.inHours < 24) return '${difference.inHours}小时前';
    if (difference.inDays < 7) return '${difference.inDays}天前';
    return DateFormat('MM月dd日 HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '生成 ${history.taskCount} 个任务',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatTime(history.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: onCopy,
                  tooltip: '复制提示词',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  onPressed: onDelete,
                  tooltip: '删除',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (history.sourceText.isNotEmpty)
              Text(
                history.sourceText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (history.contactNames.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: history.contactNames.take(5).map((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
