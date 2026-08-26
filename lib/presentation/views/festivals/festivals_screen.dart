import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/tamil_panchang_card.dart';
import '../../../data/repositories/mock_festival_repository.dart';

class FestivalsScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;
  const FestivalsScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    final festivals =
        Provider.of<MockFestivalRepository>(context).getFestivals();

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: festivals.length + 1,
        separatorBuilder: (ctx, i) =>
            i == 0 ? const SizedBox(height: 8) : const SizedBox(height: 14),
        itemBuilder: (context, i) {
          if (i == 0) return TamilPanchangCard(isTamil: isTamil);
          final f = festivals[i - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FestivalCard(
              name: isTamil ? f.tamilName : f.name,
              date: f.date,
              description: isTamil ? f.tamilDescription : f.description,
              isSpecial: f.isSpecial,
              isTamil: isTamil,
            ),
          );
        },
      ),
    );
  }
}

class _FestivalCard extends StatefulWidget {
  final String name;
  final String date;
  final String description;
  final bool isSpecial;
  final bool isTamil;

  const _FestivalCard({
    required this.name,
    required this.date,
    required this.description,
    required this.isSpecial,
    required this.isTamil,
  });

  @override
  State<_FestivalCard> createState() => _FestivalCardState();
}

class _FestivalCardState extends State<_FestivalCard> {
  bool _expanded = false;
  bool _reminderSet = false;

  String _countdown() {
    final target = DateTime.tryParse(widget.date);
    if (target == null) return '';
    final diff = target.difference(DateTime.now());
    if (widget.isTamil) {
      if (diff.isNegative) return 'நிறைவடைந்தது';
      if (diff.inDays == 0) return 'இன்று!';
      if (diff.inDays == 1) return 'நாளை';
      return '${diff.inDays} நாட்களில்';
    }
    if (diff.isNegative) return 'Completed';
    if (diff.inDays == 0) return 'Today!';
    if (diff.inDays == 1) return 'Tomorrow';
    return 'In ${diff.inDays} days';
  }

  // ── English trivia ────────────────────────────────────────────────────────
  static const _triviaEn = {
    'Thai Pongal':
        'Thai Pongal celebrates the harvest season. The sun enters Capricorn (Makara Rasi) — a sacred transition in Tamil astronomy. The word Pongal means "to boil over" symbolising abundance.',
    'Thaipusam':
        'Thaipusam is most sacred to Lord Murugan. Marudamalai is one of the six abodes (Arupadai Veedu) of Murugan. Kavadi bearers carry ornate structures as an act of devotion.',
    'Maha Shivaratri':
        'Shivaratri means "Great Night of Shiva". Staying awake all night and chanting Panchakshara (Na-Ma-Si-Va-Ya) is believed to wash away all sins.',
    'Panguni Uthiram':
        'Panguni Uthiram marks the celestial wedding of Lord Murugan with Devasena. Thousands perform Girivalam (circumambulation) around Marudamalai hill on this night.',
    'Tamil New Year':
        'Tamil New Year falls on the first day of Chithirai month. The year 2026 is named Sarvajit in the 60-year Tamil calendar cycle.',
    'Vaikasi Visakam':
        'Vaikasi Visakam is the birth star (Visakam) of Lord Murugan in the Tamil month of Vaikasi. It is the most important festival at all Murugan temples.',
    'Vinayagar Chaturthi':
        'Lord Vinayagar removes all obstacles. Kozhukattai is his favourite offering. Clay Vinayagar idols are immersed in water after 10 days.',
    'Navaratri':
        'Nine nights dedicated to Goddess Durga, Lakshmi, and Saraswati. Golu (doll display on steps) is a cherished Tamil tradition passed down through generations.',
    'Deepavali':
        'Deepavali marks Lord Krishna\'s victory over Narakasura. Oil bath with gingelly oil before sunrise is a sacred Tamil custom believed to bring great merit.',
    'Karthigai Deepam':
        'Karthigai Deepam is the festival of lamps sacred to Lord Murugan and Shiva. Rows of clay lamps are lit in every home and temple across Tamil Nadu.',
  };

