class CashfreeOrder {
  final String orderId;
  final String paymentSessionId;
  final String orderStatus;

  const CashfreeOrder({
    required this.orderId,
    required this.paymentSessionId,
    required this.orderStatus,
  });

  factory CashfreeOrder.fromJson(Map<String, dynamic> json) => CashfreeOrder(
        orderId:          json['order_id'] as String,
        paymentSessionId: json['payment_session_id'] as String,
        orderStatus:      json['order_status'] as String,
      );
}

class CashfreePaymentStatus {
  final String orderId;
  final String orderStatus; // PAID | ACTIVE | EXPIRED | CANCELLED
  final double orderAmount;
  final String orderCurrency;
  final String? paymentStatus;
  final String? paymentMessage;
  final Map<String, dynamic>? errorDetails;
  final String? failureReasonFromBackend;

  const CashfreePaymentStatus({
    required this.orderId,
    required this.orderStatus,
    required this.orderAmount,
    required this.orderCurrency,
    this.paymentStatus,
    this.paymentMessage,
    this.errorDetails,
    this.failureReasonFromBackend,
  });

  bool get isPaid => orderStatus == 'PAID';

  bool get hasDetailedFailureReason =>
      (failureReasonFromBackend?.trim().isNotEmpty ?? false) ||
      (paymentMessage?.trim().isNotEmpty ?? false) ||
      errorDetails?.isNotEmpty == true;

  factory CashfreePaymentStatus.fromJson(Map<String, dynamic> json) =>
      CashfreePaymentStatus(
        orderId:       json['order_id'] as String,
        orderStatus:   json['order_status'] as String,
        orderAmount:   (json['order_amount'] as num).toDouble(),
        orderCurrency: json['order_currency'] as String,
        paymentStatus: json['payment_status'] as String?,
        paymentMessage: json['payment_message'] as String?,
        errorDetails: (json['error_details'] as Map?)?.cast<String, dynamic>(),
        failureReasonFromBackend: json['failure_reason'] as String?,
      );

  String get failureReason {
    final backendReason = failureReasonFromBackend?.trim();
    if (backendReason != null && backendReason.isNotEmpty) return backendReason;

    final message = paymentMessage?.trim();
    if (message != null && message.isNotEmpty) return message;

    final details = errorDetails;
    if (details != null) {
      for (final key in ['error_description', 'error_reason', 'error_code']) {
        final value = details[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }

    return 'Payment status: $orderStatus';
  }
}
