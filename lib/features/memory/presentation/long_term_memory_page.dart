import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/di/service_locator.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/database/database.dart';
import '../../../core/utils/doc_parser.dart';

class LongTermMemoryPage extends StatelessWidget {
  const LongTermMemoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: getIt<SyncService>().syncTick,
      builder: (_, tick, __) => DefaultTabController(
        key: ValueKey('sync_$tick'),
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('长久记忆与知识库',
                style: TextStyle(fontSize: 18, color: Colors.black87)),
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black87),
            bottom: const TabBar(
              labelColor: Colors.black87,
              indicatorColor: Colors.black87,
              tabs: [
                Tab(icon: Icon(Icons.psychology), text: '核心设定与记忆'),
                Tab(icon: Icon(Icons.folder_shared), text: '本地参考资料'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _MemoryRulesView(),
              _KnowledgeBaseView(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Tab 1：核心设定与记忆 ====================

class _MemoryRulesView extends StatelessWidget {
  const _MemoryRulesView();

  AppDatabase get db => getIt<AppDatabase>();

  void _showMemoryDialog(BuildContext context, {LongTermMemory? existingMemory}) {
    final controller = TextEditingController(text: existingMemory?.content ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingMemory == null ? '🧠 注入新记忆' : '✏️ 修改记忆'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '例如：发票抬头是XX科技；碳化硅膜工艺温度不能低于1800度...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final content = controller.text.trim();
              if (content.isNotEmpty) {
                if (existingMemory == null) {
                  db.addMemory(content);
                } else {
                  db.updateMemory(existingMemory.id, content);
                }
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMemoryDialog(context),
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<LongTermMemory>>(
        stream: db.watchAllMemories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final memories = snapshot.data ?? [];
          if (memories.isEmpty) {
            return Center(
              child: Text(
                '知识库还是空的，试着添加一些规则吧。',
                style: TextStyle(color: Colors.grey[400]),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  title: Text(memory.content, style: const TextStyle(height: 1.5)),
                  subtitle: Text(
                    '更新于: ${memory.updatedAt.month}-${memory.updatedAt.day}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.blueGrey),
                        onPressed: () => _showMemoryDialog(context, existingMemory: memory),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => db.deleteMemory(memory.id),
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
  const _KnowledgeBaseView();

  @override
  State<_KnowledgeBaseView> createState() => _KnowledgeBaseViewState();
}

class _KnowledgeBaseViewState extends State<_KnowledgeBaseView> {
  bool _isUploading = false;
  int? _parsingFileId;

  AppDatabase get db => getIt<AppDatabase>();

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
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.article, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(file.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Text('${text.length} 字符', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(text, style: const TextStyle(fontSize: 14, height: 1.6)),
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
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'md'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploading = true);

      final selectedFile = result.files.first;
      if (selectedFile.path == null) return;

      final appDocDir = await getApplicationDocumentsDirectory();
      final knowledgeFolder = Directory(p.join(appDocDir.path, 'knowledge_base'));

      if (!await knowledgeFolder.exists()) {
        await knowledgeFolder.create(recursive: true);
      }

      final targetPath = p.join(knowledgeFolder.path, selectedFile.name);

      final originalFile = File(selectedFile.path!);
      await originalFile.copy(targetPath);

      final fileId = await db.addFile(
        name: selectedFile.name,
        localPath: targetPath,
        size: selectedFile.size,
        extension: selectedFile.extension ?? 'txt',
      );

      // 异步触发 RAG 深度阅读入库（不阻塞 UI）
      if (selectedFile.extension?.toLowerCase() == 'pdf') {
        db.processFileForRAG(fileId, targetPath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 "${selectedFile.name}" 已成功挂载至本地资料库！')),
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
    await db.deleteFile(file.id);

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _isUploading
          ? const CircularProgressIndicator()
          : FloatingActionButton.extended(
              onPressed: _mountLocalFile,
              backgroundColor: Colors.black87,
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              label: const Text('挂载本地文件', style: TextStyle(color: Colors.white)),
            ),
      body: StreamBuilder<List<KnowledgeFile>>(
        stream: db.watchAllFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final files = snapshot.data ?? [];
          if (files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('资料库空空如也',
                      style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                  Text('挂载技术文档或合同后，AI 将具备本地解析能力',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return Opacity(
                opacity: file.isActive ? 1.0 : 0.55,
                child: Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      file.extension.contains('pdf')
                          ? Icons.picture_as_pdf
                          : Icons.description_rounded,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                  title: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  subtitle: Text(
                    '大小: ${_formatFileSize(file.size)} | 挂载于: ${file.createdAt.month}-${file.createdAt.day}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  onTap: () async {
                    final res = await OpenFilex.open(file.localPath);
                    if (res.type != ResultType.done) {
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('无法打开文件: ${res.message}')),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.text_snippet, color: Colors.orange, size: 20),
                                tooltip: '提取文字',
                                onPressed: () => _extractAndShowText(file),
                              ),
                      Text(
                        file.isActive ? '检索中' : '已屏蔽',
                        style: TextStyle(
                          fontSize: 12,
                          color: file.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      Switch(
                        value: file.isActive,
                        onChanged: (newValue) {
                          db.toggleFileActive(file.id, newValue);
                        },
                        activeThumbColor: Colors.green,
                        activeTrackColor: Colors.green.withValues(alpha: 0.3),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                        onPressed: () => _deleteFile(file),
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
