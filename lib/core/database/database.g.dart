// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $HubPayloadsTable extends HubPayloads
    with TableInfo<$HubPayloadsTable, HubPayload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HubPayloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _rawTextMeta =
      const VerificationMeta('rawText');
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
      'raw_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaPathsMeta =
      const VerificationMeta('mediaPaths');
  @override
  late final GeneratedColumn<String> mediaPaths = GeneratedColumn<String>(
      'media_paths', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _intentTagMeta =
      const VerificationMeta('intentTag');
  @override
  late final GeneratedColumn<String> intentTag = GeneratedColumn<String>(
      'intent_tag', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('NOTE'));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, rawText, mediaPaths, intentTag, syncStatus, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hub_payloads';
  @override
  VerificationContext validateIntegrity(Insertable<HubPayload> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('raw_text')) {
      context.handle(_rawTextMeta,
          rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta));
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('media_paths')) {
      context.handle(
          _mediaPathsMeta,
          mediaPaths.isAcceptableOrUnknown(
              data['media_paths']!, _mediaPathsMeta));
    }
    if (data.containsKey('intent_tag')) {
      context.handle(_intentTagMeta,
          intentTag.isAcceptableOrUnknown(data['intent_tag']!, _intentTagMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HubPayload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HubPayload(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      rawText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_text'])!,
      mediaPaths: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_paths'])!,
      intentTag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}intent_tag'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HubPayloadsTable createAlias(String alias) {
    return $HubPayloadsTable(attachedDatabase, alias);
  }
}

class HubPayload extends DataClass implements Insertable<HubPayload> {
  final int id;
  final String rawText;
  final String mediaPaths;
  final String intentTag;
  final int syncStatus;
  final DateTime createdAt;
  const HubPayload(
      {required this.id,
      required this.rawText,
      required this.mediaPaths,
      required this.intentTag,
      required this.syncStatus,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['raw_text'] = Variable<String>(rawText);
    map['media_paths'] = Variable<String>(mediaPaths);
    map['intent_tag'] = Variable<String>(intentTag);
    map['sync_status'] = Variable<int>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HubPayloadsCompanion toCompanion(bool nullToAbsent) {
    return HubPayloadsCompanion(
      id: Value(id),
      rawText: Value(rawText),
      mediaPaths: Value(mediaPaths),
      intentTag: Value(intentTag),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
    );
  }

  factory HubPayload.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HubPayload(
      id: serializer.fromJson<int>(json['id']),
      rawText: serializer.fromJson<String>(json['rawText']),
      mediaPaths: serializer.fromJson<String>(json['mediaPaths']),
      intentTag: serializer.fromJson<String>(json['intentTag']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rawText': serializer.toJson<String>(rawText),
      'mediaPaths': serializer.toJson<String>(mediaPaths),
      'intentTag': serializer.toJson<String>(intentTag),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HubPayload copyWith(
          {int? id,
          String? rawText,
          String? mediaPaths,
          String? intentTag,
          int? syncStatus,
          DateTime? createdAt}) =>
      HubPayload(
        id: id ?? this.id,
        rawText: rawText ?? this.rawText,
        mediaPaths: mediaPaths ?? this.mediaPaths,
        intentTag: intentTag ?? this.intentTag,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
      );
  HubPayload copyWithCompanion(HubPayloadsCompanion data) {
    return HubPayload(
      id: data.id.present ? data.id.value : this.id,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      mediaPaths:
          data.mediaPaths.present ? data.mediaPaths.value : this.mediaPaths,
      intentTag: data.intentTag.present ? data.intentTag.value : this.intentTag,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HubPayload(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('mediaPaths: $mediaPaths, ')
          ..write('intentTag: $intentTag, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, rawText, mediaPaths, intentTag, syncStatus, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HubPayload &&
          other.id == this.id &&
          other.rawText == this.rawText &&
          other.mediaPaths == this.mediaPaths &&
          other.intentTag == this.intentTag &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt);
}

class HubPayloadsCompanion extends UpdateCompanion<HubPayload> {
  final Value<int> id;
  final Value<String> rawText;
  final Value<String> mediaPaths;
  final Value<String> intentTag;
  final Value<int> syncStatus;
  final Value<DateTime> createdAt;
  const HubPayloadsCompanion({
    this.id = const Value.absent(),
    this.rawText = const Value.absent(),
    this.mediaPaths = const Value.absent(),
    this.intentTag = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HubPayloadsCompanion.insert({
    this.id = const Value.absent(),
    required String rawText,
    this.mediaPaths = const Value.absent(),
    this.intentTag = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : rawText = Value(rawText);
  static Insertable<HubPayload> custom({
    Expression<int>? id,
    Expression<String>? rawText,
    Expression<String>? mediaPaths,
    Expression<String>? intentTag,
    Expression<int>? syncStatus,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawText != null) 'raw_text': rawText,
      if (mediaPaths != null) 'media_paths': mediaPaths,
      if (intentTag != null) 'intent_tag': intentTag,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HubPayloadsCompanion copyWith(
      {Value<int>? id,
      Value<String>? rawText,
      Value<String>? mediaPaths,
      Value<String>? intentTag,
      Value<int>? syncStatus,
      Value<DateTime>? createdAt}) {
    return HubPayloadsCompanion(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      intentTag: intentTag ?? this.intentTag,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (mediaPaths.present) {
      map['media_paths'] = Variable<String>(mediaPaths.value);
    }
    if (intentTag.present) {
      map['intent_tag'] = Variable<String>(intentTag.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HubPayloadsCompanion(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('mediaPaths: $mediaPaths, ')
          ..write('intentTag: $intentTag, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HubPayloadsTable hubPayloads = $HubPayloadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [hubPayloads];
}

typedef $$HubPayloadsTableCreateCompanionBuilder = HubPayloadsCompanion
    Function({
  Value<int> id,
  required String rawText,
  Value<String> mediaPaths,
  Value<String> intentTag,
  Value<int> syncStatus,
  Value<DateTime> createdAt,
});
typedef $$HubPayloadsTableUpdateCompanionBuilder = HubPayloadsCompanion
    Function({
  Value<int> id,
  Value<String> rawText,
  Value<String> mediaPaths,
  Value<String> intentTag,
  Value<int> syncStatus,
  Value<DateTime> createdAt,
});

class $$HubPayloadsTableFilterComposer
    extends Composer<_$AppDatabase, $HubPayloadsTable> {
  $$HubPayloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawText => $composableBuilder(
      column: $table.rawText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaPaths => $composableBuilder(
      column: $table.mediaPaths, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get intentTag => $composableBuilder(
      column: $table.intentTag, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$HubPayloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $HubPayloadsTable> {
  $$HubPayloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawText => $composableBuilder(
      column: $table.rawText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaPaths => $composableBuilder(
      column: $table.mediaPaths, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get intentTag => $composableBuilder(
      column: $table.intentTag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$HubPayloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HubPayloadsTable> {
  $$HubPayloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get mediaPaths => $composableBuilder(
      column: $table.mediaPaths, builder: (column) => column);

  GeneratedColumn<String> get intentTag =>
      $composableBuilder(column: $table.intentTag, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HubPayloadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HubPayloadsTable,
    HubPayload,
    $$HubPayloadsTableFilterComposer,
    $$HubPayloadsTableOrderingComposer,
    $$HubPayloadsTableAnnotationComposer,
    $$HubPayloadsTableCreateCompanionBuilder,
    $$HubPayloadsTableUpdateCompanionBuilder,
    (HubPayload, BaseReferences<_$AppDatabase, $HubPayloadsTable, HubPayload>),
    HubPayload,
    PrefetchHooks Function()> {
  $$HubPayloadsTableTableManager(_$AppDatabase db, $HubPayloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HubPayloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HubPayloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HubPayloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> rawText = const Value.absent(),
            Value<String> mediaPaths = const Value.absent(),
            Value<String> intentTag = const Value.absent(),
            Value<int> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              HubPayloadsCompanion(
            id: id,
            rawText: rawText,
            mediaPaths: mediaPaths,
            intentTag: intentTag,
            syncStatus: syncStatus,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String rawText,
            Value<String> mediaPaths = const Value.absent(),
            Value<String> intentTag = const Value.absent(),
            Value<int> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              HubPayloadsCompanion.insert(
            id: id,
            rawText: rawText,
            mediaPaths: mediaPaths,
            intentTag: intentTag,
            syncStatus: syncStatus,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HubPayloadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HubPayloadsTable,
    HubPayload,
    $$HubPayloadsTableFilterComposer,
    $$HubPayloadsTableOrderingComposer,
    $$HubPayloadsTableAnnotationComposer,
    $$HubPayloadsTableCreateCompanionBuilder,
    $$HubPayloadsTableUpdateCompanionBuilder,
    (HubPayload, BaseReferences<_$AppDatabase, $HubPayloadsTable, HubPayload>),
    HubPayload,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HubPayloadsTableTableManager get hubPayloads =>
      $$HubPayloadsTableTableManager(_db, _db.hubPayloads);
}