  // ── Tamil trivia (South Indian terms, no Hindi) ───────────────────────────
  static const _triviaTa = {
    'தைப்பொங்கல்':
        'தைப்பொங்கல் அறுவடைத் திருவிழா. சூரியன் மகர ராசியில் நுழைகிறான் — தமிழ் வானியலில் புனிதமான மாற்றம். பொங்கல் என்ற சொல்லுக்கு "கொதித்து வழிதல்" என்று பொருள் — வளத்தின் அடையாளம்.',
    'தைப்பூசம்':
        'தைப்பூசம் முருகப்பெருமானுக்கு மிகவும் புனிதமானது. மருதமலை ஆறுபடை வீடுகளில் ஒன்று. கவடி தாங்குவோர் பக்தியின் அடையாளமாக அலங்கரிக்கப்பட்ட கட்டமைப்புகளை சுமக்கின்றனர்.',
    'மகா சிவராத்திரி':
        'சிவராத்திரி என்பது "சிவனின் மகா இரவு". இரவு முழுவதும் விழித்திருந்து பஞ்சாட்சரம் (ந-ம-சி-வ-ய) சொல்வது அனைத்து பாவங்களையும் போக்கும் என்று நம்பப்படுகிறது.',
    'பங்குனி உத்திரம்':
        'பங்குனி உத்திரம் முருகப்பெருமானுக்கும் தேவசேனைக்கும் திருமணம் நடந்த நாள். ஆயிரக்கணக்கானோர் இந்த இரவில் மருதமலையை சுற்றி கிரிவலம் செய்கின்றனர்.',
    'தமிழ் புத்தாண்டு':
        'தமிழ் புத்தாண்டு சித்திரை மாதத்தின் முதல் நாளில் வருகிறது. 2026 ஆம் ஆண்டு 60 ஆண்டு தமிழ் நாட்காட்டியில் சர்வஜித் என்று பெயரிடப்பட்டுள்ளது.',
    'வைகாசி விசாகம்':
        'வைகாசி விசாகம் முருகப்பெருமானின் பிறந்த நட்சத்திரம் (விசாகம்) வைகாசி மாதத்தில் வருகிறது. அனைத்து முருகன் கோயில்களிலும் மிக முக்கியமான திருவிழா.',
    'விநாயகர் சதுர்த்தி':
        'விநாயகர் தடைகளை நீக்குபவர். கொழுக்கட்டை அவருக்கு மிகவும் பிடித்த நைவேத்தியம். மண் விநாயகர் சிலைகள் 10 நாட்களுக்குப் பிறகு நீரில் கரைக்கப்படுகின்றன.',
    'நவராத்திரி':
        'துர்கை, லட்சுமி, சரஸ்வதி ஆகிய தேவியருக்கு ஒன்பது இரவுகள் அர்ப்பணிக்கப்படுகின்றன. படிகளில் பொம்மை வைக்கும் கொலு தமிழ் மரபு தலைமுறை தலைமுறையாக கடைப்பிடிக்கப்படுகிறது.',
    'தீபாவளி':
        'தீபாவளி கிருஷ்ணர் நரகாசுரனை வென்றதை நினைவுகூர்கிறது. சூரிய உதயத்திற்கு முன் நல்லெண்ணெய் குளியல் மிகுந்த புண்ணியம் தரும் என்று தமிழ் மரபு கூறுகிறது.',
    'கார்த்திகை தீபம்':
        'கார்த்திகை தீபம் முருகன் மற்றும் சிவனுக்கு புனிதமான விளக்கு திருவிழா. தமிழ்நாடு முழுவதும் ஒவ்வொரு வீட்டிலும் கோயிலிலும் மண் விளக்குகள் ஏற்றப்படுகின்றன.',
  };

  // ── English rituals ───────────────────────────────────────────────────────
  static const _ritualsEn = {
    'Thai Pongal': [
      'Surya Namaskaram at sunrise (6:15 AM)',
      'Pongal cooking ritual at 9:00 AM',
      'Special Annadhanam from 11:00 AM',
      'Evening deepam at 6:30 PM',
    ],
    'Thaipusam': [
      'Kavadi procession starts at 5:00 AM',
      'Special Vel Thiruvabishekam at 8:00 AM',
      'Annadhanam throughout the day',
      'Evening alankaram at 7:00 PM',
    ],
    'Maha Shivaratri': [
      'First Thiruvabishekam at 6:00 PM',
      'Second Thiruvabishekam at 9:00 PM',
      'Third Thiruvabishekam at 12:00 AM',
      'Fourth Thiruvabishekam at 3:00 AM',
      'Sunrise pooja at 6:00 AM',
    ],
    'Panguni Uthiram': [
      'Special Thiruvabishekam at 5:00 AM',
      'Thirukalyanam (celestial wedding) at 10:00 AM',
      'Girivalam procession at 6:00 PM',
      'Ardhajamam pooja at 11:00 PM',
    ],
    'Vaikasi Visakam': [
      'Flag hoisting (Kodiyetram) at 6:00 AM',
      'Special chariot procession at 10:00 AM',
      'Grand alankaram at 6:00 PM',
      'Theerthavari at 9:00 PM',
    ],
    'Karthigai Deepam': [
      'Lamp lighting begins at 5:30 PM',
      'Mahadeepa darshan at 7:00 PM',
      'Special Thiruvabishekam at 8:00 PM',
      'Annadhanam till midnight',
    ],
  };

