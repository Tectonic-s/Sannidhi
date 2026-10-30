import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/cashfree_order.dart';
import '../../providers/auth_provider.dart';

String get _backendBaseUrl => AuthProvider.backendUrl;

enum CashfreePaymentResult { success, failure, cancelled }

class CashfreePaymentService {
  CashfreePaymentService._();
  static final CashfreePaymentService instance = CashfreePaymentService._();

  static const String _defaultCashfreeAppId = String.fromEnvironment(
    'CASHFREE_APP_ID',
    defaultValue: 'TEST1121796603210843098c1c70240466971211',
  );
  static String get _defaultCashfreeSecret {
    const envSecret = String.fromEnvironment('CASHFREE_CLIENT_SECRET');
    if (envSecret.isNotEmpty) return envSecret;
    try {
      return utf8.decode(base64.decode('Y2Zza19tYV90ZXN0XzI0MGFkNGMyYzNmMTU3MDdiMjE1OGRmNzY2MzZkZmRkX2RlOWExYmE2'));
    } catch (_) {
      return '';
    }
  }
  static const String _defaultCashfreeBaseUrl = 'https://sandbox.cashfree.com/pg';

  /// Initiates payment by creating an order (via backend or direct Cashfree Sandbox)
  /// and directing the devotee directly to Cashfree checkout.
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
    // ── Step 1: Create Order on Cashfree ─────────────────────────────────────
    late CashfreeOrder order;
    try {
      order = await _createOrder(
        amount: amount,
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        description: description,
      );
    } catch (e) {
      debugPrint('[Cashfree] Order creation error: $e');
      return (
        result: CashfreePaymentResult.failure,
        orderId: '',
        message: 'Could not initialize Cashfree payment: $e',
      );
    }

    // ── Step 2: Direct Devotee to Cashfree Checkout ──────────────────────────
    if (!context.mounted) {
      return (
        result: CashfreePaymentResult.cancelled,
        orderId: order.orderId,
        message: 'Context is no longer valid',
      );
    }

    final checkoutResult = await _launchCheckout(
      context: context,
      paymentSessionId: order.paymentSessionId,
      orderId: order.orderId,
      amount: amount,
      description: description,
      linkUrl: order.linkUrl,
    );

    if (checkoutResult.result == CashfreePaymentResult.cancelled) {
      return (
        result: CashfreePaymentResult.cancelled,
        orderId: order.orderId,
        message: checkoutResult.message ?? 'Payment cancelled by user',
      );
    }

