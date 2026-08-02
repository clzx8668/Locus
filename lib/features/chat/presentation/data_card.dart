import 'package:flutter/material.dart';

/// A compact card widget that renders structured data (from Text-to-SQL results)
/// inline within a chat message.
///
/// Displays up to [maxPreviewRows] rows in a mini table, with a "show more"
/// affordance if the data exceeds the preview limit.
class DataCard extends StatefulWidget {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final int maxPreviewRows;

  const DataCard({
    super.key,
    required this.columns,
    required this.rows,
    this.maxPreviewRows = 3,
  });

  /// Create a DataCard from a [SqlQueryResult]-compatible map.
  factory DataCard.fromResult({
    required List<String> columns,
    required List<Map<String, dynamic>> rows,
  }) {
    return DataCard(columns: columns, rows: rows);
  }

  @override
  State<DataCard> createState() => _DataCardState();
}

class _DataCardState extends State<DataCard> {
  bool _expanded = false;

  List<Map<String, dynamic>> get _visibleRows =>
      _expanded ? widget.rows : widget.rows.take(widget.maxPreviewRows).toList();

  bool get _hasMore => widget.rows.length > widget.maxPreviewRows;

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(context),
        child: Text(
          'No results',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: cs.primary.withValues(alpha: isDark ? 0.2 : 0.08),
            child: Row(
              children: [
                Icon(Icons.table_chart_outlined, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Data (${widget.rows.length} records)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),

          // Mini table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 32,
              dataRowMinHeight: 28,
              dataRowMaxHeight: 36,
              horizontalMargin: 8,
              columnSpacing: 16,
              headingTextStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
              dataTextStyle: TextStyle(
                fontSize: 12,
                color: cs.onSurface,
              ),
              columns: widget.columns
                  .map((col) => DataColumn(label: Text(_truncate(col, 12))))
                  .toList(),
              rows: _visibleRows.map((row) {
                return DataRow(
                  cells: widget.columns.map((col) {
                    final val = row[col];
                    final display = val?.toString() ?? '';
                    return DataCell(Text(_truncate(display, 20)));
                  }).toList(),
                );
              }).toList(),
            ),
          ),

          // Expand/collapse toggle
          if (_hasMore)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded
                          ? 'Collapse'
                          : 'Show all (${widget.rows.length - widget.maxPreviewRows} more)',
                      style: TextStyle(fontSize: 11, color: cs.primary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[300]!,
      ),
    );
  }

  String _truncate(String s, int maxLen) =>
      s.length > maxLen ? '${s.substring(0, maxLen)}…' : s;
}
