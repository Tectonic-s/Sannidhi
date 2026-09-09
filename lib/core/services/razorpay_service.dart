import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  RazorpayService._();
  static final RazorpayService instance = RazorpayService._();

  // ── Sandbox key — replace with your live key before production ──────────────
  // Get yours at https://dashboard.razorpay.com → Settings → API Keys
  static const _keyId = 'rzp_test_XXXXXXXXXXXXXXXX';

  Razorpay? _rzp;

  void Function(PaymentSuccessResponse)? _onSuccess;
  void Function(PaymentFailureResponse)? _onFailure;

  /// Call once (e.g. in initState) to wire up the SDK.
  void init() {
    _rzp = Razorpay();
    _rzp!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _rzp!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _rzp!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Call in dispose() to free resources.
  void dispose() {
    _rzp?.clear();
    _rzp = null;
  }

  /// Opens the Razorpay checkout sheet.
  ///
  /// [amountInRupees] — pass rupees, we convert to paise internally.
  /// [description]    — shown on the checkout screen.
  /// [onSuccess]      — called with the payment ID on success.
  /// [onFailure]      — called with the error message on failure.
  void open({
    required double amountInRupees,
    required String description,
    required void Function(String paymentId) onSuccess,
    required void Function(String message) onFailure,
    String prefillName = '',
    String prefillContact = '',
    String prefillEmail = '',
  }) {
    assert(_rzp != null,
        'RazorpayService.init() must be called before open()');

    _onSuccess = (res) => onSuccess(res.paymentId ?? '');
    _onFailure = (res) => onFailure(res.message ?? 'Payment failed');

    final options = {
      'key': _keyId,
      'amount': (amountInRupees * 100).toInt(), // Razorpay expects paise
      'name': 'Marudamalai Devasthanam',
      'description': description,
      'currency': 'INR',
      'prefill': {
        'name': prefillName,
        'contact': prefillContact,
        'email': prefillEmail,
      },
      'theme': {'color': '#800000'}, // temple maroon
      'modal': {
        'ondismiss': () => onFailure('Payment cancelled'),
      },
    };

    _rzp!.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse res) =>
      _onSuccess?.call(res);

  void _handleFailure(PaymentFailureResponse res) =>
      _onFailure?.call(res);

  void _handleExternalWallet(ExternalWalletResponse res) {
    // External wallet selected — fire the failure callback with a message
    _onFailure?.call(PaymentFailureResponse(0, 'External wallet: ${res.walletName}', {}));
  }
}