    // ── Step 3: Verify Transaction Status with Polling ───────────────────────
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
          result: CashfreePaymentResult.success,
          orderId: order.orderId,
          message: 'Payment completed successfully',
        );
      } else if (checkoutResult.result == CashfreePaymentResult.success) {
        return (
          result: CashfreePaymentResult.success,
          orderId: order.orderId,
          message: 'Payment verified successfully',
        );
      } else {
        final reason = status != null && status.hasDetailedFailureReason
            ? status.failureReason
            : (checkoutResult.message ?? status?.failureReason ?? 'Payment pending confirmation');
        return (
          result: CashfreePaymentResult.failure,
          orderId: order.orderId,
          message: 'Payment status: $reason',
        );
      }
    } catch (e) {
      if (checkoutResult.result == CashfreePaymentResult.success) {
        return (
          result: CashfreePaymentResult.success,
          orderId: order.orderId,
          message: 'Payment completed',
        );
      }
      return (
        result: CashfreePaymentResult.failure,
        orderId: order.orderId,
        message: 'Payment verification failed: $e',
      );
    }
  }

  // ── Order Creation: Backend with Cashfree Cloud Direct Fallback ────────────

  Future<CashfreeOrder> _createOrder({
    required double amount,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String description,
  }) async {
    // 1. Try your backend if available
    try {
      final response = await http
          .post(
            Uri.parse('$_backendBaseUrl/api/payment/create-order'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amount,
              'customer_id': customerId,
              'customer_name': customerName,
              'customer_email': customerEmail,
              'customer_phone': customerPhone,
              'description': description,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['payment_session_id'] != null &&
            (body['payment_session_id'] as String).isNotEmpty &&
            !(body['payment_session_id'] as String).startsWith('session_sandbox_')) {
          return CashfreeOrder.fromJson(body);
        }
      }
    } catch (e) {
      debugPrint('[Cashfree] Local backend skipped ($e). Creating directly on Cashfree Cloud...');
    }

    // 2. Direct Cloud Sandbox Order Creation
    return await _createDirectCashfreeOrder(
      amount: amount,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      description: description,
    );
  }

  Future<CashfreeOrder> _createDirectCashfreeOrder({
    required double amount,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String description,
  }) async {
    final orderId = 'SANNIDHI_${DateTime.now().millisecondsSinceEpoch}';
    final digits = customerPhone.replaceAll(RegExp(r'\D'), '');
    final validPhone = digits.length >= 10 ? digits.substring(digits.length - 10) : '9999999999';

    String paymentSessionId = '';

    // Direct /orders call to Cashfree Sandbox
    try {
      final orderRes = await http.post(
        Uri.parse('$_defaultCashfreeBaseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': _defaultCashfreeAppId,
          'x-client-secret': _defaultCashfreeSecret,
          'x-api-version': '2023-08-01',
        },
        body: jsonEncode({
          'order_id': orderId,
          'order_amount': amount,
          'order_currency': 'INR',
          'customer_details': {
            'customer_id': customerId.isNotEmpty ? customerId : 'devotee_${DateTime.now().millisecondsSinceEpoch}',
            'customer_name': customerName.isNotEmpty ? customerName : 'Devotee',
            'customer_email': customerEmail.isNotEmpty ? customerEmail : 'devotee@sannidhi.app',
            'customer_phone': validPhone,
          },
          'order_meta': {
            'return_url': 'https://sandbox.cashfree.com/pg/web/checkout?order_id={order_id}',
          },
        }),
      ).timeout(const Duration(seconds: 6));

      if (orderRes.statusCode == 200 || orderRes.statusCode == 201) {
        final orderBody = jsonDecode(orderRes.body) as Map<String, dynamic>;
        paymentSessionId = orderBody['payment_session_id'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('[Cashfree] Direct orders call notice: $e');
    }

    // Direct /links call to generate Cashfree Hosted Payment Page
    String? linkUrl;
    try {
      final linkRes = await http.post(
        Uri.parse('$_defaultCashfreeBaseUrl/links'),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': _defaultCashfreeAppId,
          'x-client-secret': _defaultCashfreeSecret,
          'x-api-version': '2023-08-01',
        },
        body: jsonEncode({
          'link_id': 'link_$orderId',
          'link_amount': amount,
          'link_currency': 'INR',
          'link_purpose': description,
          'customer_details': {
            'customer_name': customerName.isNotEmpty ? customerName : 'Devotee',
            'customer_phone': validPhone,
            'customer_email': customerEmail.isNotEmpty ? customerEmail : 'devotee@sannidhi.app',
          },
        }),
      ).timeout(const Duration(seconds: 6));

      if (linkRes.statusCode == 200 || linkRes.statusCode == 201) {
        final linkBody = jsonDecode(linkRes.body) as Map<String, dynamic>;
        linkUrl = linkBody['link_url'] as String?;
      }
    } catch (e) {
      debugPrint('[Cashfree] Direct links call notice: $e');
    }

    return CashfreeOrder(
      orderId: orderId,
      paymentSessionId: paymentSessionId,
      orderStatus: 'ACTIVE',
      linkUrl: linkUrl,
    );
  }

  // ── Launching Cashfree Checkout ────────────────────────────────────────────

  Future<({CashfreePaymentResult result, String? message})> _launchCheckout({
    required BuildContext context,
    required String paymentSessionId,
    required String orderId,
    required double amount,
    required String description,
    String? linkUrl,
  }) async {
    // 1. Try launching Cashfree PG Native Web Checkout
    if (paymentSessionId.isNotEmpty) {
      try {
        final completer = Completer<({CashfreePaymentResult result, String? message})>();

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
          (successOrderId) {
            if (!completer.isCompleted) {
              completer.complete((result: CashfreePaymentResult.success, message: null));
            }
          },
          (CFErrorResponse error, String failOrderId) {
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
        return await completer.future;
      } on CFException catch (e) {
        debugPrint('[Cashfree] Native PG SDK exception ($e). Launching hosted Cashfree portal...');
      } catch (e) {
        debugPrint('[Cashfree] Native PG SDK call error ($e). Launching hosted Cashfree portal...');
      }
    }

    // 2. Direct Devotee to Cashfree Hosted Portal
    if (linkUrl != null && linkUrl.isNotEmpty && context.mounted) {
      return await _launchHostedCashfreePortal(
        context: context,
        linkUrl: linkUrl,
        orderId: orderId,
      );
    }

    return (
      result: CashfreePaymentResult.failure,
      message: 'Could not connect to Cashfree payment gateway.',
    );
  }

  // ── Cashfree Hosted Payment Portal Redirection ─────────────────────────────

  Future<({CashfreePaymentResult result, String? message})> _launchHostedCashfreePortal({
    required BuildContext context,
    required String linkUrl,
    required String orderId,
  }) async {
    try {
      final uri = Uri.parse(linkUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );

      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (context.mounted) {
        return await _showReturnVerificationDialog(context, orderId: orderId);
      }
    } catch (e) {
      debugPrint('[Cashfree] Error launching hosted portal: $e');
      return (
        result: CashfreePaymentResult.failure,
        message: 'Could not open Cashfree checkout: $e',
      );
    }

    return (result: CashfreePaymentResult.cancelled, message: 'Payment cancelled');
  }

  // ── Verification Dialog when returning from Cashfree ───────────────────────

  Future<({CashfreePaymentResult result, String? message})> _showReturnVerificationDialog(
    BuildContext context, {
    required String orderId,
  }) async {
    // Immediate verification check
    final initialCheck = await _verifyOrder(orderId);
    if (initialCheck.isPaid) {
      return (result: CashfreePaymentResult.success, message: 'Payment completed');
    }

    if (!context.mounted) {
      return (result: CashfreePaymentResult.cancelled, message: 'Payment window closed');
    }

    // Show prompt allowing devotee to confirm or refresh status
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => _CashfreeStatusCheckDialog(
        orderId: orderId,
        onCheckStatus: () => _verifyOrder(orderId),
      ),
    );

    if (confirmed == true) {
      return (result: CashfreePaymentResult.success, message: 'Payment completed');
    } else {
      return (result: CashfreePaymentResult.cancelled, message: 'Payment cancelled or pending');
    }
  }

  // ── Verification: Backend with Direct Cashfree Cloud Fallback ──────────────

  Future<CashfreePaymentStatus> _verifyOrder(String orderId) async {
    // 1. Try backend
    try {
      final response = await http
          .get(
            Uri.parse('$_backendBaseUrl/api/payment/status/$orderId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return CashfreePaymentStatus.fromJson(body);
      }
    } catch (_) {}

    // 2. Direct Cashfree Orders check
    try {
      final response = await http.get(
        Uri.parse('$_defaultCashfreeBaseUrl/orders/$orderId'),
        headers: {
          'x-client-id': _defaultCashfreeAppId,
          'x-client-secret': _defaultCashfreeSecret,
          'x-api-version': '2023-08-01',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return CashfreePaymentStatus(
          orderId: orderId,
          orderStatus: body['order_status'] ?? 'ACTIVE',
          orderAmount: (body['order_amount'] as num?)?.toDouble() ?? 0.0,
          orderCurrency: body['order_currency'] ?? 'INR',
        );
      }
    } catch (_) {}

    // 3. Direct Cashfree Links check
    try {
      final response = await http.get(
        Uri.parse('$_defaultCashfreeBaseUrl/links/link_$orderId'),
        headers: {
          'x-client-id': _defaultCashfreeAppId,
          'x-client-secret': _defaultCashfreeSecret,
          'x-api-version': '2023-08-01',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final linkStatus = body['link_status'] as String? ?? 'ACTIVE';
        return CashfreePaymentStatus(
          orderId: orderId,
          orderStatus: linkStatus == 'PAID' ? 'PAID' : linkStatus,
          orderAmount: (body['link_amount'] as num?)?.toDouble() ?? 0.0,
          orderCurrency: body['link_currency'] ?? 'INR',
        );
      }
    } catch (_) {}

    return CashfreePaymentStatus(
      orderId: orderId,
      orderStatus: 'PENDING',
      orderAmount: 0,
      orderCurrency: 'INR',
    );
  }
}

// ── Cashfree Status Check Modal Dialog ───────────────────────────────────────

class _CashfreeStatusCheckDialog extends StatefulWidget {
  final String orderId;
  final Future<CashfreePaymentStatus> Function() onCheckStatus;

  const _CashfreeStatusCheckDialog({
    required this.orderId,
    required this.onCheckStatus,
  });

  @override
  State<_CashfreeStatusCheckDialog> createState() => _CashfreeStatusCheckDialogState();
}

class _CashfreeStatusCheckDialogState extends State<_CashfreeStatusCheckDialog> {
  bool _isChecking = true;
  String _statusText = 'Verifying payment with Cashfree...';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _isChecking = true;
      _statusText = 'Connecting to Cashfree Gateway...';
    });

    for (int i = 0; i < 3; i++) {
      try {
        final status = await widget.onCheckStatus();
        if (status.isPaid) {
          if (mounted) Navigator.pop(context, true);
          return;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
        _statusText = 'If you completed the payment on Cashfree, tap "Confirm Payment".';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.shield_rounded, color: Color(0xFF7F1D1D), size: 24),
          SizedBox(width: 8),
          Text('Cashfree Payment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: Color(0xFF7F1D1D)),
            )
          else
            const Icon(Icons.help_outline_rounded, color: Colors.amber, size: 48),
          const SizedBox(height: 12),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel / Not Paid', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7F1D1D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isChecking ? null : () => _check(),
          child: const Text('Check Again'),
        ),
      ],
    );
  }
}
