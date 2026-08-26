import 'dart:math';

// ── Data classes ──────────────────────────────────────────────────────────────

class TimeSlot {
  final String name;
  final String tamilName;
  final DateTime start;
  final DateTime end;
  final bool isInauspicious;

  const TimeSlot({
    required this.name,
    required this.tamilName,
    required this.start,
    required this.end,
    required this.isInauspicious,
  });

  String get formatted {
    String fmt(DateTime t) {
      final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
      final m = t.minute.toString().padLeft(2, '0');
      final ampm = t.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }
    return '${fmt(start)} – ${fmt(end)}';
  }
}

class PanchangResult {
  final DateTime date;
  // Module 1 — Solar
  final DateTime sunrise;
  final DateTime sunset;
  // Module 2 — Tamil calendar
  final String tamilMonth;
  final String tamilMonthTamil;
  final int tamilDay;
  final String tamilYear;
  // Module 3 — Lunar
  final String tithi;
  final String tithiTamil;
  final String paksha; // Shukla (waxing) or Krishna (waning)
  // Module 4 — Nakshatra
  final String nakshatra;
  final String nakshatraTamil;
  // Module 5 — Time slots
  final TimeSlot raahuKalam;
  final TimeSlot yamagandam;
  final TimeSlot gulikaKalam;
  final TimeSlot abhijitMuhurtam;

  PanchangResult({
    required this.date,
    required this.sunrise,
    required this.sunset,
    required this.tamilMonth,
    required this.tamilMonthTamil,
    required this.tamilDay,
    required this.tamilYear,
    required this.tithi,
    required this.tithiTamil,
    required this.paksha,
    required this.nakshatra,
    required this.nakshatraTamil,
    required this.raahuKalam,
    required this.yamagandam,
    required this.gulikaKalam,
    required this.abhijitMuhurtam,
  });
}

// ── Main service ──────────────────────────────────────────────────────────────

class PanchangService {
  PanchangService._();
  static final instance = PanchangService._();

  // Marudamalai temple coordinates
  static const _lat = 11.04611;
  static const _lon = 76.85194;
  static const _tzOffset = 5.5; // IST = UTC+5:30

  // ── Public API ──────────────────────────────────────────────────────────────

  PanchangResult calculate([DateTime? date]) {
    final d = date ?? DateTime.now();
    final sunrise = _sunrise(d);
    final sunset = _sunset(d);
    final sunLon = _sunLongitude(d);
    final moonLon = _moonLongitude(d);

    return PanchangResult(
      date: d,
      sunrise: sunrise,
      sunset: sunset,
      tamilMonth: _tamilMonth(sunLon).$1,
      tamilMonthTamil: _tamilMonth(sunLon).$2,
      tamilDay: _tamilDay(d, sunLon),
      tamilYear: _tamilYear(d),
      tithi: _tithi(sunLon, moonLon).$1,
      tithiTamil: _tithi(sunLon, moonLon).$2,
      paksha: _paksha(sunLon, moonLon),
      nakshatra: _nakshatra(moonLon).$1,
      nakshatraTamil: _nakshatra(moonLon).$2,
      raahuKalam: _raahuKalam(d, sunrise, sunset),
      yamagandam: _yamagandam(d, sunrise, sunset),
      gulikaKalam: _gulikaKalam(d, sunrise, sunset),
      abhijitMuhurtam: _abhijitMuhurtam(sunrise, sunset),
    );
  }

  // ── Module 1: Sunrise / Sunset (NOAA Solar Algorithm) ──────────────────────
  //
  // HOW IT WORKS (plain English):
  // Earth tilts 23.5° on its axis. As it orbits the sun, the sun appears
  // to move along a path called the ECLIPTIC. We calculate:
  // 1. Julian Day Number — a continuous count of days since Jan 1, 4713 BC
  //    (astronomers use this so they don't have to deal with months/years)
  // 2. Solar Mean Anomaly — how far Earth has travelled in its elliptical orbit
  // 3. Equation of Center — correction because orbit is ellipse not circle
  // 4. Solar Declination — how far north/south the sun is today
  // 5. Hour Angle — the angle at which sun crosses the horizon at your location
  // Convert that angle to time = sunrise/sunset.

  double _julianDay(DateTime d) {
    // Julian Day Number (JDN) — continuous astronomical day count
    final a = (14 - d.month) ~/ 12;
    final y = d.year + 4800 - a;
    final m = d.month + 12 * a - 3;
    return d.day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045 -
        0.5 +
        (12 - _tzOffset) / 24.0; // noon UTC reference
  }

