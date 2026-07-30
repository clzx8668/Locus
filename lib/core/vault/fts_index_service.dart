import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'vault_service.dart';

/// FTS5 full-text index service
class FtsIndexService {
  Database? _db;
  String? _vaultPath;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(String vaultPath) async {
    _vaultPath = vaultPath;

    final locusDir = Directory(p.join(vaultPath, '.locus'));
    if (!await locusDir.exists()) {
      await locusDir.create(recursive: true);
    }

    final dbPath = p.join(locusDir.path, 'index.db');

    _db = sqlite3.open(dbPath);

    _db!.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
        file_path,
        title,
        tags,
        body,
        tokenize='unicode61'
      )
    ''');

    _isInitialized = true;
    debugPrint('FTS index initialized: $dbPath');
  }

  Future<void> indexFile(
    String filePath, {
    required String title,
    required String tags,
    required String body,
  }) async {
    if (_db == null || !_isInitialized) return;

    try {
      _db!.execute(
        'DELETE FROM notes_fts WHERE file_path = ?',
        [filePath],
      );

      _db!.execute(
        'INSERT INTO notes_fts (file_path, title, tags, body) VALUES (?, ?, ?, ?)',
        [filePath, title, tags, body],
      );
    } catch (e) {
      debugPrint('FTS index error for $filePath: $e');
    }
  }

  void removeFile(String filePath) {
    if (_db == null || !_isInitialized) return;
    _db!.execute('DELETE FROM notes_fts WHERE file_path = ?', [filePath]);
  }

  List<Map<String, dynamic>> search(String query) {
    if (_db == null || !_isInitialized || query.trim().isEmpty) return [];

    try {
      final terms = query
          .trim()
          .split(RegExp(r'\s+'))
          .map((t) => '"$t"')
          .join(' OR ');

      final stmt = _db!.prepare('''
        SELECT file_path, title, tags,
               snippet(notes_fts, 2, '<mark>', '</mark>', '...', 40) AS snippet
        FROM notes_fts
        WHERE notes_fts MATCH ?
        ORDER BY rank
        LIMIT 50
      ''');

      final results = <Map<String, dynamic>>[];
      for (final row in stmt.select([terms])) {
        results.add({
          'filePath': row['file_path'],
          'title': row['title'],
          'tags': row['tags'],
          'snippet': row['snippet'],
        });
      }
      stmt.dispose();
      return results;
    } catch (e) {
      debugPrint('FTS search error: $e');
      return [];
    }
  }

  Future<void> rebuildAll(VaultService vaultService) async {
    if (_db == null || !_isInitialized || _vaultPath == null) return;

    _db!.execute('DELETE FROM notes_fts');

    final vaultDir = Directory(_vaultPath!);
    if (!await vaultDir.exists()) return;

    final files = await vaultDir
        .list(recursive: true)
        .where((entity) =>
            entity is File &&
            entity.path.endsWith('.md') &&
            !entity.path.contains('${p.separator}.locus${p.separator}') &&
            !entity.path.contains('${p.separator}templates${p.separator}'))
        .cast<File>()
        .toList();

    int count = 0;
    for (final file in files) {
      try {
        final note = await vaultService.readNote(file.path);
        if (note != null) {
          final tags =
              (note.frontmatter['tags'] as String? ?? '').toString();
          await indexFile(
            file.path,
            title: note.title,
            tags: tags,
            body: note.body,
          );
          count++;
        }
      } catch (e) {
        debugPrint('Rebuild index error for ${file.path}: $e');
      }
    }

    debugPrint('FTS index rebuilt: $count files indexed');
  }

  int get documentCount {
    if (_db == null || !_isInitialized) return 0;
    final result = _db!.select('SELECT COUNT(*) as cnt FROM notes_fts');
    if (result.isEmpty) return 0;
    return result.first['cnt'] as int;
  }

  void dispose() {
    _db?.dispose();
    _db = null;
    _isInitialized = false;
  }
}
