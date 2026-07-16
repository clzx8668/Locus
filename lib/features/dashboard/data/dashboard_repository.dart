import '../../../core/database/database.dart';

/// 数据看板仓库 —— 封装 Dashboard 页面所需的聚合统计查询
class DashboardRepository {
  final AppDatabase _db;

  DashboardRepository(this._db);

  Future<double> getTotalIncome(int year, int month) =>
      _db.getTotalIncome(year, month);

  Future<double> getTotalExpense(int year, int month) =>
      _db.getTotalExpense(year, month);

  Future<Map<String, double>> getMonthlyExpense(int year, int month) =>
      _db.getMonthlyExpense(year, month);

  Future<int> getPendingTodoCount() => _db.getPendingTodoCount();

  Future<int> getCompletedTodoCount() => _db.getCompletedTodoCount();

  Future<int> getPayloadsToday() => _db.getPayloadsToday();

  Future<int> getPayloadsThisWeek() => _db.getPayloadsThisWeek();

  Future<int> getNewCustomersThisWeek() => _db.getNewCustomersThisWeek();

  Future<int> getTotalCustomers() => _db.getTotalCustomers();

  Future<List<({String name, int count, String color})>> getTopTagsWithCount({
    int limit = 12,
  }) =>
      _db.getTopTagsWithCount(limit: limit);
}
