import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
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
        padding: const EdgeInsets.all(16),
        itemCount: festivals.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final f = festivals[i];
          return _FestivalCard(
            name: isTamil ? f.tamilName : f.name,
            date: f.date,
            description: f.description,
            isSpecial: f.isSpecial,
            l10n: l10n,
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
  final AppLocalizations l10n;

  const _FestivalCard({
    required this.name,
    required this.date,
    required this.description,
    required this.isSpecial,
    required this.l10n,
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
    if (diff.isNegative) return 'Completed';
    if (diff.inDays == 0) return 'Today!';
    if (diff.inDays == 1) return 'Tomorrow';
    return 'In ${diff.inDays} days';
  }

  static const _trivia = {
    'Panguni Uthiram':
        'Panguni Uthiram marks the celestial wedding of Lord Murugan with Devasena. Thousands perform Girivalam on this night.',
    'Thai Pongal':
        'Thai Pongal celebrates the harvest season. The sun enters Capricorn (Makara Rasi) — a sacred transition in Tamil astronomy.',
    'Krishna Janmashtami':
        'Lord Krishna was born at midnight. Devotees fast all day and break it only after midnight abhishekam.',
    'Navaratri':
        'Nine nights dedicated to Goddess Durga, Lakshmi, and Saraswati. Golu (doll display) is a unique Tamil tradition.',
    'Deepavali':
        'Deepavali commemorates Lord Krishna\'s victory over Narakasura. Oil bath before sunrise is a sacred Tamil custom.',
  };

  static const _rituals = {
    'Panguni Uthiram': [
      'Special Abhishekam at 5:00 AM',
      'Thirukalyanam (celestial wedding) at 10:00 AM',
      'Girivalam procession at 6:00 PM',
      'Ardhajamam pooja at 11:00 PM',
    ],
    'Thai Pongal': [
      'Surya Namaskaram at sunrise',
      'Pongal cooking ritual at 9:00 AM',
      'Special Annadhanam from 11:00 AM',
      'Evening deepam at 6:30 PM',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final countdown = _countdown();
    final trivia = _trivia[widget.name];
    final rituals = _rituals[widget.name];

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
                        child: const Text('Special',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ),
                    const SizedBox(height: 4),
                    // Countdown chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: countdown == 'Today!'
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        countdown,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: countdown == 'Today!'
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
                  const Text('Did You Know?',
                      style: TextStyle(
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Ritual Timeline',
                  style: TextStyle(
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
                      ? 'Reminder set!'
                      : 'Set Temple Reminder',
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
