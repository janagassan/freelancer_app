// ===== frontend/lib/widgets/financial_charts.dart =====
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FinancialCharts extends StatelessWidget {
  final List<Map<String, dynamic>> periodStats;
  final Map<String, double>? categoryDistribution;
  final double totalEarnings;
  final String chartType;

  const FinancialCharts({
    super.key,
    required this.periodStats,
    this.categoryDistribution,
    required this.totalEarnings,
    this.chartType = 'bar',
  });

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing "$value" to double: $e');
        return 0.0;
      }
    }
    if (value is num) return value.toDouble();
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    switch (chartType) {
      case 'line':
        return _buildLineChart();
      case 'pie':
        return _buildPieChart();
      default:
        return _buildBarChart();
    }
  }

  Widget _buildBarChart() {
    if (periodStats.isEmpty) {
      return _buildEmptyChart('No earnings data available');
    }

    final validStats = periodStats.where((s) {
      final total = _parseToDouble(s['total']);
      return total > 0;
    }).toList();

    if (validStats.isEmpty) {
      return _buildEmptyChart('No earnings data available');
    }

    final maxY = validStats
        .map((s) => _parseToDouble(s['total']))
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final value = rod.toY;
                return BarTooltipItem(
                  '\$${value.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < validStats.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _getLabel(validStats[index]),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
                reservedSize: 45,
                interval: (maxY / 5).ceilToDouble(),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              left: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY / 5).ceilToDouble(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          barGroups: List.generate(validStats.length, (index) {
            final total = _parseToDouble(validStats[index]['total']);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: total,
                  color: const Color(0xff14A800),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.shade100,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    if (periodStats.isEmpty) {
      return _buildEmptyChart('No earnings data available');
    }

    final validStats = periodStats.where((s) {
      final total = _parseToDouble(s['total']);
      return total > 0;
    }).toList();

    if (validStats.isEmpty) {
      return _buildEmptyChart('No earnings data available');
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < validStats.length; i++) {
      final total = _parseToDouble(validStats[i]['total']);
      spots.add(FlSpot(i.toDouble(), total));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY / 5).ceilToDouble(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < validStats.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _getLabel(validStats[index]),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
                reservedSize: 45,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              left: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xff14A800),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: const Color(0xff14A800),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xff14A800).withOpacity(0.3),
                    const Color(0xff14A800).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(0)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (categoryDistribution == null || categoryDistribution!.isEmpty) {
      return _buildEmptyChart('No category data available');
    }

    final colors = [
      const Color(0xff14A800),
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    final sections = <PieChartSectionData>[];
    int index = 0;
    categoryDistribution!.forEach((category, amount) {
      final percentage = (amount / totalEarnings) * 100;
      sections.add(
        PieChartSectionData(
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          color: colors[index % colors.length],
          showTitle: true,
        ),
      );
      index++;
    });

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          startDegreeOffset: -90,
          pieTouchData: PieTouchData(
            enabled: true,
            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          ),
        ),
      ),
    );
  }

  Widget buildMiniStats() {
    if (periodStats.isEmpty) return const SizedBox.shrink();

    final currentTotal = _parseToDouble(periodStats.last['total']);
    final previousTotal = periodStats.length > 1
        ? _parseToDouble(periodStats[periodStats.length - 2]['total'])
        : 0;

    final percentageChange = previousTotal > 0
        ? ((currentTotal - previousTotal) / previousTotal) * 100
        : 0;

    final isPositive = percentageChange >= 0;

    return Row(
      children: [
        _buildMiniStatCard(
          title: 'Current Period',
          value: '\$${currentTotal.toStringAsFixed(0)}',
          icon: Icons.trending_up,
          color: const Color(0xff14A800),
        ),
        const SizedBox(width: 12),
        _buildMiniStatCard(
          title: 'vs Previous',
          value:
              '${isPositive ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
          icon: isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }


String _getLabel(Map<String, dynamic> stat) {
  if (stat['period'] != null) {
    final period = stat['period'].toString();
    if (period.contains('-')) {
      final parts = period.split('-');
      if (parts.length == 2) {
        final month = int.tryParse(parts[1]);
        if (month != null && month >= 1 && month <= 12) {
          return '${_getMonthName(month)} ${parts[0]}';
        }
        return period; 
      }
    }
    return period;
  }
  if (stat['month'] != null) {
    final monthStr = stat['month'].toString();
    if (monthStr.contains('-')) {
      final parts = monthStr.split('-');
      if (parts.length == 2) {
        final month = int.tryParse(parts[1]);
        if (month != null && month >= 1 && month <= 12) {
          return '${_getMonthName(month)} ${parts[0]}';
        }
      }
    }
    return monthStr;
  }
  if (stat['week'] != null) {
    return 'W${stat['week']}';
  }
  return '';
}

String _getMonthName(int month) {
  if (month < 1 || month > 12) {
    return 'Invalid'; 
  }
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month - 1];
}
  Widget _buildEmptyChart(String message) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class GradientLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;

  const GradientLineChart({
    super.key,
    required this.spots,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SparklineChart extends StatelessWidget {
  final List<double> data;
  final Color color;

  const SparklineChart({
    super.key,
    required this.data,
    this.color = const Color(0xff14A800),
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i]),
    );
    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;

    return SizedBox(
      height: 40,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: minY - (range * 0.1),
          maxY: maxY + (range * 0.1),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 1.5,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DonutChart extends StatelessWidget {
  final Map<String, double> data;
  final double? total;

  const DonutChart({super.key, required this.data, this.total});

  @override
  Widget build(BuildContext context) {
    final totalValue = total ?? data.values.reduce((a, b) => a + b);
    final colors = [
      const Color(0xff14A800),
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    final sections = <PieChartSectionData>[];
    int index = 0;
    data.forEach((key, value) {
      final percentage = (value / totalValue) * 100;
      sections.add(
        PieChartSectionData(
          value: value,
          title: percentage > 10 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          color: colors[index % colors.length],
          showTitle: percentage > 10,
        ),
      );
      index++;
    });

    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 35,
              startDegreeOffset: -90,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${totalValue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Total',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HorizontalBarChart extends StatelessWidget {
  final Map<String, double> data;
  final int itemCount;

  const HorizontalBarChart({super.key, required this.data, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final sorted = entries..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sorted.take(itemCount).toList();
    final maxValue = topEntries.isNotEmpty ? topEntries.first.value : 1;

    return Column(
      children: topEntries.map((entry) {
        final percentage = (entry.value / maxValue) * 100;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 12)),
                  Text(
                    '\$${entry.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Color(0xff14A800)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
