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

/// Backend URL can be overridden at build time with:
/// --dart-define=BACKEND_BASE_URL=https://your-public-backend.example.com
/// Android emulator  → http://10.0.2.2:3000
/// Real device       → http://192.168.1.12:3000
/// iOS simulator     → http://127.0.0.1:3000
const String _backendBaseUrl = String.fromEnvironment(
  'BACKEND_BASE_URL',
  defaultValue: 'http://192.168.1.12:3000',
);

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
      return (
        result:  CashfreePaymentResult.failure,
        orderId: '',
        message: 'Could not create order: $e',
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

    // ── Step 3: Verify on backend ─────────────────────────────────────────────
    try {
      final status = await _verifyOrder(order.orderId);
      if (status.isPaid) {
        return (
          result:  CashfreePaymentResult.success,
          orderId: order.orderId,
          message: 'Payment successful',
        );
      } else {
        return (
          result:  CashfreePaymentResult.failure,
          orderId: order.orderId,
          message: 'Payment failed: ${status.hasDetailedFailureReason ? status.failureReason : checkoutResult.message ?? status.failureReason}',
        );
      }
    } catch (e) {
      return (
        result:  CashfreePaymentResult.failure,
        orderId: order.orderId,
        message: 'Verification failed: $e',
      );
    }
  }

  Future<void> _wakeBackend() async {
    final response = await http
        .get(Uri.parse('$_backendBaseUrl/health'))
        .timeout(const Duration(seconds: 45));

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
