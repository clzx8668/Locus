import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Vault folder structure definition
class VaultStructure {
  static const List<String> directories = [
    'inbox',
    'daily',
    'crm/contacts',
    'crm/deals',
    'Reference',
    'chat-logs',
    'attachments',
    'system/memories',
    'templates',
    '.locus',
  ];
}

/// Markdown note with parsed frontmatter
class VaultNote {
  final String filePath;
  final String title;
  final Map<String, dynamic> frontmatter;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaultNote({
    required this.filePath,
    required this.title,
    required this.frontmatter,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'title': title,
        'frontmatter': frontmatter,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// VaultService - manages Markdown Vault read/write
class VaultService {
  String? _vaultPath;
  StreamController<FileSystemEvent>? _watcher;
  StreamSubscription<FileSystemEvent>? _watchSubscription;

  final StreamController<VaultNote> onCreateNote = StreamController<VaultNote>.broadcast();
  final StreamController<String> onChangeNote = StreamController<String>.broadcast();
  final StreamController<String> onDeleteNote = StreamController<String>.broadcast();

  VaultService();

  String? get vaultPath => _vaultPath;

  // ==================== Initialization ====================

  Future<void> initialize(String vaultPath) async {
    _vaultPath = vaultPath;

    final dir = Directory(vaultPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    for (final subDir in VaultStructure.directories) {
      final d = Directory(p.join(vaultPath, subDir));
      if (!await d.exists()) {
        await d.create(recursive: true);
      }
    }

    await _writeDefaultTemplates(vaultPath);
    _startWatching(vaultPath);

    debugPrint('Locus Vault initialized: $vaultPath');
  }

  void _startWatching(String vaultPath) {
    _watcher?.close();
    _watcher = StreamController<FileSystemEvent>.broadcast();

    final dir = Directory(vaultPath);
    _watchSubscription = dir.watch(recursive: true).listen(
      (event) {
        if (!event.path.endsWith('.md')) return;
        if (event.path.contains('${p.separator}.locus${p.separator}')) return;

        try {
          switch (event.type) {
            case FileSystemEvent.create:
            case FileSystemEvent.modify:
              _handleFileChanged(event.path);
              break;
            case FileSystemEvent.delete:
              onDeleteNote.add(event.path);
              break;
            default:
              break;
          }
        } catch (e) {
          debugPrint('Vault watcher error: $e');
        }
      },
      onError: (error) {
        debugPrint('Vault watcher stream error: $error');
      },
    );
  }

  void _handleFileChanged(String filePath) {
    try {
      final note = _readNoteSync(filePath);
      if (note != null) {
        onChangeNote.add(filePath);
      }
    } catch (e) {
      debugPrint('Failed to handle file change: $e');
    }
  }

  VaultNote? _readNoteSync(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;
      final content = file.readAsStringSync();
      final parsed = _parseFrontmatter(content);
      return VaultNote(
        filePath: filePath,
        title: parsed['title'] as String? ?? _titleFromPath(filePath),
        frontmatter: parsed,
        body: parsed['_body'] as String? ?? '',
        createdAt: file.lastModifiedSync(),
        updatedAt: file.lastModifiedSync(),
      );
    } catch (e) {
      return null;
    }
  }

  // ==================== Markdown Read/Write ====================

  Future<VaultNote?> readNote(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final parsed = _parseFrontmatter(content);
      final stat = await file.stat();
      return VaultNote(
        filePath: filePath,
        title: parsed['title'] as String? ?? _titleFromPath(filePath),
        frontmatter: parsed,
        body: parsed['_body'] as String? ?? '',
        createdAt: stat.changed,
        updatedAt: stat.modified,
      );
    } catch (e) {
      debugPrint('Failed to read note $filePath: $e');
      return null;
    }
  }

  Future<String> writeNote({
    required String subDir,
    required String fileName,
    required Map<String, dynamic> frontmatter,
    required String body,
  }) async {
    if (_vaultPath == null) throw StateError('Vault not initialized');

    final safeName = fileName.endsWith('.md') ? fileName : '$fileName.md';
    final dirPath = p.join(_vaultPath!, subDir);
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final filePath = p.join(dirPath, safeName);
    final content = _buildMarkdown(frontmatter, body);
    await File(filePath).writeAsString(content);

    onCreateNote.add(VaultNote(
      filePath: filePath,
      title: frontmatter['title'] as String? ?? _titleFromPath(filePath),
      frontmatter: frontmatter,
      body: body,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    return filePath;
  }

  Future<void> appendToNote(String filePath, String newContent) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    await file.writeAsString('\n$newContent\n', mode: FileMode.append);
    onChangeNote.add(filePath);
  }

  String generateFileName(String title) {
    final now = DateTime.now();
    final datePart =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    final safeTitle = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .substring(0, title.length < 30 ? title.length : 30)
        .trim();

    return '$datePart-${safeTitle.isEmpty ? 'quick-note' : safeTitle}.md';
  }

  Future<List<File>> listNotes(String subDir) async {
    if (_vaultPath == null) return [];
    final dir = Directory(p.join(_vaultPath!, subDir));
    if (!await dir.exists()) return [];
    return dir.listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList();
  }

  Future<List<VaultNote>> search(String query) async {
    if (_vaultPath == null) return [];
    final results = <VaultNote>[];
    final lowerQuery = query.toLowerCase();

    final files = await Directory(_vaultPath!)
        .list(recursive: true)
        .where((entity) =>
            entity is File &&
            entity.path.endsWith('.md') &&
            !entity.path.contains('${p.separator}.locus${p.separator}'))
        .cast<File>()
        .toList();

    for (final file in files) {
      final content = await file.readAsString();
      final fileName = p.basename(file.path).toLowerCase();

      if (fileName.contains(lowerQuery) || content.toLowerCase().contains(lowerQuery)) {
        final parsed = _parseFrontmatter(content);
        results.add(VaultNote(
          filePath: file.path,
          title: parsed['title'] as String? ?? _titleFromPath(file.path),
          frontmatter: parsed,
          body: parsed['_body'] as String? ?? '',
          createdAt: (await file.stat()).changed,
          updatedAt: (await file.stat()).modified,
        ));
      }
    }

    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  // ==================== Internal Helpers ====================

  Map<String, dynamic> _parseFrontmatter(String content) {
    final result = <String, dynamic>{};
    result['_body'] = content;

    if (!content.trimLeft().startsWith('---')) return result;

    final endIndex = content.indexOf('\n---', 3);
    if (endIndex == -1) return result;

    final frontmatterStr = content.substring(3, endIndex).trim();
    result['_body'] = content.substring(endIndex + 4).trim();

    for (final line in frontmatterStr.split('\n')) {
      final colonIndex = line.indexOf(':');
      if (colonIndex == -1) continue;

      final key = line.substring(0, colonIndex).trim();
      var value = line.substring(colonIndex + 1).trim();

      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }

      result[key] = value;
    }

    return result;
  }

  String _buildMarkdown(Map<String, dynamic> frontmatter, String body) {
    final buffer = StringBuffer();
    buffer.writeln('---');

    for (final entry in frontmatter.entries) {
      final value = entry.value;
      if (value is String && (value.contains(':') || value.contains('#'))) {
        buffer.writeln('${entry.key}: "$value"');
      } else {
        buffer.writeln('${entry.key}: $value');
      }
    }

    buffer.writeln('---');
    buffer.writeln();
    buffer.write(body);
    return buffer.toString();
  }

  String _titleFromPath(String filePath) {
    final name = p.basenameWithoutExtension(filePath);
    final cleaned = name.replaceFirst(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{4}-'), '');
    return cleaned.replaceAll('-', ' ');
  }

  // ==================== Default Templates ====================

  Future<void> _writeDefaultTemplates(String vaultPath) async {
    final templateDir = Directory(p.join(vaultPath, 'templates'));
    if (!await templateDir.exists()) {
      await templateDir.create(recursive: true);
    }

    final templates = {
      'quick-note.md': '''---
title: "{{title}}"
type: note
tags: []
created: "{{date}}"
updated: "{{date}}"
source: quick-capture
intent: {{intent}}
---

# {{title}}

{{content}}''',

      'contact.md': '''---
title: "{{name}}"
type: contact
aliases: [{{aliases}}]
company: "{{company}}"
role: "{{role}}"
phone: "{{phone}}"
email: "{{email}}"
tags: [crm, {{tags}}]
created: "{{date}}"
---

# {{name}}

{{company}} · {{role}}

## Info

- Phone: {{phone}}
- Email: {{email}}

## Activity Log

{{activities}}''',

      'deal.md': '''---
title: "{{title}}"
type: deal
contact: "{{contact}}"
stage: lead
value: {{value}}
probability: {{probability}}
expected_close: "{{expected_close}}"
created: "{{date}}"
---

# {{title}}

**Contact**: [[{{contact}}]]
**Stage**: {{stage}}
**Value**: {{value}}
**Probability**: {{probability}}%

{{notes}}''',

      'meeting-note.md': '''---
title: "{{title}}"
type: meeting
date: "{{meeting_date}}"
attendees: [{{attendees}}]
location: "{{location}}"
tags: [meeting]
created: "{{date}}"
---

# {{title}}

**Time**: {{meeting_date}}
**Location**: {{location}}
**Attendees**: {{attendees}}

## Agenda

{{agenda}}

## Conclusions

{{conclusions}}

## Action Items

{{action_items}}''',

      'daily.md': '''---
title: "{{date_title}}"
type: daily
tags: [daily]
created: "{{date}}"
---

# {{date_title}}

## Tasks

{{tasks}}

## Notes

{{notes}}''',
    };

    for (final entry in templates.entries) {
      final file = File(p.join(templateDir.path, entry.key));
      if (!await file.exists()) {
        await file.writeAsString(entry.value);
      }
    }

    debugPrint('Default templates written to ${templateDir.path}');
  }

  // ==================== Cleanup ====================

  void dispose() {
    _watchSubscription?.cancel();
    _watcher?.close();
    onCreateNote.close();
    onChangeNote.close();
    onDeleteNote.close();
  }
}