  double _sunLongitude(DateTime d) {
    // Julian centuries since J2000.0 (Jan 1.5, 2000)
    final jd = _julianDay(d);
    final T = (jd - 2451545.0) / 36525.0;

    // Geometric mean longitude of sun (degrees)
    final l0 = (280.46646 + 36000.76983 * T) % 360;
    final mDeg = (357.52911 + 35999.05029 * T - 0.0001537 * T * T) % 360;
    final mRad = mDeg * pi / 180;
    final c = (1.914602 - 0.004817 * T) * sin(mRad) +
        0.019993 * sin(2 * mRad) +
        0.000289 * sin(3 * mRad);
    return (l0 + c) % 360;
  }

  double _moonLongitude(DateTime d) {
    // Simplified lunar longitude using mean elements
    // Accurate to ~1° which is sufficient for tithi/nakshatra
    final jd = _julianDay(d);
    final T = (jd - 2451545.0) / 36525.0;

    // Moon's mean longitude
    final L = (218.3164477 + 481267.88123421 * T) % 360;
    // Moon's mean anomaly
    final M = (134.9633964 + 477198.8675055 * T) % 360;
    // Moon's argument of latitude
    final F = (93.2720950 + 483202.0175233 * T) % 360;
    // Sun's mean anomaly
    final ms = (357.5291092 + 35999.0502909 * T) % 360;
    // Elongation
    final D = (297.8501921 + 445267.1114034 * T) % 360;

    final mRad2 = M * pi / 180;
    final msRad2 = ms * pi / 180;
    final dRad = D * pi / 180;
    final fRad = F * pi / 180;

    // Main periodic terms (degrees)
    final lon = L +
        6.288774 * sin(mRad2) +
        1.274027 * sin(2 * dRad - mRad2) +
        0.658314 * sin(2 * dRad) +
        0.213618 * sin(2 * mRad2) -
        0.185116 * sin(msRad2) -
        0.114332 * sin(2 * fRad);

    return lon % 360;
  }

  DateTime _sunrise(DateTime d) => _sunEvent(d, true);
  DateTime _sunset(DateTime d) => _sunEvent(d, false);

  DateTime _sunEvent(DateTime d, bool isRise) {
    final jd = _julianDay(d);
    final T = (jd - 2451545.0) / 36525.0;

    final l0 = (280.46646 + 36000.76983 * T) % 360;
    final mAngle = (357.52911 + 35999.05029 * T) % 360;
    final mRad = mAngle * pi / 180;
    final c = (1.914602 - 0.004817 * T) * sin(mRad) +
        0.019993 * sin(2 * mRad);
    final sunLon = (l0 + c) % 360;

    // Obliquity of ecliptic
    final e = 23.439291 - 0.013004 * T;
    final eRad = e * pi / 180;
    final sunLonRad = sunLon * pi / 180;

    // Solar declination (how far north/south the sun is)
    final decl = asin(sin(eRad) * sin(sunLonRad));

    // Hour angle — the angle the sun needs to travel to reach the horizon
    final latRad = _lat * pi / 180;
    final cosH = (cos(89.833 * pi / 180) - sin(latRad) * sin(decl)) /
        (cos(latRad) * cos(decl));

    // Clamp to valid range
    final cosHClamped = cosH.clamp(-1.0, 1.0);
    final hAngle = acos(cosHClamped) * 180 / pi;

    // Solar noon in hours (UTC)
    final eqTime = 4 * (l0 - 0.0057183 - sunLon + 0.0 /* approx */);
    final solarNoonUTC = 12.0 - eqTime / 60.0 - _lon / 15.0;

    final eventUTC = isRise
        ? solarNoonUTC - hAngle / 15.0
        : solarNoonUTC + hAngle / 15.0;

    final eventIST = eventUTC + _tzOffset;
    final hours = eventIST.floor();
    final minutes = ((eventIST - hours) * 60).round();

    return DateTime(d.year, d.month, d.day, hours.clamp(0, 23),
        minutes.clamp(0, 59));
  }

  // ── Module 2: Tamil Month (Solar Ingress into Rasi) ────────────────────────
  //
  // HOW IT WORKS:
  // The ecliptic (sun's apparent path) is a 360° circle.
  // Divide it into 12 equal 30° slices = 12 Rasis (zodiac signs).
  // Tamil month name = which Rasi the sun is currently in.
  // Chithirai = 0°–30° (Mesha/Aries), Vaikasi = 30°–60° (Rishabha/Taurus)...

