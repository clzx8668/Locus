import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/di/service_locator.dart';
import '../../../core/utils/doc_parser.dart';
import '../data/memory_repository.dart';

class LongTermMemoryPage extends StatelessWidget {
  const LongTermMemoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('长久记忆与知识库',
              style: TextStyle(
                  fontSize: 18,
                  color: theme.textTheme.titleMedium?.color)),
          backgroundColor: theme.cardColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          shadowColor: theme.shadowColor,
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.psychology), text: '核心设定与记忆'),
              Tab(icon: Icon(Icons.folder_shared), text: '本地参考资料'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MemoryRulesView(isDark: isDark),
            _KnowledgeBaseView(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ==================== Tab 1：核心设定与记忆 ====================

class _MemoryRulesView extends StatelessWidget {
  final bool isDark;
  _MemoryRulesView({required this.isDark});

  final MemoryRepository _repo = getIt<MemoryRepository>();

  void _showMemoryDialog(
      BuildContext context, {
      LongTermMemory? existingMemory,
      }) {
    final theme = Theme.of(context);
    final controller =
        TextEditingController(text: existingMemory?.content ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            existingMemory == null ? '注入新记忆' : '修改记忆'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '例如：发票抬头是XX科技；碳化硅膜工艺温度不能低于1800度...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消',
                style: TextStyle(color: theme.hintColor)),
          ),
          FilledButton(
            onPressed: () {
              final content = controller.text.trim();
              if (content.isNotEmpty) {
                if (existingMemory == null) {
                  _repo.addMemory(content);
                } else {
                  _repo.updateMemory(existingMemory.id, content);
                }
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary),
            child: const Text('保存',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMemoryDialog(context),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<LongTermMemory>>(
        stream: _repo.watchAllMemories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final memories = snapshot.data ?? [];
          if (memories.isEmpty) {
            return Center(
              child: Text(
                '知识库还是空的，试着添加一些规则吧。',
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.5)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memories.length,
            itemBuilder: (context, index) {
              final memory = memories[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: ListTile(
                  title: Text(memory.content,
                      style: TextStyle(
                          height: 1.5,
                          color:
                              theme.textTheme.bodyLarge?.color)),
                  subtitle: Text(
                    '更新于: ${memory.updatedAt.month}-${memory.updatedAt.day}',
                    style: TextStyle(
                        color: theme.hintColor, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_note,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.7)),
                        onPressed: () => _showMemoryDialog(context,
                            existingMemory: memory),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _repo.deleteMemory(memory.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==================== Tab 2：本地参考资料库 ====================

class _KnowledgeBaseView extends StatefulWidget {
  final bool isDark;
  _KnowledgeBaseView({required this.isDark});

  @override
  State<_KnowledgeBaseView> createState() => _KnowledgeBaseViewState();
}

class _KnowledgeBaseViewState extends State<_KnowledgeBaseView> {
  bool _isUploading = false;
  int? _parsingFileId;

  final MemoryRepository _repo = getIt<MemoryRepository>();

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _extractAndShowText(KnowledgeFile file) async {
    setState(() => _parsingFileId = file.id);
    try {
      final text = await DocParser.extractTextFromPdf(file.localPath);
      if (!mounted) return;
      final theme = Theme.of(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.article,
                          size: 18,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(file.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge
                                    ?.color)),
                      ),
                      Text('${text.length} 字符',
                          style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 13)),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: theme.dividerColor),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(text,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: theme.textTheme.bodyLarge
                                ?.color)),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解析失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _parsingFileId = null);
    }
  }

  Future<void> _mountLocalFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'md'
        ],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploading = true);

      final selectedFile = result.files.first;
      if (selectedFile.path == null) return;

      final appDocDir =
          await getApplicationDocumentsDirectory();
      final knowledgeFolder =
          Directory(p.join(appDocDir.path, 'knowledge_base'));

      if (!await knowledgeFolder.exists()) {
        await knowledgeFolder.create(recursive: true);
      }

      final targetPath =
          p.join(knowledgeFolder.path, selectedFile.name);

      final originalFile = File(selectedFile.path!);
      await originalFile.copy(targetPath);

      final fileId = await _repo.addFile(
        name: selectedFile.name,
        localPath: targetPath,
        size: selectedFile.size,
        extension: selectedFile.extension ?? 'txt',
      );

      if (selectedFile.extension?.toLowerCase() == 'pdf') {
        _repo.processFileForRag(fileId, targetPath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '"${selectedFile.name}" 已成功挂载至本地资料库！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('挂载失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _deleteFile(KnowledgeFile file) async {
    await _repo.deleteFile(file.id);

    try {
      final physicalFile = File(file.localPath);
      if (await physicalFile.exists()) {
        await physicalFile.delete();
      }
    } catch (e) {
      debugPrint("物理文件删除失败: $e");
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已从资料库中卸载: ${file.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _isUploading
          ? const CircularProgressIndicator()
          : FloatingActionButton.extended(
              onPressed: _mountLocalFile,
              backgroundColor: theme.colorScheme.primary,
              icon: const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.white),
              label: const Text('挂载本地文件',
                  style: TextStyle(color: Colors.white)),
            ),
      body: StreamBuilder<List<KnowledgeFile>>(
        stream: _repo.watchAllFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final files = snapshot.data ?? [];
          if (files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded,
                      size: 64,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('资料库空空如也',
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.5),
                          fontSize: 15)),
                  Text('挂载技术文档或合同后，AI 将具备本地解析能力',
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.4),
                          fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final iconBgColor = widget.isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFF0F4F8);
              final iconFg = theme.colorScheme.primary
                  .withValues(alpha: 0.8);

              return Opacity(
                opacity: file.isActive ? 1.0 : 0.55,
                child: Card(
                  elevation: 0,
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side:
                        BorderSide(color: theme.dividerColor),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Icon(
                        file.extension.contains('pdf')
                            ? Icons.picture_as_pdf
                            : Icons.description_rounded,
                        color: iconFg,
                      ),
                    ),
                    title: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: theme
                              .textTheme.bodyLarge?.color),
                    ),
                    subtitle: Text(
                      '大小: ${_formatFileSize(file.size)} | 挂载于: ${file.createdAt.month}-${file.createdAt.day}',
                      style: TextStyle(
                          color: theme.hintColor,
                          fontSize: 12),
                    ),
                    onTap: () async {
                      final res =
                          await OpenFilex.open(file.localPath);
                      if (res.type != ResultType.done) {
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                              content: Text(
                                  '无法打开文件: ${res.message}')),
                        );
                      }
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (file.extension.contains('pdf'))
                          _parsingFileId == file.id
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(
                                          strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(
                                      Icons.text_snippet,
                                      color: Colors.orange,
                                      size: 20),
                                  tooltip: '提取文字',
                                  onPressed: () =>
                                      _extractAndShowText(
                                          file),
                                ),
                        Text(
                          file.isActive ? '检索中' : '已屏蔽',
                          style: TextStyle(
                            fontSize: 12,
                            color: file.isActive
                                ? Colors.green
                                : theme.hintColor,
                          ),
                        ),
                        Switch(
                          value: file.isActive,
                          onChanged: (newValue) {
                            _repo.toggleFileActive(file.id, newValue);
                          },
                          activeTrackColor: Colors.green
                              .withValues(alpha: 0.3),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.delete_sweep_outlined,
                              color: Colors.redAccent),
                          onPressed: () =>
                              _deleteFile(file),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
