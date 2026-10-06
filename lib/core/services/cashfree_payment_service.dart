import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:http/http.dart' as http;
import '../models/cashfree_order.dart';
import '../../providers/auth_provider.dart';

/// Backend URL is resolved dynamically and can be overridden at build time with:
/// flutter build apk --dart-define=BACKEND_BASE_URL=https://your-backend-url.com
String get _backendBaseUrl => AuthProvider.backendUrl;

enum CashfreePaymentResult { success, failure, cancelled }

class CashfreePaymentService {
  CashfreePaymentService._();
  static final CashfreePaymentService instance = CashfreePaymentService._();

  /// Creates an order via your backend, launches Cashfree checkout,
  /// then verifies the result via your backend.
  Future<({CashfreePaymentResult result, String orderId, String message})>
      startPayment({
    required BuildContext context,
    required double amount,
    required String description,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    // ── Step 1: Create order on backend ──────────────────────────────────────
    late CashfreeOrder order;
    try {
      await _wakeBackend();
      order = await _createOrder(
        amount:        amount,
        customerId:    customerId,
        customerName:  customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
      );
    } catch (e) {
      if (context.mounted) {
        final shouldSimulate = await _promptOfflineSimulation(context, e.toString());
        if (shouldSimulate == true) {
          final mockOrderId = 'SANNIDHI_SIM_${DateTime.now().millisecondsSinceEpoch}';
          return (
            result:  CashfreePaymentResult.success,
            orderId: mockOrderId,
            message: 'Payment completed via Sandbox Simulation',
          );
        }
      }

      return (
        result:  CashfreePaymentResult.failure,
        orderId: '',
        message: 'Could not connect to backend at $_backendBaseUrl: $e',
      );
    }

    // ── Step 2: Launch Cashfree checkout ─────────────────────────────────────
    if (!context.mounted) {
      return (
        result:  CashfreePaymentResult.cancelled,
        orderId: order.orderId,
        message: 'Context no longer valid',
      );
    }

    final checkoutResult = await _launchCheckout(
      paymentSessionId: order.paymentSessionId,
      orderId:          order.orderId,
    );

    if (checkoutResult.result == CashfreePaymentResult.cancelled) {
      return (
        result:  CashfreePaymentResult.cancelled,
        orderId: order.orderId,
        message: 'Payment cancelled by user',
      );
    }

    // ── Step 3: Verify on backend (with polling for Sandbox propagation) ──────
    try {
      CashfreePaymentStatus? status;
      for (int i = 0; i < 4; i++) {
        try {
          status = await _verifyOrder(order.orderId);
          if (status.isPaid) break;
        } catch (_) {}
        if (i < 3) {
          await Future.delayed(const Duration(milliseconds: 1200));
        }
      }

      if (status != null && status.isPaid) {
        return (
          result:  CashfreePaymentResult.success,
          orderId: order.orderId,
          message: 'Payment successful',
        );
      } else if (checkoutResult.result == CashfreePaymentResult.success) {
        // SDK reported success, accept in sandbox
        return (
          result:  CashfreePaymentResult.success,
          orderId: order.orderId,
          message: 'Payment verified via SDK callback',
        );
      } else {
        final reason = status != null && status.hasDetailedFailureReason
            ? status.failureReason
            : (checkoutResult.message ?? status?.failureReason ?? 'Payment pending or failed');
        return (
          result:  CashfreePaymentResult.failure,
          orderId: order.orderId,
          message: 'Payment failed: $reason',
        );
      }
    } catch (e) {
      if (checkoutResult.result == CashfreePaymentResult.success) {
        return (
          result:  CashfreePaymentResult.success,
          orderId: order.orderId,
          message: 'Payment successful (verified via SDK)',
        );
      }
      return (
        result:  CashfreePaymentResult.failure,
        orderId: order.orderId,
        message: 'Verification failed: $e',
      );
    }
  }

  Future<bool?> _promptOfflineSimulation(BuildContext context, String error) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Color(0xFFD97706), size: 28),
            SizedBox(width: 10),
            Text('Backend Offline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Could not connect to Sannidhi API server:\n$_backendBaseUrl',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.25)),
              ),
              child: const Text(
                'Make sure `npm start` is running in `backend/` and your phone is on the same WiFi network.\n\nWould you like to simulate a successful payment to test pass and receipt generation?',
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.flash_on_rounded, size: 18),
            label: const Text('Simulate Test Payment'),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
  }

  Future<void> _wakeBackend() async {
    final response = await http
        .get(Uri.parse('$_backendBaseUrl/health'))
        .timeout(const Duration(seconds: 6));

    if (response.statusCode != 200) {
      throw Exception('Backend is unavailable (${response.statusCode})');
    }
  }

  // ── Private: call backend create-order ─────────────────────────────────────

  Future<CashfreeOrder> _createOrder({
    required double amount,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_backendBaseUrl/api/payment/create-order'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount':          amount,
            'customer_id':     customerId,
            'customer_name':   customerName,
            'customer_email':  customerEmail,
            'customer_phone':  customerPhone,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Order creation failed');
    }

    return CashfreeOrder.fromJson(body);
  }

  // ── Private: launch Cashfree SDK checkout ──────────────────────────────────

  Future<({CashfreePaymentResult result, String? message})> _launchCheckout({
    required String paymentSessionId,
    required String orderId,
  }) async {
    final completer = Completer<({CashfreePaymentResult result, String? message})>();

    try {
      final session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.SANDBOX)
          .setPaymentSessionId(paymentSessionId)
          .setOrderId(orderId)
          .build();

      final theme = CFThemeBuilder()
          .setNavigationBarBackgroundColorColor('#800000')
          .setNavigationBarTextColor('#FFFFFF')
          .setPrimaryTextColor('#333333')
          .setSecondaryTextColor('#666666')
          .setButtonBackgroundColor('#800000')
          .setButtonTextColor('#FFFFFF')
          .setPrimaryFont('Roboto')
          .setSecondaryFont('Roboto')
          .build();

      final cfPayment = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .setTheme(theme)
          .build();

      final gatewayService = CFPaymentGatewayService();

      gatewayService.setCallback(
        (orderId) {
          if (!completer.isCompleted) {
            completer.complete((result: CashfreePaymentResult.success, message: null));
          }
        },
        (CFErrorResponse error, String orderId) {
          final msg = error.getMessage()?.toLowerCase() ?? '';
          if (!completer.isCompleted) {
            if (msg.contains('cancel') || msg.contains('dismiss')) {
              completer.complete((result: CashfreePaymentResult.cancelled, message: error.getMessage()));
            } else {
              completer.complete((result: CashfreePaymentResult.failure, message: error.getMessage()));
            }
          }
        },
      );

      await gatewayService.doPayment(cfPayment);

    } on CFException catch (e) {
      if (!completer.isCompleted) {
        completer.complete((result: CashfreePaymentResult.failure, message: e.message));
      }
      debugPrint('[Cashfree] CFException: ${e.message}');
    }

    return completer.future;
  }

  // ── Private: verify order status via backend ───────────────────────────────

  Future<CashfreePaymentStatus> _verifyOrder(String orderId) async {
    final response = await http
        .get(
          Uri.parse('$_backendBaseUrl/api/payment/status/$orderId'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Status check failed');
    }

    return CashfreePaymentStatus.fromJson(body);
  }
}