  static const _tamilMonths = [
    ('Chithirai', 'சித்திரை'),
    ('Vaikasi', 'வைகாசி'),
    ('Aani', 'ஆனி'),
    ('Aadi', 'ஆடி'),
    ('Aavani', 'ஆவணி'),
    ('Purattasi', 'புரட்டாசி'),
    ('Aippasi', 'ஐப்பசி'),
    ('Karthigai', 'கார்த்திகை'),
    ('Margazhi', 'மார்கழி'),
    ('Thai', 'தை'),
    ('Maasi', 'மாசி'),
    ('Panguni', 'பங்குனி'),
  ];

  (String, String) _tamilMonth(double sunLon) {
    final idx = (sunLon / 30).floor() % 12;
    return _tamilMonths[idx];
  }

  int _tamilDay(DateTime d, double sunLon) {
    // Day within Tamil month = degrees into current 30° Rasi slice + 1
    return ((sunLon % 30)).floor() + 1;
  }

  static const _tamilYears = [
    'Prabhava','Vibhava','Shukla','Pramodoota','Prajothpatti',
    'Aangirasa','Srimukha','Bhava','Yuva','Dhaatu',
    'Ishvara','Bahudhanya','Pramadi','Vikrama','Visha',
    'Chitrabhanu','Subhanu','Tharana','Parthiva','Vyaya',
    'Sarvajit','Sarvadhari','Virodhi','Vikruti','Khara',
    'Nandana','Vijaya','Jaya','Manmatha','Durmukhi',
    'Hevilambi','Vilambi','Vikari','Sharvari','Plava',
    'Shubhakrut','Shobhakrut','Krodhi','Vishvavasu','Parabhava',
    'Plavanga','Keelaka','Saumya','Sadharana','Virodhikrut',
    'Paridhavi','Pramaadi','Aananda','Rakshasa','Nala',
    'Pingala','Kalayukti','Siddharthi','Raudra','Durmathi',
    'Dundubhi','Rudhirodgari','Raktakshi','Krodhana','Akshaya',
  ];

  String _tamilYear(DateTime d) {
    int y = d.year;
    // Tamil year starts ~Apr 14; before that still previous year
    if (d.month < 4 || (d.month == 4 && d.day < 14)) y--;
    final idx = (y - 1987 + 13) % 60; // 1987 = Pramadi (index 12)
    return _tamilYears[idx < 0 ? idx + 60 : idx];
  }

  // ── Module 3: Tithi (Lunar Day) ────────────────────────────────────────────
  //
  // HOW IT WORKS:
  // Tithi = angular gap between Moon and Sun, divided into 12° chunks.
  // Moon moves ~13°/day, Sun moves ~1°/day → gap grows ~12°/day → 1 Tithi/day.
  // Gap 0°–12° = Tithi 1 (Prathama), 12°–24° = Tithi 2 (Dvitiya)... up to 30.
  // First 15 Tithis = Shukla Paksha (bright/waxing fortnight).
  // Next 15 = Krishna Paksha (dark/waning fortnight).

  static const _tithiNames = [
    ('Prathama','பிரதமை'),('Dvitiya','துவிதியை'),('Tritiya','திருதியை'),
    ('Chaturthi','சதுர்த்தி'),('Panchami','பஞ்சமி'),('Shashti','சஷ்டி'),
    ('Saptami','சப்தமி'),('Ashtami','அஷ்டமி'),('Navami','நவமி'),
    ('Dashami','தசமி'),('Ekadashi','ஏகாதசி'),('Dvadashi','துவாதசி'),
    ('Trayodashi','திரயோதசி'),('Chaturdashi','சதுர்தசி'),('Purnima/Amavasya','பௌர்ணமி'),
  ];

  (String, String) _tithi(double sunLon, double moonLon) {
    double gap = (moonLon - sunLon + 360) % 360;
    final idx = (gap / 12).floor() % 15;
    return _tithiNames[idx];
  }

  String _paksha(double sunLon, double moonLon) {
    final gap = (moonLon - sunLon + 360) % 360;
    return gap < 180 ? 'Shukla Paksha' : 'Krishna Paksha';
  }

  // ── Module 4: Nakshatra (Moon's Star Mansion) ──────────────────────────────
  //
  // HOW IT WORKS:
  // The 360° sky is divided into 27 equal segments of 13°20' (13.333°) each.
  // Each segment is named after the star cluster (asterism) in that region.
  // Moon's longitude ÷ 13.333° = which Nakshatra the Moon is in today.
  // Moon takes ~27.3 days to complete one orbit = visits one Nakshatra per day.

