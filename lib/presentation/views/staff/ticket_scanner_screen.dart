import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/firebase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_activity_provider.dart';

enum _VerifyState { idle, loading, success, alreadyUsed, invalid, expired }

class TicketScannerScreen extends StatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  State<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends State<TicketScannerScreen> {
  final _inputController = TextEditingController();
  _VerifyState _state = _VerifyState.idle;
  String? _message;
  Map<String, dynamic>? _ticketData;
  Map<String, dynamic>? _bookingData;

  final List<Map<String, dynamic>> _scanHistory = [];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _verifyPass(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _state = _VerifyState.loading;
      _message = null;
    });

    final auth = context.read<AuthProvider>();

    final activity = context.read<UserActivityProvider>();

    // 1. Check Cloud Firestore gate verifier
    if (FirebaseService.instance.isInitialized) {
      final user = auth.currentUser;
      final fbResult = await FirebaseService.instance.verifyTicketAtGate(
        qrPayloadOrTicketId: trimmed,
        staffId: user?.id ?? 'staff_01',
        staffName: user?.name ?? 'Gate Staff',
      );

      if (fbResult.status == 'VERIFIED') {
        activity.markTicketUsed(fbResult.ticketId ?? trimmed, verifiedBy: user?.name);
        setState(() {
          _state = _VerifyState.success;
          _message = fbResult.message;
          _ticketData = {
            'ticket_id': fbResult.ticketId ?? trimmed,
            'ticket_label': fbResult.ticketId ?? trimmed,
            'slot_time': fbResult.slotTime ?? 'Live Slot',
          };
          _bookingData = {
            'booking_id': fbResult.bookingId ?? 'BK-CLOUD',
            'devotee_name': fbResult.devoteeName ?? 'Devotee',
          };
          _scanHistory.insert(0, {
            'status': 'VALID',
            'time': DateTime.now(),
            'label': fbResult.ticketId ?? trimmed,
            'devotee': fbResult.devoteeName ?? 'Devotee',
          });
        });
        return;
      } else if (fbResult.status == 'ALREADY_USED') {
        activity.markTicketUsed(fbResult.ticketId ?? trimmed, verifiedBy: user?.name);
        setState(() {
          _state = _VerifyState.alreadyUsed;
          _message = fbResult.message;
          _ticketData = {
            'ticket_id': fbResult.ticketId ?? trimmed,
            'ticket_label': fbResult.ticketId ?? trimmed,
            'slot_time': fbResult.slotTime ?? 'Live Slot',
          };
          _bookingData = {
            'booking_id': fbResult.bookingId ?? 'BK-CLOUD',
            'devotee_name': fbResult.devoteeName ?? 'Devotee',
          };
          _scanHistory.insert(0, {
            'status': 'ALREADY_USED',
            'time': DateTime.now(),
            'label': fbResult.ticketId ?? trimmed,
            'devotee': fbResult.devoteeName ?? 'Devotee',
          });
        });
        _showAlreadyScannedDialog(
          ticketId: fbResult.ticketId ?? trimmed,
          ticketLabel: fbResult.ticketId ?? trimmed,
          slotTime: fbResult.slotTime ?? 'Live Slot',
          bookingId: fbResult.bookingId ?? 'BK-CLOUD',
          devoteeName: fbResult.devoteeName ?? 'Devotee',
        );
        return;
      } else if (fbResult.status == 'EXPIRED') {
        setState(() {
          _state = _VerifyState.expired;
          _message = fbResult.message;
          _ticketData = {
            'ticket_id': fbResult.ticketId ?? trimmed,
            'ticket_label': fbResult.ticketId ?? trimmed,
            'slot_time': fbResult.slotTime ?? 'Expired Slot',
          };
          _bookingData = {
            'booking_id': fbResult.bookingId ?? 'BK-EXPIRED',
            'devotee_name': fbResult.devoteeName ?? 'Devotee',
          };
          _scanHistory.insert(0, {
            'status': 'EXPIRED',
            'time': DateTime.now(),
            'label': fbResult.ticketId ?? trimmed,
            'devotee': fbResult.devoteeName ?? 'Devotee',
          });
        });
        return;
      }
    }

    // 2. Fallback to Express backend or local verification
    try {
      final response = await http.post(
        Uri.parse('${AuthProvider.backendUrl}/api/bookings/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: jsonEncode({
          'qr_payload': trimmed,
          'ticket_id': trimmed,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['valid'] == true) {
        final t = data['ticket'] as Map<String, dynamic>?;
        final verifiedId = t?['id'] ?? trimmed;
        activity.markTicketUsed(verifiedId, verifiedBy: auth.currentUser?.name);

        setState(() {
          _state = _VerifyState.success;
          _message = data['message'] as String?;
          _ticketData = t;
          _bookingData = data['booking'] as Map<String, dynamic>?;
          _scanHistory.insert(0, {
            'status': 'VALID',
            'time': DateTime.now(),
            'label': _ticketData?['ticket_label'] ?? trimmed,
            'devotee': _bookingData?['devotee_name'] ?? 'Devotee',
          });
        });
      } else if (data['status'] == 'USED') {
        final t = data['ticket'] as Map<String, dynamic>?;
        final usedId = t?['id'] ?? trimmed;
        activity.markTicketUsed(usedId, verifiedBy: auth.currentUser?.name);

        setState(() {
          _state = _VerifyState.alreadyUsed;
          _message = data['message'] as String? ?? 'Pass already used';
          _ticketData = t;
          _bookingData = data['booking'] as Map<String, dynamic>?;
          _scanHistory.insert(0, {
            'status': 'ALREADY_USED',
            'time': DateTime.now(),
            'label': _ticketData?['ticket_label'] ?? trimmed,
            'devotee': _bookingData?['devotee_name'] ?? 'Devotee',
          });
        });
        _showAlreadyScannedDialog(
          ticketId: usedId,
          ticketLabel: t?['ticket_label'] ?? trimmed,
          slotTime: (data['booking'] as Map<String, dynamic>?)?['slot_time'] ?? 'Live Slot',
          bookingId: (data['booking'] as Map<String, dynamic>?)?['id'] ?? 'BK-SERVER',
          devoteeName: _bookingData?['devotee_name'] ?? 'Devotee',
        );
      } else if (data['status'] == 'EXPIRED') {
        setState(() {
          _state = _VerifyState.expired;
          _message = data['message'] as String? ?? 'Pass has expired';
          _ticketData = data['ticket'] as Map<String, dynamic>?;
          _bookingData = data['booking'] as Map<String, dynamic>?;
          _scanHistory.insert(0, {
            'status': 'EXPIRED',
            'time': DateTime.now(),
            'label': _ticketData?['ticket_label'] ?? trimmed,
            'devotee': _bookingData?['devotee_name'] ?? 'Devotee',
          });
        });
      } else {
        setState(() {
          _state = _VerifyState.invalid;
          _message = data['message'] as String? ?? 'Invalid Pass';
          _ticketData = null;
          _bookingData = null;
        });
      }
    } catch (e) {
      setState(() {
        _state = _VerifyState.invalid;
        _message = 'Network error connecting to verification server.';
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _VerifyState.idle;
      _message = null;
      _ticketData = null;
      _bookingData = null;
      _inputController.clear();
    });
  }

  void _showAlreadyScannedDialog({
    required String ticketId,
    required String ticketLabel,
    required String slotTime,
    required String bookingId,
    required String devoteeName,
  }) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();

    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(dialogCtx),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFDC2626),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isTamil ? 'பாஸ் ஏற்கனவே ஸ்கேன் செய்யப்பட்டது!' : 'PASS ALREADY SCANNED!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isTamil ? 'நுழைவு நிராகரிக்கப்பட்டது • USED' : 'ENTRY REJECTED • ALREADY USED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  children: [
                    Text(
                      isTamil
                          ? 'இந்த பாஸ் ஏற்கனவே வாயிலில் சரிபார்க்கப்பட்டு அனுமதிக்கப்பட்டுள்ளது. மறுமுறை அனுமதி வழங்கப்படாது!'
                          : 'This pass has ALREADY been verified and admitted at the gate. Duplicate entry is strictly prohibited!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimaryOf(dialogCtx),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.qr_code_rounded, size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Text(isTamil ? 'பாஸ் எண்' : 'Pass ID', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryOf(dialogCtx), fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(ticketId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            children: [
                              Icon(Icons.confirmation_number_outlined, size: 16, color: AppTheme.textSecondaryOf(dialogCtx)),
                              const SizedBox(width: 8),
                              Text(isTamil ? 'வகை' : 'Pass Type', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryOf(dialogCtx), fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(ticketLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(dialogCtx))),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondaryOf(dialogCtx)),
                              const SizedBox(width: 8),
                              Text(isTamil ? 'நேரம்' : 'Slot Time', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryOf(dialogCtx), fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(slotTime, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(dialogCtx))),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textSecondaryOf(dialogCtx)),
                              const SizedBox(width: 8),
                              Text(isTamil ? 'பக்தர் / முன்பதிவு' : 'Devotee / Ref', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryOf(dialogCtx), fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text('$devoteeName (#$bookingId)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(dialogCtx))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          _reset();
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                        label: Text(
                          isTamil ? 'அடுத்த பாஸை ஸ்கேன் செய்' : 'Scan Next Pass',
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'வாயில் சரிபார்ப்பு' : 'Gate Pass Verifier'),
        backgroundColor: const Color(0xFFD97706),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header / Verifier info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFD97706).withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.security, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTamil ? 'அதிகாரப்பூர்வ சரிபார்ப்பு முறைமை' : 'Authorized Gatekeeper Check-In',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      Text(
                        isTamil
                            ? 'பாஸை சரிபார்க்க QR தரவு அல்லது டிக்கெட் குறியீட்டை உள்ளிடவும்'
                            : 'Enter QR payload or Ticket ID to check validity',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Input Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'QR தரவு / டிக்கெட் ஐடி' : 'QR Payload / Ticket ID',
                          hintText: 'e.g. SANNIDHI|DRS|MRD-DRS-... or ticket ID',
                          prefixIcon: const Icon(Icons.qr_code_scanner),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _inputController.clear(),
                          ),
                        ),
                        onSubmitted: _verifyPass,
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.verified_user),
                        label: Text(
                          isTamil ? 'பாஸை சரிபார்க்கவும்' : 'Verify Pass',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                        ),
                        onPressed: _state == _VerifyState.loading
                            ? null
                            : () => _verifyPass(_inputController.text),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Status Card
                if (_state == _VerifyState.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: Color(0xFFD97706)),
                    ),
                  )
                else if (_state != _VerifyState.idle)
                  _buildResultCard(isTamil),

                const SizedBox(height: 20),

                // Recent Scans
                if (_scanHistory.isNotEmpty) ...[
                  Text(
                    isTamil ? 'சமீபத்திய சரிபார்ப்புகள்' : 'Recent Verifications (This Session)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._scanHistory.map((item) {
                    final isValid = item['status'] == 'VALID';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                            color: isValid ? AppColors.success : AppColors.error,
                            width: 4,
                          ),
                          top: BorderSide(color: AppTheme.borderColor(context)),
                          right: BorderSide(color: AppTheme.borderColor(context)),
                          bottom: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryOf(context),
                                ),
                              ),
                              Text(
                                'Devotee: ${item['devotee']}',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isValid
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isValid ? 'VERIFIED' : 'USED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isValid ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(bool isTamil) {
    Color bg;
    Color border;
    IconData icon;
    String header;

    switch (_state) {
      case _VerifyState.success:
        bg = const Color(0xFFE8F5E9);
        border = AppColors.success;
        icon = Icons.check_circle;
        header = isTamil ? 'ஏற்றுக்கொள்ளப்பட்டது (VALID PASS)' : 'ENTRY PERMITTED - VALID PASS';
        break;
      case _VerifyState.alreadyUsed:
        bg = const Color(0xFFFFF3E0);
        border = const Color(0xFFF57C00);
        icon = Icons.warning_amber;
        header = isTamil ? 'ஏற்கனவே பயன்படுத்தப்பட்டது' : 'ALREADY USED - DUPLICATE SCAN';
        break;
      case _VerifyState.expired:
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFDC2626);
        icon = Icons.timer_off_rounded;
        header = isTamil ? 'காலாவதியான பாஸ் (EXPIRED)' : 'PASS EXPIRED - ENTRY DENIED';
        break;
      case _VerifyState.invalid:
      default:
        bg = const Color(0xFFFFEBEE);
        border = AppColors.error;
        icon = Icons.cancel;
        header = isTamil ? 'செல்லுபடியாகாத பாஸ்' : 'INVALID PASS - ENTRY DENIED';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: border, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  header,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: border),
                ),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(
              _message!,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: border),
            ),
          ],
          if (_bookingData != null) ...[
            const Divider(height: 24),
            _infoRow('Devotee Name', _bookingData!['devotee_name'] ?? 'Devotee'),
            _infoRow('Pass Type', _bookingData!['title'] ?? _bookingData!['type'] ?? ''),
            _infoRow('Slot Time', _bookingData!['slot_time'] ?? ''),
            _infoRow('Date', _bookingData!['date'] ?? ''),
            _infoRow('Ticket ID', _ticketData?['id'] ?? ''),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryOf(context)),
            ),
          ),
          Text(': ', style: TextStyle(color: AppTheme.textSecondaryOf(context))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context)),
            ),
          ),
        ],
      ),
    );
  }
}
