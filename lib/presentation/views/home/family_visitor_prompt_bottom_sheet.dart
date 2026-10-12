import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/geofence_service.dart';
import '../../../data/repositories/mock_crowd_repository.dart';

class FamilyVisitorPromptBottomSheet extends StatefulWidget {
  final bool isTamil;
  final VoidCallback? onConfirmed;

  const FamilyVisitorPromptBottomSheet({
    super.key,
    required this.isTamil,
    this.onConfirmed,
  });

  static Future<void> show(BuildContext context, {required bool isTamil}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => FamilyVisitorPromptBottomSheet(isTamil: isTamil),
    );
  }

  @override
  State<FamilyVisitorPromptBottomSheet> createState() =>
      _FamilyVisitorPromptBottomSheetState();
}

class _FamilyVisitorPromptBottomSheetState
    extends State<FamilyVisitorPromptBottomSheet> {
  int _adults = 2;
  int _children = 1;
  bool _saveAsDefault = false;

  int get _total => _adults + _children;

  @override
  void initState() {
    super.initState();
    _loadInitialSavedSize();
  }

  Future<void> _loadInitialSavedSize() async {
    final saved = await GeofenceService.instance.getSavedFamilySize();
    if (saved != null && saved > 0 && mounted) {
      setState(() {
        if (saved == 1) {
          _adults = 1;
          _children = 0;
        } else if (saved == 2) {
          _adults = 2;
          _children = 0;
        } else {
          _adults = 2;
          _children = (saved - 2).clamp(0, 10);
        }
      });
    }
  }

  void _applyQuickPreset(int adults, int children) {
    HapticFeedback.lightImpact();
    setState(() {
      _adults = adults;
      _children = children;
    });
  }

  void _confirmSelection() {
    HapticFeedback.heavyImpact();
    final total = _total.clamp(1, 20);

    // Update GeofenceService
    GeofenceService.instance.updateDevoteeGroupCount(
      total,
      saveAsDefault: _saveAsDefault,
      isUserInitiated: true,
    );

    // Update MockCrowdRepository
    context.read<MockCrowdRepository>().recordFamilyGroupDeclaration(
      count: total,
    );

    widget.onConfirmed?.call();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF065F46),
        content: Row(
          children: [
            const Icon(Icons.verified, color: Color(0xFF34D399), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.isTamil
                  ? 'குடும்ப உறுப்பினர் எண்ணிக்கை $total வெற்றிகரமாக பதிவு செய்யப்பட்டது! 🙏'
                  : 'Family group size of $total devotees logged successfully! 🙏',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isTamil = widget.isTamil;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141416) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF2E2E32) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFB45309)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.family_restroom, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'குடும்பத்துடன் தரிசனமா? 🙏' : 'Visiting with Family & Kids? 🙏',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTamil
                              ? 'மருதமலை திருக்கோயில் நெரிசல் கண்காணிப்பு & வரிசை பாதுகாப்பு'
                              : 'Temple Live Queue Times & Child Safety Tracking',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Subtitle explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isTamil
                            ? 'குழந்தைகளிடம் மொபைல் போன் இல்லாததால், உங்கள் குழுவின் மொத்த உறுப்பினர்களை தேர்வு செய்யுங்கள். இது நெரிசல் நேரங்களை துல்லியமாக கணக்கிட உதவும்.'
                            : 'Since kids do not carry phones, declare your total family group so temple live queues, Annadhanam, and security teams count everyone.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Preset Chips
              Text(
                isTamil ? 'விரைவு தேர்வு:' : 'Quick Presets:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _presetChip('1 (Solo)', 1, 0),
                  _presetChip('2 (Couple)', 2, 0),
                  _presetChip('3 (Family)', 2, 1),
                  _presetChip('4 (Family of 4)', 2, 2),
                  _presetChip('5+ (Joint Family)', 3, 2),
                ],
              ),
              const SizedBox(height: 16),

              // Stepper Counters for Adults and Children
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor(context)),
                ),
                child: Column(
                  children: [
                    _counterRow(
                      title: isTamil ? 'பெரியவர்கள் (Adults)' : 'Adult Devotees',
                      subtitle: isTamil ? '12 வயதுக்கு மேல்' : 'Ages 12+',
                      value: _adults,
                      min: 1,
                      onChanged: (v) => setState(() => _adults = v),
                    ),
                    const Divider(height: 20),
                    _counterRow(
                      title: isTamil ? 'குழந்தைகள் (Children)' : 'Children & Toddlers',
                      subtitle: isTamil ? '12 வயதுக்கு கீழ் (போன் இல்லாதவர்கள்)' : 'Under 12 (No phones)',
                      value: _children,
                      min: 0,
                      onChanged: (v) => setState(() => _children = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Total display & Default checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTamil ? 'மொத்த பக்தர்கள்:' : 'Total Group Size:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD97706)),
                    ),
                    child: Text(
                      '$_total ${isTamil ? "பக்தர்கள்" : (_total == 1 ? "Devotee" : "Devotees")}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Checkbox: Save as default
              InkWell(
                onTap: () => setState(() => _saveAsDefault = !_saveAsDefault),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _saveAsDefault,
                          activeColor: const Color(0xFFD97706),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _saveAsDefault = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isTamil
                              ? 'அடுத்த முறை வரும்போதும் இதே எண்ணிக்கையை பயன்படுத்தவும்'
                              : 'Remember this family size for future temple visits',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        GeofenceService.instance.updateDevoteeGroupCount(1, isUserInitiated: false);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        isTamil ? 'நான் மட்டும் (1)' : 'Just Me (1)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _confirmSelection,
                      child: Text(
                        isTamil
                            ? 'உறுதி செய் ($_total)'
                            : 'Confirm Group ($_total)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, int adults, int children) {
    final isSelected = _adults == adults && _children == children;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _applyQuickPreset(adults, children),
      selectedColor: const Color(0xFFD97706),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : AppTheme.textPrimaryOf(context),
      ),
      backgroundColor: AppTheme.elevatedBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFFD97706) : AppTheme.borderColor(context),
        ),
      ),
    );
  }

  Widget _counterRow({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryOf(context),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _circleBtn(
              icon: Icons.remove,
              enabled: value > min,
              onTap: () {
                if (value > min) {
                  HapticFeedback.lightImpact();
                  onChanged(value - 1);
                }
              },
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 36),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimaryOf(context),
                ),
              ),
            ),
            _circleBtn(
              icon: Icons.add,
              enabled: value < 15,
              onTap: () {
                if (value < 15) {
                  HapticFeedback.lightImpact();
                  onChanged(value + 1);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.elevatedBg(context)
              : AppTheme.elevatedBg(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppTheme.textPrimaryOf(context)
              : AppTheme.textSecondaryOf(context).withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
