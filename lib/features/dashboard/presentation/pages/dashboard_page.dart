
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/dashboard_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardRepository _repo;

  final _brandColor = const Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();
    _repo = getIt<DashboardRepository>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('数据看板'),
        centerTitle: false,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width > 960) {
            return _buildThreeColumnLayout(isDark);
          } else if (width > 600) {
            return _buildTwoColumnLayout(isDark);
          } else {
            return _buildSingleColumnLayout(isDark);
          }
        },
      ),
    );
  }

  // ============================================================
  //  Responsive Layouts
  // ============================================================

  Widget _buildThreeColumnLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildColumn1(isDark),
        ),
        Expanded(
          child: _buildColumn2(isDark),
        ),
        Expanded(
          child: _buildColumn3(isDark),
        ),
      ],
    );
  }

  Widget _buildTwoColumnLayout(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildColumn1(isDark)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _buildColumn2(isDark),
                const SizedBox(height: 16),
                _buildColumn3(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleColumnLayout(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildColumn1(isDark),
          const SizedBox(height: 16),
          _buildColumn2(isDark),
          const SizedBox(height: 16),
          _buildColumn3(isDark),
        ],
      ),
    );
  }

  // ============================================================
  //  Column 1: Financial Summary + Expense Pie Chart
  // ============================================================

  Widget _buildColumn1(bool isDark) {
    return Column(
      children: [
        _buildFinancialSummary(isDark),
        const SizedBox(height: 16),
        _buildExpensePieChart(isDark),
      ],
    );
  }

  // ============================================================
  //  Column 2: Todo Progress + Note Activity + Tag Cloud
  // ============================================================

  Widget _buildColumn2(bool isDark) {
    return Column(
      children: [
        _buildTodoProgress(isDark),
        const SizedBox(height: 16),
        _buildNoteActivity(isDark),
        const SizedBox(height: 16),
        _buildTagCloud(isDark),
      ],
    );
  }

  // ============================================================
  //  Column 3: CRM Snapshot
  // ============================================================

  Widget _buildColumn3(bool isDark) {
    return _buildCrmSnapshot(isDark);
  }

  // ============================================================
  //  1. Financial Summary – Stacked BarChart
  // ============================================================

  Widget _buildFinancialSummary(bool isDark) {
    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.account_balance_wallet, '本月财务概览'),
            const SizedBox(height: 16),
            FutureBuilder<_FinancialData>(
              future: _loadFinancialData(now.year, now.month),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _errorWidget();
                }
                final data = snapshot.data!;
                if (data.income == 0 && data.expense == 0) {
                  return _emptyWidget('本月暂无收支记录');
                }
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryChip('收入', data.income, Colors.green),
                        _summaryChip('支出', data.expense, _brandColor),
                        _summaryChip(
                          '结余',
                          data.income - data.expense,
                          (data.income - data.expense) >= 0
                              ? Colors.blue
                              : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: max(data.income, data.expense) * 1.2,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval:
                                max(data.income, data.expense) / 4,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: data.income,
                                  color: Colors.green,
                                  width: 28,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: data.expense,
                                  color: _brandColor,
                                  width: 28,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendDot(Colors.green, '收入'),
                        const SizedBox(width: 24),
                        _legendDot(_brandColor, '支出'),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<_FinancialData> _loadFinancialData(int year, int month) async {
    final income = await _repo.getTotalIncome(year, month);
    final expense = await _repo.getTotalExpense(year, month);
    return _FinancialData(income: income, expense: expense);
  }

  // ============================================================
  //  2. Expense Pie Chart – by category
  // ============================================================

  Widget _buildExpensePieChart(bool isDark) {
    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.pie_chart, '本月支出分类'),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, double>>(
              future: _repo.getMonthlyExpense(now.year, now.month),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _errorWidget();
                }
                final data = snapshot.data!;
                if (data.isEmpty) {
                  return _emptyWidget('本月暂无支出');
                }

                final colors = _generateColors(data.length);
                final total =
                    data.values.fold(0.0, (sum, v) => sum + v);

                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieSections(data, colors),
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: data.entries.toList().asMap().entries.map((e) {
                        final i = e.key;
                        final entry = e.value;
                        final pct =
                            (entry.value / total * 100).toStringAsFixed(0);
                        return _legendDot(
                            colors[i % colors.length],
                            '${entry.key} ($pct%)');
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      Map<String, double> data, List<Color> colors) {
    final total = data.values.fold(0.0, (sum, v) => sum + v);
    return data.entries.toList().asMap().entries.map((e) {
      final i = e.key;
      final entry = e.value;
      final pct = (entry.value / total * 100).toStringAsFixed(0);
      return PieChartSectionData(
        value: entry.value,
        color: colors[i % colors.length],
        title: '$pct%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // ============================================================
  //  3. Todo Completion Progress Ring
  // ============================================================

  Widget _buildTodoProgress(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.check_circle_outline, '待办完成率'),
            const SizedBox(height: 16),
            FutureBuilder<_TodoStats>(
              future: _loadTodoStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _errorWidget();
                }
                final stats = snapshot.data!;
                if (stats.total == 0) {
                  return _emptyWidget('暂无待办事项');
                }
                return Column(
                  children: [
                    SizedBox(
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: stats.rate,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              backgroundColor: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _progressColor(stats.rate),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(stats.rate * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _progressColor(stats.rate),
                                ),
                              ),
                              Text(
                                '完成率',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem('已完成', stats.completed, Colors.green),
                        _statItem('进行中', stats.pending, Colors.orange),
                        _statItem('总计', stats.total, Colors.blue),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<_TodoStats> _loadTodoStats() async {
    final completed = await _repo.getCompletedTodoCount();
    final pending = await _repo.getPendingTodoCount();
    final total = completed + pending;
    final rate = total == 0 ? 0.0 : completed / total;
    return _TodoStats(
      completed: completed,
      pending: pending,
      total: total,
      rate: rate,
    );
  }

  Color _progressColor(double rate) {
    if (rate >= 0.7) return Colors.green;
    if (rate >= 0.4) return Colors.orange;
    return _brandColor;
  }

  // ============================================================
  //  4. Note Activity
  // ============================================================

  Widget _buildNoteActivity(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.note_alt_outlined, '笔记动态'),
            const SizedBox(height: 16),
            FutureBuilder<_NoteStats>(
              future: _loadNoteStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _errorWidget();
                }
                final stats = snapshot.data!;
                if (stats.thisWeek == 0 && stats.today == 0) {
                  return _emptyWidget('本周暂无新笔记');
                }
                return Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        icon: Icons.calendar_view_week,
                        label: '本周笔记',
                        value: stats.thisWeek.toString(),
                        color: Colors.indigo,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        icon: Icons.today,
                        label: '今日笔记',
                        value: stats.today.toString(),
                        color: Colors.teal,
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<_NoteStats> _loadNoteStats() async {
    final thisWeek = await _repo.getPayloadsThisWeek();
    final today = await _repo.getPayloadsToday();
    return _NoteStats(thisWeek: thisWeek, today: today);
  }

  // ============================================================
  //  5. Tag Cloud – Top Tags as Colored Chips
  // ============================================================

  Widget _buildTagCloud(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.tag, '热门标签'),
            const SizedBox(height: 16),
            FutureBuilder<List<({String name, int count, String color})>>(
              future: _repo.getTopTagsWithCount(limit: 12),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _errorWidget();
                }
                final tags = snapshot.data!;
                if (tags.isEmpty) {
                  return _emptyWidget('暂无标签数据');
                }

                final maxCount =
                    tags.map((t) => t.count).reduce(max);

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    final scale = (tag.count / maxCount * 0.7) + 0.3;
                    final fontSize = 12.0 * scale;
                    Color chipColor;
                    try {
                      chipColor = Color(
                        int.parse(tag.color.replaceFirst('#', '0xFF')),
                      );
                    } catch (_) {
                      chipColor = _brandColor;
                    }
                    return Chip(
                      label: Text(
                        '${tag.name} (${tag.count})',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: _chipTextColor(chipColor),
                        ),
                      ),
                      backgroundColor: chipColor.withValues(alpha: 0.2),
                      side: BorderSide(color: chipColor.withValues(alpha: 0.4)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _chipTextColor(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black87 : bg;
  }

  // ============================================================
  //  6. CRM Snapshot
  // ============================================================

  Widget _buildCrmSnapshot(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.people_outline, '客户概览'),
            const SizedBox(height: 16),
            FutureBuilder<_CrmStats>(
              future: _loadCrmStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _errorWidget();
                }
                final stats = snapshot.data!;
                if (stats.total == 0) {
                  return _emptyWidget('暂无客户记录');
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.person_add_alt,
                            label: '本周新增',
                            value: stats.newThisWeek.toString(),
                            color: Colors.purple,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            icon: Icons.group,
                            label: '客户总数',
                            value: stats.total.toString(),
                            color: Colors.indigo,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    if (stats.total > 0) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: stats.total > 0
                              ? stats.newThisWeek / stats.total
                              : 0,
                          minHeight: 8,
                          backgroundColor:
                              isDark ? Colors.white12 : Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.purple),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '本周新增占比 ${stats.total > 0 ? (stats.newThisWeek / stats.total * 100).toStringAsFixed(0) : 0}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<_CrmStats> _loadCrmStats() async {
    final newThisWeek = await _repo.getNewCustomersThisWeek();
    final total = await _repo.getTotalCustomers();
    return _CrmStats(newThisWeek: newThisWeek, total: total);
  }

  // ============================================================
  //  Shared Widgets
  // ============================================================

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _brandColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _emptyWidget(String message) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return const SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            SizedBox(height: 8),
            Text(
              '数据加载失败',
              style: TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate a list of visually distinct colors for the pie chart
  List<Color> _generateColors(int count) {
    const baseColors = [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFFE66D),
      Color(0xFF1A535C),
      Color(0xFFA78BFA),
      Color(0xFFF97316),
      Color(0xFF06B6D4),
      Color(0xFFEC4899),
      Color(0xFF10B981),
      Color(0xFF6366F1),
      Color(0xFFF43F5E),
      Color(0xFF14B8A6),
    ];
    if (count <= baseColors.length) return baseColors.sublist(0, count);
    return List.generate(
        count, (i) => baseColors[i % baseColors.length]);
  }
}

// ============================================================
//  Private data classes
// ============================================================

class _FinancialData {
  final double income;
  final double expense;
  const _FinancialData({required this.income, required this.expense});
}

class _TodoStats {
  final int completed;
  final int pending;
  final int total;
  final double rate;
  const _TodoStats({
    required this.completed,
    required this.pending,
    required this.total,
    required this.rate,
  });
}

class _NoteStats {
  final int thisWeek;
  final int today;
  const _NoteStats({required this.thisWeek, required this.today});
}

class _CrmStats {
  final int newThisWeek;
  final int total;
  const _CrmStats({required this.newThisWeek, required this.total});
}
