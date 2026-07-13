import '../../../core/database/database.dart';

/// 记账流水数据仓库
class LedgerRepository {
  final AppDatabase _db;

  LedgerRepository(this._db);

  Stream<List<LedgerEntry>> watchAll() => _db.watchAllLedgerEntries();

  Future<int> insert(LedgerEntriesCompanion entry) =>
      _db.insertLedgerEntry(entry);

  Future<void> update(int id, LedgerEntriesCompanion entry) =>
      _db.updateLedgerEntry(id, entry);

  Future<int> delete(int id) => _db.deleteLedgerEntry(id);
}
