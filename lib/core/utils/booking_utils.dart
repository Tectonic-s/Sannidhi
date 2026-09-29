/// Utility functions for booking dates, slot parsing, and expiration checks.
library;

/// Returns true if a slot time and date have passed relative to [now].
/// If the booking or ticket is already used, callers should not mark it expired.
bool isBookingExpired({
  required String? slotTime,
  required String? date,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();

  // 1. Resolve target date
  final targetDate = parseBookingDate(date);

  if (targetDate != null) {
    final today = DateTime(current.year, current.month, current.day);
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);

    if (targetDay.isBefore(today)) {
      return true; // Past day is definitely expired
    }
    if (targetDay.isAfter(today)) {
      return false; // Future day is not expired
    }
    // Same day -> check slot time below
  } else if (date != null &&
      (date.toLowerCase().contains('tomorrow') || date.contains('நாளை'))) {
    return false;
  }

  // 2. Resolve slot time on the current day
  if (slotTime == null || slotTime.trim().isEmpty) {
    return false;
  }

  final slotEndMinutes = parseSlotEndMinutes(slotTime);
  if (slotEndMinutes == null) {
    return false;
  }

  final currentMinutes = current.hour * 60 + current.minute;
  return currentMinutes >= slotEndMinutes;
}

/// Parses a date string into a DateTime (year, month, day).
DateTime? parseBookingDate(String? rawDate) {
  if (rawDate == null) return null;
  final clean = rawDate.trim();
  if (clean.isEmpty) return null;

  // Check for ISO-8601 (e.g. 2026-09-28 or 2026-09-28T...)
  final iso = DateTime.tryParse(clean);
  if (iso != null) {
    return DateTime(iso.year, iso.month, iso.day);
  }

  // Check for DD-MM-YYYY or DD/MM/YYYY
  final dmyNumMatch =
      RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(clean);
  if (dmyNumMatch != null) {
    final day = int.tryParse(dmyNumMatch.group(1)!);
    final month = int.tryParse(dmyNumMatch.group(2)!);
    final year = int.tryParse(dmyNumMatch.group(3)!);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }

  // Check for DD MMM YYYY or MMM DD YYYY (e.g. "28 Sep 2026" or "Sep 28, 2026")
  final dmyTextMatch = RegExp(
    r'(?:(\d{1,2})\s+([A-Za-z]{3,9})(?:,?\s+(\d{4}))?)|(?:([A-Za-z]{3,9})\s+(\d{1,2})(?:,?\s+(\d{4}))?)',
  ).firstMatch(clean);

  if (dmyTextMatch != null) {
    final dayStr = dmyTextMatch.group(1) ?? dmyTextMatch.group(5);
    final monthStr = dmyTextMatch.group(2) ?? dmyTextMatch.group(4);
    final yearStr = dmyTextMatch.group(3) ?? dmyTextMatch.group(6);

    final day = int.tryParse(dayStr ?? '');
    final year = int.tryParse(yearStr ?? '') ?? DateTime.now().year;
    final month = _parseMonth(monthStr);

    if (day != null && month != null) {
      return DateTime(year, month, day);
    }
  }

  // Check for "Today" or "இன்று"
  if (clean.toLowerCase().contains('today') || clean.contains('இன்று')) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  return null;
}

int? _parseMonth(String? m) {
  if (m == null) return null;
  const en = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec'
  ];
  final lower = m.toLowerCase();
  for (int i = 0; i < en.length; i++) {
    if (lower.startsWith(en[i])) return i + 1;
  }
  return null;
}

/// Parses a slot string like "10:00 AM - 11:30 AM" or "09:00 AM" into minutes from midnight for the slot end.
int? parseSlotEndMinutes(String slot) {
  final clean = slot.trim();
  if (clean.isEmpty) return null;

  // If slot has a range (e.g. "10:00 AM - 11:30 AM" or "10:00 AM to 11:30 AM"), pick the end time
  String timeString = clean;
  if (clean.contains('-')) {
    timeString = clean.split('-').last.trim();
  } else if (clean.toLowerCase().contains('to')) {
    timeString =
        clean.split(RegExp(r'\bto\b', caseSensitive: false)).last.trim();
  }

  final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false)
      .firstMatch(timeString);
  if (match == null) return null;

  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)?.toUpperCase();

  if (period == 'AM' && hour == 12) hour = 0;
  if (period == 'PM' && hour != 12) hour += 12;

  return hour * 60 + minute;
}