  static const _nakshatras = [
    ('Ashwini','அஸ்வினி'),('Bharani','பரணி'),('Krittika','கார்த்திகை'),
    ('Rohini','ரோகிணி'),('Mrigashira','மிருகசீரிஷம்'),('Ardra','திருவாதிரை'),
    ('Punarvasu','புனர்பூசம்'),('Pushya','பூசம்'),('Ashlesha','ஆயில்யம்'),
    ('Magha','மகம்'),('Purva Phalguni','பூரம்'),('Uttara Phalguni','உத்திரம்'),
    ('Hasta','அஸ்தம்'),('Chitra','சித்திரை'),('Swati','சுவாதி'),
    ('Vishakha','விசாகம்'),('Anuradha','அனுஷம்'),('Jyeshtha','கேட்டை'),
    ('Mula','மூலம்'),('Purva Ashadha','பூராடம்'),('Uttara Ashadha','உத்திராடம்'),
    ('Shravana','திருவோணம்'),('Dhanishtha','அவிட்டம்'),('Shatabhisha','சதயம்'),
    ('Purva Bhadrapada','பூரட்டாதி'),('Uttara Bhadrapada','உத்திரட்டாதி'),
    ('Revati','ரேவதி'),
  ];

  (String, String) _nakshatra(double moonLon) {
    final idx = (moonLon / (360.0 / 27)).floor() % 27;
    return _nakshatras[idx];
  }

  // ── Module 5: Time Slots (Day Slicing) ────────────────────────────────────
  //
  // HOW IT WORKS:
  // Take the daylight period (sunrise to sunset) and divide into 8 equal slots.
  // Each slot = (sunset - sunrise) / 8 minutes long (~90 min on average).
  // Ancient Tamil astrology assigns each slot on each weekday a meaning:
  //
  // RAAHU KALAM (inauspicious — ruled by shadow planet Rahu):
  //   Sun=8, Mon=2, Tue=7, Wed=5, Thu=6, Fri=4, Sat=3
  //
  // YAMAGANDAM (inauspicious — ruled by Yama, god of death):
  //   Sun=5, Mon=4, Tue=3, Wed=2, Thu=1, Fri=7, Sat=6  (1-indexed from sunrise)
  //   Actually traditional: Sun=4, Mon=3, Tue=2, Wed=1, Thu=7, Fri=6, Sat=5
  //
  // GULIKA KALAM (inauspicious — ruled by Gulika/Mandi):
  //   Sun=7, Mon=6, Tue=5, Wed=4, Thu=3, Fri=2, Sat=1
  //
  // ABHIJIT MUHURTAM (most auspicious — midday window):
  //   Always the 8th muhurtam of the day = 24 mins around solar noon.

  // Slot index (1-based) for each weekday (0=Sun, 1=Mon...6=Sat)
  static const _raahuSlots    = [8, 2, 7, 5, 6, 4, 3];
  static const _yamagandamSlots = [4, 3, 2, 1, 7, 6, 5];
  static const _gulikaSlots   = [7, 6, 5, 4, 3, 2, 1];

  TimeSlot _slot(DateTime d, DateTime sunrise, DateTime sunset,
      List<int> table, String name, String tamilName) {
    final totalMins = sunset.difference(sunrise).inMinutes;
    final slotMins = totalMins / 8.0;
    final weekday = d.weekday % 7; // DateTime.weekday: Mon=1..Sun=7 → Sun=0
    final slotIdx = table[weekday] - 1; // convert to 0-based
    final startMins = slotIdx * slotMins;
    final start = sunrise.add(Duration(minutes: startMins.round()));
    final end = sunrise.add(Duration(minutes: (startMins + slotMins).round()));
    return TimeSlot(
        name: name,
        tamilName: tamilName,
        start: start,
        end: end,
        isInauspicious: true);
  }

  TimeSlot _raahuKalam(DateTime d, DateTime sunrise, DateTime sunset) =>
      _slot(d, sunrise, sunset, _raahuSlots, 'Raahu Kalam', 'ராகு காலம்');

  TimeSlot _yamagandam(DateTime d, DateTime sunrise, DateTime sunset) =>
      _slot(d, sunrise, sunset, _yamagandamSlots, 'Yamagandam', 'யமகண்டம்');

  TimeSlot _gulikaKalam(DateTime d, DateTime sunrise, DateTime sunset) =>
      _slot(d, sunrise, sunset, _gulikaSlots, 'Gulika Kalam', 'குளிகை காலம்');

  TimeSlot _abhijitMuhurtam(DateTime sunrise, DateTime sunset) {
    // Solar noon ± 12 minutes = most auspicious window of the day
    final noon = sunrise
        .add(Duration(minutes: sunset.difference(sunrise).inMinutes ~/ 2));
    return TimeSlot(
      name: 'Abhijit Muhurtam',
      tamilName: 'அபிஜித் முகூர்த்தம்',
      start: noon.subtract(const Duration(minutes: 12)),
      end: noon.add(const Duration(minutes: 12)),
      isInauspicious: false,
    );
  }
}
