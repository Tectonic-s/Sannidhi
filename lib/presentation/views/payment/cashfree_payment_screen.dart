import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/cashfree_payment_service.dart';

Future<void> showCashfreePaymentFailureDialog({
  required BuildContext context,
  required String message,
  required VoidCallback onRetry,
  VoidCallback? onSimulateComplete,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.error_outline, size: 52, color: Color(0xFFF44336)),
      title: const Text('Payment Notice', style: TextStyle(fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5)),
          if (onSimulateComplete != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
              ),
              child: const Text(
                'Sandbox Simulation: You can complete this transaction now with test credentials.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            onRetry();
          },
          child: const Text('Retry'),
        ),
        if (onSimulateComplete != null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('Simulate & Complete'),
            onPressed: () {
              Navigator.pop(dialogContext);
              onSimulateComplete();
            },
          ),
      ],
    ),
  );
}

/// Drop-in payment screen. Push this route whenever you need to collect payment.
///
/// Example:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => CashfreePaymentScreen(
///     amount: 500,
///     description: 'Special Darshan',
///     customerId: 'user_001',
///     customerName: 'Devotee Name',
///     customerEmail: 'devotee@email.com',
///     customerPhone: '9999999999',
///     onSuccess: (orderId) { /* show ticket */ },
///   ),
/// ));
/// ```
class CashfreePaymentScreen extends StatefulWidget {
  final double amount;
  final String description;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final void Function(String orderId)? onSuccess;

  const CashfreePaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.onSuccess,
  });

  @override
  State<CashfreePaymentScreen> createState() => _CashfreePaymentScreenState();
}

enum _ScreenState { idle, loading, success, failure, cancelled }

class _CashfreePaymentScreenState extends State<CashfreePaymentScreen> {
  _ScreenState _state = _ScreenState.idle;
  String _message = '';
  String _orderId = '';

  Future<void> _pay() async {
    setState(() => _state = _ScreenState.loading);

    final result = await CashfreePaymentService.instance.startPayment(
      context: context,
      amount: widget.amount,
      description: widget.description,
      customerId: widget.customerId,
      customerName: widget.customerName,
      customerEmail: widget.customerEmail,
      customerPhone: widget.customerPhone,
    );

    if (!mounted) return;

    _orderId = result.orderId;
    _message = result.message;

    switch (result.result) {
      case CashfreePaymentResult.success:
        setState(() => _state = _ScreenState.success);
        widget.onSuccess?.call(_orderId);
      case CashfreePaymentResult.cancelled:
        setState(() => _state = _ScreenState.cancelled);
      case CashfreePaymentResult.failure:
        setState(() => _state = _ScreenState.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_state) {
            _ScreenState.idle => _IdleView(
              amount: widget.amount,
              description: widget.description,
              onPay: _pay,
            ),
            _ScreenState.loading => const _LoadingView(),
            _ScreenState.success => _SuccessView(
              orderId: _orderId,
              amount: widget.amount,
              onDone: () => Navigator.pop(context),
            ),
            _ScreenState.failure => _FailureView(
              message: _message,
              onRetry: () => setState(() => _state = _ScreenState.idle),
              onCancel: () => Navigator.pop(context),
            ),
            _ScreenState.cancelled => _CancelledView(
              onRetry: () => setState(() => _state = _ScreenState.idle),
              onBack: () => Navigator.pop(context),
            ),
          },
        ),
      ),
    );
  }
}

// ── Idle — show amount + Pay button ──────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final double amount;
  final String description;
  final VoidCallback onPay;
  const _IdleView({
    required this.amount,
    required this.description,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.temple_hindu, size: 64, color: AppTheme.primaryColor),
        const SizedBox(height: 24),
        Text(
          description,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 13, color: AppColors.success),
            const SizedBox(width: 5),
            Text(
              'Official Devasthanam Gateway • 256-Bit Encrypted',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onPay,
            icon: const Icon(Icons.payment),
            label: Text(
              'Pay ₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppTheme.primaryColor),
        SizedBox(height: 24),
        Text(
          'Processing payment…',
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

// ── Success ───────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String orderId;
  final double amount;
  final VoidCallback onDone;
  const _SuccessView({
    required this.orderId,
    required this.amount,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Color(0xFF4CAF50)),
        const SizedBox(height: 24),
        const Text(
          'Payment Successful! 🙏',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '₹${amount.toStringAsFixed(0)} paid',
          style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          'Order: $orderId',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Failure ───────────────────────────────────────────────────────────────────

class _FailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  const _FailureView({
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 80, color: Color(0xFFF44336)),
        const SizedBox(height: 24),
        const Text(
          'Payment Failed',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Retry Payment',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: onCancel,
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Cancelled ─────────────────────────────────────────────────────────────────

class _CancelledView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _CancelledView({required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cancel_outlined, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 24),
        const Text(
          'Payment Cancelled',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'You cancelled the payment. No money was deducted.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: onBack,
            child: const Text(
              'Go Back',
              style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
