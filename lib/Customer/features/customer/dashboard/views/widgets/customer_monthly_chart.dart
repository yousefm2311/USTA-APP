import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerMonthlyChart extends StatelessWidget {
  const CustomerMonthlyChart({
    super.key,
    required this.values,
    required this.labels,
    this.loading = false,
  });

  final List<double> values;
  final List<String> labels;
  final bool loading;

  Color get blue => const Color(0xFF2563EB);
  Color get bg => const Color(0xFF0B1020);
  Color get grid => Colors.white12;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _container(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (values.isEmpty) {
      return _container(
        child: Center(
          child: Text(
            "لا توجد بيانات حتى الآن".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
      );
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = ((maxValue + 5).clamp(5, double.infinity)).toDouble();

    return _container(
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY / 4).clamp(1, maxY).toDouble(),
            verticalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: grid, strokeWidth: 1),
            getDrawingVerticalLine: (_) => FlLine(color: grid, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 11,
                  );
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) {
                    return const SizedBox();
                  }
                  return Text(labels[idx], style: style);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: grid, width: 1),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: blue.withOpacity(0.15),
                gradient: LinearGradient(
                  colors: [blue.withOpacity(0.25), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              spots: List.generate(
                values.length,
                (index) => FlSpot(index.toDouble(), values[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _container({required Widget child}) {
    final schema = Theme.of(Get.context!).colorScheme;
    return Container(
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: schema.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}