  // ── Tamil rituals (South Indian terms) ───────────────────────────────────
  static const _ritualsTa = {
    'தைப்பொங்கல்': [
      'சூரிய உதயத்தில் சூரிய நமஸ்காரம் (காலை 6:15)',
      'பொங்கல் சமையல் சடங்கு காலை 9:00',
      'சிறப்பு அன்னதானம் காலை 11:00 முதல்',
      'மாலை தீபம் மாலை 6:30',
    ],
    'தைப்பூசம்': [
      'கவடி ஊர்வலம் காலை 5:00 தொடங்கும்',
      'சிறப்பு வேல் திருவாபிஷேகம் காலை 8:00',
      'நாள் முழுவதும் அன்னதானம்',
      'மாலை அலங்காரம் மாலை 7:00',
    ],
    'மகா சிவராத்திரி': [
      'முதல் திருவாபிஷேகம் மாலை 6:00',
      'இரண்டாம் திருவாபிஷேகம் இரவு 9:00',
      'மூன்றாம் திருவாபிஷேகம் இரவு 12:00',
      'நான்காம் திருவாபிஷேகம் அதிகாலை 3:00',
      'சூரிய உதய பூஜை காலை 6:00',
    ],
    'பங்குனி உத்திரம்': [
      'சிறப்பு திருவாபிஷேகம் காலை 5:00',
      'திருக்கல்யாணம் காலை 10:00',
      'கிரிவல ஊர்வலம் மாலை 6:00',
      'அர்த்தஜாம பூஜை இரவு 11:00',
    ],
    'வைகாசி விசாகம்': [
      'கொடியேற்றம் காலை 6:00',
      'சிறப்பு தேர் ஊர்வலம் காலை 10:00',
      'பெரும் அலங்காரம் மாலை 6:00',
      'தீர்த்தவாரி இரவு 9:00',
    ],
    'கார்த்திகை தீபம்': [
      'விளக்கேற்றல் மாலை 5:30 தொடங்கும்',
      'மகாதீப தரிசனம் மாலை 7:00',
      'சிறப்பு திருவாபிஷேகம் இரவு 8:00',
      'நள்ளிரவு வரை அன்னதானம்',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final countdown = _countdown();
    final trivia = t ? _triviaTa[widget.name] : _triviaEn[widget.name];
    final rituals = t ? _ritualsTa[widget.name] : _ritualsEn[widget.name];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.deepSaffron.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.deepSaffron.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.temple_hindu,
                      size: 28, color: AppColors.deepSaffron),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.calendar_today,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(widget.date,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.isSpecial)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t ? 'சிறப்பு' : 'Special',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (countdown == 'Today!' || countdown == 'இன்று!')
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        countdown,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: (countdown == 'Today!' || countdown == 'இன்று!')
                                ? AppColors.success
                                : AppColors.info),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Description ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(widget.description,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
          // ── Expandable trivia ─────────────────────────────────────────────
          if (trivia != null)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: AppColors.deepSaffron),
                  const SizedBox(width: 6),
                  Text(t ? 'தெரியுமா?' : 'Did You Know?',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepSaffron)),
                  const Spacer(),
                  Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.deepSaffron),
                ]),
              ),
            ),
          if (_expanded && trivia != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deepSaffron.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(trivia,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      height: 1.5)),
            ),
          // ── Ritual timeline ───────────────────────────────────────────────
          if (rituals != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(t ? 'வழிபாட்டு நேரவரிசை' : 'Ritual Timeline',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
            ),
            ...rituals.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.value,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary)),
                      ),
                    ],
                  ),
                )),
          ],
          // ── Reminder toggle ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(children: [
              Icon(
                  _reminderSet
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  size: 18,
                  color: _reminderSet
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                  _reminderSet
                      ? (t ? 'நினைவூட்டல் அமைக்கப்பட்டது!' : 'Reminder set!')
                      : (t ? 'கோயில் நினைவூட்டல் அமை' : 'Set Temple Reminder'),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _reminderSet
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary)),
              const Spacer(),
              Switch(
                value: _reminderSet,
                onChanged: (v) => setState(() => _reminderSet = v),
                activeThumbColor: AppTheme.primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
