import '../../../core/database/database.dart';

/// 待办日程数据仓库
class TodoRepository {
  final AppDatabase _db;

  TodoRepository(this._db);

  Stream<List<TodoSchedule>> watchAll() => _db.watchAllTodoSchedules();

  Stream<List<TodoSchedule>> watchForPayload(int payloadId) =>
      _db.watchTodosForPayload(payloadId);

  Future<int> insert(TodoSchedulesCompanion entry) =>
      _db.insertTodoSchedule(entry);

  Future<void> toggleDone(int id, bool isDone) =>
      _db.toggleTodoDone(id, isDone);

  Future<int> delete(int id) => _db.deleteTodoSchedule(id);
}
