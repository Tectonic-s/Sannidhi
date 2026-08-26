import 'package:flutter/material.dart';

class AnnouncementTicker extends StatefulWidget {
  const AnnouncementTicker({super.key});

  static const _messages = [
    '🔔 Girivalam starts at 6:30 PM today — carry water & wear footwear',
    '🍛 Free Annadhanam served at Hilltop Mandapam — 11:30 AM to 3:00 PM',
    '🚗 Senior citizen battery cars operational at Adivaram — No charge',
    '💧 RO drinking water available at Steps 200, 500 & 830',
    '🏥 Free First-Aid post open near Adivaram entrance — 24 hours',
    '📿 Kanda Sashti Kavasam recitation at 7:00 AM & 7:00 PM daily',
    '🎉 Panguni Uthiram special abhishekam — pre-book at counter 3',
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
        _index = (_index + 1) % AnnouncementTicker._messages.length;
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
    return Container(
      height: 36,
      color: const Color(0xFF800000),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFFF9933),
            height: double.infinity,
            child: const Center(
              child: Row(
                children: [
                  Icon(Icons.campaign, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
                key: ValueKey(_index),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  AnnouncementTicker._messages[_index],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
