import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/micro_animations.dart';
import '../../../core/widgets/tamil_panchang_card.dart';
import '../../../data/repositories/mock_festival_repository.dart';

class FestivalsScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;
  const FestivalsScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    // Strictly retrieve only upcoming, unexpired festivals
    final festivals =
        Provider.of<MockFestivalRepository>(context).getFestivals();

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: ListView.separated(
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: festivals.isEmpty ? 2 : festivals.length + 1,
        separatorBuilder: (ctx, i) =>
            i == 0 ? const SizedBox(height: 6) : const SizedBox(height: 14),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  delay: Duration.zero,
                  child: TamilPanchangCard(isTamil: isTamil),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_available_rounded,
                              size: 20, color: AppColors.deepSaffron),
                          const SizedBox(width: 8),
                          Text(
                            isTamil
                                ? 'வரவிருக்கும் திருவிழாக்கள்'
                                : 'Upcoming Temple Festivals',
                            style: TextStyle(
                              fontSize: isTamil ? 17 : 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryOf(context),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.deepSaffron.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.deepSaffron.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isTamil
                              ? '${festivals.length} விழாக்கள்'
                              : '${festivals.length} Upcoming',
                          style: TextStyle(
                            fontSize: isTamil ? 12.5 : 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepSaffron,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (festivals.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.celebration_outlined,
                        size: 44, color: AppTheme.textSecondaryOf(context)),
                    const SizedBox(height: 10),
                    Text(
                      isTamil
                          ? 'தற்போது வரவிருக்கும் திருவிழாக்கள் ஏதுமில்லை'
                          : 'No upcoming festivals scheduled at this moment',
                      style: TextStyle(
                        fontSize: isTamil ? 15 : 13.5,
                        color: AppTheme.textSecondaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final f = festivals[i - 1];
          return FadeSlideIn(
            delay: Duration(milliseconds: 30 * i.clamp(0, 10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FestivalCard(
                id: f.id,
                name: isTamil ? f.tamilName : f.name,
                date: f.date,
                description: isTamil ? f.tamilDescription : f.description,
                isSpecial: f.isSpecial,
                isTamil: isTamil,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FestivalCard extends StatefulWidget {
  final String id;
  final String name;
  final String date;
  final String description;
  final bool isSpecial;
  final bool isTamil;

  const _FestivalCard({
    required this.id,
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

  @override
  void initState() {
    super.initState();
    _loadReminderState();
  }

  Future<void> _loadReminderState() async {
    final isSet =
        await NotificationService.instance.isFestivalReminderSet(widget.id);
    if (mounted) {
      setState(() => _reminderSet = isSet);
    }
  }

  Future<void> _toggleReminder(bool v) async {
    setState(() => _reminderSet = v);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isTamil = widget.isTamil;

    if (v) {
      final fDate = DateTime.tryParse(widget.date) ?? DateTime.now();
      final success = await NotificationService.instance.setFestivalReminder(
        festivalId: widget.id,
        festivalName: widget.name,
        festivalDate: fDate,
        isTamil: isTamil,
      );

      if (!mounted) return;
      if (success) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isTamil
                        ? '${widget.name} நினைவூட்டல் பதிவு செய்யப்பட்டது! (முந்தைய நாள் & காலை 7:00)'
                        : 'Reminder scheduled for ${widget.name}! (1 day before & 7:00 AM)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      await NotificationService.instance.cancelFestivalReminder(widget.id);
      if (!mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_off_outlined,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTamil
                      ? '${widget.name} நினைவூட்டல் நீக்கப்பட்டது'
                      : 'Reminder cancelled for ${widget.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _countdown() {
    final target = DateTime.tryParse(widget.date);
    if (target == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(target.year, target.month, target.day);
    final diff = targetDay.difference(today).inDays;
    if (widget.isTamil) {
      if (diff < 0) return 'நிறைவடைந்தது';
      if (diff == 0) return 'இன்று!';
      if (diff == 1) return 'நாளை';
      return 'இன்னும் $diff நாட்களில்';
    }
    if (diff < 0) return 'Completed';
    if (diff == 0) return 'Today!';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  // ── English trivia by ID & Name ───────────────────────────────────────────
  static const _triviaEn = {
    '1': 'Nine sacred nights dedicated to Goddess Durga, Lakshmi, and Saraswati. Golu (doll display on tiered steps) is a cherished Tamil tradition symbolising the spiritual evolution of life.',
    '2': 'Books, musical instruments, and occupational tools are placed before Goddess Saraswati for divine consecration, invoking wisdom and mastery.',
    '3': 'Marks the cosmic victory of light over darkness. Auspicious day for Vidyarambham where young children write their first sacred letter in rice or sand.',
    '4': 'Festival of lights celebrating victory over negativity. Pre-dawn Ganga Snanam oil bath with fragrant gingelly oil is believed to bring immense spiritual merit.',
    '5': 'Commemorates Lord Murugan\'s historic triumph over Soorapadman. Marudamalai witnesses thousands of pilgrims observing the sacred 6-day fasting and the climactic Soorasamharam battle.',
    '6': 'Festival of beacon lamps sacred to Lord Murugan and Shiva. A massive brass Mahadeepam is ignited atop Marudamalai hill, visible for miles across Coimbatore.',
    '7': 'Celebrates Lord Shiva\'s Cosmic Dance (Ananda Tandava) on the Arudra star night in Margazhi. Devotees break fasting with sacred Thiruvathirai Kali and Ezhu Kari Kootu.',
    '8': 'The opening of the celestial Paramapada Vasal (heavenly gateway). Fasting and night-long chanting are believed to grant liberation from the cycle of rebirths.',
    '9': 'Eve of Pongal celebrating renewal. Discarding old negative traits and welcoming new spiritual light and divine abundance.',
    '10': 'Harvest festival celebrating the sun\'s entrance into Makara Rasi. Boiling over of freshly harvested rice and milk in clay pots symbolises eternal abundance.',
    '11': 'The supreme festival of Lord Murugan at Marudamalai. Devotees carry ornate Kavadis and Pal Kudam (milk pots) as supreme acts of devotion, gratitude, and penance.',
    '12': 'Great night of Lord Shiva. Four distinct stages of Thiruvabishekam are conducted every three hours with sacred Bilva leaves, keeping devotees awake in prayer.',
    '13': 'Celebrates the celestial divine wedding of Lord Murugan with Devasena. Thousands perform the sacred Girivalam around Marudamalai hill under the full moon.',
    '14': 'First day of Chithirai month. Auspicious traditions include Kani viewing (auspicious sight of gold, fruits, and mirror at dawn) and Panchanga Sravanam.',
    '15': 'Sacred incarnation day of Lord Murugan under the Visakam asterism in Vaikasi month. Celebrated with grand temple chariot procession (Therottam).',
  };

  // ── Tamil trivia by ID & Name ─────────────────────────────────────────────
  static const _triviaTa = {
    '1': 'துர்கை, லட்சுமி, சரஸ்வதி ஆகிய முப்பெரும் தேவியருக்கு ஒன்பது புனித இரவுகள். படிகளில் பொம்மை வைக்கும் கொலு மனித ஆன்மாவின் படிமுறை ஆன்மீக வளர்ச்சியை உணர்த்துகிறது.',
    '2': 'சரஸ்வதி தேவியின் திருவடிகளில் நூல்கள், இசைக் கருவிகள் மற்றும் தொழில் கருவிகள் வைத்து ஆசீர்வாதம் பெறும் திருநாள். கல்வி ஞானத்திற்கும் கலை வளர்ச்சிக்கும் உகந்தது.',
    '3': 'தீமையை வென்ற வெற்றித் திருநாள். குழந்தைகளுக்கு அரிசி அல்லது மணலில் "ஓம்" அல்லது "அ" எழுதி வித்யாரம்பம் (கல்வித் தொடக்கம்) செய்ய மிகவும் உகந்த புனித நாள்.',
    '4': 'ஒளித் திருநாள். அதிகாலை சூரிய உதயத்திற்கு முன் நல்லெண்ணெய் குளியல் (கங்கா ஸ்நானம்) செய்து புத்தாடை அணிந்து, சிறப்பு கோயில் தீபம் தரிசிப்பது மிகுந்த புண்ணியம் தரும்.',
    '5': 'முருகப்பெருமான் சூரபத்மனை வென்ற மாபெரும் திருநாள். மருதமலையில் ஆயிரக்கணக்கான பக்தர்கள் 6 நாள் உண்ணாநோன்பு விரதமிருந்து, மலை அடிவாரத்தில் நடைபெறும் சூரசம்ஹாரத்தைக் காண்பர்.',
    '6': 'முருகனுக்கும் சிவனுக்கும் உரிய மகா விளக்குத் திருவிழா. மருதமலை உச்சியில் பிரம்மாண்ட மகாதீபம் ஏற்றப்படும். கோவை மாவட்டம் முழுவதிலும் இதன் ஒளி பரவும்.',
    '7': 'மார்கழி திருவாதிரை நட்சத்திரத்தில் நடராஜப் பெருமானின் ஆனந்தத் தாண்டவ தரிசனம். பக்தர்கள் விரதமிருந்து திருவெம்பாவை பாடி, திருவாதிரைக் களி நைவேத்தியம் படைப்பர்.',
    '8': 'சொர்க்கவாசல் (பரமபத வாசல்) திறக்கும் புனித ஏகாதசி நாள். இரவு முழுவதும் விழித்திருந்து துளசி அர்ச்சனையுடன் இறைவனை வழிபடுவது மோட்சம் தரும் நம்பிக்கை.',
    '9': 'பழையன கழிதலும் புதியன புகுதலுமான போகித் திருநாள். மார்கழி மாதத்தின் கடைசி நாளில் இந்திர பகவானை வணங்கி நற்பயன் வேண்டுவர்.',
    '10': 'சூரியன் மகர ராசியில் நுழையும் உழவர் திருநாள். புதிய மண்பானையில் பொங்கல் வைத்து பொங்கி வழியும்போது "பொங்கலோ பொங்கல்" என்று குலவையிட்டு கொண்டாடுவர்.',
    '11': 'மருதமலையில் முருகப்பெருமானின் முதன்மைப் பெருவிழா. பல்லாயிரக்கணக்கான பக்தர்கள் பால்குடம், அலகு குத்தி, காவடி ஏந்தி வேல் முழக்கத்துடன் மருதமலையை கிரிவலம் வருவர்.',
    '12': 'சிவவழிபாட்டின் மகா இரவு. இரவு முழுவதும் 4 கால சிறப்பு திருவாபிஷேகம், வில்வ அர்ச்சனை மற்றும் பஞ்சாட்சர (ந-ம-சி-வ-ய) ஜபத்துடன் விழிப்புடன் இருப்பர்.',
    '13': 'முருகப்பெருமான் - தேவசேனா திருக்கல்யாண வைபவம். பௌர்ணமி நிலவில் மருதமலையை சுற்றி ஆயிரக்கணக்கான பக்தர்கள் கிரிவலம் வந்து சுவாமி அருள் பெறுவர்.',
    '14': 'சித்திரை முதல் நாள் பிறக்கும் தமிழ்ப் புத்தாண்டு. சித்திரைக் கனி காணுதல், பஞ்சாங்கம் வாசித்தல் மற்றும் வேப்பம்பூ பச்சடி நைவேத்தியம் படைத்தல் முக்கிய மரபுகள்.',
    '15': 'முருகப்பெருமான் அவதரித்த புனித விசாக நட்சத்திர நாள். மருதமலையில் 108 சங்காபிஷேகம் மற்றும் பிரம்மாண்ட திருத்தேர் உலா (தேரோட்டம்) நடைபெறும்.',
  };

  // ── English rituals by ID ─────────────────────────────────────────────────
  static const _ritualsEn = {
    '1': [
      'Maha Kalasa Sthapana & Pooja at 7:30 AM',
      'Lalitha Sahasranama Archana at 10:30 AM',
      'Evening Golu viewing & Prasad at 5:00 PM',
      'Special Navaratri Alankaram Deeparadhana at 7:00 PM',
    ],
    '2': [
      'Sacred tool and book consecration at 8:00 AM',
      'Maha Saraswati Homam at 9:30 AM',
      'Special Kadalai Sundal prasadam at 11:30 AM',
      'Evening Vedic chanting at 6:30 PM',
    ],
    '3': [
      'Vidyarambham (sacred initiation into letters) at 7:00 AM',
      'Aksharabhyasam ceremonies through 12:00 PM',
      'Shami tree circumambulation pooja at 5:00 PM',
      'Special evening Utsavam at 7:00 PM',
    ],
    '4': [
      'Pre-dawn Ganga Snanam special pooja at 4:30 AM',
      'New Vastram (silk garments) offering at 6:00 AM',
      'Continuous Maha Annadhanam from 11:00 AM',
      'Special Deepavali Deepam & Fireworks at 6:30 PM',
    ],
    '5': [
      'Special Vel Thiruvabishekam at 8:00 AM',
      'Sashti Vratam Parayanam & Annadhanam at 12:00 PM',
      'Grand Soorasamharam Battle reenactment at 5:00 PM',
      'Shanti Thiruvabishekam & Alankaram at 7:30 PM',
    ],
    '6': [
      'Bharani Deepam sanctum lighting at 4:00 AM',
      'Thirupugazh chanting congregation at 10:00 AM',
      'Lighting of hillock Mahadeepam at 6:00 PM',
      'Grand Girivalam procession till midnight',
    ],
    '7': [
      'Midnight Nataraja Maha Abhishekam at 12:00 AM',
      'Thiruvempavai pasurams chanting at 4:30 AM',
      'Dawn Arudra Darshan with live Nagaswaram at 6:00 AM',
      'Sacred Thiruvathirai Kali prasadam at 7:30 AM',
    ],
    '8': [
      'Paramapada Vasal (Heavenly Gateway) opens at 4:30 AM',
      'Garuda Vahana Utsavam at 7:00 AM',
      'Vishnu Sahasranama Parayanam throughout day',
      'Sayana Aradhana at 10:00 PM',
    ],
    '9': [
      'Pre-dawn Bhogi bonfire ritual at 5:00 AM',
      'Indra Pooja for agricultural abundance at 8:00 AM',
      'Sweet Poli offering to deity at 11:30 AM',
      'Evening temple lighting at 6:30 PM',
    ],
    '10': [
      'Surya Namaskaram at sunrise (6:15 AM)',
      'Pongal cooking ritual at 9:00 AM',
      'Special Annadhanam from 11:00 AM',
      'Evening deepam at 6:30 PM',
    ],
    '11': [
      'Kavadi procession starts at 5:00 AM',
      'Special Vel Thiruvabishekam at 8:00 AM',
      'Continuous Annadhanam throughout the day',
      'Evening grand Raja Alankaram at 7:00 PM',
    ],
    '12': [
      'First Kala Thiruvabishekam at 6:00 PM',
      'Second Kala Thiruvabishekam at 9:00 PM',
      'Third Kala Thiruvabishekam at 12:00 AM',
      'Fourth Kala Thiruvabishekam at 3:00 AM',
      'Sunrise pooja & prasad at 6:00 AM',
    ],
    '13': [
      'Special Thiruvabishekam at 5:00 AM',
      'Thirukalyanam (celestial wedding) at 10:00 AM',
      'Girivalam full moon procession at 6:00 PM',
      'Ardhajamam pooja at 11:00 PM',
    ],
    '14': [
      'Vishu Kani viewing at 5:30 AM',
      'Panchanga Sravanam reading at 9:00 AM',
      'Special Annadhanam with Mangai Pachadi from 11:30 AM',
      'Evening classical music concert at 6:30 PM',
    ],
    '15': [
      'Flag hoisting (Kodiyetram) at 6:00 AM',
      '108 Sangabhishekam at 9:00 AM',
      'Grand Chariot Car (Therottam) procession at 10:00 AM',
      'Sacred Theerthavari at 9:00 PM',
    ],
  };

  // ── Tamil rituals by ID ───────────────────────────────────────────────────
  static const _ritualsTa = {
    '1': [
      'மகா கலச ஸ்தாபனம் மற்றும் பூஜை காலை 7:30',
      'லலிதா சகஸ்ரநாம அர்ச்சனை காலை 10:30',
      'மாலை கொலு தரிசனம் மற்றும் பிரசாதம் மாலை 5:00',
      'சிறப்பு நவராத்திரி அலங்கார தீபாராதனை இரவு 7:00',
    ],
    '2': [
      'ஆயுதங்கள் மற்றும் நூல்கள் வைபவம் காலை 8:00',
      'மகா சரஸ்வதி ஹோமம் காலை 9:30',
      'சுண்டல் பிரசாத விநியோகம் காலை 11:30',
      'மாலை வேத பாராயணம் மாலை 6:30',
    ],
    '3': [
      'வித்யாரம்பம் (குழந்தைகள் கல்வித் தொடக்கம்) காலை 7:00',
      'அக்ஷராப்யாசம் தொடர் சடங்கு மதியம் 12:00 வரை',
      'வன்னி மர பிரதக்ஷிண பூஜை மாலை 5:00',
      'சிறப்பு உற்சவர் உலா இரவு 7:00',
    ],
    '4': [
      'அதிகாலை கங்கா ஸ்நான சிறப்பு பூஜை அதிகாலை 4:30',
      'புத்தாடை அணிவித்து விசேஷ அலங்காரம் காலை 6:00',
      'தொடர் மகா அன்னதானம் காலை 11:00 முதல்',
      'தீபாவளி மகா தீபம் மற்றும் வாணவேடிக்கை மாலை 6:30',
    ],
    '5': [
      'சிறப்பு வேல் திருவாபிஷேகம் காலை 8:00',
      'சஷ்டி விரத பாராயணம் மற்றும் அன்னதானம் மதியம் 12:00',
      'பிரசித்தி பெற்ற சூரசம்ஹார திருவிழா மாலை 5:00',
      'சாந்தி திருவாபிஷேகம் மற்றும் ராஜ அலங்காரம் இரவு 7:30',
    ],
    '6': [
      'கருவறையில் பரணி தீபம் ஏற்றுதல் அதிகாலை 4:00',
      'திருப்புகழ் இன்னிசை பாராயணம் காலை 10:00',
      'மருதமலை உச்சியில் பிரம்மாண்ட மகாதீபம் மாலை 6:00',
      'நள்ளிரவு வரை பல்லாயிரக்கணக்கான பக்தர்களின் கிரிவலம்',
    ],
    '7': [
      'நடராஜர் மகா அபிஷேகம் நள்ளிரவு 12:00',
      'திருவெம்பாவை பாசுரங்கள் பாராயணம் அதிகாலை 4:30',
      'அருணோதய ஆருத்ரா தரிசனம் காலை 6:00',
      'திருவாதிரைக் களி நைவேத்தியம் காலை 7:30',
    ],
    '8': [
      'பரமபத சொர்க்கவாசல் திறப்பு அதிகாலை 4:30',
      'கருட வாகன உற்சவம் காலை 7:00',
      'நாள் முழுவதும் விஷ்ணு சகஸ்ரநாம பாராயணம்',
      'சயன ஆராதனை இரவு 10:00',
    ],
    '9': [
      'அதிகாலை போகி மூலிகைத் தீ மூட்டுதல் காலை 5:00',
      'இந்திர பகவான் சிறப்பு பூஜை காலை 8:00',
      'போகி போளி நைவேத்தியம் காலை 11:30',
      'மாலை மங்கல தீப வழிபாடு மாலை 6:30',
    ],
    '10': [
      'சூரிய உதயத்தில் சூரிய நமஸ்காரம் (காலை 6:15)',
      'பொங்கல் சமையல் நைவேத்திய சடங்கு காலை 9:00',
      'சிறப்பு அன்னதானம் காலை 11:00 முதல்',
      'மாலை மங்கல தீபம் மாலை 6:30',
    ],
    '11': [
      'காவடி மற்றும் பால்குட ஊர்வலம் அதிகாலை 5:00',
      'சிறப்பு வேல் திருவாபிஷேகம் காலை 8:00',
      'நாள் முழுவதும் இடைவிடாத அன்னதானம்',
      'மாலை ராஜ அலங்கார தீபாராதனை இரவு 7:00',
    ],
    '12': [
      'முதல் கால திருவாபிஷேகம் மாலை 6:00',
      'இரண்டாம் கால திருவாபிஷேகம் இரவு 9:00',
      'மூன்றாம் கால திருவாபிஷேகம் நள்ளிரவு 12:00',
      'நான்காம் கால திருவாபிஷேகம் அதிகாலை 3:00',
      'சூரிய உதய மகா தீபாராதனை காலை 6:00',
    ],
    '13': [
      'சிறப்பு திருவாபிஷேகம் காலை 5:00',
      'திருக்கல்யாண வைபவம் காலை 10:00',
      'பௌர்ணமி கிரிவல ஊர்வலம் மாலை 6:00',
      'அர்த்தஜாம பூஜை இரவு 11:00',
    ],
    '14': [
      'விஷு கனி காணுதல் அதிகாலை 5:30',
      'பஞ்சாங்கம் வாசித்தல் காலை 9:00',
      'மாங்கனி பச்சடி சிறப்பு அன்னதானம் காலை 11:30',
      'மாலை நாதஸ்வர மங்கல கச்சேரி மாலை 6:30',
    ],
    '15': [
      'கொடியேற்றம் அதிகாலை 6:00',
      '108 சங்காபிஷேகம் காலை 9:00',
      'சிறப்பு திருத்தேர் உலா (தேரோட்டம்) காலை 10:00',
      'தீர்த்தவாரி இரவு 9:00',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final countdown = _countdown();
    final trivia = (t ? _triviaTa : _triviaEn)[widget.id];
    final rituals = (t ? _ritualsTa : _ritualsEn)[widget.id];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(context)),
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
            padding: EdgeInsets.all(t ? 16 : 14),
            decoration: BoxDecoration(
              color: AppColors.deepSaffron.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: t ? 54 : 48,
                  height: t ? 54 : 48,
                  decoration: BoxDecoration(
                    color: AppColors.deepSaffron.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.temple_hindu,
                      size: t ? 30 : 26, color: AppColors.deepSaffron),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: t ? 17.5 : 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryOf(context),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: AppColors.deepSaffron),
                          const SizedBox(width: 5),
                          Text(
                            widget.date,
                            style: TextStyle(
                              fontSize: t ? 13.5 : 12.5,
                              color: AppColors.deepSaffron,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.isSpecial)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(t ? 'சிறப்பு' : 'Special',
                            style: TextStyle(
                                fontSize: t ? 11 : 10,
                                color: AppColors.error,
                                fontWeight: FontWeight.w800)),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (countdown == 'Today!' || countdown == 'இன்று!')
                            ? AppColors.success.withValues(alpha: 0.14)
                            : AppColors.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        countdown,
                        style: TextStyle(
                            fontSize: t ? 11 : 10,
                            fontWeight: FontWeight.w800,
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
            padding: EdgeInsets.fromLTRB(16, t ? 14 : 12, 16, 4),
            child: Text(
              widget.description,
              style: TextStyle(
                fontSize: t ? 15 : 13.5,
                color: AppTheme.textSecondaryOf(context),
                height: t ? 1.55 : 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // ── Expandable trivia ─────────────────────────────────────────────
          if (trivia != null) ...[
            BouncingScaleTap(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 18, color: AppColors.deepSaffron),
                  const SizedBox(width: 6),
                  Text(t ? 'தெரியுமா?' : 'Did You Know?',
                      style: TextStyle(
                          fontSize: t ? 14 : 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepSaffron)),
                  const Spacer(),
                  Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppTheme.textSecondaryOf(context)),
                ]),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  trivia,
                  style: TextStyle(
                      fontSize: t ? 14 : 12.5,
                      color: AppTheme.textPrimaryOf(context),
                      height: t ? 1.6 : 1.5),
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 240),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],

          // ── Ritual timeline ───────────────────────────────────────────────
          if (rituals != null) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16, t ? 14 : 12, 16, 6),
              child: Text(
                t ? 'வழிபாட்டு நேரவரிசை & சடங்குகள்' : 'Ritual Timeline & Ceremonies',
                style: TextStyle(
                  fontSize: t ? 14.5 : 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryOf(context),
                ),
              ),
            ),
            ...rituals.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: t ? 24 : 20,
                        height: t ? 24 : 20,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: t ? 12 : 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: t ? 14 : 12.5,
                            color: AppTheme.textPrimaryOf(context),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // ── Reminder toggle ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(14, t ? 14 : 10, 14, 12),
            child: Row(children: [
              Icon(
                  _reminderSet
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  size: 20,
                  color: _reminderSet
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                  _reminderSet
                      ? (t ? 'நினைவூட்டல் அமைக்கப்பட்டது!' : 'Reminder set!')
                      : (t ? 'கோயில் நினைவூட்டல் அமை' : 'Set Temple Reminder'),
                  style: TextStyle(
                      fontSize: t ? 13.5 : 12.5,
                      fontWeight: FontWeight.w700,
                      color: _reminderSet
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary)),
              const Spacer(),
              Switch(
                value: _reminderSet,
                onChanged: _toggleReminder,
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
