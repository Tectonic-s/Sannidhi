import 'package:flutter/material.dart';
import '../services/panchang_service.dart';

class TamilPanchangCard extends StatefulWidget {
  final bool isTamil;
  const TamilPanchangCard({super.key, this.isTamil = false});

  @override
  State<TamilPanchangCard> createState() => _TamilPanchangCardState();
}

class _TamilPanchangCardState extends State<TamilPanchangCard> {
  late final PanchangResult _p;
  bool _expanded = false;

  bool get _t => widget.isTamil;

  @override
  void initState() {
    super.initState();
    _p = PanchangService.instance.calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F0413), Color(0xFF6B0E27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Compact Header Row ──
          _compactHeader(),

          // ── Compact Highlights Row ──
          _compactHighlights(),

          // ── Expand Toggle ──
          _expandToggle(),

          // ── Expandable Details ──
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _expandedDetails(),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  // ── 1. Compact Header: Date & Calendar Names ──
  Widget _compactHeader() {
    final tithiText = _t ? _p.tithiTamil : _p.tithi;
    final nakshatraText = _t ? _p.nakshatraTamil : _p.nakshatra;
    final monthText = _t ? _p.tamilMonthTamil : _p.tamilMonth;
    final pakshaLabel = _t
        ? (_p.paksha.contains('Shukla') ? 'வளர்பிறை' : 'தேய்பிறை')
        : (_p.paksha.contains('Shukla') ? 'Waxing Moon' : 'Waning Moon');

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tamil date badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_p.tamilDay}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _t ? 'நாள்' : 'DAY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: _t ? 9 : 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Month, Year & Paksha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _t ? '$monthText மாதம்' : '$monthText Month',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _t ? 16 : 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pakshaLabel,
                        style: TextStyle(
                          color: const Color(0xFFFDE68A),
                          fontSize: _t ? 10.5 : 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _t
                      ? 'திதி: $tithiText  •  நட்சத்திரம்: $nakshatraText'
                      : 'Tithi: $tithiText  •  Nakshatra: $nakshatraText',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: _t ? 12 : 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // English date badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_p.date.day} ${_monthName(_p.date.month)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_p.date.year}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Compact Highlights: Sunrise, Sunset & Rahu Kalam ──
  Widget _compactHighlights() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          // Sunrise / Sunset Chip
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined,
                      color: Color(0xFFFDE68A), size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _t
                          ? 'உதயம்: ${_fmtTime(_p.sunrise)}'
                          : 'Sunrise: ${_fmtTime(_p.sunrise)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _t ? 11.5 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Rahu Kalam Chip
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled,
                      color: Color(0xFFFCA5A5), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _t
                          ? 'ராகு: ${_p.raahuKalam.formatted}'
                          : 'Rahu: ${_p.raahuKalam.formatted}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _t ? 11.5 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Expand Toggle Button ──
  Widget _expandToggle() {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _expanded
                  ? (_t ? 'சுருக்கமாக காட்டு' : 'Show Less')
                  : (_t ? 'முழு பஞ்சாங்கம் & முகூர்த்தம்' : 'View Full Panchang & Timings'),
              style: TextStyle(
                color: const Color(0xFFFDE68A),
                fontSize: _t ? 12 : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFFFDE68A),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Expanded Full Panchang Details ──
  Widget _expandedDetails() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Abhijit Muhurtam
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 15),
              const SizedBox(width: 6),
              Text(
                _t ? 'அபிஜித் முகூர்த்தம்' : 'Abhijit Muhurtam',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _t ? 12.5 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _p.abhijitMuhurtam.formatted,
                style: const TextStyle(
                  color: Color(0xFFFDE68A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 8),

          // Daily time slots grid
          Row(
            children: [
              Expanded(
                child: _slotMiniBox(
                  name: _t ? 'யமகண்டம்' : 'Yamagandam',
                  time: _p.yamagandam.formatted,
                  color: const Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _slotMiniBox(
                  name: _t ? 'குளிகை காலம்' : 'Gulika Kalam',
                  time: _p.gulikaKalam.formatted,
                  color: const Color(0xFFA855F7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sunset & Tamil Year
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t
                    ? 'அஸ்தமனம்: ${_fmtTime(_p.sunset)}'
                    : 'Sunset: ${_fmtTime(_p.sunset)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: _t ? 11.5 : 11,
                ),
              ),
              Text(
                _t
                    ? '${_p.tamilYear} வருடம்'
                    : '${_p.tamilYear} Year (${_p.date.year})',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: _t ? 11.5 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slotMiniBox(
      {required String name, required String time, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: _t ? 11.5 : 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: _t ? 11 : 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime t) {
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  String _monthName(int m) {
    if (_t) {
      const taMonths = [
        '',
        'ஜன',
        'பிப்',
        'மார்',
        'ஏப்',
        'மே',
        'ஜூன்',
        'ஜூலை',
        'ஆக',
        'செப்',
        'அக்',
        'நவ',
        'டிச'
      ];
      return taMonths[m];
    }
    const enMonths = [
      '',
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
      'Dec'
    ];
    return enMonths[m];
  }
}
