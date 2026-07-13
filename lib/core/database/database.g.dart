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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _processingStatusMeta =
      const VerificationMeta('processingStatus');
  @override
  late final GeneratedColumn<String> processingStatus = GeneratedColumn<String>(
      'processing_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced_local'));
  static const VerificationMeta _dispatchedRefMeta =
      const VerificationMeta('dispatchedRef');
  @override
  late final GeneratedColumn<String> dispatchedRef = GeneratedColumn<String>(
      'dispatched_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _aiEntitiesMeta =
      const VerificationMeta('aiEntities');
  @override
  late final GeneratedColumn<String> aiEntities = GeneratedColumn<String>(
      'ai_entities', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isEphemeralMeta =
      const VerificationMeta('isEphemeral');
  @override
  late final GeneratedColumn<bool> isEphemeral = GeneratedColumn<bool>(
      'is_ephemeral', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_ephemeral" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _decayDeadlineMeta =
      const VerificationMeta('decayDeadline');
  @override
  late final GeneratedColumn<DateTime> decayDeadline =
      GeneratedColumn<DateTime>('decay_deadline', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        rawText,
        mediaPaths,
        intentTag,
        title,
        syncStatus,
        processingStatus,
        dispatchedRef,
        aiEntities,
        isEphemeral,
        decayDeadline,
        createdAt
      ];
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
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('processing_status')) {
      context.handle(
          _processingStatusMeta,
          processingStatus.isAcceptableOrUnknown(
              data['processing_status']!, _processingStatusMeta));
    }
    if (data.containsKey('dispatched_ref')) {
      context.handle(
          _dispatchedRefMeta,
          dispatchedRef.isAcceptableOrUnknown(
              data['dispatched_ref']!, _dispatchedRefMeta));
    }
    if (data.containsKey('ai_entities')) {
      context.handle(
          _aiEntitiesMeta,
          aiEntities.isAcceptableOrUnknown(
              data['ai_entities']!, _aiEntitiesMeta));
    }
    if (data.containsKey('is_ephemeral')) {
      context.handle(
          _isEphemeralMeta,
          isEphemeral.isAcceptableOrUnknown(
              data['is_ephemeral']!, _isEphemeralMeta));
    }
    if (data.containsKey('decay_deadline')) {
      context.handle(
          _decayDeadlineMeta,
          decayDeadline.isAcceptableOrUnknown(
              data['decay_deadline']!, _decayDeadlineMeta));
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
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
      processingStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}processing_status'])!,
      dispatchedRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dispatched_ref']),
      aiEntities: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_entities']),
      isEphemeral: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_ephemeral'])!,
      decayDeadline: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}decay_deadline']),
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
  final String? title;
  final int syncStatus;

  /// 处理流水线状态：synced_local / vector_checking / ai_routing / dispatching / dispatched / failed_retry
  final String processingStatus;

  /// 分发引用，格式 "table_name:id"，用于双向链接追溯
  final String? dispatchedRef;

  /// AI 路由抽取的实体 JSON 快照
  final String? aiEntities;

  /// 是否标记为日常废话（触发衰减）
  final bool isEphemeral;

  /// 废话衰减到期时间（创建后 48h）
  final DateTime? decayDeadline;
  final DateTime createdAt;
  const HubPayload(
      {required this.id,
      required this.rawText,
      required this.mediaPaths,
      required this.intentTag,
      this.title,
      required this.syncStatus,
      required this.processingStatus,
      this.dispatchedRef,
      this.aiEntities,
      required this.isEphemeral,
      this.decayDeadline,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['raw_text'] = Variable<String>(rawText);
    map['media_paths'] = Variable<String>(mediaPaths);
    map['intent_tag'] = Variable<String>(intentTag);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['processing_status'] = Variable<String>(processingStatus);
    if (!nullToAbsent || dispatchedRef != null) {
      map['dispatched_ref'] = Variable<String>(dispatchedRef);
    }
    if (!nullToAbsent || aiEntities != null) {
      map['ai_entities'] = Variable<String>(aiEntities);
    }
    map['is_ephemeral'] = Variable<bool>(isEphemeral);
    if (!nullToAbsent || decayDeadline != null) {
      map['decay_deadline'] = Variable<DateTime>(decayDeadline);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HubPayloadsCompanion toCompanion(bool nullToAbsent) {
    return HubPayloadsCompanion(
      id: Value(id),
      rawText: Value(rawText),
      mediaPaths: Value(mediaPaths),
      intentTag: Value(intentTag),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      syncStatus: Value(syncStatus),
      processingStatus: Value(processingStatus),
      dispatchedRef: dispatchedRef == null && nullToAbsent
          ? const Value.absent()
          : Value(dispatchedRef),
      aiEntities: aiEntities == null && nullToAbsent
          ? const Value.absent()
          : Value(aiEntities),
      isEphemeral: Value(isEphemeral),
      decayDeadline: decayDeadline == null && nullToAbsent
          ? const Value.absent()
          : Value(decayDeadline),
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
      title: serializer.fromJson<String?>(json['title']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      processingStatus: serializer.fromJson<String>(json['processingStatus']),
      dispatchedRef: serializer.fromJson<String?>(json['dispatchedRef']),
      aiEntities: serializer.fromJson<String?>(json['aiEntities']),
      isEphemeral: serializer.fromJson<bool>(json['isEphemeral']),
      decayDeadline: serializer.fromJson<DateTime?>(json['decayDeadline']),
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
      'title': serializer.toJson<String?>(title),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'processingStatus': serializer.toJson<String>(processingStatus),
      'dispatchedRef': serializer.toJson<String?>(dispatchedRef),
      'aiEntities': serializer.toJson<String?>(aiEntities),
      'isEphemeral': serializer.toJson<bool>(isEphemeral),
      'decayDeadline': serializer.toJson<DateTime?>(decayDeadline),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HubPayload copyWith(
          {int? id,
          String? rawText,
          String? mediaPaths,
          String? intentTag,
          Value<String?> title = const Value.absent(),
          int? syncStatus,
          String? processingStatus,
          Value<String?> dispatchedRef = const Value.absent(),
          Value<String?> aiEntities = const Value.absent(),
          bool? isEphemeral,
          Value<DateTime?> decayDeadline = const Value.absent(),
          DateTime? createdAt}) =>
      HubPayload(
        id: id ?? this.id,
        rawText: rawText ?? this.rawText,
        mediaPaths: mediaPaths ?? this.mediaPaths,
        intentTag: intentTag ?? this.intentTag,
        title: title.present ? title.value : this.title,
        syncStatus: syncStatus ?? this.syncStatus,
        processingStatus: processingStatus ?? this.processingStatus,
        dispatchedRef:
            dispatchedRef.present ? dispatchedRef.value : this.dispatchedRef,
        aiEntities: aiEntities.present ? aiEntities.value : this.aiEntities,
        isEphemeral: isEphemeral ?? this.isEphemeral,
        decayDeadline:
            decayDeadline.present ? decayDeadline.value : this.decayDeadline,
        createdAt: createdAt ?? this.createdAt,
      );
  HubPayload copyWithCompanion(HubPayloadsCompanion data) {
    return HubPayload(
      id: data.id.present ? data.id.value : this.id,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      mediaPaths:
          data.mediaPaths.present ? data.mediaPaths.value : this.mediaPaths,
      intentTag: data.intentTag.present ? data.intentTag.value : this.intentTag,
      title: data.title.present ? data.title.value : this.title,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      processingStatus: data.processingStatus.present
          ? data.processingStatus.value
          : this.processingStatus,
      dispatchedRef: data.dispatchedRef.present
          ? data.dispatchedRef.value
          : this.dispatchedRef,
      aiEntities:
          data.aiEntities.present ? data.aiEntities.value : this.aiEntities,
      isEphemeral:
          data.isEphemeral.present ? data.isEphemeral.value : this.isEphemeral,
      decayDeadline: data.decayDeadline.present
          ? data.decayDeadline.value
          : this.decayDeadline,
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
          ..write('title: $title, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('dispatchedRef: $dispatchedRef, ')
          ..write('aiEntities: $aiEntities, ')
          ..write('isEphemeral: $isEphemeral, ')
          ..write('decayDeadline: $decayDeadline, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      rawText,
      mediaPaths,
      intentTag,
      title,
      syncStatus,
      processingStatus,
      dispatchedRef,
      aiEntities,
      isEphemeral,
      decayDeadline,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HubPayload &&
          other.id == this.id &&
          other.rawText == this.rawText &&
          other.mediaPaths == this.mediaPaths &&
          other.intentTag == this.intentTag &&
          other.title == this.title &&
          other.syncStatus == this.syncStatus &&
          other.processingStatus == this.processingStatus &&
          other.dispatchedRef == this.dispatchedRef &&
          other.aiEntities == this.aiEntities &&
          other.isEphemeral == this.isEphemeral &&
          other.decayDeadline == this.decayDeadline &&
          other.createdAt == this.createdAt);
}

class HubPayloadsCompanion extends UpdateCompanion<HubPayload> {
  final Value<int> id;
  final Value<String> rawText;
  final Value<String> mediaPaths;
  final Value<String> intentTag;
  final Value<String?> title;
  final Value<int> syncStatus;
  final Value<String> processingStatus;
  final Value<String?> dispatchedRef;
  final Value<String?> aiEntities;
  final Value<bool> isEphemeral;
  final Value<DateTime?> decayDeadline;
  final Value<DateTime> createdAt;
  const HubPayloadsCompanion({
    this.id = const Value.absent(),
    this.rawText = const Value.absent(),
    this.mediaPaths = const Value.absent(),
    this.intentTag = const Value.absent(),
    this.title = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.processingStatus = const Value.absent(),
    this.dispatchedRef = const Value.absent(),
    this.aiEntities = const Value.absent(),
    this.isEphemeral = const Value.absent(),
    this.decayDeadline = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HubPayloadsCompanion.insert({
    this.id = const Value.absent(),
    required String rawText,
    this.mediaPaths = const Value.absent(),
    this.intentTag = const Value.absent(),
    this.title = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.processingStatus = const Value.absent(),
    this.dispatchedRef = const Value.absent(),
    this.aiEntities = const Value.absent(),
    this.isEphemeral = const Value.absent(),
    this.decayDeadline = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : rawText = Value(rawText);
  static Insertable<HubPayload> custom({
    Expression<int>? id,
    Expression<String>? rawText,
    Expression<String>? mediaPaths,
    Expression<String>? intentTag,
    Expression<String>? title,
    Expression<int>? syncStatus,
    Expression<String>? processingStatus,
    Expression<String>? dispatchedRef,
    Expression<String>? aiEntities,
    Expression<bool>? isEphemeral,
    Expression<DateTime>? decayDeadline,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawText != null) 'raw_text': rawText,
      if (mediaPaths != null) 'media_paths': mediaPaths,
      if (intentTag != null) 'intent_tag': intentTag,
      if (title != null) 'title': title,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (processingStatus != null) 'processing_status': processingStatus,
      if (dispatchedRef != null) 'dispatched_ref': dispatchedRef,
      if (aiEntities != null) 'ai_entities': aiEntities,
      if (isEphemeral != null) 'is_ephemeral': isEphemeral,
      if (decayDeadline != null) 'decay_deadline': decayDeadline,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HubPayloadsCompanion copyWith(
      {Value<int>? id,
      Value<String>? rawText,
      Value<String>? mediaPaths,
      Value<String>? intentTag,
      Value<String?>? title,
      Value<int>? syncStatus,
      Value<String>? processingStatus,
      Value<String?>? dispatchedRef,
      Value<String?>? aiEntities,
      Value<bool>? isEphemeral,
      Value<DateTime?>? decayDeadline,
      Value<DateTime>? createdAt}) {
    return HubPayloadsCompanion(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      intentTag: intentTag ?? this.intentTag,
      title: title ?? this.title,
      syncStatus: syncStatus ?? this.syncStatus,
      processingStatus: processingStatus ?? this.processingStatus,
      dispatchedRef: dispatchedRef ?? this.dispatchedRef,
      aiEntities: aiEntities ?? this.aiEntities,
      isEphemeral: isEphemeral ?? this.isEphemeral,
      decayDeadline: decayDeadline ?? this.decayDeadline,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (processingStatus.present) {
      map['processing_status'] = Variable<String>(processingStatus.value);
    }
    if (dispatchedRef.present) {
      map['dispatched_ref'] = Variable<String>(dispatchedRef.value);
    }
    if (aiEntities.present) {
      map['ai_entities'] = Variable<String>(aiEntities.value);
    }
    if (isEphemeral.present) {
      map['is_ephemeral'] = Variable<bool>(isEphemeral.value);
    }
    if (decayDeadline.present) {
      map['decay_deadline'] = Variable<DateTime>(decayDeadline.value);
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
          ..write('title: $title, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('dispatchedRef: $dispatchedRef, ')
          ..write('aiEntities: $aiEntities, ')
          ..write('isEphemeral: $isEphemeral, ')
          ..write('decayDeadline: $decayDeadline, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ChatSessionsTable extends ChatSessions
    with TableInfo<$ChatSessionsTable, ChatSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, title, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<ChatSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChatSessionsTable createAlias(String alias) {
    return $ChatSessionsTable(attachedDatabase, alias);
  }
}

class ChatSession extends DataClass implements Insertable<ChatSession> {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChatSession(
      {required this.id,
      required this.title,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChatSessionsCompanion toCompanion(bool nullToAbsent) {
    return ChatSessionsCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChatSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatSession(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChatSession copyWith(
          {int? id, String? title, DateTime? createdAt, DateTime? updatedAt}) =>
      ChatSession(
        id: id ?? this.id,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ChatSession copyWithCompanion(ChatSessionsCompanion data) {
    return ChatSession(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatSession(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSession &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChatSessionsCompanion extends UpdateCompanion<ChatSession> {
  final Value<int> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ChatSessionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ChatSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<ChatSession> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ChatSessionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ChatSessionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
      'session_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES chat_sessions (id)'));
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
      [id, sessionId, role, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(Insertable<ChatMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
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
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final int id;
  final int sessionId;
  final String role;
  final String content;
  final DateTime createdAt;
  const ChatMessage(
      {required this.id,
      required this.sessionId,
      required this.role,
      required this.content,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessage copyWith(
          {int? id,
          int? sessionId,
          String? role,
          String? content,
          DateTime? createdAt}) =>
      ChatMessage(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        role: role ?? this.role,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  ChatMessage copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessage(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String role,
    required String content,
    this.createdAt = const Value.absent(),
  })  : sessionId = Value(sessionId),
        role = Value(role),
        content = Value(content);
  static Insertable<ChatMessage> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ChatMessagesCompanion copyWith(
      {Value<int>? id,
      Value<int>? sessionId,
      Value<String>? role,
      Value<String>? content,
      Value<DateTime>? createdAt}) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LongTermMemoriesTable extends LongTermMemories
    with TableInfo<$LongTermMemoriesTable, LongTermMemory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LongTermMemoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, content, tags, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'long_term_memories';
  @override
  VerificationContext validateIntegrity(Insertable<LongTermMemory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LongTermMemory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LongTermMemory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LongTermMemoriesTable createAlias(String alias) {
    return $LongTermMemoriesTable(attachedDatabase, alias);
  }
}

class LongTermMemory extends DataClass implements Insertable<LongTermMemory> {
  final int id;
  final String content;
  final String? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LongTermMemory(
      {required this.id,
      required this.content,
      this.tags,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LongTermMemoriesCompanion toCompanion(bool nullToAbsent) {
    return LongTermMemoriesCompanion(
      id: Value(id),
      content: Value(content),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LongTermMemory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LongTermMemory(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      tags: serializer.fromJson<String?>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'tags': serializer.toJson<String?>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LongTermMemory copyWith(
          {int? id,
          String? content,
          Value<String?> tags = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LongTermMemory(
        id: id ?? this.id,
        content: content ?? this.content,
        tags: tags.present ? tags.value : this.tags,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LongTermMemory copyWithCompanion(LongTermMemoriesCompanion data) {
    return LongTermMemory(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LongTermMemory(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, tags, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LongTermMemory &&
          other.id == this.id &&
          other.content == this.content &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LongTermMemoriesCompanion extends UpdateCompanion<LongTermMemory> {
  final Value<int> id;
  final Value<String> content;
  final Value<String?> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LongTermMemoriesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LongTermMemoriesCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : content = Value(content);
  static Insertable<LongTermMemory> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LongTermMemoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? content,
      Value<String?>? tags,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return LongTermMemoriesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LongTermMemoriesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $KnowledgeFilesTable extends KnowledgeFiles
    with TableInfo<$KnowledgeFilesTable, KnowledgeFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnowledgeFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _extensionMeta =
      const VerificationMeta('extension');
  @override
  late final GeneratedColumn<String> extension = GeneratedColumn<String>(
      'extension', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
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
      [id, name, localPath, size, extension, isActive, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'knowledge_files';
  @override
  VerificationContext validateIntegrity(Insertable<KnowledgeFile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('extension')) {
      context.handle(_extensionMeta,
          extension.isAcceptableOrUnknown(data['extension']!, _extensionMeta));
    } else if (isInserting) {
      context.missing(_extensionMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
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
  KnowledgeFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnowledgeFile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      extension: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}extension'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $KnowledgeFilesTable createAlias(String alias) {
    return $KnowledgeFilesTable(attachedDatabase, alias);
  }
}

class KnowledgeFile extends DataClass implements Insertable<KnowledgeFile> {
  final int id;
  final String name;
  final String localPath;
  final int size;
  final String extension;
  final bool isActive;
  final DateTime createdAt;
  const KnowledgeFile(
      {required this.id,
      required this.name,
      required this.localPath,
      required this.size,
      required this.extension,
      required this.isActive,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['local_path'] = Variable<String>(localPath);
    map['size'] = Variable<int>(size);
    map['extension'] = Variable<String>(extension);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  KnowledgeFilesCompanion toCompanion(bool nullToAbsent) {
    return KnowledgeFilesCompanion(
      id: Value(id),
      name: Value(name),
      localPath: Value(localPath),
      size: Value(size),
      extension: Value(extension),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory KnowledgeFile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnowledgeFile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      localPath: serializer.fromJson<String>(json['localPath']),
      size: serializer.fromJson<int>(json['size']),
      extension: serializer.fromJson<String>(json['extension']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'localPath': serializer.toJson<String>(localPath),
      'size': serializer.toJson<int>(size),
      'extension': serializer.toJson<String>(extension),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  KnowledgeFile copyWith(
          {int? id,
          String? name,
          String? localPath,
          int? size,
          String? extension,
          bool? isActive,
          DateTime? createdAt}) =>
      KnowledgeFile(
        id: id ?? this.id,
        name: name ?? this.name,
        localPath: localPath ?? this.localPath,
        size: size ?? this.size,
        extension: extension ?? this.extension,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
  KnowledgeFile copyWithCompanion(KnowledgeFilesCompanion data) {
    return KnowledgeFile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      size: data.size.present ? data.size.value : this.size,
      extension: data.extension.present ? data.extension.value : this.extension,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeFile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('localPath: $localPath, ')
          ..write('size: $size, ')
          ..write('extension: $extension, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, localPath, size, extension, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnowledgeFile &&
          other.id == this.id &&
          other.name == this.name &&
          other.localPath == this.localPath &&
          other.size == this.size &&
          other.extension == this.extension &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class KnowledgeFilesCompanion extends UpdateCompanion<KnowledgeFile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> localPath;
  final Value<int> size;
  final Value<String> extension;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  const KnowledgeFilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.localPath = const Value.absent(),
    this.size = const Value.absent(),
    this.extension = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  KnowledgeFilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String localPath,
    required int size,
    required String extension,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        localPath = Value(localPath),
        size = Value(size),
        extension = Value(extension);
  static Insertable<KnowledgeFile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? localPath,
    Expression<int>? size,
    Expression<String>? extension,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (localPath != null) 'local_path': localPath,
      if (size != null) 'size': size,
      if (extension != null) 'extension': extension,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  KnowledgeFilesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? localPath,
      Value<int>? size,
      Value<String>? extension,
      Value<bool>? isActive,
      Value<DateTime>? createdAt}) {
    return KnowledgeFilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      size: size ?? this.size,
      extension: extension ?? this.extension,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (extension.present) {
      map['extension'] = Variable<String>(extension.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeFilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('localPath: $localPath, ')
          ..write('size: $size, ')
          ..write('extension: $extension, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $VectorStorageTable extends VectorStorage
    with TableInfo<$VectorStorageTable, VectorStorageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VectorStorageTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sourceFileIdMeta =
      const VerificationMeta('sourceFileId');
  @override
  late final GeneratedColumn<int> sourceFileId = GeneratedColumn<int>(
      'source_file_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES knowledge_files (id)'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, sourceFileId, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vector_storage';
  @override
  VerificationContext validateIntegrity(Insertable<VectorStorageData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_file_id')) {
      context.handle(
          _sourceFileIdMeta,
          sourceFileId.isAcceptableOrUnknown(
              data['source_file_id']!, _sourceFileIdMeta));
    } else if (isInserting) {
      context.missing(_sourceFileIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VectorStorageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VectorStorageData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sourceFileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source_file_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
    );
  }

  @override
  $VectorStorageTable createAlias(String alias) {
    return $VectorStorageTable(attachedDatabase, alias);
  }
}

class VectorStorageData extends DataClass
    implements Insertable<VectorStorageData> {
  final int id;
  final int sourceFileId;
  final String content;
  const VectorStorageData(
      {required this.id, required this.sourceFileId, required this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_file_id'] = Variable<int>(sourceFileId);
    map['content'] = Variable<String>(content);
    return map;
  }

  VectorStorageCompanion toCompanion(bool nullToAbsent) {
    return VectorStorageCompanion(
      id: Value(id),
      sourceFileId: Value(sourceFileId),
      content: Value(content),
    );
  }

  factory VectorStorageData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VectorStorageData(
      id: serializer.fromJson<int>(json['id']),
      sourceFileId: serializer.fromJson<int>(json['sourceFileId']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceFileId': serializer.toJson<int>(sourceFileId),
      'content': serializer.toJson<String>(content),
    };
  }

  VectorStorageData copyWith({int? id, int? sourceFileId, String? content}) =>
      VectorStorageData(
        id: id ?? this.id,
        sourceFileId: sourceFileId ?? this.sourceFileId,
        content: content ?? this.content,
      );
  VectorStorageData copyWithCompanion(VectorStorageCompanion data) {
    return VectorStorageData(
      id: data.id.present ? data.id.value : this.id,
      sourceFileId: data.sourceFileId.present
          ? data.sourceFileId.value
          : this.sourceFileId,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VectorStorageData(')
          ..write('id: $id, ')
          ..write('sourceFileId: $sourceFileId, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourceFileId, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VectorStorageData &&
          other.id == this.id &&
          other.sourceFileId == this.sourceFileId &&
          other.content == this.content);
}

class VectorStorageCompanion extends UpdateCompanion<VectorStorageData> {
  final Value<int> id;
  final Value<int> sourceFileId;
  final Value<String> content;
  const VectorStorageCompanion({
    this.id = const Value.absent(),
    this.sourceFileId = const Value.absent(),
    this.content = const Value.absent(),
  });
  VectorStorageCompanion.insert({
    this.id = const Value.absent(),
    required int sourceFileId,
    required String content,
  })  : sourceFileId = Value(sourceFileId),
        content = Value(content);
  static Insertable<VectorStorageData> custom({
    Expression<int>? id,
    Expression<int>? sourceFileId,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceFileId != null) 'source_file_id': sourceFileId,
      if (content != null) 'content': content,
    });
  }

  VectorStorageCompanion copyWith(
      {Value<int>? id, Value<int>? sourceFileId, Value<String>? content}) {
    return VectorStorageCompanion(
      id: id ?? this.id,
      sourceFileId: sourceFileId ?? this.sourceFileId,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceFileId.present) {
      map['source_file_id'] = Variable<int>(sourceFileId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VectorStorageCompanion(')
          ..write('id: $id, ')
          ..write('sourceFileId: $sourceFileId, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $IdeaTasksTable extends IdeaTasks
    with TableInfo<$IdeaTasksTable, IdeaTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdeaTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _payloadIdMeta =
      const VerificationMeta('payloadId');
  @override
  late final GeneratedColumn<int> payloadId = GeneratedColumn<int>(
      'payload_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES hub_payloads (id)'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
      'is_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
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
      [id, payloadId, content, isDone, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'idea_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<IdeaTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payload_id')) {
      context.handle(_payloadIdMeta,
          payloadId.isAcceptableOrUnknown(data['payload_id']!, _payloadIdMeta));
    } else if (isInserting) {
      context.missing(_payloadIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_done')) {
      context.handle(_isDoneMeta,
          isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
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
  IdeaTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdeaTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      payloadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payload_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      isDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_done'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $IdeaTasksTable createAlias(String alias) {
    return $IdeaTasksTable(attachedDatabase, alias);
  }
}

class IdeaTask extends DataClass implements Insertable<IdeaTask> {
  final int id;
  final int payloadId;
  final String content;
  final bool isDone;
  final int sortOrder;
  final DateTime createdAt;
  const IdeaTask(
      {required this.id,
      required this.payloadId,
      required this.content,
      required this.isDone,
      required this.sortOrder,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload_id'] = Variable<int>(payloadId);
    map['content'] = Variable<String>(content);
    map['is_done'] = Variable<bool>(isDone);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IdeaTasksCompanion toCompanion(bool nullToAbsent) {
    return IdeaTasksCompanion(
      id: Value(id),
      payloadId: Value(payloadId),
      content: Value(content),
      isDone: Value(isDone),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory IdeaTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdeaTask(
      id: serializer.fromJson<int>(json['id']),
      payloadId: serializer.fromJson<int>(json['payloadId']),
      content: serializer.fromJson<String>(json['content']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payloadId': serializer.toJson<int>(payloadId),
      'content': serializer.toJson<String>(content),
      'isDone': serializer.toJson<bool>(isDone),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IdeaTask copyWith(
          {int? id,
          int? payloadId,
          String? content,
          bool? isDone,
          int? sortOrder,
          DateTime? createdAt}) =>
      IdeaTask(
        id: id ?? this.id,
        payloadId: payloadId ?? this.payloadId,
        content: content ?? this.content,
        isDone: isDone ?? this.isDone,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  IdeaTask copyWithCompanion(IdeaTasksCompanion data) {
    return IdeaTask(
      id: data.id.present ? data.id.value : this.id,
      payloadId: data.payloadId.present ? data.payloadId.value : this.payloadId,
      content: data.content.present ? data.content.value : this.content,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdeaTask(')
          ..write('id: $id, ')
          ..write('payloadId: $payloadId, ')
          ..write('content: $content, ')
          ..write('isDone: $isDone, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, payloadId, content, isDone, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdeaTask &&
          other.id == this.id &&
          other.payloadId == this.payloadId &&
          other.content == this.content &&
          other.isDone == this.isDone &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class IdeaTasksCompanion extends UpdateCompanion<IdeaTask> {
  final Value<int> id;
  final Value<int> payloadId;
  final Value<String> content;
  final Value<bool> isDone;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const IdeaTasksCompanion({
    this.id = const Value.absent(),
    this.payloadId = const Value.absent(),
    this.content = const Value.absent(),
    this.isDone = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IdeaTasksCompanion.insert({
    this.id = const Value.absent(),
    required int payloadId,
    required String content,
    this.isDone = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : payloadId = Value(payloadId),
        content = Value(content);
  static Insertable<IdeaTask> custom({
    Expression<int>? id,
    Expression<int>? payloadId,
    Expression<String>? content,
    Expression<bool>? isDone,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadId != null) 'payload_id': payloadId,
      if (content != null) 'content': content,
      if (isDone != null) 'is_done': isDone,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IdeaTasksCompanion copyWith(
      {Value<int>? id,
      Value<int>? payloadId,
      Value<String>? content,
      Value<bool>? isDone,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt}) {
    return IdeaTasksCompanion(
      id: id ?? this.id,
      payloadId: payloadId ?? this.payloadId,
      content: content ?? this.content,
      isDone: isDone ?? this.isDone,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payloadId.present) {
      map['payload_id'] = Variable<int>(payloadId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdeaTasksCompanion(')
          ..write('id: $id, ')
          ..write('payloadId: $payloadId, ')
          ..write('content: $content, ')
          ..write('isDone: $isDone, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ContentBlocksTable extends ContentBlocks
    with TableInfo<$ContentBlocksTable, ContentBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _payloadIdMeta =
      const VerificationMeta('payloadId');
  @override
  late final GeneratedColumn<int> payloadId = GeneratedColumn<int>(
      'payload_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES hub_payloads (id)'));
  static const VerificationMeta _blockTypeMeta =
      const VerificationMeta('blockType');
  @override
  late final GeneratedColumn<String> blockType = GeneratedColumn<String>(
      'block_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaPathsMeta =
      const VerificationMeta('mediaPaths');
  @override
  late final GeneratedColumn<String> mediaPaths = GeneratedColumn<String>(
      'media_paths', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _aiPolishedMeta =
      const VerificationMeta('aiPolished');
  @override
  late final GeneratedColumn<bool> aiPolished = GeneratedColumn<bool>(
      'ai_polished', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ai_polished" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        payloadId,
        blockType,
        content,
        mediaPaths,
        sourceType,
        aiPolished,
        sortOrder,
        tags,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_blocks';
  @override
  VerificationContext validateIntegrity(Insertable<ContentBlock> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payload_id')) {
      context.handle(_payloadIdMeta,
          payloadId.isAcceptableOrUnknown(data['payload_id']!, _payloadIdMeta));
    } else if (isInserting) {
      context.missing(_payloadIdMeta);
    }
    if (data.containsKey('block_type')) {
      context.handle(_blockTypeMeta,
          blockType.isAcceptableOrUnknown(data['block_type']!, _blockTypeMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('media_paths')) {
      context.handle(
          _mediaPathsMeta,
          mediaPaths.isAcceptableOrUnknown(
              data['media_paths']!, _mediaPathsMeta));
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    }
    if (data.containsKey('ai_polished')) {
      context.handle(
          _aiPolishedMeta,
          aiPolished.isAcceptableOrUnknown(
              data['ai_polished']!, _aiPolishedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
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
  ContentBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentBlock(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      payloadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payload_id'])!,
      blockType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}block_type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      mediaPaths: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_paths'])!,
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type'])!,
      aiPolished: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ai_polished'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ContentBlocksTable createAlias(String alias) {
    return $ContentBlocksTable(attachedDatabase, alias);
  }
}

class ContentBlock extends DataClass implements Insertable<ContentBlock> {
  final int id;
  final int payloadId;
  final String blockType;
  final String content;
  final String mediaPaths;
  final String sourceType;
  final bool aiPolished;
  final int sortOrder;

  /// 该内容块独立关联的标签，JSON 数组格式如 ["#标签1","#标签2"]
  final String tags;
  final DateTime createdAt;
  const ContentBlock(
      {required this.id,
      required this.payloadId,
      required this.blockType,
      required this.content,
      required this.mediaPaths,
      required this.sourceType,
      required this.aiPolished,
      required this.sortOrder,
      required this.tags,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload_id'] = Variable<int>(payloadId);
    map['block_type'] = Variable<String>(blockType);
    map['content'] = Variable<String>(content);
    map['media_paths'] = Variable<String>(mediaPaths);
    map['source_type'] = Variable<String>(sourceType);
    map['ai_polished'] = Variable<bool>(aiPolished);
    map['sort_order'] = Variable<int>(sortOrder);
    map['tags'] = Variable<String>(tags);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ContentBlocksCompanion toCompanion(bool nullToAbsent) {
    return ContentBlocksCompanion(
      id: Value(id),
      payloadId: Value(payloadId),
      blockType: Value(blockType),
      content: Value(content),
      mediaPaths: Value(mediaPaths),
      sourceType: Value(sourceType),
      aiPolished: Value(aiPolished),
      sortOrder: Value(sortOrder),
      tags: Value(tags),
      createdAt: Value(createdAt),
    );
  }

  factory ContentBlock.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentBlock(
      id: serializer.fromJson<int>(json['id']),
      payloadId: serializer.fromJson<int>(json['payloadId']),
      blockType: serializer.fromJson<String>(json['blockType']),
      content: serializer.fromJson<String>(json['content']),
      mediaPaths: serializer.fromJson<String>(json['mediaPaths']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      aiPolished: serializer.fromJson<bool>(json['aiPolished']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      tags: serializer.fromJson<String>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payloadId': serializer.toJson<int>(payloadId),
      'blockType': serializer.toJson<String>(blockType),
      'content': serializer.toJson<String>(content),
      'mediaPaths': serializer.toJson<String>(mediaPaths),
      'sourceType': serializer.toJson<String>(sourceType),
      'aiPolished': serializer.toJson<bool>(aiPolished),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'tags': serializer.toJson<String>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ContentBlock copyWith(
          {int? id,
          int? payloadId,
          String? blockType,
          String? content,
          String? mediaPaths,
          String? sourceType,
          bool? aiPolished,
          int? sortOrder,
          String? tags,
          DateTime? createdAt}) =>
      ContentBlock(
        id: id ?? this.id,
        payloadId: payloadId ?? this.payloadId,
        blockType: blockType ?? this.blockType,
        content: content ?? this.content,
        mediaPaths: mediaPaths ?? this.mediaPaths,
        sourceType: sourceType ?? this.sourceType,
        aiPolished: aiPolished ?? this.aiPolished,
        sortOrder: sortOrder ?? this.sortOrder,
        tags: tags ?? this.tags,
        createdAt: createdAt ?? this.createdAt,
      );
  ContentBlock copyWithCompanion(ContentBlocksCompanion data) {
    return ContentBlock(
      id: data.id.present ? data.id.value : this.id,
      payloadId: data.payloadId.present ? data.payloadId.value : this.payloadId,
      blockType: data.blockType.present ? data.blockType.value : this.blockType,
      content: data.content.present ? data.content.value : this.content,
      mediaPaths:
          data.mediaPaths.present ? data.mediaPaths.value : this.mediaPaths,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      aiPolished:
          data.aiPolished.present ? data.aiPolished.value : this.aiPolished,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentBlock(')
          ..write('id: $id, ')
          ..write('payloadId: $payloadId, ')
          ..write('blockType: $blockType, ')
          ..write('content: $content, ')
          ..write('mediaPaths: $mediaPaths, ')
          ..write('sourceType: $sourceType, ')
          ..write('aiPolished: $aiPolished, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payloadId, blockType, content, mediaPaths,
      sourceType, aiPolished, sortOrder, tags, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentBlock &&
          other.id == this.id &&
          other.payloadId == this.payloadId &&
          other.blockType == this.blockType &&
          other.content == this.content &&
          other.mediaPaths == this.mediaPaths &&
          other.sourceType == this.sourceType &&
          other.aiPolished == this.aiPolished &&
          other.sortOrder == this.sortOrder &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt);
}

class ContentBlocksCompanion extends UpdateCompanion<ContentBlock> {
  final Value<int> id;
  final Value<int> payloadId;
  final Value<String> blockType;
  final Value<String> content;
  final Value<String> mediaPaths;
  final Value<String> sourceType;
  final Value<bool> aiPolished;
  final Value<int> sortOrder;
  final Value<String> tags;
  final Value<DateTime> createdAt;
  const ContentBlocksCompanion({
    this.id = const Value.absent(),
    this.payloadId = const Value.absent(),
    this.blockType = const Value.absent(),
    this.content = const Value.absent(),
    this.mediaPaths = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.aiPolished = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ContentBlocksCompanion.insert({
    this.id = const Value.absent(),
    required int payloadId,
    this.blockType = const Value.absent(),
    required String content,
    this.mediaPaths = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.aiPolished = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : payloadId = Value(payloadId),
        content = Value(content);
  static Insertable<ContentBlock> custom({
    Expression<int>? id,
    Expression<int>? payloadId,
    Expression<String>? blockType,
    Expression<String>? content,
    Expression<String>? mediaPaths,
    Expression<String>? sourceType,
    Expression<bool>? aiPolished,
    Expression<int>? sortOrder,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadId != null) 'payload_id': payloadId,
      if (blockType != null) 'block_type': blockType,
      if (content != null) 'content': content,
      if (mediaPaths != null) 'media_paths': mediaPaths,
      if (sourceType != null) 'source_type': sourceType,
      if (aiPolished != null) 'ai_polished': aiPolished,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ContentBlocksCompanion copyWith(
      {Value<int>? id,
      Value<int>? payloadId,
      Value<String>? blockType,
      Value<String>? content,
      Value<String>? mediaPaths,
      Value<String>? sourceType,
      Value<bool>? aiPolished,
      Value<int>? sortOrder,
      Value<String>? tags,
      Value<DateTime>? createdAt}) {
    return ContentBlocksCompanion(
      id: id ?? this.id,
      payloadId: payloadId ?? this.payloadId,
      blockType: blockType ?? this.blockType,
      content: content ?? this.content,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      sourceType: sourceType ?? this.sourceType,
      aiPolished: aiPolished ?? this.aiPolished,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payloadId.present) {
      map['payload_id'] = Variable<int>(payloadId.value);
    }
    if (blockType.present) {
      map['block_type'] = Variable<String>(blockType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mediaPaths.present) {
      map['media_paths'] = Variable<String>(mediaPaths.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (aiPolished.present) {
      map['ai_polished'] = Variable<bool>(aiPolished.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentBlocksCompanion(')
          ..write('id: $id, ')
          ..write('payloadId: $payloadId, ')
          ..write('blockType: $blockType, ')
          ..write('content: $content, ')
          ..write('mediaPaths: $mediaPaths, ')
          ..write('sourceType: $sourceType, ')
          ..write('aiPolished: $aiPolished, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AiConversationsTable extends AiConversations
    with TableInfo<$AiConversationsTable, AiConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _payloadIdMeta =
      const VerificationMeta('payloadId');
  @override
  late final GeneratedColumn<int> payloadId = GeneratedColumn<int>(
      'payload_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES hub_payloads (id)'));
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
      [id, payloadId, role, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_conversations';
  @override
  VerificationContext validateIntegrity(Insertable<AiConversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payload_id')) {
      context.handle(_payloadIdMeta,
          payloadId.isAcceptableOrUnknown(data['payload_id']!, _payloadIdMeta));
    } else if (isInserting) {
      context.missing(_payloadIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
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
  AiConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiConversation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      payloadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payload_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AiConversationsTable createAlias(String alias) {
    return $AiConversationsTable(attachedDatabase, alias);
  }
}

class AiConversation extends DataClass implements Insertable<AiConversation> {
  final int id;
  final int payloadId;
  final String role;
  final String content;
  final DateTime createdAt;
  const AiConversation(
      {required this.id,
      required this.payloadId,
      required this.role,
      required this.content,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload_id'] = Variable<int>(payloadId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AiConversationsCompanion toCompanion(bool nullToAbsent) {
    return AiConversationsCompanion(
      id: Value(id),
      payloadId: Value(payloadId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory AiConversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiConversation(
      id: serializer.fromJson<int>(json['id']),
      payloadId: serializer.fromJson<int>(json['payloadId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payloadId': serializer.toJson<int>(payloadId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AiConversation copyWith(
          {int? id,
          int? payloadId,
          String? role,
          String? content,
          DateTime? createdAt}) =>
      AiConversation(
        id: id ?? this.id,
        payloadId: payloadId ?? this.payloadId,
        role: role ?? this.role,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  AiConversation copyWithCompanion(AiConversationsCompanion data) {
    return AiConversation(
      id: data.id.present ? data.id.value : this.id,
      payloadId: data.payloadId.present ? data.payloadId.value : this.payloadId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiConversation(')
          ..write('id: $id, ')
          ..write('payloadId: $payloadId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payloadId, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiConversation &&
          other.id == this.id &&
          other.payloadId == this.payloadId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class AiConversationsCompanion extends UpdateCompanion<AiConversation> {
  final Value<int> id;
  final Value<int> payloadId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  const AiConversationsCompanion({
    this.id = const Value.absent(),
    this.payloadId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AiConversationsCompanion.insert({
    this.id = const Value.absent(),
    required int payloadId,
    required String role,
    required String content,
    this.createdAt = const Value.absent(),
  })  : payloadId = Value(payloadId),
        role = Value(role),
        content = Value(content);
  static Insertable<AiConversation> custom({
    Expression<int>? id,
    Expression<int>? payloadId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadId != null) 'payload_id': payloadId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AiConversationsCompanion copyWith(
      {Value<int>? id,
      Value<int>? payloadId,
      Value<String>? role,
      Value<String>? content,
      Value<DateTime>? createdAt}) {
    return AiConversationsCompanion(
      id: id ?? this.id,
      payloadId: payloadId ?? this.payloadId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payloadId.present) {
      map['payload_id'] = Variable<int>(payloadId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiConversationsCompanion(')
          ..write('id: $id, ')
          ..write('payloadId: $payloadId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AiTemplatesTable extends AiTemplates
    with TableInfo<$AiTemplatesTable, AiTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('📋'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
      'prompt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isEnabledMeta =
      const VerificationMeta('isEnabled');
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
      'is_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
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
      [id, icon, name, prompt, isEnabled, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_templates';
  @override
  VerificationContext validateIntegrity(Insertable<AiTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(_promptMeta,
          prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta));
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(_isEnabledMeta,
          isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
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
  AiTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      prompt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt'])!,
      isEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_enabled'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AiTemplatesTable createAlias(String alias) {
    return $AiTemplatesTable(attachedDatabase, alias);
  }
}

class AiTemplate extends DataClass implements Insertable<AiTemplate> {
  final int id;
  final String icon;
  final String name;
  final String prompt;
  final bool isEnabled;
  final int sortOrder;
  final DateTime createdAt;
  const AiTemplate(
      {required this.id,
      required this.icon,
      required this.name,
      required this.prompt,
      required this.isEnabled,
      required this.sortOrder,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['icon'] = Variable<String>(icon);
    map['name'] = Variable<String>(name);
    map['prompt'] = Variable<String>(prompt);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AiTemplatesCompanion toCompanion(bool nullToAbsent) {
    return AiTemplatesCompanion(
      id: Value(id),
      icon: Value(icon),
      name: Value(name),
      prompt: Value(prompt),
      isEnabled: Value(isEnabled),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory AiTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiTemplate(
      id: serializer.fromJson<int>(json['id']),
      icon: serializer.fromJson<String>(json['icon']),
      name: serializer.fromJson<String>(json['name']),
      prompt: serializer.fromJson<String>(json['prompt']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'icon': serializer.toJson<String>(icon),
      'name': serializer.toJson<String>(name),
      'prompt': serializer.toJson<String>(prompt),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AiTemplate copyWith(
          {int? id,
          String? icon,
          String? name,
          String? prompt,
          bool? isEnabled,
          int? sortOrder,
          DateTime? createdAt}) =>
      AiTemplate(
        id: id ?? this.id,
        icon: icon ?? this.icon,
        name: name ?? this.name,
        prompt: prompt ?? this.prompt,
        isEnabled: isEnabled ?? this.isEnabled,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  AiTemplate copyWithCompanion(AiTemplatesCompanion data) {
    return AiTemplate(
      id: data.id.present ? data.id.value : this.id,
      icon: data.icon.present ? data.icon.value : this.icon,
      name: data.name.present ? data.name.value : this.name,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiTemplate(')
          ..write('id: $id, ')
          ..write('icon: $icon, ')
          ..write('name: $name, ')
          ..write('prompt: $prompt, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, icon, name, prompt, isEnabled, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiTemplate &&
          other.id == this.id &&
          other.icon == this.icon &&
          other.name == this.name &&
          other.prompt == this.prompt &&
          other.isEnabled == this.isEnabled &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class AiTemplatesCompanion extends UpdateCompanion<AiTemplate> {
  final Value<int> id;
  final Value<String> icon;
  final Value<String> name;
  final Value<String> prompt;
  final Value<bool> isEnabled;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const AiTemplatesCompanion({
    this.id = const Value.absent(),
    this.icon = const Value.absent(),
    this.name = const Value.absent(),
    this.prompt = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AiTemplatesCompanion.insert({
    this.id = const Value.absent(),
    this.icon = const Value.absent(),
    required String name,
    required String prompt,
    this.isEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        prompt = Value(prompt);
  static Insertable<AiTemplate> custom({
    Expression<int>? id,
    Expression<String>? icon,
    Expression<String>? name,
    Expression<String>? prompt,
    Expression<bool>? isEnabled,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (icon != null) 'icon': icon,
      if (name != null) 'name': name,
      if (prompt != null) 'prompt': prompt,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AiTemplatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? icon,
      Value<String>? name,
      Value<String>? prompt,
      Value<bool>? isEnabled,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt}) {
    return AiTemplatesCompanion(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      name: name ?? this.name,
      prompt: prompt ?? this.prompt,
      isEnabled: isEnabled ?? this.isEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('icon: $icon, ')
          ..write('name: $name, ')
          ..write('prompt: $prompt, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CrmCustomersTable extends CrmCustomers
    with TableInfo<$CrmCustomersTable, CrmCustomer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CrmCustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sourcePayloadIdMeta =
      const VerificationMeta('sourcePayloadId');
  @override
  late final GeneratedColumn<int> sourcePayloadId = GeneratedColumn<int>(
      'source_payload_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES hub_payloads (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyMeta =
      const VerificationMeta('company');
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
      'company', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contactMeta =
      const VerificationMeta('contact');
  @override
  late final GeneratedColumn<String> contact = GeneratedColumn<String>(
      'contact', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sourcePayloadId,
        name,
        company,
        contact,
        tags,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crm_customers';
  @override
  VerificationContext validateIntegrity(Insertable<CrmCustomer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_payload_id')) {
      context.handle(
          _sourcePayloadIdMeta,
          sourcePayloadId.isAcceptableOrUnknown(
              data['source_payload_id']!, _sourcePayloadIdMeta));
    } else if (isInserting) {
      context.missing(_sourcePayloadIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('company')) {
      context.handle(_companyMeta,
          company.isAcceptableOrUnknown(data['company']!, _companyMeta));
    }
    if (data.containsKey('contact')) {
      context.handle(_contactMeta,
          contact.isAcceptableOrUnknown(data['contact']!, _contactMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CrmCustomer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CrmCustomer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sourcePayloadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source_payload_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      company: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company']),
      contact: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CrmCustomersTable createAlias(String alias) {
    return $CrmCustomersTable(attachedDatabase, alias);
  }
}

class CrmCustomer extends DataClass implements Insertable<CrmCustomer> {
  final int id;
  final int sourcePayloadId;
  final String name;
  final String? company;
  final String? contact;
  final String tags;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CrmCustomer(
      {required this.id,
      required this.sourcePayloadId,
      required this.name,
      this.company,
      this.contact,
      required this.tags,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_payload_id'] = Variable<int>(sourcePayloadId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || company != null) {
      map['company'] = Variable<String>(company);
    }
    if (!nullToAbsent || contact != null) {
      map['contact'] = Variable<String>(contact);
    }
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CrmCustomersCompanion toCompanion(bool nullToAbsent) {
    return CrmCustomersCompanion(
      id: Value(id),
      sourcePayloadId: Value(sourcePayloadId),
      name: Value(name),
      company: company == null && nullToAbsent
          ? const Value.absent()
          : Value(company),
      contact: contact == null && nullToAbsent
          ? const Value.absent()
          : Value(contact),
      tags: Value(tags),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CrmCustomer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CrmCustomer(
      id: serializer.fromJson<int>(json['id']),
      sourcePayloadId: serializer.fromJson<int>(json['sourcePayloadId']),
      name: serializer.fromJson<String>(json['name']),
      company: serializer.fromJson<String?>(json['company']),
      contact: serializer.fromJson<String?>(json['contact']),
      tags: serializer.fromJson<String>(json['tags']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourcePayloadId': serializer.toJson<int>(sourcePayloadId),
      'name': serializer.toJson<String>(name),
      'company': serializer.toJson<String?>(company),
      'contact': serializer.toJson<String?>(contact),
      'tags': serializer.toJson<String>(tags),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CrmCustomer copyWith(
          {int? id,
          int? sourcePayloadId,
          String? name,
          Value<String?> company = const Value.absent(),
          Value<String?> contact = const Value.absent(),
          String? tags,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CrmCustomer(
        id: id ?? this.id,
        sourcePayloadId: sourcePayloadId ?? this.sourcePayloadId,
        name: name ?? this.name,
        company: company.present ? company.value : this.company,
        contact: contact.present ? contact.value : this.contact,
        tags: tags ?? this.tags,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CrmCustomer copyWithCompanion(CrmCustomersCompanion data) {
    return CrmCustomer(
      id: data.id.present ? data.id.value : this.id,
      sourcePayloadId: data.sourcePayloadId.present
          ? data.sourcePayloadId.value
          : this.sourcePayloadId,
      name: data.name.present ? data.name.value : this.name,
      company: data.company.present ? data.company.value : this.company,
      contact: data.contact.present ? data.contact.value : this.contact,
      tags: data.tags.present ? data.tags.value : this.tags,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CrmCustomer(')
          ..write('id: $id, ')
          ..write('sourcePayloadId: $sourcePayloadId, ')
          ..write('name: $name, ')
          ..write('company: $company, ')
          ..write('contact: $contact, ')
          ..write('tags: $tags, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourcePayloadId, name, company, contact,
      tags, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrmCustomer &&
          other.id == this.id &&
          other.sourcePayloadId == this.sourcePayloadId &&
          other.name == this.name &&
          other.company == this.company &&
          other.contact == this.contact &&
          other.tags == this.tags &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CrmCustomersCompanion extends UpdateCompanion<CrmCustomer> {
  final Value<int> id;
  final Value<int> sourcePayloadId;
  final Value<String> name;
  final Value<String?> company;
  final Value<String?> contact;
  final Value<String> tags;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CrmCustomersCompanion({
    this.id = const Value.absent(),
    this.sourcePayloadId = const Value.absent(),
    this.name = const Value.absent(),
    this.company = const Value.absent(),
    this.contact = const Value.absent(),
    this.tags = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CrmCustomersCompanion.insert({
    this.id = const Value.absent(),
    required int sourcePayloadId,
    required String name,
    this.company = const Value.absent(),
    this.contact = const Value.absent(),
    this.tags = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : sourcePayloadId = Value(sourcePayloadId),
        name = Value(name);
  static Insertable<CrmCustomer> custom({
    Expression<int>? id,
    Expression<int>? sourcePayloadId,
    Expression<String>? name,
    Expression<String>? company,
    Expression<String>? contact,
    Expression<String>? tags,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePayloadId != null) 'source_payload_id': sourcePayloadId,
      if (name != null) 'name': name,
      if (company != null) 'company': company,
      if (contact != null) 'contact': contact,
      if (tags != null) 'tags': tags,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CrmCustomersCompanion copyWith(
      {Value<int>? id,
      Value<int>? sourcePayloadId,
      Value<String>? name,
      Value<String?>? company,
      Value<String?>? contact,
      Value<String>? tags,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return CrmCustomersCompanion(
      id: id ?? this.id,
      sourcePayloadId: sourcePayloadId ?? this.sourcePayloadId,
      name: name ?? this.name,
      company: company ?? this.company,
      contact: contact ?? this.contact,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourcePayloadId.present) {
      map['source_payload_id'] = Variable<int>(sourcePayloadId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (contact.present) {
      map['contact'] = Variable<String>(contact.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CrmCustomersCompanion(')
          ..write('id: $id, ')
          ..write('sourcePayloadId: $sourcePayloadId, ')
          ..write('name: $name, ')
          ..write('company: $company, ')
          ..write('contact: $contact, ')
          ..write('tags: $tags, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, LedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sourcePayloadIdMeta =
      const VerificationMeta('sourcePayloadId');
  @override
  late final GeneratedColumn<int> sourcePayloadId = GeneratedColumn<int>(
      'source_payload_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES hub_payloads (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('expense'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sourcePayloadId,
        amount,
        category,
        type,
        description,
        occurredAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(Insertable<LedgerEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_payload_id')) {
      context.handle(
          _sourcePayloadIdMeta,
          sourcePayloadId.isAcceptableOrUnknown(
              data['source_payload_id']!, _sourcePayloadIdMeta));
    } else if (isInserting) {
      context.missing(_sourcePayloadIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
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
  LedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sourcePayloadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source_payload_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }
}

class LedgerEntry extends DataClass implements Insertable<LedgerEntry> {
  final int id;
  final int sourcePayloadId;
  final double amount;
  final String category;
  final String type;
  final String? description;
  final DateTime? occurredAt;
  final DateTime createdAt;
  const LedgerEntry(
      {required this.id,
      required this.sourcePayloadId,
      required this.amount,
      required this.category,
      required this.type,
      this.description,
      this.occurredAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_payload_id'] = Variable<int>(sourcePayloadId);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || occurredAt != null) {
      map['occurred_at'] = Variable<DateTime>(occurredAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      sourcePayloadId: Value(sourcePayloadId),
      amount: Value(amount),
      category: Value(category),
      type: Value(type),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      occurredAt: occurredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(occurredAt),
      createdAt: Value(createdAt),
    );
  }

  factory LedgerEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntry(
      id: serializer.fromJson<int>(json['id']),
      sourcePayloadId: serializer.fromJson<int>(json['sourcePayloadId']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      type: serializer.fromJson<String>(json['type']),
      description: serializer.fromJson<String?>(json['description']),
      occurredAt: serializer.fromJson<DateTime?>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourcePayloadId': serializer.toJson<int>(sourcePayloadId),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'type': serializer.toJson<String>(type),
      'description': serializer.toJson<String?>(description),
      'occurredAt': serializer.toJson<DateTime?>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LedgerEntry copyWith(
          {int? id,
          int? sourcePayloadId,
          double? amount,
          String? category,
          String? type,
          Value<String?> description = const Value.absent(),
          Value<DateTime?> occurredAt = const Value.absent(),
          DateTime? createdAt}) =>
      LedgerEntry(
        id: id ?? this.id,
        sourcePayloadId: sourcePayloadId ?? this.sourcePayloadId,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        type: type ?? this.type,
        description: description.present ? description.value : this.description,
        occurredAt: occurredAt.present ? occurredAt.value : this.occurredAt,
        createdAt: createdAt ?? this.createdAt,
      );
  LedgerEntry copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      sourcePayloadId: data.sourcePayloadId.present
          ? data.sourcePayloadId.value
          : this.sourcePayloadId,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      type: data.type.present ? data.type.value : this.type,
      description:
          data.description.present ? data.description.value : this.description,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntry(')
          ..write('id: $id, ')
          ..write('sourcePayloadId: $sourcePayloadId, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourcePayloadId, amount, category, type,
      description, occurredAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntry &&
          other.id == this.id &&
          other.sourcePayloadId == this.sourcePayloadId &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.type == this.type &&
          other.description == this.description &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntry> {
  final Value<int> id;
  final Value<int> sourcePayloadId;
  final Value<double> amount;
  final Value<String> category;
  final Value<String> type;
  final Value<String?> description;
  final Value<DateTime?> occurredAt;
  final Value<DateTime> createdAt;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.sourcePayloadId = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int sourcePayloadId,
    required double amount,
    required String category,
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : sourcePayloadId = Value(sourcePayloadId),
        amount = Value(amount),
        category = Value(category);
  static Insertable<LedgerEntry> custom({
    Expression<int>? id,
    Expression<int>? sourcePayloadId,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<String>? type,
    Expression<String>? description,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePayloadId != null) 'source_payload_id': sourcePayloadId,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LedgerEntriesCompanion copyWith(
      {Value<int>? id,
      Value<int>? sourcePayloadId,
      Value<double>? amount,
      Value<String>? category,
      Value<String>? type,
      Value<String?>? description,
      Value<DateTime?>? occurredAt,
      Value<DateTime>? createdAt}) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      sourcePayloadId: sourcePayloadId ?? this.sourcePayloadId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourcePayloadId.present) {
      map['source_payload_id'] = Variable<int>(sourcePayloadId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sourcePayloadId: $sourcePayloadId, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TodoSchedulesTable extends TodoSchedules
    with TableInfo<$TodoSchedulesTable, TodoSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sourcePayloadIdMeta =
      const VerificationMeta('sourcePayloadId');
  @override
  late final GeneratedColumn<int> sourcePayloadId = GeneratedColumn<int>(
      'source_payload_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES hub_payloads (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
      'is_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
      [id, sourcePayloadId, title, dueDate, priority, isDone, notes, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_schedules';
  @override
  VerificationContext validateIntegrity(Insertable<TodoSchedule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_payload_id')) {
      context.handle(
          _sourcePayloadIdMeta,
          sourcePayloadId.isAcceptableOrUnknown(
              data['source_payload_id']!, _sourcePayloadIdMeta));
    } else if (isInserting) {
      context.missing(_sourcePayloadIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('is_done')) {
      context.handle(_isDoneMeta,
          isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
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
  TodoSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoSchedule(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sourcePayloadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source_payload_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      isDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_done'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TodoSchedulesTable createAlias(String alias) {
    return $TodoSchedulesTable(attachedDatabase, alias);
  }
}

class TodoSchedule extends DataClass implements Insertable<TodoSchedule> {
  final int id;
  final int sourcePayloadId;
  final String title;
  final DateTime? dueDate;
  final int priority;
  final bool isDone;
  final String? notes;
  final DateTime createdAt;
  const TodoSchedule(
      {required this.id,
      required this.sourcePayloadId,
      required this.title,
      this.dueDate,
      required this.priority,
      required this.isDone,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_payload_id'] = Variable<int>(sourcePayloadId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['priority'] = Variable<int>(priority);
    map['is_done'] = Variable<bool>(isDone);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TodoSchedulesCompanion toCompanion(bool nullToAbsent) {
    return TodoSchedulesCompanion(
      id: Value(id),
      sourcePayloadId: Value(sourcePayloadId),
      title: Value(title),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      priority: Value(priority),
      isDone: Value(isDone),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory TodoSchedule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoSchedule(
      id: serializer.fromJson<int>(json['id']),
      sourcePayloadId: serializer.fromJson<int>(json['sourcePayloadId']),
      title: serializer.fromJson<String>(json['title']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      priority: serializer.fromJson<int>(json['priority']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourcePayloadId': serializer.toJson<int>(sourcePayloadId),
      'title': serializer.toJson<String>(title),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'priority': serializer.toJson<int>(priority),
      'isDone': serializer.toJson<bool>(isDone),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TodoSchedule copyWith(
          {int? id,
          int? sourcePayloadId,
          String? title,
          Value<DateTime?> dueDate = const Value.absent(),
          int? priority,
          bool? isDone,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      TodoSchedule(
        id: id ?? this.id,
        sourcePayloadId: sourcePayloadId ?? this.sourcePayloadId,
        title: title ?? this.title,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        priority: priority ?? this.priority,
        isDone: isDone ?? this.isDone,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  TodoSchedule copyWithCompanion(TodoSchedulesCompanion data) {
    return TodoSchedule(
      id: data.id.present ? data.id.value : this.id,
      sourcePayloadId: data.sourcePayloadId.present
          ? data.sourcePayloadId.value
          : this.sourcePayloadId,
      title: data.title.present ? data.title.value : this.title,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      priority: data.priority.present ? data.priority.value : this.priority,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoSchedule(')
          ..write('id: $id, ')
          ..write('sourcePayloadId: $sourcePayloadId, ')
          ..write('title: $title, ')
          ..write('dueDate: $dueDate, ')
          ..write('priority: $priority, ')
          ..write('isDone: $isDone, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, sourcePayloadId, title, dueDate, priority, isDone, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoSchedule &&
          other.id == this.id &&
          other.sourcePayloadId == this.sourcePayloadId &&
          other.title == this.title &&
          other.dueDate == this.dueDate &&
          other.priority == this.priority &&
          other.isDone == this.isDone &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class TodoSchedulesCompanion extends UpdateCompanion<TodoSchedule> {
  final Value<int> id;
  final Value<int> sourcePayloadId;
  final Value<String> title;
  final Value<DateTime?> dueDate;
  final Value<int> priority;
  final Value<bool> isDone;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const TodoSchedulesCompanion({
    this.id = const Value.absent(),
    this.sourcePayloadId = const Value.absent(),
    this.title = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDone = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TodoSchedulesCompanion.insert({
    this.id = const Value.absent(),
    required int sourcePayloadId,
    required String title,
    this.dueDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDone = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : sourcePayloadId = Value(sourcePayloadId),
        title = Value(title);
  static Insertable<TodoSchedule> custom({
    Expression<int>? id,
    Expression<int>? sourcePayloadId,
    Expression<String>? title,
    Expression<DateTime>? dueDate,
    Expression<int>? priority,
    Expression<bool>? isDone,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePayloadId != null) 'source_payload_id': sourcePayloadId,
      if (title != null) 'title': title,
      if (dueDate != null) 'due_date': dueDate,
      if (priority != null) 'priority': priority,
      if (isDone != null) 'is_done': isDone,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TodoSchedulesCompanion copyWith(
      {Value<int>? id,
      Value<int>? sourcePayloadId,
      Value<String>? title,
      Value<DateTime?>? dueDate,
      Value<int>? priority,
      Value<bool>? isDone,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return TodoSchedulesCompanion(
      id: id ?? this.id,
      sourcePayloadId: sourcePayloadId ?? this.sourcePayloadId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourcePayloadId.present) {
      map['source_payload_id'] = Variable<int>(sourcePayloadId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('sourcePayloadId: $sourcePayloadId, ')
          ..write('title: $title, ')
          ..write('dueDate: $dueDate, ')
          ..write('priority: $priority, ')
          ..write('isDone: $isDone, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HubPayloadsTable hubPayloads = $HubPayloadsTable(this);
  late final $ChatSessionsTable chatSessions = $ChatSessionsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $LongTermMemoriesTable longTermMemories =
      $LongTermMemoriesTable(this);
  late final $KnowledgeFilesTable knowledgeFiles = $KnowledgeFilesTable(this);
  late final $VectorStorageTable vectorStorage = $VectorStorageTable(this);
  late final $IdeaTasksTable ideaTasks = $IdeaTasksTable(this);
  late final $ContentBlocksTable contentBlocks = $ContentBlocksTable(this);
  late final $AiConversationsTable aiConversations =
      $AiConversationsTable(this);
  late final $AiTemplatesTable aiTemplates = $AiTemplatesTable(this);
  late final $CrmCustomersTable crmCustomers = $CrmCustomersTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $TodoSchedulesTable todoSchedules = $TodoSchedulesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        hubPayloads,
        chatSessions,
        chatMessages,
        longTermMemories,
        knowledgeFiles,
        vectorStorage,
        ideaTasks,
        contentBlocks,
        aiConversations,
        aiTemplates,
        crmCustomers,
        ledgerEntries,
        todoSchedules
      ];
}

typedef $$HubPayloadsTableCreateCompanionBuilder = HubPayloadsCompanion
    Function({
  Value<int> id,
  required String rawText,
  Value<String> mediaPaths,
  Value<String> intentTag,
  Value<String?> title,
  Value<int> syncStatus,
  Value<String> processingStatus,
  Value<String?> dispatchedRef,
  Value<String?> aiEntities,
  Value<bool> isEphemeral,
  Value<DateTime?> decayDeadline,
  Value<DateTime> createdAt,
});
typedef $$HubPayloadsTableUpdateCompanionBuilder = HubPayloadsCompanion
    Function({
  Value<int> id,
  Value<String> rawText,
  Value<String> mediaPaths,
  Value<String> intentTag,
  Value<String?> title,
  Value<int> syncStatus,
  Value<String> processingStatus,
  Value<String?> dispatchedRef,
  Value<String?> aiEntities,
  Value<bool> isEphemeral,
  Value<DateTime?> decayDeadline,
  Value<DateTime> createdAt,
});

final class $$HubPayloadsTableReferences
    extends BaseReferences<_$AppDatabase, $HubPayloadsTable, HubPayload> {
  $$HubPayloadsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IdeaTasksTable, List<IdeaTask>>
      _ideaTasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.ideaTasks,
          aliasName:
              $_aliasNameGenerator(db.hubPayloads.id, db.ideaTasks.payloadId));

  $$IdeaTasksTableProcessedTableManager get ideaTasksRefs {
    final manager = $$IdeaTasksTableTableManager($_db, $_db.ideaTasks)
        .filter((f) => f.payloadId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_ideaTasksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ContentBlocksTable, List<ContentBlock>>
      _contentBlocksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.contentBlocks,
              aliasName: $_aliasNameGenerator(
                  db.hubPayloads.id, db.contentBlocks.payloadId));

  $$ContentBlocksTableProcessedTableManager get contentBlocksRefs {
    final manager = $$ContentBlocksTableTableManager($_db, $_db.contentBlocks)
        .filter((f) => f.payloadId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_contentBlocksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AiConversationsTable, List<AiConversation>>
      _aiConversationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.aiConversations,
              aliasName: $_aliasNameGenerator(
                  db.hubPayloads.id, db.aiConversations.payloadId));

  $$AiConversationsTableProcessedTableManager get aiConversationsRefs {
    final manager =
        $$AiConversationsTableTableManager($_db, $_db.aiConversations)
            .filter((f) => f.payloadId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_aiConversationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CrmCustomersTable, List<CrmCustomer>>
      _crmCustomersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.crmCustomers,
              aliasName: $_aliasNameGenerator(
                  db.hubPayloads.id, db.crmCustomers.sourcePayloadId));

  $$CrmCustomersTableProcessedTableManager get crmCustomersRefs {
    final manager = $$CrmCustomersTableTableManager($_db, $_db.crmCustomers)
        .filter((f) => f.sourcePayloadId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_crmCustomersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<LedgerEntry>>
      _ledgerEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.ledgerEntries,
              aliasName: $_aliasNameGenerator(
                  db.hubPayloads.id, db.ledgerEntries.sourcePayloadId));

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager($_db, $_db.ledgerEntries)
        .filter((f) => f.sourcePayloadId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TodoSchedulesTable, List<TodoSchedule>>
      _todoSchedulesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.todoSchedules,
              aliasName: $_aliasNameGenerator(
                  db.hubPayloads.id, db.todoSchedules.sourcePayloadId));

  $$TodoSchedulesTableProcessedTableManager get todoSchedulesRefs {
    final manager = $$TodoSchedulesTableTableManager($_db, $_db.todoSchedules)
        .filter((f) => f.sourcePayloadId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_todoSchedulesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

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

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get processingStatus => $composableBuilder(
      column: $table.processingStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dispatchedRef => $composableBuilder(
      column: $table.dispatchedRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiEntities => $composableBuilder(
      column: $table.aiEntities, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEphemeral => $composableBuilder(
      column: $table.isEphemeral, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get decayDeadline => $composableBuilder(
      column: $table.decayDeadline, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> ideaTasksRefs(
      Expression<bool> Function($$IdeaTasksTableFilterComposer f) f) {
    final $$IdeaTasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ideaTasks,
        getReferencedColumn: (t) => t.payloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IdeaTasksTableFilterComposer(
              $db: $db,
              $table: $db.ideaTasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> contentBlocksRefs(
      Expression<bool> Function($$ContentBlocksTableFilterComposer f) f) {
    final $$ContentBlocksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.contentBlocks,
        getReferencedColumn: (t) => t.payloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentBlocksTableFilterComposer(
              $db: $db,
              $table: $db.contentBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> aiConversationsRefs(
      Expression<bool> Function($$AiConversationsTableFilterComposer f) f) {
    final $$AiConversationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aiConversations,
        getReferencedColumn: (t) => t.payloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiConversationsTableFilterComposer(
              $db: $db,
              $table: $db.aiConversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> crmCustomersRefs(
      Expression<bool> Function($$CrmCustomersTableFilterComposer f) f) {
    final $$CrmCustomersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.crmCustomers,
        getReferencedColumn: (t) => t.sourcePayloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CrmCustomersTableFilterComposer(
              $db: $db,
              $table: $db.crmCustomers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ledgerEntriesRefs(
      Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ledgerEntries,
        getReferencedColumn: (t) => t.sourcePayloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LedgerEntriesTableFilterComposer(
              $db: $db,
              $table: $db.ledgerEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> todoSchedulesRefs(
      Expression<bool> Function($$TodoSchedulesTableFilterComposer f) f) {
    final $$TodoSchedulesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.todoSchedules,
        getReferencedColumn: (t) => t.sourcePayloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoSchedulesTableFilterComposer(
              $db: $db,
              $table: $db.todoSchedules,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
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

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get processingStatus => $composableBuilder(
      column: $table.processingStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dispatchedRef => $composableBuilder(
      column: $table.dispatchedRef,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiEntities => $composableBuilder(
      column: $table.aiEntities, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEphemeral => $composableBuilder(
      column: $table.isEphemeral, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get decayDeadline => $composableBuilder(
      column: $table.decayDeadline,
      builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get processingStatus => $composableBuilder(
      column: $table.processingStatus, builder: (column) => column);

  GeneratedColumn<String> get dispatchedRef => $composableBuilder(
      column: $table.dispatchedRef, builder: (column) => column);

  GeneratedColumn<String> get aiEntities => $composableBuilder(
      column: $table.aiEntities, builder: (column) => column);

  GeneratedColumn<bool> get isEphemeral => $composableBuilder(
      column: $table.isEphemeral, builder: (column) => column);

  GeneratedColumn<DateTime> get decayDeadline => $composableBuilder(
      column: $table.decayDeadline, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> ideaTasksRefs<T extends Object>(
      Expression<T> Function($$IdeaTasksTableAnnotationComposer a) f) {
    final $$IdeaTasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ideaTasks,
        getReferencedColumn: (t) => t.payloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IdeaTasksTableAnnotationComposer(
              $db: $db,
              $table: $db.ideaTasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> contentBlocksRefs<T extends Object>(
      Expression<T> Function($$ContentBlocksTableAnnotationComposer a) f) {
    final $$ContentBlocksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.contentBlocks,
        getReferencedColumn: (t) => t.payloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContentBlocksTableAnnotationComposer(
              $db: $db,
              $table: $db.contentBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> aiConversationsRefs<T extends Object>(
      Expression<T> Function($$AiConversationsTableAnnotationComposer a) f) {
    final $$AiConversationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aiConversations,
        getReferencedColumn: (t) => t.payloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiConversationsTableAnnotationComposer(
              $db: $db,
              $table: $db.aiConversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> crmCustomersRefs<T extends Object>(
      Expression<T> Function($$CrmCustomersTableAnnotationComposer a) f) {
    final $$CrmCustomersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.crmCustomers,
        getReferencedColumn: (t) => t.sourcePayloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CrmCustomersTableAnnotationComposer(
              $db: $db,
              $table: $db.crmCustomers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
      Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ledgerEntries,
        getReferencedColumn: (t) => t.sourcePayloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LedgerEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.ledgerEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> todoSchedulesRefs<T extends Object>(
      Expression<T> Function($$TodoSchedulesTableAnnotationComposer a) f) {
    final $$TodoSchedulesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.todoSchedules,
        getReferencedColumn: (t) => t.sourcePayloadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoSchedulesTableAnnotationComposer(
              $db: $db,
              $table: $db.todoSchedules,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
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
    (HubPayload, $$HubPayloadsTableReferences),
    HubPayload,
    PrefetchHooks Function(
        {bool ideaTasksRefs,
        bool contentBlocksRefs,
        bool aiConversationsRefs,
        bool crmCustomersRefs,
        bool ledgerEntriesRefs,
        bool todoSchedulesRefs})> {
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
            Value<String?> title = const Value.absent(),
            Value<int> syncStatus = const Value.absent(),
            Value<String> processingStatus = const Value.absent(),
            Value<String?> dispatchedRef = const Value.absent(),
            Value<String?> aiEntities = const Value.absent(),
            Value<bool> isEphemeral = const Value.absent(),
            Value<DateTime?> decayDeadline = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              HubPayloadsCompanion(
            id: id,
            rawText: rawText,
            mediaPaths: mediaPaths,
            intentTag: intentTag,
            title: title,
            syncStatus: syncStatus,
            processingStatus: processingStatus,
            dispatchedRef: dispatchedRef,
            aiEntities: aiEntities,
            isEphemeral: isEphemeral,
            decayDeadline: decayDeadline,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String rawText,
            Value<String> mediaPaths = const Value.absent(),
            Value<String> intentTag = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<int> syncStatus = const Value.absent(),
            Value<String> processingStatus = const Value.absent(),
            Value<String?> dispatchedRef = const Value.absent(),
            Value<String?> aiEntities = const Value.absent(),
            Value<bool> isEphemeral = const Value.absent(),
            Value<DateTime?> decayDeadline = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              HubPayloadsCompanion.insert(
            id: id,
            rawText: rawText,
            mediaPaths: mediaPaths,
            intentTag: intentTag,
            title: title,
            syncStatus: syncStatus,
            processingStatus: processingStatus,
            dispatchedRef: dispatchedRef,
            aiEntities: aiEntities,
            isEphemeral: isEphemeral,
            decayDeadline: decayDeadline,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$HubPayloadsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {ideaTasksRefs = false,
              contentBlocksRefs = false,
              aiConversationsRefs = false,
              crmCustomersRefs = false,
              ledgerEntriesRefs = false,
              todoSchedulesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ideaTasksRefs) db.ideaTasks,
                if (contentBlocksRefs) db.contentBlocks,
                if (aiConversationsRefs) db.aiConversations,
                if (crmCustomersRefs) db.crmCustomers,
                if (ledgerEntriesRefs) db.ledgerEntries,
                if (todoSchedulesRefs) db.todoSchedules
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ideaTasksRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$HubPayloadsTableReferences
                            ._ideaTasksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HubPayloadsTableReferences(db, table, p0)
                                .ideaTasksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.payloadId == item.id),
                        typedResults: items),
                  if (contentBlocksRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$HubPayloadsTableReferences
                            ._contentBlocksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HubPayloadsTableReferences(db, table, p0)
                                .contentBlocksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.payloadId == item.id),
                        typedResults: items),
                  if (aiConversationsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$HubPayloadsTableReferences
                            ._aiConversationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HubPayloadsTableReferences(db, table, p0)
                                .aiConversationsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.payloadId == item.id),
                        typedResults: items),
                  if (crmCustomersRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$HubPayloadsTableReferences
                            ._crmCustomersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HubPayloadsTableReferences(db, table, p0)
                                .crmCustomersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourcePayloadId == item.id),
                        typedResults: items),
                  if (ledgerEntriesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$HubPayloadsTableReferences
                            ._ledgerEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HubPayloadsTableReferences(db, table, p0)
                                .ledgerEntriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourcePayloadId == item.id),
                        typedResults: items),
                  if (todoSchedulesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$HubPayloadsTableReferences
                            ._todoSchedulesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HubPayloadsTableReferences(db, table, p0)
                                .todoSchedulesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourcePayloadId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
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
    (HubPayload, $$HubPayloadsTableReferences),
    HubPayload,
    PrefetchHooks Function(
        {bool ideaTasksRefs,
        bool contentBlocksRefs,
        bool aiConversationsRefs,
        bool crmCustomersRefs,
        bool ledgerEntriesRefs,
        bool todoSchedulesRefs})>;
typedef $$ChatSessionsTableCreateCompanionBuilder = ChatSessionsCompanion
    Function({
  Value<int> id,
  required String title,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ChatSessionsTableUpdateCompanionBuilder = ChatSessionsCompanion
    Function({
  Value<int> id,
  Value<String> title,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ChatSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $ChatSessionsTable, ChatSession> {
  $$ChatSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChatMessagesTable, List<ChatMessage>>
      _chatMessagesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.chatMessages,
              aliasName: $_aliasNameGenerator(
                  db.chatSessions.id, db.chatMessages.sessionId));

  $$ChatMessagesTableProcessedTableManager get chatMessagesRefs {
    final manager = $$ChatMessagesTableTableManager($_db, $_db.chatMessages)
        .filter((f) => f.sessionId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_chatMessagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChatSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> chatMessagesRefs(
      Expression<bool> Function($$ChatMessagesTableFilterComposer f) f) {
    final $$ChatMessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableFilterComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChatSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ChatSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> chatMessagesRefs<T extends Object>(
      Expression<T> Function($$ChatMessagesTableAnnotationComposer a) f) {
    final $$ChatMessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChatSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatSessionsTable,
    ChatSession,
    $$ChatSessionsTableFilterComposer,
    $$ChatSessionsTableOrderingComposer,
    $$ChatSessionsTableAnnotationComposer,
    $$ChatSessionsTableCreateCompanionBuilder,
    $$ChatSessionsTableUpdateCompanionBuilder,
    (ChatSession, $$ChatSessionsTableReferences),
    ChatSession,
    PrefetchHooks Function({bool chatMessagesRefs})> {
  $$ChatSessionsTableTableManager(_$AppDatabase db, $ChatSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ChatSessionsCompanion(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ChatSessionsCompanion.insert(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChatSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({chatMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chatMessagesRefs) db.chatMessages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatMessagesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ChatSessionsTableReferences
                            ._chatMessagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChatSessionsTableReferences(db, table, p0)
                                .chatMessagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChatSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatSessionsTable,
    ChatSession,
    $$ChatSessionsTableFilterComposer,
    $$ChatSessionsTableOrderingComposer,
    $$ChatSessionsTableAnnotationComposer,
    $$ChatSessionsTableCreateCompanionBuilder,
    $$ChatSessionsTableUpdateCompanionBuilder,
    (ChatSession, $$ChatSessionsTableReferences),
    ChatSession,
    PrefetchHooks Function({bool chatMessagesRefs})>;
typedef $$ChatMessagesTableCreateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<int> id,
  required int sessionId,
  required String role,
  required String content,
  Value<DateTime> createdAt,
});
typedef $$ChatMessagesTableUpdateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<int> id,
  Value<int> sessionId,
  Value<String> role,
  Value<String> content,
  Value<DateTime> createdAt,
});

final class $$ChatMessagesTableReferences
    extends BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage> {
  $$ChatMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.chatSessions.createAlias(
          $_aliasNameGenerator(db.chatMessages.sessionId, db.chatSessions.id));

  $$ChatSessionsTableProcessedTableManager? get sessionId {
    if ($_item.sessionId == null) return null;
    final manager = $$ChatSessionsTableTableManager($_db, $_db.chatSessions)
        .filter((f) => f.id($_item.sessionId!));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ChatSessionsTableFilterComposer get sessionId {
    final $$ChatSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableFilterComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ChatSessionsTableOrderingComposer get sessionId {
    final $$ChatSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChatSessionsTableAnnotationComposer get sessionId {
    final $$ChatSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (ChatMessage, $$ChatMessagesTableReferences),
    ChatMessage,
    PrefetchHooks Function({bool sessionId})> {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> sessionId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ChatMessagesCompanion(
            id: id,
            sessionId: sessionId,
            role: role,
            content: content,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int sessionId,
            required String role,
            required String content,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ChatMessagesCompanion.insert(
            id: id,
            sessionId: sessionId,
            role: role,
            content: content,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChatMessagesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$ChatMessagesTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$ChatMessagesTableReferences._sessionIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ChatMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (ChatMessage, $$ChatMessagesTableReferences),
    ChatMessage,
    PrefetchHooks Function({bool sessionId})>;
typedef $$LongTermMemoriesTableCreateCompanionBuilder
    = LongTermMemoriesCompanion Function({
  Value<int> id,
  required String content,
  Value<String?> tags,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$LongTermMemoriesTableUpdateCompanionBuilder
    = LongTermMemoriesCompanion Function({
  Value<int> id,
  Value<String> content,
  Value<String?> tags,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$LongTermMemoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LongTermMemoriesTable> {
  $$LongTermMemoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LongTermMemoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LongTermMemoriesTable> {
  $$LongTermMemoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LongTermMemoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LongTermMemoriesTable> {
  $$LongTermMemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LongTermMemoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LongTermMemoriesTable,
    LongTermMemory,
    $$LongTermMemoriesTableFilterComposer,
    $$LongTermMemoriesTableOrderingComposer,
    $$LongTermMemoriesTableAnnotationComposer,
    $$LongTermMemoriesTableCreateCompanionBuilder,
    $$LongTermMemoriesTableUpdateCompanionBuilder,
    (
      LongTermMemory,
      BaseReferences<_$AppDatabase, $LongTermMemoriesTable, LongTermMemory>
    ),
    LongTermMemory,
    PrefetchHooks Function()> {
  $$LongTermMemoriesTableTableManager(
      _$AppDatabase db, $LongTermMemoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LongTermMemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LongTermMemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LongTermMemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LongTermMemoriesCompanion(
            id: id,
            content: content,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String content,
            Value<String?> tags = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LongTermMemoriesCompanion.insert(
            id: id,
            content: content,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LongTermMemoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LongTermMemoriesTable,
    LongTermMemory,
    $$LongTermMemoriesTableFilterComposer,
    $$LongTermMemoriesTableOrderingComposer,
    $$LongTermMemoriesTableAnnotationComposer,
    $$LongTermMemoriesTableCreateCompanionBuilder,
    $$LongTermMemoriesTableUpdateCompanionBuilder,
    (
      LongTermMemory,
      BaseReferences<_$AppDatabase, $LongTermMemoriesTable, LongTermMemory>
    ),
    LongTermMemory,
    PrefetchHooks Function()>;
typedef $$KnowledgeFilesTableCreateCompanionBuilder = KnowledgeFilesCompanion
    Function({
  Value<int> id,
  required String name,
  required String localPath,
  required int size,
  required String extension,
  Value<bool> isActive,
  Value<DateTime> createdAt,
});
typedef $$KnowledgeFilesTableUpdateCompanionBuilder = KnowledgeFilesCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> localPath,
  Value<int> size,
  Value<String> extension,
  Value<bool> isActive,
  Value<DateTime> createdAt,
});

final class $$KnowledgeFilesTableReferences
    extends BaseReferences<_$AppDatabase, $KnowledgeFilesTable, KnowledgeFile> {
  $$KnowledgeFilesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VectorStorageTable, List<VectorStorageData>>
      _vectorStorageRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.vectorStorage,
              aliasName: $_aliasNameGenerator(
                  db.knowledgeFiles.id, db.vectorStorage.sourceFileId));

  $$VectorStorageTableProcessedTableManager get vectorStorageRefs {
    final manager = $$VectorStorageTableTableManager($_db, $_db.vectorStorage)
        .filter((f) => f.sourceFileId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_vectorStorageRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$KnowledgeFilesTableFilterComposer
    extends Composer<_$AppDatabase, $KnowledgeFilesTable> {
  $$KnowledgeFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get extension => $composableBuilder(
      column: $table.extension, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> vectorStorageRefs(
      Expression<bool> Function($$VectorStorageTableFilterComposer f) f) {
    final $$VectorStorageTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vectorStorage,
        getReferencedColumn: (t) => t.sourceFileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VectorStorageTableFilterComposer(
              $db: $db,
              $table: $db.vectorStorage,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$KnowledgeFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $KnowledgeFilesTable> {
  $$KnowledgeFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get extension => $composableBuilder(
      column: $table.extension, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$KnowledgeFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KnowledgeFilesTable> {
  $$KnowledgeFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get extension =>
      $composableBuilder(column: $table.extension, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> vectorStorageRefs<T extends Object>(
      Expression<T> Function($$VectorStorageTableAnnotationComposer a) f) {
    final $$VectorStorageTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vectorStorage,
        getReferencedColumn: (t) => t.sourceFileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VectorStorageTableAnnotationComposer(
              $db: $db,
              $table: $db.vectorStorage,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$KnowledgeFilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KnowledgeFilesTable,
    KnowledgeFile,
    $$KnowledgeFilesTableFilterComposer,
    $$KnowledgeFilesTableOrderingComposer,
    $$KnowledgeFilesTableAnnotationComposer,
    $$KnowledgeFilesTableCreateCompanionBuilder,
    $$KnowledgeFilesTableUpdateCompanionBuilder,
    (KnowledgeFile, $$KnowledgeFilesTableReferences),
    KnowledgeFile,
    PrefetchHooks Function({bool vectorStorageRefs})> {
  $$KnowledgeFilesTableTableManager(
      _$AppDatabase db, $KnowledgeFilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnowledgeFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnowledgeFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnowledgeFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<int> size = const Value.absent(),
            Value<String> extension = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              KnowledgeFilesCompanion(
            id: id,
            name: name,
            localPath: localPath,
            size: size,
            extension: extension,
            isActive: isActive,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String localPath,
            required int size,
            required String extension,
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              KnowledgeFilesCompanion.insert(
            id: id,
            name: name,
            localPath: localPath,
            size: size,
            extension: extension,
            isActive: isActive,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$KnowledgeFilesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({vectorStorageRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (vectorStorageRefs) db.vectorStorage
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (vectorStorageRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$KnowledgeFilesTableReferences
                            ._vectorStorageRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$KnowledgeFilesTableReferences(db, table, p0)
                                .vectorStorageRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourceFileId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$KnowledgeFilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KnowledgeFilesTable,
    KnowledgeFile,
    $$KnowledgeFilesTableFilterComposer,
    $$KnowledgeFilesTableOrderingComposer,
    $$KnowledgeFilesTableAnnotationComposer,
    $$KnowledgeFilesTableCreateCompanionBuilder,
    $$KnowledgeFilesTableUpdateCompanionBuilder,
    (KnowledgeFile, $$KnowledgeFilesTableReferences),
    KnowledgeFile,
    PrefetchHooks Function({bool vectorStorageRefs})>;
typedef $$VectorStorageTableCreateCompanionBuilder = VectorStorageCompanion
    Function({
  Value<int> id,
  required int sourceFileId,
  required String content,
});
typedef $$VectorStorageTableUpdateCompanionBuilder = VectorStorageCompanion
    Function({
  Value<int> id,
  Value<int> sourceFileId,
  Value<String> content,
});

final class $$VectorStorageTableReferences extends BaseReferences<_$AppDatabase,
    $VectorStorageTable, VectorStorageData> {
  $$VectorStorageTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $KnowledgeFilesTable _sourceFileIdTable(_$AppDatabase db) =>
      db.knowledgeFiles.createAlias($_aliasNameGenerator(
          db.vectorStorage.sourceFileId, db.knowledgeFiles.id));

  $$KnowledgeFilesTableProcessedTableManager? get sourceFileId {
    if ($_item.sourceFileId == null) return null;
    final manager = $$KnowledgeFilesTableTableManager($_db, $_db.knowledgeFiles)
        .filter((f) => f.id($_item.sourceFileId!));
    final item = $_typedResult.readTableOrNull(_sourceFileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$VectorStorageTableFilterComposer
    extends Composer<_$AppDatabase, $VectorStorageTable> {
  $$VectorStorageTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  $$KnowledgeFilesTableFilterComposer get sourceFileId {
    final $$KnowledgeFilesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceFileId,
        referencedTable: $db.knowledgeFiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KnowledgeFilesTableFilterComposer(
              $db: $db,
              $table: $db.knowledgeFiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VectorStorageTableOrderingComposer
    extends Composer<_$AppDatabase, $VectorStorageTable> {
  $$VectorStorageTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  $$KnowledgeFilesTableOrderingComposer get sourceFileId {
    final $$KnowledgeFilesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceFileId,
        referencedTable: $db.knowledgeFiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KnowledgeFilesTableOrderingComposer(
              $db: $db,
              $table: $db.knowledgeFiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VectorStorageTableAnnotationComposer
    extends Composer<_$AppDatabase, $VectorStorageTable> {
  $$VectorStorageTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  $$KnowledgeFilesTableAnnotationComposer get sourceFileId {
    final $$KnowledgeFilesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceFileId,
        referencedTable: $db.knowledgeFiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KnowledgeFilesTableAnnotationComposer(
              $db: $db,
              $table: $db.knowledgeFiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VectorStorageTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VectorStorageTable,
    VectorStorageData,
    $$VectorStorageTableFilterComposer,
    $$VectorStorageTableOrderingComposer,
    $$VectorStorageTableAnnotationComposer,
    $$VectorStorageTableCreateCompanionBuilder,
    $$VectorStorageTableUpdateCompanionBuilder,
    (VectorStorageData, $$VectorStorageTableReferences),
    VectorStorageData,
    PrefetchHooks Function({bool sourceFileId})> {
  $$VectorStorageTableTableManager(_$AppDatabase db, $VectorStorageTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VectorStorageTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VectorStorageTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VectorStorageTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> sourceFileId = const Value.absent(),
            Value<String> content = const Value.absent(),
          }) =>
              VectorStorageCompanion(
            id: id,
            sourceFileId: sourceFileId,
            content: content,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int sourceFileId,
            required String content,
          }) =>
              VectorStorageCompanion.insert(
            id: id,
            sourceFileId: sourceFileId,
            content: content,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$VectorStorageTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sourceFileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sourceFileId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourceFileId,
                    referencedTable:
                        $$VectorStorageTableReferences._sourceFileIdTable(db),
                    referencedColumn: $$VectorStorageTableReferences
                        ._sourceFileIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$VectorStorageTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VectorStorageTable,
    VectorStorageData,
    $$VectorStorageTableFilterComposer,
    $$VectorStorageTableOrderingComposer,
    $$VectorStorageTableAnnotationComposer,
    $$VectorStorageTableCreateCompanionBuilder,
    $$VectorStorageTableUpdateCompanionBuilder,
    (VectorStorageData, $$VectorStorageTableReferences),
    VectorStorageData,
    PrefetchHooks Function({bool sourceFileId})>;
typedef $$IdeaTasksTableCreateCompanionBuilder = IdeaTasksCompanion Function({
  Value<int> id,
  required int payloadId,
  required String content,
  Value<bool> isDone,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});
typedef $$IdeaTasksTableUpdateCompanionBuilder = IdeaTasksCompanion Function({
  Value<int> id,
  Value<int> payloadId,
  Value<String> content,
  Value<bool> isDone,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

final class $$IdeaTasksTableReferences
    extends BaseReferences<_$AppDatabase, $IdeaTasksTable, IdeaTask> {
  $$IdeaTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HubPayloadsTable _payloadIdTable(_$AppDatabase db) =>
      db.hubPayloads.createAlias(
          $_aliasNameGenerator(db.ideaTasks.payloadId, db.hubPayloads.id));

  $$HubPayloadsTableProcessedTableManager? get payloadId {
    if ($_item.payloadId == null) return null;
    final manager = $$HubPayloadsTableTableManager($_db, $_db.hubPayloads)
        .filter((f) => f.id($_item.payloadId!));
    final item = $_typedResult.readTableOrNull(_payloadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IdeaTasksTableFilterComposer
    extends Composer<_$AppDatabase, $IdeaTasksTable> {
  $$IdeaTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$HubPayloadsTableFilterComposer get payloadId {
    final $$HubPayloadsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableFilterComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IdeaTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $IdeaTasksTable> {
  $$IdeaTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$HubPayloadsTableOrderingComposer get payloadId {
    final $$HubPayloadsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableOrderingComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IdeaTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $IdeaTasksTable> {
  $$IdeaTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HubPayloadsTableAnnotationComposer get payloadId {
    final $$HubPayloadsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableAnnotationComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IdeaTasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IdeaTasksTable,
    IdeaTask,
    $$IdeaTasksTableFilterComposer,
    $$IdeaTasksTableOrderingComposer,
    $$IdeaTasksTableAnnotationComposer,
    $$IdeaTasksTableCreateCompanionBuilder,
    $$IdeaTasksTableUpdateCompanionBuilder,
    (IdeaTask, $$IdeaTasksTableReferences),
    IdeaTask,
    PrefetchHooks Function({bool payloadId})> {
  $$IdeaTasksTableTableManager(_$AppDatabase db, $IdeaTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdeaTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdeaTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdeaTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> payloadId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              IdeaTasksCompanion(
            id: id,
            payloadId: payloadId,
            content: content,
            isDone: isDone,
            sortOrder: sortOrder,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int payloadId,
            required String content,
            Value<bool> isDone = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              IdeaTasksCompanion.insert(
            id: id,
            payloadId: payloadId,
            content: content,
            isDone: isDone,
            sortOrder: sortOrder,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IdeaTasksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({payloadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (payloadId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.payloadId,
                    referencedTable:
                        $$IdeaTasksTableReferences._payloadIdTable(db),
                    referencedColumn:
                        $$IdeaTasksTableReferences._payloadIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IdeaTasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IdeaTasksTable,
    IdeaTask,
    $$IdeaTasksTableFilterComposer,
    $$IdeaTasksTableOrderingComposer,
    $$IdeaTasksTableAnnotationComposer,
    $$IdeaTasksTableCreateCompanionBuilder,
    $$IdeaTasksTableUpdateCompanionBuilder,
    (IdeaTask, $$IdeaTasksTableReferences),
    IdeaTask,
    PrefetchHooks Function({bool payloadId})>;
typedef $$ContentBlocksTableCreateCompanionBuilder = ContentBlocksCompanion
    Function({
  Value<int> id,
  required int payloadId,
  Value<String> blockType,
  required String content,
  Value<String> mediaPaths,
  Value<String> sourceType,
  Value<bool> aiPolished,
  Value<int> sortOrder,
  Value<String> tags,
  Value<DateTime> createdAt,
});
typedef $$ContentBlocksTableUpdateCompanionBuilder = ContentBlocksCompanion
    Function({
  Value<int> id,
  Value<int> payloadId,
  Value<String> blockType,
  Value<String> content,
  Value<String> mediaPaths,
  Value<String> sourceType,
  Value<bool> aiPolished,
  Value<int> sortOrder,
  Value<String> tags,
  Value<DateTime> createdAt,
});

final class $$ContentBlocksTableReferences
    extends BaseReferences<_$AppDatabase, $ContentBlocksTable, ContentBlock> {
  $$ContentBlocksTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $HubPayloadsTable _payloadIdTable(_$AppDatabase db) =>
      db.hubPayloads.createAlias(
          $_aliasNameGenerator(db.contentBlocks.payloadId, db.hubPayloads.id));

  $$HubPayloadsTableProcessedTableManager? get payloadId {
    if ($_item.payloadId == null) return null;
    final manager = $$HubPayloadsTableTableManager($_db, $_db.hubPayloads)
        .filter((f) => f.id($_item.payloadId!));
    final item = $_typedResult.readTableOrNull(_payloadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ContentBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $ContentBlocksTable> {
  $$ContentBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get blockType => $composableBuilder(
      column: $table.blockType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaPaths => $composableBuilder(
      column: $table.mediaPaths, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get aiPolished => $composableBuilder(
      column: $table.aiPolished, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$HubPayloadsTableFilterComposer get payloadId {
    final $$HubPayloadsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableFilterComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ContentBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentBlocksTable> {
  $$ContentBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blockType => $composableBuilder(
      column: $table.blockType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaPaths => $composableBuilder(
      column: $table.mediaPaths, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get aiPolished => $composableBuilder(
      column: $table.aiPolished, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$HubPayloadsTableOrderingComposer get payloadId {
    final $$HubPayloadsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableOrderingComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ContentBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentBlocksTable> {
  $$ContentBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get blockType =>
      $composableBuilder(column: $table.blockType, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get mediaPaths => $composableBuilder(
      column: $table.mediaPaths, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => column);

  GeneratedColumn<bool> get aiPolished => $composableBuilder(
      column: $table.aiPolished, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HubPayloadsTableAnnotationComposer get payloadId {
    final $$HubPayloadsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableAnnotationComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ContentBlocksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContentBlocksTable,
    ContentBlock,
    $$ContentBlocksTableFilterComposer,
    $$ContentBlocksTableOrderingComposer,
    $$ContentBlocksTableAnnotationComposer,
    $$ContentBlocksTableCreateCompanionBuilder,
    $$ContentBlocksTableUpdateCompanionBuilder,
    (ContentBlock, $$ContentBlocksTableReferences),
    ContentBlock,
    PrefetchHooks Function({bool payloadId})> {
  $$ContentBlocksTableTableManager(_$AppDatabase db, $ContentBlocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> payloadId = const Value.absent(),
            Value<String> blockType = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> mediaPaths = const Value.absent(),
            Value<String> sourceType = const Value.absent(),
            Value<bool> aiPolished = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ContentBlocksCompanion(
            id: id,
            payloadId: payloadId,
            blockType: blockType,
            content: content,
            mediaPaths: mediaPaths,
            sourceType: sourceType,
            aiPolished: aiPolished,
            sortOrder: sortOrder,
            tags: tags,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int payloadId,
            Value<String> blockType = const Value.absent(),
            required String content,
            Value<String> mediaPaths = const Value.absent(),
            Value<String> sourceType = const Value.absent(),
            Value<bool> aiPolished = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ContentBlocksCompanion.insert(
            id: id,
            payloadId: payloadId,
            blockType: blockType,
            content: content,
            mediaPaths: mediaPaths,
            sourceType: sourceType,
            aiPolished: aiPolished,
            sortOrder: sortOrder,
            tags: tags,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ContentBlocksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({payloadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (payloadId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.payloadId,
                    referencedTable:
                        $$ContentBlocksTableReferences._payloadIdTable(db),
                    referencedColumn:
                        $$ContentBlocksTableReferences._payloadIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ContentBlocksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ContentBlocksTable,
    ContentBlock,
    $$ContentBlocksTableFilterComposer,
    $$ContentBlocksTableOrderingComposer,
    $$ContentBlocksTableAnnotationComposer,
    $$ContentBlocksTableCreateCompanionBuilder,
    $$ContentBlocksTableUpdateCompanionBuilder,
    (ContentBlock, $$ContentBlocksTableReferences),
    ContentBlock,
    PrefetchHooks Function({bool payloadId})>;
typedef $$AiConversationsTableCreateCompanionBuilder = AiConversationsCompanion
    Function({
  Value<int> id,
  required int payloadId,
  required String role,
  required String content,
  Value<DateTime> createdAt,
});
typedef $$AiConversationsTableUpdateCompanionBuilder = AiConversationsCompanion
    Function({
  Value<int> id,
  Value<int> payloadId,
  Value<String> role,
  Value<String> content,
  Value<DateTime> createdAt,
});

final class $$AiConversationsTableReferences extends BaseReferences<
    _$AppDatabase, $AiConversationsTable, AiConversation> {
  $$AiConversationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $HubPayloadsTable _payloadIdTable(_$AppDatabase db) =>
      db.hubPayloads.createAlias($_aliasNameGenerator(
          db.aiConversations.payloadId, db.hubPayloads.id));

  $$HubPayloadsTableProcessedTableManager? get payloadId {
    if ($_item.payloadId == null) return null;
    final manager = $$HubPayloadsTableTableManager($_db, $_db.hubPayloads)
        .filter((f) => f.id($_item.payloadId!));
    final item = $_typedResult.readTableOrNull(_payloadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AiConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $AiConversationsTable> {
  $$AiConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$HubPayloadsTableFilterComposer get payloadId {
    final $$HubPayloadsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableFilterComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AiConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiConversationsTable> {
  $$AiConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$HubPayloadsTableOrderingComposer get payloadId {
    final $$HubPayloadsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableOrderingComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AiConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiConversationsTable> {
  $$AiConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HubPayloadsTableAnnotationComposer get payloadId {
    final $$HubPayloadsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableAnnotationComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AiConversationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiConversationsTable,
    AiConversation,
    $$AiConversationsTableFilterComposer,
    $$AiConversationsTableOrderingComposer,
    $$AiConversationsTableAnnotationComposer,
    $$AiConversationsTableCreateCompanionBuilder,
    $$AiConversationsTableUpdateCompanionBuilder,
    (AiConversation, $$AiConversationsTableReferences),
    AiConversation,
    PrefetchHooks Function({bool payloadId})> {
  $$AiConversationsTableTableManager(
      _$AppDatabase db, $AiConversationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> payloadId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AiConversationsCompanion(
            id: id,
            payloadId: payloadId,
            role: role,
            content: content,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int payloadId,
            required String role,
            required String content,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AiConversationsCompanion.insert(
            id: id,
            payloadId: payloadId,
            role: role,
            content: content,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AiConversationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({payloadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (payloadId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.payloadId,
                    referencedTable:
                        $$AiConversationsTableReferences._payloadIdTable(db),
                    referencedColumn:
                        $$AiConversationsTableReferences._payloadIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AiConversationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiConversationsTable,
    AiConversation,
    $$AiConversationsTableFilterComposer,
    $$AiConversationsTableOrderingComposer,
    $$AiConversationsTableAnnotationComposer,
    $$AiConversationsTableCreateCompanionBuilder,
    $$AiConversationsTableUpdateCompanionBuilder,
    (AiConversation, $$AiConversationsTableReferences),
    AiConversation,
    PrefetchHooks Function({bool payloadId})>;
typedef $$AiTemplatesTableCreateCompanionBuilder = AiTemplatesCompanion
    Function({
  Value<int> id,
  Value<String> icon,
  required String name,
  required String prompt,
  Value<bool> isEnabled,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});
typedef $$AiTemplatesTableUpdateCompanionBuilder = AiTemplatesCompanion
    Function({
  Value<int> id,
  Value<String> icon,
  Value<String> name,
  Value<String> prompt,
  Value<bool> isEnabled,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

class $$AiTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $AiTemplatesTable> {
  $$AiTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prompt => $composableBuilder(
      column: $table.prompt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AiTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $AiTemplatesTable> {
  $$AiTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prompt => $composableBuilder(
      column: $table.prompt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AiTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiTemplatesTable> {
  $$AiTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AiTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiTemplatesTable,
    AiTemplate,
    $$AiTemplatesTableFilterComposer,
    $$AiTemplatesTableOrderingComposer,
    $$AiTemplatesTableAnnotationComposer,
    $$AiTemplatesTableCreateCompanionBuilder,
    $$AiTemplatesTableUpdateCompanionBuilder,
    (AiTemplate, BaseReferences<_$AppDatabase, $AiTemplatesTable, AiTemplate>),
    AiTemplate,
    PrefetchHooks Function()> {
  $$AiTemplatesTableTableManager(_$AppDatabase db, $AiTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> prompt = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AiTemplatesCompanion(
            id: id,
            icon: icon,
            name: name,
            prompt: prompt,
            isEnabled: isEnabled,
            sortOrder: sortOrder,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> icon = const Value.absent(),
            required String name,
            required String prompt,
            Value<bool> isEnabled = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AiTemplatesCompanion.insert(
            id: id,
            icon: icon,
            name: name,
            prompt: prompt,
            isEnabled: isEnabled,
            sortOrder: sortOrder,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AiTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiTemplatesTable,
    AiTemplate,
    $$AiTemplatesTableFilterComposer,
    $$AiTemplatesTableOrderingComposer,
    $$AiTemplatesTableAnnotationComposer,
    $$AiTemplatesTableCreateCompanionBuilder,
    $$AiTemplatesTableUpdateCompanionBuilder,
    (AiTemplate, BaseReferences<_$AppDatabase, $AiTemplatesTable, AiTemplate>),
    AiTemplate,
    PrefetchHooks Function()>;
typedef $$CrmCustomersTableCreateCompanionBuilder = CrmCustomersCompanion
    Function({
  Value<int> id,
  required int sourcePayloadId,
  required String name,
  Value<String?> company,
  Value<String?> contact,
  Value<String> tags,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$CrmCustomersTableUpdateCompanionBuilder = CrmCustomersCompanion
    Function({
  Value<int> id,
  Value<int> sourcePayloadId,
  Value<String> name,
  Value<String?> company,
  Value<String?> contact,
  Value<String> tags,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$CrmCustomersTableReferences
    extends BaseReferences<_$AppDatabase, $CrmCustomersTable, CrmCustomer> {
  $$CrmCustomersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HubPayloadsTable _sourcePayloadIdTable(_$AppDatabase db) =>
      db.hubPayloads.createAlias($_aliasNameGenerator(
          db.crmCustomers.sourcePayloadId, db.hubPayloads.id));

  $$HubPayloadsTableProcessedTableManager? get sourcePayloadId {
    if ($_item.sourcePayloadId == null) return null;
    final manager = $$HubPayloadsTableTableManager($_db, $_db.hubPayloads)
        .filter((f) => f.id($_item.sourcePayloadId!));
    final item = $_typedResult.readTableOrNull(_sourcePayloadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CrmCustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CrmCustomersTable> {
  $$CrmCustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contact => $composableBuilder(
      column: $table.contact, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$HubPayloadsTableFilterComposer get sourcePayloadId {
    final $$HubPayloadsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePayloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableFilterComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CrmCustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CrmCustomersTable> {
  $$CrmCustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contact => $composableBuilder(
      column: $table.contact, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$HubPayloadsTableOrderingComposer get sourcePayloadId {
    final $$HubPayloadsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePayloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableOrderingComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CrmCustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CrmCustomersTable> {
  $$CrmCustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get contact =>
      $composableBuilder(column: $table.contact, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$HubPayloadsTableAnnotationComposer get sourcePayloadId {
    final $$HubPayloadsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePayloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableAnnotationComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CrmCustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CrmCustomersTable,
    CrmCustomer,
    $$CrmCustomersTableFilterComposer,
    $$CrmCustomersTableOrderingComposer,
    $$CrmCustomersTableAnnotationComposer,
    $$CrmCustomersTableCreateCompanionBuilder,
    $$CrmCustomersTableUpdateCompanionBuilder,
    (CrmCustomer, $$CrmCustomersTableReferences),
    CrmCustomer,
    PrefetchHooks Function({bool sourcePayloadId})> {
  $$CrmCustomersTableTableManager(_$AppDatabase db, $CrmCustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CrmCustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CrmCustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CrmCustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> sourcePayloadId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> company = const Value.absent(),
            Value<String?> contact = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CrmCustomersCompanion(
            id: id,
            sourcePayloadId: sourcePayloadId,
            name: name,
            company: company,
            contact: contact,
            tags: tags,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int sourcePayloadId,
            required String name,
            Value<String?> company = const Value.absent(),
            Value<String?> contact = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CrmCustomersCompanion.insert(
            id: id,
            sourcePayloadId: sourcePayloadId,
            name: name,
            company: company,
            contact: contact,
            tags: tags,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CrmCustomersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sourcePayloadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sourcePayloadId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourcePayloadId,
                    referencedTable:
                        $$CrmCustomersTableReferences._sourcePayloadIdTable(db),
                    referencedColumn: $$CrmCustomersTableReferences
                        ._sourcePayloadIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CrmCustomersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CrmCustomersTable,
    CrmCustomer,
    $$CrmCustomersTableFilterComposer,
    $$CrmCustomersTableOrderingComposer,
    $$CrmCustomersTableAnnotationComposer,
    $$CrmCustomersTableCreateCompanionBuilder,
    $$CrmCustomersTableUpdateCompanionBuilder,
    (CrmCustomer, $$CrmCustomersTableReferences),
    CrmCustomer,
    PrefetchHooks Function({bool sourcePayloadId})>;
typedef $$LedgerEntriesTableCreateCompanionBuilder = LedgerEntriesCompanion
    Function({
  Value<int> id,
  required int sourcePayloadId,
  required double amount,
  required String category,
  Value<String> type,
  Value<String?> description,
  Value<DateTime?> occurredAt,
  Value<DateTime> createdAt,
});
typedef $$LedgerEntriesTableUpdateCompanionBuilder = LedgerEntriesCompanion
    Function({
  Value<int> id,
  Value<int> sourcePayloadId,
  Value<double> amount,
  Value<String> category,
  Value<String> type,
  Value<String?> description,
  Value<DateTime?> occurredAt,
  Value<DateTime> createdAt,
});

final class $$LedgerEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry> {
  $$LedgerEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $HubPayloadsTable _sourcePayloadIdTable(_$AppDatabase db) =>
      db.hubPayloads.createAlias($_aliasNameGenerator(
          db.ledgerEntries.sourcePayloadId, db.hubPayloads.id));

  $$HubPayloadsTableProcessedTableManager? get sourcePayloadId {
    if ($_item.sourcePayloadId == null) return null;
    final manager = $$HubPayloadsTableTableManager($_db, $_db.hubPayloads)
        .filter((f) => f.id($_item.sourcePayloadId!));
    final item = $_typedResult.readTableOrNull(_sourcePayloadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$HubPayloadsTableFilterComposer get sourcePayloadId {
    final $$HubPayloadsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePayloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableFilterComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$HubPayloadsTableOrderingComposer get sourcePayloadId {
    final $$HubPayloadsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePayloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableOrderingComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HubPayloadsTableAnnotationComposer get sourcePayloadId {
    final $$HubPayloadsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePayloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableAnnotationComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LedgerEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LedgerEntriesTable,
    LedgerEntry,
    $$LedgerEntriesTableFilterComposer,
    $$LedgerEntriesTableOrderingComposer,
    $$LedgerEntriesTableAnnotationComposer,
    $$LedgerEntriesTableCreateCompanionBuilder,
    $$LedgerEntriesTableUpdateCompanionBuilder,
    (LedgerEntry, $$LedgerEntriesTableReferences),
    LedgerEntry,
    PrefetchHooks Function({bool sourcePayloadId})> {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> sourcePayloadId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime?> occurredAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LedgerEntriesCompanion(
            id: id,
            sourcePayloadId: sourcePayloadId,
            amount: amount,
            category: category,
            type: type,
            description: description,
            occurredAt: occurredAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int sourcePayloadId,
            required double amount,
            required String category,
            Value<String> type = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime?> occurredAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LedgerEntriesCompanion.insert(
            id: id,
            sourcePayloadId: sourcePayloadId,
            amount: amount,
            category: category,
            type: type,
            description: description,
            occurredAt: occurredAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LedgerEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sourcePayloadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sourcePayloadId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourcePayloadId,
                    referencedTable: $$LedgerEntriesTableReferences
                        ._sourcePayloadIdTable(db),
                    referencedColumn: $$LedgerEntriesTableReferences
                        ._sourcePayloadIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LedgerEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LedgerEntriesTable,
    LedgerEntry,
    $$LedgerEntriesTableFilterComposer,
    $$LedgerEntriesTableOrderingComposer,
    $$LedgerEntriesTableAnnotationComposer,
    $$LedgerEntriesTableCreateCompanionBuilder,
    $$LedgerEntriesTableUpdateCompanionBuilder,
    (LedgerEntry, $$LedgerEntriesTableReferences),
    LedgerEntry,
    PrefetchHooks Function({bool sourcePayloadId})>;
typedef $$TodoSchedulesTableCreateCompanionBuilder = TodoSchedulesCompanion
    Function({
  Value<int> id,
  required int sourcePayloadId,
  required String title,
  Value<DateTime?> dueDate,
  Value<int> priority,
  Value<bool> isDone,
  Value<String?> notes,
  Value<DateTime> createdAt,
});
typedef $$TodoSchedulesTableUpdateCompanionBuilder = TodoSchedulesCompanion
    Function({
  Value<int> id,
  Value<int> sourcePayloadId,
  Value<String> title,
  Value<DateTime?> dueDate,
  Value<int> priority,
  Value<bool> isDone,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

final class $$TodoSchedulesTableReferences
    extends BaseReferences<_$AppDatabase, $TodoSchedulesTable, TodoSchedule> {
  $$TodoSchedulesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $HubPayloadsTable _sourcePayloadIdTable(_$AppDatabase db) =>
      db.hubPayloads.createAlias($_aliasNameGenerator(
          db.todoSchedules.sourcePayloadId, db.hubPayloads.id));

  $$HubPayloadsTableProcessedTableManager? get sourcePayloadId {
    if ($_item.sourcePayloadId == null) return null;
    final manager = $$HubPayloadsTableTableManager($_db, $_db.hubPayloads)
        .filter((f) => f.id($_item.sourcePayloadId!));
    final item = $_typedResult.readTableOrNull(_sourcePayloadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TodoSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $TodoSchedulesTable> {
  $$TodoSchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$HubPayloadsTableFilterComposer get sourcePayloadId {
    final $$HubPayloadsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePayloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableFilterComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TodoSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $TodoSchedulesTable> {
  $$TodoSchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$HubPayloadsTableOrderingComposer get sourcePayloadId {
    final $$HubPayloadsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePayloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableOrderingComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TodoSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodoSchedulesTable> {
  $$TodoSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HubPayloadsTableAnnotationComposer get sourcePayloadId {
    final $$HubPayloadsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourcePayloadId,
        referencedTable: $db.hubPayloads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HubPayloadsTableAnnotationComposer(
              $db: $db,
              $table: $db.hubPayloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TodoSchedulesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TodoSchedulesTable,
    TodoSchedule,
    $$TodoSchedulesTableFilterComposer,
    $$TodoSchedulesTableOrderingComposer,
    $$TodoSchedulesTableAnnotationComposer,
    $$TodoSchedulesTableCreateCompanionBuilder,
    $$TodoSchedulesTableUpdateCompanionBuilder,
    (TodoSchedule, $$TodoSchedulesTableReferences),
    TodoSchedule,
    PrefetchHooks Function({bool sourcePayloadId})> {
  $$TodoSchedulesTableTableManager(_$AppDatabase db, $TodoSchedulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoSchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoSchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> sourcePayloadId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TodoSchedulesCompanion(
            id: id,
            sourcePayloadId: sourcePayloadId,
            title: title,
            dueDate: dueDate,
            priority: priority,
            isDone: isDone,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int sourcePayloadId,
            required String title,
            Value<DateTime?> dueDate = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TodoSchedulesCompanion.insert(
            id: id,
            sourcePayloadId: sourcePayloadId,
            title: title,
            dueDate: dueDate,
            priority: priority,
            isDone: isDone,
            notes: notes,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TodoSchedulesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sourcePayloadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sourcePayloadId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourcePayloadId,
                    referencedTable: $$TodoSchedulesTableReferences
                        ._sourcePayloadIdTable(db),
                    referencedColumn: $$TodoSchedulesTableReferences
                        ._sourcePayloadIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TodoSchedulesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TodoSchedulesTable,
    TodoSchedule,
    $$TodoSchedulesTableFilterComposer,
    $$TodoSchedulesTableOrderingComposer,
    $$TodoSchedulesTableAnnotationComposer,
    $$TodoSchedulesTableCreateCompanionBuilder,
    $$TodoSchedulesTableUpdateCompanionBuilder,
    (TodoSchedule, $$TodoSchedulesTableReferences),
    TodoSchedule,
    PrefetchHooks Function({bool sourcePayloadId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HubPayloadsTableTableManager get hubPayloads =>
      $$HubPayloadsTableTableManager(_db, _db.hubPayloads);
  $$ChatSessionsTableTableManager get chatSessions =>
      $$ChatSessionsTableTableManager(_db, _db.chatSessions);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$LongTermMemoriesTableTableManager get longTermMemories =>
      $$LongTermMemoriesTableTableManager(_db, _db.longTermMemories);
  $$KnowledgeFilesTableTableManager get knowledgeFiles =>
      $$KnowledgeFilesTableTableManager(_db, _db.knowledgeFiles);
  $$VectorStorageTableTableManager get vectorStorage =>
      $$VectorStorageTableTableManager(_db, _db.vectorStorage);
  $$IdeaTasksTableTableManager get ideaTasks =>
      $$IdeaTasksTableTableManager(_db, _db.ideaTasks);
  $$ContentBlocksTableTableManager get contentBlocks =>
      $$ContentBlocksTableTableManager(_db, _db.contentBlocks);
  $$AiConversationsTableTableManager get aiConversations =>
      $$AiConversationsTableTableManager(_db, _db.aiConversations);
  $$AiTemplatesTableTableManager get aiTemplates =>
      $$AiTemplatesTableTableManager(_db, _db.aiTemplates);
  $$CrmCustomersTableTableManager get crmCustomers =>
      $$CrmCustomersTableTableManager(_db, _db.crmCustomers);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$TodoSchedulesTableTableManager get todoSchedules =>
      $$TodoSchedulesTableTableManager(_db, _db.todoSchedules);
}
