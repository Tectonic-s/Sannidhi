import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AnnouncementTicker extends StatefulWidget {
  const AnnouncementTicker({super.key});

  static const _messagesEn = [
    '🔔 Girivalam starts at 6:30 PM today — carry water & wear footwear',
    '🍛 Free Annadhanam served at Hilltop Mandapam — 11:30 AM to 3:00 PM',
    '🚗 Senior citizen battery cars operational at Adivaram — No charge',
    '💧 RO drinking water available at Steps 200, 500 & 830',
    '🏥 Free First-Aid post open near Adivaram entrance — 24 hours',
    '📿 Kanda Sashti Kavasam recitation at 7:00 AM & 7:00 PM daily',
    '🎉 Panguni Uthiram special abhishekam — pre-book at counter 3',
  ];

  static const _messagesTa = [
    '🔔 இன்று மாலை 6:30 மணிக்கு கிரிவலம் தொடங்கும் — தண்ணீர் கொண்டு செல்லுங்கள்',
    '🍛 மலை மண்டபத்தில் இலவச அன்னதானம் — காலை 11:30 முதல் மாலை 3:00 வரை',
    '🚗 ஆதிவாரத்தில் மூத்தோர்க்கு இலவச மின்சார வாகனம் உள்ளது',
    '💧 படிகள் 200, 500 & 830 இல் சுத்தமான குடிநீர் கிடைக்கும்',
    '🏥 ஆதிவார நுழைவாயலில் இலவச முதலளவு சிகிச்சை — 24 மணி நேரமும்',
    '📿 தினமும் காலை 7:00 & மாலை 7:00 மணிக்கு கந்த சஷ்டி கவசம் பாராயணம்',
    '🎉 பங்குனி உத்திர சிறப்பு திருவாபிஷேகம் — கார்ண்டர் 3 இல் முன்பதிவு செய்யுங்கள்',
  ];

  @override
  State<AnnouncementTicker> createState() => _AnnouncementTickerState();
}

class _AnnouncementTickerState extends State<AnnouncementTicker>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startCycle();
  }

  void _startCycle() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) break;
      setState(() {
        _index = (_index + 1) % AnnouncementTicker._messagesEn.length;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';
    final messages = isTamil
        ? AnnouncementTicker._messagesTa
        : AnnouncementTicker._messagesEn;

    return Container(
      height: 44,
      color: const Color(0xFF800000),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFFF9933),
            height: double.infinity,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.campaign, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    isTamil ? 'நேரலை' : 'LIVE',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
              child: Padding(
                key: ValueKey('$isTamil-$_index'),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  messages[_index % messages.length],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
