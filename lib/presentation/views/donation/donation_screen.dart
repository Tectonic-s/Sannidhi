import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/mock_payment_sheet.dart';
import '../../../data/models/activity_models.dart';
import '../../../providers/user_activity_provider.dart';
import '../../../services/tax_receipt_service.dart';

class DonationScreen extends StatefulWidget {
  final VoidCallback onToggleLocale;
  const DonationScreen({super.key, required this.onToggleLocale});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  static const _quickAmounts = [101, 501, 1001, 5001];

  final _causes = <_Cause>[
    _Cause(key: 'annadhanam', icon: Icons.restaurant, color: const Color(0xFFE65100)),
    _Cause(key: 'renovation', icon: Icons.construction, color: const Color(0xFF1565C0)),
    _Cause(key: 'ghoShala', icon: Icons.pets, color: const Color(0xFF2E7D32)),
    _Cause(key: 'archana', icon: Icons.auto_awesome, color: AppColors.templeMaroon),
  ];

  String _selectedCauseKey = 'annadhanam';
  int _amount = 501;
  final _controller = TextEditingController(text: '501');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: widget.onToggleLocale),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label(l10n.translate('selectCause') ?? 'Select Cause'),
          const SizedBox(height: 12),
          _CauseChips(
            causes: _causes,
            selected: _selectedCauseKey,
            l10n: l10n,
            onSelect: (k) => setState(() => _selectedCauseKey = k),
          ),
          const SizedBox(height: 24),
          _label(l10n.translate('donationAmount') ?? 'Donation Amount'),
          const SizedBox(height: 12),
          _QuickAmountPills(
            amounts: _quickAmounts,
            selected: _amount,
            onSelect: (v) {
              setState(() => _amount = v);
              _controller.text = v.toString();
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.translate('customAmount') ?? 'Custom Amount',
              prefixText: '₹ ',
            ),
            onChanged: (v) {
              final p = int.tryParse(v);
              if (p != null && p > 0) setState(() => _amount = p);
            },
          ),
          const SizedBox(height: 12),
          Text(
            l10n.translate('donationNote') ??
                'Your generous donation will help us serve humanity',
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.favorite),
              label: Text(
                  '${l10n.translate('proceedToPay') ?? 'Proceed to Pay'}  ₹$_amount'),
              onPressed: _proceedToPay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));

  void _proceedToPay() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    final cause = _causes.firstWhere((c) => c.key == _selectedCauseKey);
    final l10n = AppLocalizations.of(context);
    final causeLabel = l10n.translate(_selectedCauseKey) ?? _selectedCauseKey;

    showMockPaymentSheet(
      context: context,
      amount: parsed.toDouble(),
      title: causeLabel,
      onSuccess: () {
        final now = DateTime.now();
        final txnId = 'TXN${now.millisecondsSinceEpoch.toString().substring(6)}';
        final qr = 'SANNIDHI|DONATION|$txnId|$causeLabel|₹$parsed';
        final receipt = DonationReceiptModel(
          transactionId: txnId,
          cause: causeLabel,
          amount: parsed,
          timestamp: now,
          qrPayload: qr,
          ref80g: '80G/MRD/$txnId',
        );
        context.read<UserActivityProvider>().addDonation(receipt);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ReceiptSheet(
            receipt: receipt,
            causeIcon: cause.icon,
            causeColor: cause.color,
          ),
        );
      },
    );
  }
}

// ── Cause chips ───────────────────────────────────────────────────────────────

class _Cause {
  final String key;
  final IconData icon;
  final Color color;
  const _Cause({required this.key, required this.icon, required this.color});
}

class _CauseChips extends StatelessWidget {
  final List<_Cause> causes;
  final String selected;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelect;

  const _CauseChips(
      {required this.causes,
      required this.selected,
      required this.l10n,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: causes.map((c) {
        final isSel = c.key == selected;
        return GestureDetector(
          onTap: () => onSelect(c.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? c.color : Colors.white,
              border: Border.all(
                  color: isSel ? c.color : Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSel
                  ? [BoxShadow(color: c.color.withValues(alpha: 0.3), blurRadius: 6)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 18, color: isSel ? Colors.white : c.color),
                const SizedBox(width: 6),
                Text(l10n.translate(c.key) ?? c.key,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSel ? Colors.white : AppTheme.textPrimary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Quick amount pills ────────────────────────────────────────────────────────

class _QuickAmountPills extends StatelessWidget {
  final List<int> amounts;
  final int selected;
  final ValueChanged<int> onSelect;

  const _QuickAmountPills(
      {required this.amounts, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: amounts.map((amt) {
        final isSel = amt == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelect(amt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 44,
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.primaryColor : Colors.white,
                  border: Border.all(
                      color: isSel
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('₹$amt',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : AppTheme.textPrimary)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Receipt sheet ─────────────────────────────────────────────────────────────

class _ReceiptSheet extends StatelessWidget {
  final DonationReceiptModel receipt;
  final IconData causeIcon;
  final Color causeColor;

  const _ReceiptSheet(
      {required this.receipt,
      required this.causeIcon,
      required this.causeColor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: causeColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24)),
              ),
              child: Column(children: [
                Icon(causeIcon, color: Colors.white, size: 36),
                const SizedBox(height: 6),
                Text(
                    l10n.translate('contributionReceipt') ??
                        'Contribution Receipt',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: QrImageView(
                data: receipt.qrPayload,
                version: QrVersions.auto,
                size: 150,
                eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: causeColor),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF333333)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                _r(l10n.translate('transactionId') ?? 'Transaction ID',
                    receipt.transactionId, bold: true),
                _r('80G Reference', receipt.ref80g),
                _r(l10n.translate('cause') ?? 'Cause', receipt.cause),
                _r(l10n.translate('amount') ?? 'Amount',
                    '₹${receipt.amount}', bold: true),
                _r(l10n.translate('date') ?? 'Date', receipt.dateStr),
              ]),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.translate('thankYou') ??
                    'Thank you for your contribution 🙏',
                style: TextStyle(
                    fontSize: 13,
                    color: causeColor,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download 80G Tax PDF'),
                onPressed: () => TaxReceiptService.instance
                    .print80gReceipt(context, receipt),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56)),
                child: Text(l10n.translate('done') ?? 'Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _r(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: AppTheme.textPrimary)),
          ],
        ),
      );
}
