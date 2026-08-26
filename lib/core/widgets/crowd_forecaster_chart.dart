import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../services/footfall_service.dart';

class CrowdForecasterChart extends StatelessWidget {
  const CrowdForecasterChart({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final points = List.generate(12, (i) {
      final dt = now.add(Duration(hours: i));
      return (dt, FootfallService.instance.estimate(dt));
    });

    // Find best window (lowest density block)
    int bestIdx = 0;
    int bestDensity = 101;
    for (int i = 0; i < points.length; i++) {
      if (points[i].$2.crowdDensityPercent < bestDensity) {
        bestDensity = points[i].$2.crowdDensityPercent;
        bestIdx = i;
      }
    }
    final bestHour = points[bestIdx].$1;
    final bestLabel =
        '${_fmt(bestHour)} – ${_fmt(bestHour.add(const Duration(hours: 2)))}';

    final bars = points.asMap().entries.map((e) {
      final density = e.value.$2.crowdDensityPercent.toDouble();
      final color = e.value.$2.color;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: density,
            color: color,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '12-Hour Crowd Forecast',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          // Best time chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
            ),
            child: Text(
              '🟢 Best Time: $bestLabel (Low Crowd)',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: 100,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final dt = points[val.toInt()].$1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _fmt(dt),
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textSecondary),
                          ),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                barGroups: bars,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.primaryColor,
                    getTooltipItem: (group, ga, rod, rb) => BarTooltipItem(
                      '${rod.toY.round()}%',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final display = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$display$suffix';
  }
}
