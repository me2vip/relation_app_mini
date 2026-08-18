import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../models/contact.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class ExternalAIPage extends StatefulWidget {
  const ExternalAIPage({super.key});

  @override
  State<ExternalAIPage> createState() => _ExternalAIPageState();
}

class _ExternalAIPageState extends State<ExternalAIPage> {
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();
  final _contextController = TextEditingController();
  String? _selectedContactId;
  List<String> _selectedAttachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('外部AI交互'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        '使用说明',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    '1. 填写任务标题和提示词\n'
                    '2. 选择关联的联系人（可选）\n'
                    '3. 添加背景信息\n'
                    '4. 点击"生成PDF"导出\n'
                    '5. 将PDF发送给外部AI（如千问、豆包）\n'
                    '6. 将AI回复复制回APP',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '任务设置',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '任务标题',
              hintText: '如：社交策略分析',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          Consumer<ContactProvider>(
            builder: (context, provider, _) {
              return DropdownButtonFormField<String>(
                value: _selectedContactId,
                decoration: const InputDecoration(
                  labelText: '关联联系人',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('无'),
                  ),
                  ...provider.contacts.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedContactId = value);
                  _updateContextFromContact(value);
                },
              );
            },
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              labelText: '提示词',
              hintText: '描述你想要AI帮你完成的任务',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _contextController,
            decoration: const InputDecoration(
              labelText: '背景信息',
              hintText: '补充相关的背景信息',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 15),
          const Text(
            '附件（可选）',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._selectedAttachments.map((path) {
                return Chip(
                  label: Text(
                    path.split('/').last,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onDeleted: () {
                    setState(() {
                      _selectedAttachments.remove(path);
                    });
                  },
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('添加文件'),
                onPressed: _pickFile,
              ),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _generatePdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('生成PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(15),
            ),
          ),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '支持的外部AI',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _ExternalAIItem(
                    name: '通义千问',
                    icon: Icons.auto_awesome,
                  ),
                  _ExternalAIItem(
                    name: '豆包',
                    icon: Icons.egg,
                  ),
                  _ExternalAIItem(
                    name: 'Kimi',
                    icon: Icons.psychology,
                  ),
                  _ExternalAIItem(
                    name: '文心一言',
                    icon: Icons.auto_stories,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateContextFromContact(String? contactId) {
    if (contactId == null) return;
    
    final provider = context.read<ContactProvider>();
    final contact = provider.contacts.firstWhere(
      (c) => c.id == contactId,
      orElse: () => Contact(
        id: '',
        name: '',
        level: ContactLevel.normal,
        methods: [],
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // 自动填充联系人信息到背景
    final buffer = StringBuffer();
    buffer.writeln('联系人: ${contact.name}');
    buffer.writeln('关系: ${contact.levelName}');
    if (contact.goalRelation != null) {
      buffer.writeln('目标关系: ${contact.goalRelation}');
    }
    
    _contextController.text = buffer.toString();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        allowMultiple: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null && !_selectedAttachments.contains(file.path)) {
              _selectedAttachments.add(file.path!);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务标题')),
      );
      return;
    }

    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入提示词')),
      );
      return;
    }

    try {
      String? contactName;
      if (_selectedContactId != null) {
        final provider = context.read<ContactProvider>();
        final contact = provider.contacts.firstWhere(
          (c) => c.id == _selectedContactId,
          orElse: () => Contact(
            id: '',
            name: '未知',
            level: ContactLevel.normal,
            methods: [],
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        contactName = contact.name;
      }

      final pdfFile = await PdfExporter.exportExternalAIPdf(
        title: _titleController.text,
        prompt: _promptController.text,
        contactName: contactName,
        context: _contextController.text.isNotEmpty ? _contextController.text : null,
        attachments: _selectedAttachments.isNotEmpty ? _selectedAttachments : null,
      );

      if (mounted) {
        _showPdfOptions(pdfFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成PDF失败: $e')),
        );
      }
    }
  }

  void _showPdfOptions(File pdfFile) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 15),
              const Text(
                'PDF已生成',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                pdfFile.path.split('/').last,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      PdfExporter.sharePdf(pdfFile);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('分享'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      PdfExporter.printPdf(pdfFile);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('打印'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExternalAIItem extends StatelessWidget {
  final String name;
  final IconData icon;

  const _ExternalAIItem({
    required this.name,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text(name),
        ],
      ),
    );
  }
}
