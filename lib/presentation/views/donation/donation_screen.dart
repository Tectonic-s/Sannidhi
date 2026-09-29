import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/auth_required_dialog.dart';
import '../../../core/widgets/micro_animations.dart';
import '../../../core/services/cashfree_payment_service.dart';
import '../../../data/models/activity_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../../../services/tax_receipt_service.dart';
import '../payment/cashfree_payment_screen.dart';

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
    final auth = context.watch<AuthProvider>();
    final isAuth = auth.isAuthenticated;

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: widget.onToggleLocale),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isAuth) ...[
            AuthLockBanner(
              featureName: l10n.translate('donation') ?? 'Donation & Offerings',
            ),
            const SizedBox(height: 16),
          ],
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
            child: BouncingScaleTap(
              onTap: isAuth
                  ? _proceedToPay
                  : () => showAuthRequiredDialog(
                        context: context,
                        featureName: l10n.translate('donation') ?? 'Donation & Offerings',
                      ),
              child: ElevatedButton.icon(
                icon: Icon(isAuth ? Icons.favorite : Icons.lock),
                label: Text(
                  isAuth
                      ? '${l10n.translate('proceedToPay') ?? 'Proceed to Pay'}  ₹$_amount'
                      : 'Sign In to Access (${l10n.translate('donation') ?? 'Donation'})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAuth ? AppTheme.primaryColor : Colors.grey.shade400,
                  elevation: isAuth ? 2 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: isAuth
                    ? _proceedToPay
                    : () => showAuthRequiredDialog(
                          context: context,
                          featureName: l10n.translate('donation') ?? 'Donation & Offerings',
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context)));

  void _proceedToPay() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      showAuthRequiredDialog(
        context: context,
        featureName: AppLocalizations.of(context).translate('donation') ?? 'Donation & Offerings',
      );
      return;
    }

    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    final cause = _causes.firstWhere((c) => c.key == _selectedCauseKey);
    final l10n = AppLocalizations.of(context);
    final causeLabel = l10n.translate(_selectedCauseKey) ?? _selectedCauseKey;
    final user = auth.currentUser;

    CashfreePaymentService.instance.startPayment(
      context: context,
      amount: parsed.toDouble(),
      description: causeLabel,
      customerId: user != null && user.id.isNotEmpty
          ? user.id
          : 'devotee_${DateTime.now().millisecondsSinceEpoch}',
      customerName: user != null && user.name.isNotEmpty ? user.name : 'Devotee',
      customerEmail: user != null && user.email.isNotEmpty ? user.email : 'devotee@sannidhi.app',
      customerPhone: user != null && user.phone.isNotEmpty ? user.phone : '9999999999',
    ).then((result) {
      if (!mounted) return;
      if (result.result == CashfreePaymentResult.success) {
        final now = DateTime.now();
        final txnId = result.orderId.isNotEmpty
            ? result.orderId
            : 'TXN${now.millisecondsSinceEpoch.toString().substring(6)}';
        final qr = 'SANNIDHI|DONATION|$txnId|$causeLabel|₹$parsed';
        final receipt = DonationReceiptModel(
          transactionId: txnId,
          cause: causeLabel,
          amount: parsed,
          timestamp: now,
          qrPayload: qr,
          ref80g: '80G/MRD/$txnId',
        );
        context.read<UserActivityProvider>().addDonation(
          receipt,
          token: auth.token,
          userId: user?.id,
        );

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
      } else if (result.result == CashfreePaymentResult.failure) {
        showCashfreePaymentFailureDialog(
          context: context,
          message: result.message,
          onRetry: _proceedToPay,
        );
      }
    });
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
        return BouncingScaleTap(
          onTap: () => onSelect(c.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? c.color : Theme.of(context).cardColor,
              border: Border.all(
                  color: isSel ? c.color : AppTheme.borderColor(context), width: 1.5),
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
                        color: isSel ? Colors.white : AppTheme.textPrimaryOf(context))),
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
            child: BouncingScaleTap(
              onTap: () => onSelect(amt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 44,
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.primaryColor : Theme.of(context).cardColor,
                  border: Border.all(
                      color: isSel
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor(context)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('₹$amt',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : AppTheme.textPrimaryOf(context))),
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
    final isDark = AppTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor(context))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: receipt.qrPayload,
                  version: QrVersions.auto,
                  size: 150,
                  eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square, color: causeColor),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF000000)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                _r(context, l10n.translate('transactionId') ?? 'Transaction ID',
                    receipt.transactionId, bold: true),
                _r(context, '80G Reference', receipt.ref80g),
                _r(context, l10n.translate('cause') ?? 'Cause', receipt.cause),
                _r(context, l10n.translate('amount') ?? 'Amount',
                    '₹${receipt.amount}', bold: true),
                _r(context, l10n.translate('date') ?? 'Date', receipt.dateStr),
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

  Widget _r(BuildContext context, String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondaryOf(context))),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: AppTheme.textPrimaryOf(context))),
          ],
        ),
      );
}
