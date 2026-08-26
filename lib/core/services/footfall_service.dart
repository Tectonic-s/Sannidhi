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
    // Closed before 5:30 AM or after 8:30 PM, or during lunch break 1–2 PM
    if (h < 5.5 || h >= 20.5) return 0;
    if (h >= 13 && h < 14) return 0;

    // Morning session: 5:30 → 13:00
    if (h >= 5.5 && h < 8) return 10 + (h - 5.5) * 8;   // ramp-up
    if (h >= 8 && h < 11.5) {
      const mid = 9.5;
      return 85 - ((h - mid) * (h - mid)) * 6;           // morning peak ~09:30
    }
    if (h >= 11.5 && h < 13) return 55 - (h - 11.5) * 20; // wind-down to close

    // Evening session: 14:00 → 20:30
    if (h >= 14 && h < 15) return 20 + (h - 14) * 20;   // ramp-up after break
    if (h >= 15 && h < 19.5) {
      const mid = 17.5;
      return 90 - ((h - mid) * (h - mid)) * 6;           // evening peak ~17:30
    }
    if (h >= 19.5 && h < 20.5) return 45 - (h - 19.5) * 45; // wind-down to close

    return 0;
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
