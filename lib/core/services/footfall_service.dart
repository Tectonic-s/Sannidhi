import 'package:flutter/material.dart';

enum CrowdStatus { low, moderate, heavy }

class FootfallResult {
  final int crowdDensityPercent;
  final int estimatedWaitMins;
  final CrowdStatus crowdStatus;
  final Color color;

  const FootfallResult({
    required this.crowdDensityPercent,
    required this.estimatedWaitMins,
    required this.crowdStatus,
    required this.color,
  });

  String get statusLabel {
    switch (crowdStatus) {
      case CrowdStatus.low:
        return 'Low';
      case CrowdStatus.moderate:
        return 'Moderate';
      case CrowdStatus.heavy:
        return 'Heavy';
    }
  }
}

class FootfallService {
  FootfallService._();
  static final FootfallService instance = FootfallService._();

  /// Returns a rule-based footfall estimate for the given [dateTime].
  /// Calibrated from on-site survey data:
  ///   - Morning peak  : 08:00 – 11:30
  ///   - Evening peak  : 16:30 – 19:30
  ///   - Tuesday multiplier : ×1.4  (Murugan/Hanuman day)
  ///   - Weekend multiplier : ×1.6
  FootfallResult estimate(DateTime dateTime) {
    final hour = dateTime.hour + dateTime.minute / 60.0;
    final weekday = dateTime.weekday; // 1=Mon … 7=Sun

    // Base density (0–100) from time-of-day curve
    double base = _baseFromHour(hour);

    // Day-of-week multiplier
    double dayMult = 1.0;
    if (weekday == DateTime.tuesday) dayMult = 1.4;
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      dayMult = 1.6;
    }

    final density = (base * dayMult).clamp(0.0, 100.0).round();
    final waitMins = _waitFromDensity(density);
    final status = _statusFromDensity(density);
    final color = _colorFromStatus(status);

    return FootfallResult(
      crowdDensityPercent: density,
      estimatedWaitMins: waitMins,
      crowdStatus: status,
      color: color,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  double _baseFromHour(double h) {
    // Morning ramp-up  05:00 → 08:00
    if (h >= 5 && h < 8) return 10 + (h - 5) * 8;
    // Morning peak     08:00 → 11:30  (peaks at ~09:30 = 85%)
    if (h >= 8 && h < 11.5) {
      final mid = 9.5;
      return 85 - ((h - mid) * (h - mid)) * 6;
    }
    // Midday lull      11:30 → 16:30
    if (h >= 11.5 && h < 16.5) return 30 + (h - 11.5) * 2;
    // Evening peak     16:30 → 19:30  (peaks at ~18:00 = 90%)
    if (h >= 16.5 && h < 19.5) {
      final mid = 18.0;
      return 90 - ((h - mid) * (h - mid)) * 7;
    }
    // Evening wind-down 19:30 → 21:00
    if (h >= 19.5 && h < 21) return 40 - (h - 19.5) * 15;
    // Closed / very low
    return 5;
  }

  int _waitFromDensity(int d) {
    if (d < 30) return 5;
    if (d < 55) return 15;
    if (d < 75) return 30;
    return 50;
  }

  CrowdStatus _statusFromDensity(int d) {
    if (d < 40) return CrowdStatus.low;
    if (d < 70) return CrowdStatus.moderate;
    return CrowdStatus.heavy;
  }

  Color _colorFromStatus(CrowdStatus s) {
    switch (s) {
      case CrowdStatus.low:
        return const Color(0xFF4CAF50);
      case CrowdStatus.moderate:
        return const Color(0xFFFF9800);
      case CrowdStatus.heavy:
        return const Color(0xFFF44336);
    }
  }
}
