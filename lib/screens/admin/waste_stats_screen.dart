import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/error_handler.dart';
import '../../models/waste_statistic.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class WasteStatsScreen extends ConsumerWidget {
  const WasteStatsScreen({super.key});

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateShort(DateTime d) {
    return '${d.day} ${_months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(wasteStatisticsProvider(7));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Waste Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Statistics',
            onPressed: () => ref.invalidate(wasteStatisticsProvider(7)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(wasteStatisticsProvider(7));
        },
        child: statsAsync.when(
          data: (stats) {
            if (stats.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 60.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No waste records available yet.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Statistics will appear after the canteen records completed meals.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // 1. Calculate Aggregate Metrics
            final now = DateTime.now();
            final todayStat = stats.where((s) => _isSameDay(s.mealDate, now)).firstOrNull;

            double totalPrepared = 0.0;
            double totalServed = 0.0;
            double totalWasted = 0.0;
            int totalMealsLogged = 0;

            for (var s in stats) {
              totalPrepared += s.preparedPortions;
              totalServed += s.servedPortions;
              totalWasted += s.wastedPortions;
              totalMealsLogged += s.mealsLogged;
            }

            final weightedWastePercent = totalPrepared > 0
                ? (totalWasted / totalPrepared) * 100
                : 0.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subheader
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Last 7 Days',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$totalMealsLogged meals logged',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Top Summary Cards Grid
                  Row(
                    children: [
                      // Today's Waste
                      Expanded(
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.today_rounded,
                                      size: 16,
                                      color: Color(0xFF15803D),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Today's Waste",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  todayStat != null
                                      ? '${todayStat.wastedPortions.toInt()} portions'
                                      : 'No data',
                                  style: TextStyle(
                                    fontSize: todayStat != null ? 18 : 15,
                                    fontWeight: FontWeight.bold,
                                    color: todayStat != null
                                        ? const Color(0xFF0F172A)
                                        : Colors.grey.shade500,
                                  ),
                                ),
                                if (todayStat != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${todayStat.wastePercentage.toStringAsFixed(1)}% waste',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 7-Day Total Waste
                      Expanded(
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.date_range_rounded,
                                      size: 16,
                                      color: Color(0xFF2563EB),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '7-Day Total',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${totalWasted.toInt()} portions',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${weightedWastePercent.toStringAsFixed(1)}% overall',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 7-Day Bar Chart Card
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Waste by Day (Wasted Portions)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Only days with recorded meals are included.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: _buildBarChart(stats),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 7-Day Summary Operational Breakdown Card
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '7-Day Meal Totals',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Prepared',
                            '${totalPrepared.toInt()} portions',
                            const Color(0xFF2563EB),
                          ),
                          const Divider(height: 16),
                          _buildSummaryRow(
                            'Served',
                            '${totalServed.toInt()} portions',
                            const Color(0xFF15803D),
                          ),
                          const Divider(height: 16),
                          _buildSummaryRow(
                            'Wasted',
                            '${totalWasted.toInt()} portions',
                            const Color(0xFFDC2626),
                          ),
                          const Divider(height: 16),
                          _buildSummaryRow(
                            'Average Waste %',
                            '${weightedWastePercent.toStringAsFixed(1)}%',
                            const Color(0xFF0F172A),
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
          loading: () => const LoadingView(
            message: 'Loading 7-day waste statistics...',
          ),
          error: (err, _) => ErrorView(
            message: ErrorHandler.getFriendlyErrorMessage(err),
            onRetry: () => ref.invalidate(wasteStatisticsProvider(7)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: const Color(0xFF334155),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<WasteStatistic> stats) {
    // Determine maximum waste portion for Y-axis scaling
    double maxWaste = 10.0;
    for (var s in stats) {
      if (s.wastedPortions > maxWaste) {
        maxWaste = s.wastedPortions;
      }
    }
    final maxY = (maxWaste * 1.2).ceilToDouble();

    // Map each stat to a BarChartGroupData
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < stats.length; i++) {
      final stat = stats[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: stat.wastedPortions,
              color: stat.wastedPortions > 0
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF22C55E),
              width: 18,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= stats.length) return null;
              final stat = stats[groupIndex];
              return BarTooltipItem(
                '${_formatDateShort(stat.mealDate)}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: 'Wasted: ${stat.wastedPortions.toInt()} portions\n',
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  TextSpan(
                    text: '(${stat.wastePercentage.toStringAsFixed(1)}% waste)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= stats.length) {
                  return const SizedBox.shrink();
                }
                final stat = stats[index];
                final dayOfWeek = _weekdays[stat.mealDate.weekday - 1];
                final dateText = '${stat.mealDate.day}';

                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    '$dayOfWeek\n$dateText',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value % (maxY > 20 ? 10 : 5) != 0 && value != 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 20 ? 10 : 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: groups,
      ),
    );
  }
}
