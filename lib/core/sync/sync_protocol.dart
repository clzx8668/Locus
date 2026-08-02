enum SyncOp { insert, update, delete }

class SyncChange {
  final String table;
  final String syncUuid;
  final SyncOp op;
  final Map<String, dynamic> data;
  final DateTime updatedAt;

  SyncChange({
    required this.table,
    required this.syncUuid,
    required this.op,
    required this.data,
    required this.updatedAt,
  });

  factory SyncChange.fromJson(Map<String, dynamic> json) {
    return SyncChange(
      table: json['table'] as String,
      syncUuid: json['sync_uuid'] as String,
      op: SyncOp.values.firstWhere((e) => e.name == json['op']),
      data: Map<String, dynamic>.from(json['data'] as Map),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'table': table,
        'sync_uuid': syncUuid,
        'op': op.name,
        'data': data,
        'updated_at': updatedAt.toIso8601String(),
      };
}
