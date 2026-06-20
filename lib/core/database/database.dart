import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

/// 核心表：HubPayloads (多模态路由载荷表)
class HubPayloads extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get rawText => text()();

  TextColumn get mediaPaths =>
      text().withDefault(const Constant('[]'))();

  TextColumn get intentTag =>
      text().withDefault(const Constant('NOTE'))();

  IntColumn get syncStatus =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [HubPayloads])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<int> insertPayload(HubPayloadsCompanion entry) {
    return into(hubPayloads).insert(entry);
  }

  Stream<List<HubPayload>> watchAllPayloads() {
    return (select(hubPayloads)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }
}

/// 打开并初始化加密数据库连接
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'locus_vault.sqlite'));

    // 核心修复1：强制 Android 系统加载加密版 SQLCipher
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }

    // 核心修复2：使用原生的 NativeDatabase，而不是 createInBackground。
    // 这样保证代码在主 Isolate 运行，能够正确读取到上面的 overrideFor 配置。
    return NativeDatabase(file, setup: (rawDb) {
      rawDb.execute("PRAGMA key = 'locus_super_secret_master_key_2026';");
    });
  });
}