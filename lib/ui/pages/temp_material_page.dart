import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/providers/persona_provider.dart';
import '../../models/temp_material.dart';

/// 临时素材页：用户添加照片/文字 → 选择可暴露的分组 → AI 按各分组人设分别配文案
/// → 为每个分组生成发圈任务
class TempMaterialPage extends StatefulWidget {
  const TempMaterialPage({super.key});

  @override
  State<TempMaterialPage> createState() => _TempMaterialPageState();
}

class _TempMaterialPageState extends State<TempMaterialPage> {
  final List<String> _imagePaths = [];
  final _textController = TextEditingController();
  final _captionControllers = <String, TextEditingController>{}; // groupId -> controller
  final Set<String> _selectedGroupIds = {};
  bool _isGenerating = false;
  bool _hasGenerated = false;
  String? _currentMaterialId;

  @override
  void dispose() {
    _textController.dispose();
    for (final c in _captionControllers.values) {
      c.dispose();
    }
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
              // 说明卡片
              Card(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: Color(0xFF6366F1)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '添加照片/文字，选择可暴露的分组，AI 会按各分组人设分别配文案',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 选择分组（多选）
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
                onPressed: _isGenerating ? null : () => _generateCaptions(provider),
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
                label: Text(_isGenerating ? 'AI 生成中...' : 'AI 按分组配文案'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 各分组文案（可编辑）
              if (_hasGenerated) ...[
                const Text(
                  '分组文案（可编辑）',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._selectedGroupIds.map((groupId) {
                  final group = provider.getGroupById(groupId);
                  final persona = provider.getPersonaByGroupId(groupId);
                  final controller = _captionControllers[groupId] ??
                      (TextEditingController()
                        ..text = '');
                  _captionControllers.putIfAbsent(groupId, () => controller);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                group?.icon ?? '👥',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                group?.name ?? '未分组',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              if (persona != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '人设：${persona.name}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _createTasks(provider),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('为各分组生成发圈任务'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
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
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...provider.tempMaterials.map((m) => _MaterialHistoryCard(
                      material: m,
                      groupNames: provider
                          .getGroupsByIds(m.groupIds)
                          .map((g) => g.name)
                          .join('、'),
                      onDelete: () => provider.deleteTempMaterial(m.id),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupSelector(PersonaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择可暴露的分组（可多选）',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (provider.groups.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '暂无分组，请先在「人设管理」中创建分组',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.groups.map((group) {
              final selected = _selectedGroupIds.contains(group.id);
              return FilterChip(
                label: Text('${group.icon ?? '👥'} ${group.name}'),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedGroupIds.add(group.id);
                    } else {
                      _selectedGroupIds.remove(group.id);
                    }
                  });
                },
                selectedColor: const Color(0xFF6366F1).withOpacity(0.15),
                checkmarkColor: const Color(0xFF6366F1),
              );
            }).toList(),
          ),
      ],
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

  Future<void> _generateCaptions(PersonaProvider provider) async {
    if (_selectedGroupIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择至少一个分组')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final textContent = _textController.text.trim();
      final material = await provider.addTempMaterial(
        groupIds: _selectedGroupIds.toList(),
        materialType: _imagePaths.isNotEmpty
            ? TempMaterialType.image
            : TempMaterialType.text,
        filePaths: List.from(_imagePaths),
        textContent: textContent.isEmpty ? null : textContent,
      );
      _currentMaterialId = material.id;

      final captions =
          await provider.generateCaptionsForMaterial(material.id);
      if (captions.isNotEmpty) {
        for (final entry in captions.entries) {
          final controller = _captionControllers.putIfAbsent(
            entry.key,
            () => TextEditingController(),
          );
          controller.text = entry.value;
        }
        setState(() => _hasGenerated = true);
      } else if (provider.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!)),
        );
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

  Future<void> _createTasks(PersonaProvider provider) async {
    if (_currentMaterialId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先生成文案')),
      );
      return;
    }

    // 将用户编辑后的文案写回素材
    final material = provider.tempMaterials
        .firstWhere((m) => m.id == _currentMaterialId!);
    final captions = <String, String>{};
    for (final entry in _captionControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        captions[entry.key] = entry.value.text.trim();
      }
    }
    final updated = material.copyWith(
      captionsByGroup: captions,
      status: TempMaterialStatus.captioned,
    );
    await provider.updateTempMaterial(updated);

    final (posts, tasks) =
        await provider.generatePostingTasks(material.id);

    if (mounted) {
      if (tasks.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已为 ${tasks.length} 个分组生成发圈任务！')),
        );
        // 清空当前输入
        setState(() {
          _imagePaths.clear();
          _textController.clear();
          for (final c in _captionControllers.values) {
            c.clear();
          }
          _selectedGroupIds.clear();
          _hasGenerated = false;
          _currentMaterialId = null;
        });
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!)),
        );
      }
    }
  }
}

class _MaterialHistoryCard extends StatelessWidget {
  final TempMaterial material;
  final String groupNames;
  final VoidCallback onDelete;

  const _MaterialHistoryCard({
    required this.material,
    required this.groupNames,
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
                    groupNames.isEmpty ? '全局' : groupNames,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    material.statusName,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
            if (material.filePaths.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: material.filePaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(material.filePaths[index]),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
            if (material.captionsByGroup.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...material.captionsByGroup.entries.take(2).map((entry) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
              if (material.captionsByGroup.length > 2)
                Text(
                  '…共 ${material.captionsByGroup.length} 个分组的文案',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
