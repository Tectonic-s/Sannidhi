import 'package:flutter/material.dart';
import '../../../core/services/panchang_service.dart';

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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFFAD1457)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _header(),
          _sunriseSunset(),
          _tithiNakshatra(),
          _timeSlots(),
          _expandButton(),
          if (_expanded) _expandedSlots(),
        ],
      ),
    );
  }

  // ── Top: Tamil date + year ──────────────────────────────────────────────────
  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Tamil date number
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${_p.tamilDay}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t ? _p.tamilMonthTamil : _p.tamilMonth,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _t
                        ? '${_p.tamilMonthTamil}  •  ${_p.tamilYear}'
                        : '${_p.tamilMonth}  •  ${_p.tamilYear}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _t ? _pakshaTamil(_p.paksha) : _p.paksha,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Today's Gregorian date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_p.date.day}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  _monthName(_p.date.month),
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11),
                ),
                Text(
                  '${_p.date.year}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );

  // ── Sunrise / Sunset row ────────────────────────────────────────────────────
  Widget _sunriseSunset() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            _sunChip(Icons.wb_sunny_outlined,
                _t ? 'சூரிய உதயம்' : 'Suuriya Udhayam', _p.sunrise),
            const SizedBox(width: 8),
            _sunChip(Icons.nights_stay_outlined,
                _t ? 'சூரிய அஸ்தமனம்' : 'Suuriya Asthamanam', _p.sunset),
          ],
        ),
      );

  Widget _sunChip(IconData icon, String label, DateTime time) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9)),
                  Text(_fmtTime(time),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      );

  // ── Tithi + Nakshatra ───────────────────────────────────────────────────────
  Widget _tithiNakshatra() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            _infoChip('🌙',
                _t ? 'திதி' : 'Tithi',
                _t ? _p.tithiTamil : _p.tithi,
                _t ? _p.tithi : _p.tithiTamil),
            const SizedBox(width: 8),
            _infoChip('⭐',
                _t ? 'நட்சத்திரம்' : 'Natchathiram',
                _t ? _p.nakshatraTamil : _p.nakshatra,
                _t ? _p.nakshatra : _p.nakshatraTamil),
          ],
        ),
      );

  Widget _infoChip(
          String emoji, String label, String primary, String secondary) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$emoji $label',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9)),
              const SizedBox(height: 2),
              Text(primary,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              Text(secondary,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9)),
            ],
          ),
        ),
      );

  // ── Main 3 inauspicious slots ───────────────────────────────────────────────
  Widget _timeSlots() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            _slotChip(_p.raahuKalam, const Color(0xFFE53935)),
            const SizedBox(width: 6),
            _slotChip(_p.yamagandam, const Color(0xFFE65100)),
            const SizedBox(width: 6),
            _slotChip(_p.gulikaKalam, const Color(0xFF6A1B9A)),
          ],
        ),
      );

  Widget _slotChip(TimeSlot slot, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot.tamilName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(slot.formatted,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 9)),
            ],
          ),
        ),
      );

  // ── Expand button ───────────────────────────────────────────────────────────
  Widget _expandButton() => GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _expanded
                    ? (_t ? 'குறைவாக காட்டு' : 'Show less')
                    : (_t ? 'அபிஜித் முகூர்த்தம் & மேலும்' : 'Abhijit Muhurtam & more'),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      );

  // ── Expanded: Abhijit + explanation ────────────────────────────────────────
  Widget _expandedSlots() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Abhijit
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: Colors.amber, size: 14),
                const SizedBox(width: 6),
                Text(
                    _t ? 'அபிஜித் முகூர்த்தம்' : 'Abhijit Muhurtham',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(_p.abhijitMuhurtam.formatted,
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            _divider(),
            const SizedBox(height: 8),
            // Legend
            _legendRow('🔴',
                _t ? 'ராகு காலம்' : 'Raahu Kaalam',
                _t ? 'புதிய தொடக்கங்களை தவிர்க்கவும்' : 'Avoid new beginnings'),
            _legendRow('🟠',
                _t ? 'யமகண்டம்' : 'Yamagandam',
                _t ? 'பயணம் & ஒப்பந்தங்களை தவிர்க்கவும்' : 'Avoid travel & contracts'),
            _legendRow('🟣',
                _t ? 'குளிகை காலம்' : 'Gulika Kaalam',
                _t ? 'மங்கல நிகழ்வுகளை தவிர்க்கவும்' : 'Avoid auspicious events'),
            _legendRow('✨',
                _t ? 'அபிஜித்' : 'Abhijit',
                _t ? 'எந்த செயலுக்கும் சிறந்த நேரம்' : 'Best time for any work'),
          ],
        ),
      );

  Widget _legendRow(String emoji, String name, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Text('— $desc',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10)),
          ],
        ),
      );

  Widget _divider() => Container(
      height: 1, color: Colors.white.withValues(alpha: 0.2));

  String _pakshaTamil(String paksha) =>
      paksha.contains('Shukla') ? 'சுக்ல பக்ஷம்' : 'கிருஷ்ண பக்ஷம்';

  String _fmtTime(DateTime t) {
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
