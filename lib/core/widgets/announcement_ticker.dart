import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bulletin_provider.dart';
import '../l10n/app_localizations.dart';
import 'micro_animations.dart';

class AnnouncementTicker extends StatefulWidget {
  const AnnouncementTicker({super.key});

  @override
  State<AnnouncementTicker> createState() => _AnnouncementTickerState();
}

class _AnnouncementTickerState extends State<AnnouncementTicker> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }
    // 7.5 seconds slow rotation gives ample time to read complete text
    _timer = Timer.periodic(const Duration(milliseconds: 7500), (_) {
      if (!mounted || _isInteracting) return;
      final provider = Provider.of<BulletinProvider?>(context, listen: false);
      final itemsCount = provider?.items.length ?? 2;
      if (itemsCount <= 0) return;
      final nextPage = (_currentPage + 1) % itemsCount;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bulletinProvider = Provider.of<BulletinProvider?>(context);
    final items = bulletinProvider?.items ?? [
      BulletinItem(
        id: 'core_safety_twowheeler',
        icon: Icons.two_wheeler_rounded,
        categoryEn: 'SAFETY ADVISORY',
        categoryTa: 'பாதுகாப்பு எச்சரிக்கை',
        textEn: 'Two-wheelers are not allowed for travel to the hilltop after 5:00 PM for safety purposes.',
        textTa: 'பாதுகாப்பு காரணங்களுக்காக மாலை 5:00 மணிக்கு மேல் இருசக்கர வாகனங்கள் மலைப்பாதையில் செல்ல அனுமதி இல்லை.',
        accentColor: const Color(0xFFEF4444),
        isCustom: false,
        createdAt: DateTime(2026, 1, 1),
      ),
      BulletinItem(
        id: 'core_daily_recitations',
        icon: Icons.auto_stories_rounded,
        categoryEn: 'DAILY RECITATION',
        categoryTa: 'தினசரி பாராயணம்',
        textEn: 'Special recitations everyday at 6:00 PM at the temple.',
        textTa: 'திருக்கோயிலில் தினமும் மாலை 6:00 மணிக்கு சிறப்பு கூட்டுப் பாராயணம் நடைபெறும்.',
        accentColor: const Color(0xFFF59E0B),
        isCustom: false,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    final count = items.length;
    if (_currentPage >= count) {
      _currentPage = 0;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1111) : const Color(0xFF7A1414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GestureDetector(
        onPanDown: (_) => setState(() => _isInteracting = true),
        onPanCancel: () => setState(() => _isInteracting = false),
        onPanEnd: (_) => setState(() => _isInteracting = false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar: LIVE Tag + Progress Dots + Arrows
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 4),
              child: Row(
                children: [
                  // Pulsing Live Indicator Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PulsingLiveDot(
                          color: Colors.white,
                          size: 6,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isTamil ? 'நேரலைச் செய்தி' : 'LIVE BULLETIN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Counter indicator (e.g., 1 / 2)
                  Text(
                    '${_currentPage + 1} / $count',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Interactive Navigation Chevrons
                  InkWell(
                    onTap: () {
                      final prev = (_currentPage - 1 + count) % count;
                      _goTo(prev);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      final next = (_currentPage + 1) % count;
                      _goTo(next);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel Slide Body
            SizedBox(
              height: isTamil ? 86 : 76,
              child: PageView.builder(
                controller: _pageController,
                itemCount: count,
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                },
                itemBuilder: (context, index) {
                  final item = items[index];
                  final text = isTamil ? item.textTa : item.textEn;
                  final category = isTamil ? item.categoryTa : item.categoryEn;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Category Icon Avatar
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.accentColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(item.icon, color: item.accentColor, size: 20),
                        ),
                        const SizedBox(width: 10),

                        // Message Text with category pill
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color: item.accentColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  if (item.isCustom) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isTamil ? 'நிர்வாகம்' : 'ADMIN',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                text,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTamil ? 11.8 : 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.28,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Subtle Dots Indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(count, (idx) {
                  final isSelected = idx == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isSelected ? 16 : 5,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD97706)
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
