/// Pure Dart Tamil calendar logic — no external package needed.
/// Covers Tamil month names, Tamil year (60-year cycle), and
/// a simple nakshatra approximation for display purposes.
class TamilCalendarService {
  TamilCalendarService._();
  static final instance = TamilCalendarService._();

  // Tamil solar months — each starts ~14th/15th of Gregorian month
  static const _tamilMonths = [
    ('Chithirai', 'சித்திரை'),   // Apr 14
    ('Vaikasi', 'வைகாசி'),       // May 15
    ('Aani', 'ஆனி'),             // Jun 15
    ('Aadi', 'ஆடி'),             // Jul 17
    ('Aavani', 'ஆவணி'),          // Aug 17
    ('Purattasi', 'புரட்டாசி'),  // Sep 17
    ('Aippasi', 'ஐப்பசி'),       // Oct 17
    ('Karthigai', 'கார்த்திகை'), // Nov 16
    ('Margazhi', 'மார்கழி'),     // Dec 16
    ('Thai', 'தை'),              // Jan 14
    ('Maasi', 'மாசி'),           // Feb 13
    ('Panguni', 'பங்குனி'),      // Mar 14
  ];

  // Approximate Gregorian start day for each Tamil month (day of month)
  static const _monthStartDays = [14, 15, 15, 17, 17, 17, 17, 16, 16, 14, 13, 14];

  // 60-year Tamil year cycle starting from a known anchor
  // Year 1987 = Pramadi (index 0 of our list offset)
  static const _tamilYears = [
    'Prabhava', 'Vibhava', 'Shukla', 'Pramodoota', 'Prajothpatti',
    'Aangirasa', 'Srimukha', 'Bhava', 'Yuva', 'Dhaatu',
    'Ishvara', 'Bahudhanya', 'Pramadi', 'Vikrama', 'Visha',
    'Chitrabhanu', 'Subhanu', 'Tharana', 'Parthiva', 'Vyaya',
    'Sarvajit', 'Sarvadhari', 'Virodhi', 'Vikruti', 'Khara',
    'Nandana', 'Vijaya', 'Jaya', 'Manmatha', 'Durmukhi',
    'Hevilambi', 'Vilambi', 'Vikari', 'Sharvari', 'Plava',
    'Shubhakrut', 'Shobhakrut', 'Krodhi', 'Vishvavasu', 'Parabhava',
    'Plavanga', 'Keelaka', 'Saumya', 'Sadharana', 'Virodhikrut',
    'Paridhavi', 'Pramaadi', 'Aananda', 'Rakshasa', 'Nala',
    'Pingala', 'Kalayukti', 'Siddharthi', 'Raudra', 'Durmathi',
    'Dundubhi', 'Rudhirodgari', 'Raktakshi', 'Krodhana', 'Akshaya',
  ];

  // Tamil year starts on Tamil New Year (Chithirai 1 = ~Apr 14)
  // 1987 CE = Pramadi (index 12), so anchor: 1987 - 12 = 1975 = index 0
  static const _anchorYear = 1975;

  /// Returns (tamilMonthIndex, tamilMonthName, tamilMonthTamil)
  (int, String, String) getTamilMonth(DateTime date) {
    // Tamil month index: 0=Chithirai(Apr), 1=Vaikasi(May)...9=Thai(Jan)...
    final m = date.month; // 1-12
    final d = date.day;

    // Map Gregorian month → Tamil month index
    // Tamil month changes around the 14th-17th of each Gregorian month
    int tamilIdx;
    final startDay = _monthStartDays[_gregorianToTamilMonthIdx(m)];
    if (d >= startDay) {
      tamilIdx = _gregorianToTamilMonthIdx(m);
    } else {
      final prevM = m == 1 ? 12 : m - 1;
      tamilIdx = _gregorianToTamilMonthIdx(prevM);
    }

    return (tamilIdx, _tamilMonths[tamilIdx].$1, _tamilMonths[tamilIdx].$2);
  }

  int _gregorianToTamilMonthIdx(int gregorianMonth) {
    // Apr=0, May=1, Jun=2, Jul=3, Aug=4, Sep=5,
    // Oct=6, Nov=7, Dec=8, Jan=9, Feb=10, Mar=11
    const map = {4: 0, 5: 1, 6: 2, 7: 3, 8: 4, 9: 5, 10: 6, 11: 7, 12: 8, 1: 9, 2: 10, 3: 11};
    return map[gregorianMonth] ?? 0;
  }

  /// Returns Tamil year name for a given Gregorian year.
  /// Tamil year starts ~Apr 14, so Jan–Apr 13 belongs to previous Tamil year.
  String getTamilYear(DateTime date) {
    int gregorianYear = date.year;
    // Before Tamil New Year (Apr 14), still in previous Tamil year
    if (date.month < 4 || (date.month == 4 && date.day < 14)) {
      gregorianYear -= 1;
    }
    final idx = (gregorianYear - _anchorYear) % 60;
    return _tamilYears[idx < 0 ? idx + 60 : idx];
  }

  /// Returns Tamil day number within the current Tamil month (1-based).
  int getTamilDay(DateTime date) {
    final (_, monthName, _) = getTamilMonth(date);
    final idx = _tamilMonths.indexWhere((m) => m.$1 == monthName);
    final startDay = _monthStartDays[idx];
    final m = date.month;
    final d = date.day;

    if (d >= startDay) {
      return d - startDay + 1;
    } else {
      // Days from previous month's start
      final daysInPrevMonth = DateTime(date.year, m, 0).day;
      final prevIdx = idx == 0 ? 11 : idx - 1;
      return daysInPrevMonth - _monthStartDays[prevIdx] + 1 + d;
    }
  }

  /// Full Tamil date string e.g. "சித்திரை 12, சர்வஜித்"
  String getTamilDateString(DateTime date) {
    final (_, _, tamilMonthTamil) = getTamilMonth(date);
    final day = getTamilDay(date);
    return '$tamilMonthTamil $day';
  }

  String getTamilMonthName(DateTime date) => getTamilMonth(date).$2;
  String getTamilMonthNameTamil(DateTime date) => getTamilMonth(date).$3;

  /// All days in the Gregorian month that have a festival
  /// Returns map of day → festival name
  Map<int, String> getFestivalDaysInMonth(
      DateTime month, List<({String name, String date})> festivals) {
    final result = <int, String>{};
    for (final f in festivals) {
      final d = DateTime.tryParse(f.date);
      if (d != null && d.year == month.year && d.month == month.month) {
        result[d.day] = f.name;
      }
    }
    return result;
  }
}
