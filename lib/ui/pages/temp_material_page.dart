import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/providers/persona_provider.dart';
import '../../models/temp_material.dart';
import '../../models/persona.dart';

class TempMaterialPage extends StatefulWidget {
  const TempMaterialPage({super.key});

  @override
  State<TempMaterialPage> createState() => _TempMaterialPageState();
}

class _TempMaterialPageState extends State<TempMaterialPage> {
  String? _selectedGroupId;
  final List<String> _imagePaths = [];
  final _textController = TextEditingController();
  final _captionController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _textController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('临时素材'),
      ),
      body: Consumer<PersonaProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 选择分组
              _buildGroupSelector(provider),
              const SizedBox(height: 16),

              // 图片区域
              _buildImageSection(),
              const SizedBox(height: 16),

              // 文字描述
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: '文字描述',
                  hintText: '描述你想发的内容、心情或场景',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // AI 配文案按钮
              FilledButton.icon(
                onPressed: _isGenerating ? null : () => _generateCaption(provider),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? 'AI 生成中...' : 'AI 配文案'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 生成的文案（可编辑）
              if (_captionController.text.isNotEmpty || _isGenerating)
                TextField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    labelText: '生成文案（可编辑）',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  maxLines: 5,
                ),
              const SizedBox(height: 16),

              // 生成发圈任务按钮
              if (_captionController.text.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _createPostTask(provider),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('生成发圈任务'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // 历史素材
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '历史素材',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${provider.tempMaterials.length} 条',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (provider.tempMaterials.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '暂无历史素材',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...provider.tempMaterials.map((m) => _MaterialHistoryCard(
                      material: m,
                      groupName:
                          provider.getGroupById(m.groupId)?.name ?? '未分组',
                      onDelete: () => provider.deleteTempMaterial(m.id),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupSelector(PersonaProvider provider) {
    return DropdownButtonFormField<String>(
      value: _selectedGroupId,
      decoration: const InputDecoration(
        labelText: '选择分组',
        hintText: '选择素材关联的联系人分组',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.group_outlined),
      ),
      items: provider.groups.map((group) {
        return DropdownMenuItem(
          value: group.id,
          child: Row(
            children: [
              Text(group.icon ?? '👥', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(group.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedGroupId = value),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '图片',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_imagePaths.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        '暂未添加图片',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagePaths[index]),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imagePaths.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_outlined, size: 18),
                        label: const Text('从相册'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('拍照'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        final images = await picker.pickMultiImage();
        setState(() {
          _imagePaths.addAll(images.map((x) => x.path));
        });
      } else {
        final image = await picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _imagePaths.add(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  Future<void> _generateCaption(PersonaProvider provider) async {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择分组')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final textContent = _textController.text.trim();
      final material = await provider.addTempMaterial(
        groupId: _selectedGroupId!,
        materialType: _imagePaths.isNotEmpty
            ? TempMaterialType.image
            : TempMaterialType.text,
        filePath: _imagePaths.isNotEmpty ? _imagePaths.first : null,
        textContent: textContent.isEmpty ? null : textContent,
      );

      final caption = await provider.generateCaptionForMaterial(material.id);
      if (caption != null) {
        _captionController.text = caption;
      } else if (provider.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.errorMessage!)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _createPostTask(PersonaProvider provider) async {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择分组')),
      );
      return;
    }

    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文案不能为空')),
      );
      return;
    }

    // 保存素材
    final material = await provider.addTempMaterial(
      groupId: _selectedGroupId!,
      materialType: _imagePaths.isNotEmpty
          ? TempMaterialType.image
          : TempMaterialType.text,
      filePath: _imagePaths.isNotEmpty ? _imagePaths.first : null,
      textContent: _textController.text.trim().isEmpty
          ? null
          : _textController.text.trim(),
    );

    // 为素材生成发圈任务（内部会创建动态 + 社交任务）
    // captionOverride 传入用户编辑后的文案
    final result = await provider.generatePostingTask(
      material.id,
      captionOverride: caption,
    );

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发圈任务已生成！')),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!)),
        );
      }
      // 清空当前输入
      setState(() {
        _imagePaths.clear();
        _textController.clear();
        _captionController.clear();
      });
    }
  }
}

class _MaterialHistoryCard extends StatelessWidget {
  final TempMaterial material;
  final String groupName;
  final VoidCallback onDelete;

  const _MaterialHistoryCard({
    required this.material,
    required this.groupName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(material.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                ),
              ],
            ),
            if (material.textContent != null &&
                material.textContent!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                material.textContent!,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (material.filePath != null &&
                material.materialType == TempMaterialType.image) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(material.filePath!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
            if (material.aiCaption != null &&
                material.aiCaption!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  material.aiCaption!,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
