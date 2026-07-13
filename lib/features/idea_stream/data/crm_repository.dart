import '../../../core/database/database.dart';

/// CRM 客户数据仓库
class CrmRepository {
  final AppDatabase _db;

  CrmRepository(this._db);

  Stream<List<CrmCustomer>> watchAll() => _db.watchAllCrmCustomers();

  Future<int> insert(CrmCustomersCompanion entry) =>
      _db.insertCrmCustomer(entry);

  Future<void> update(int id, CrmCustomersCompanion entry) =>
      _db.updateCrmCustomer(id, entry);

  Future<int> delete(int id) => _db.deleteCrmCustomer(id);
}
