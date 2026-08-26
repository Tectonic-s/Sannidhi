import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sannidhi/core/constants/app_theme.dart';

Future<void> showMockPaymentSheet({
  required BuildContext context,
  required double amount,
  required String title,
  required VoidCallback onSuccess,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MockPaymentSheet(
      amount: amount,
      title: title,
      onSuccess: onSuccess,
    ),
  );
}

class _MockPaymentSheet extends StatefulWidget {
  final double amount;
  final String title;
  final VoidCallback onSuccess;

  const _MockPaymentSheet({
    required this.amount,
    required this.title,
    required this.onSuccess,
  });

  @override
  State<_MockPaymentSheet> createState() => _MockPaymentSheetState();
}

class _MockPaymentSheetState extends State<_MockPaymentSheet> {
  bool _processing = false;

  static const _upiApps = [
    ('GPay', Icons.g_mobiledata, Color(0xFF4285F4)),
    ('PhonePe', Icons.phone_android, Color(0xFF5F259F)),
    ('Paytm', Icons.account_balance_wallet, Color(0xFF00BAF2)),
    ('BHIM', Icons.flag, Color(0xFF138808)),
  ];

  Future<void> _pay() async {
    setState(() => _processing = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(),
          _header(),
          if (_processing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text('Verifying payment…',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),
            )
          else ...[
            const SizedBox(height: 20),
            _sectionLabel('Pay via UPI'),
            const SizedBox(height: 12),
            _upiRow(),
            const SizedBox(height: 20),
            _sectionLabel('Other Options'),
            const SizedBox(height: 12),
            _otherOptions(),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _handle() => Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${widget.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
        ),
      );

  Widget _upiRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _upiApps.map((app) {
            return GestureDetector(
              onTap: _pay,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: app.$3.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: app.$3.withValues(alpha: 0.3)),
                    ),
                    child: Icon(app.$2, color: app.$3, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(app.$1,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                ],
              ),
            );
          }).toList(),
        ),
      );

  Widget _otherOptions() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _optionTile(Icons.credit_card, 'Credit / Debit Card'),
            const SizedBox(height: 8),
            _optionTile(Icons.account_balance, 'Net Banking'),
          ],
        ),
      );

  Widget _optionTile(IconData icon, String label) => GestureDetector(
        onTap: _pay,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
              const Spacer(),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary, size: 20),
            ],
          ),
        ),
      );
}
