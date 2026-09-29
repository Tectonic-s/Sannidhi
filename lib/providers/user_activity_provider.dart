import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/activity_models.dart';
import '../core/services/firebase_service.dart';
import '../core/services/notification_service.dart';
import 'auth_provider.dart';

class UserActivityProvider extends ChangeNotifier {
  // New booking lists
  final List<ShuttleBooking> _shuttleBookings = [];
  final List<DarshanBooking> _darshanBookings = [];
  final List<DonationReceipt> _donationReceipts = [];

  // Legacy lists (kept for backward compat with tax_receipt_service etc.)
  final List<ShuttleTicketModel> _shuttleTickets = [];
  final List<DarshanTicketModel> _darshanTickets = [];
  final List<DonationReceiptModel> _donations = [];

  UserActivityProvider() {
    loadFromLocal();
  }

  // ── New getters ─────────────────────────────────────────────────────────────

  List<ShuttleBooking> get shuttleBookings =>
      List.unmodifiable(_shuttleBookings);

  List<ShuttleBooking> get activeShuttleBookings =>
      _shuttleBookings.where((b) => !b.isCancelled).toList();

  List<DarshanBooking> get darshanBookings =>
      List.unmodifiable(_darshanBookings);

  List<DonationReceipt> get donationReceipts =>
      List.unmodifiable(_donationReceipts);

  // ── Legacy getters (used by existing screens) ───────────────────────────────

  List<ShuttleTicketModel> get shuttleTickets =>
      List.unmodifiable(_shuttleTickets);

  List<ShuttleTicketModel> get activeShuttleTickets =>
      _shuttleTickets.where((t) => !t.isCancelled).toList();

  List<DarshanTicketModel> get darshanTickets =>
      List.unmodifiable(_darshanTickets);

  List<DonationReceiptModel> get donations => List.unmodifiable(_donations);

  // ── Local Storage (SharedPreferences) ───────────────────────────────────────

  Future<void> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usedIds = (prefs.getStringList('sannidhi_used_ticket_ids') ?? []).toSet();

      // Load shuttle bookings
      final shuttleRaw = prefs.getString('sannidhi_shuttle_bookings');
      if (shuttleRaw != null) {
        final list = jsonDecode(shuttleRaw) as List<dynamic>;
        _shuttleBookings.clear();
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          final ticketsRaw = m['tickets'] as List<dynamic>? ?? [];
          final tickets = ticketsRaw.map((t) {
            final tid = t['ticketId'] ?? '';
            final qr = t['qrPayload'] ?? '';
            final isUsed = (t['isUsed'] == true) ||
                (t['status'] == 'USED') ||
                usedIds.contains(tid) ||
                usedIds.contains(qr);
            return IndividualTicket(
              ticketId: tid,
              qrPayload: qr,
              ticketLabel: t['ticketLabel'] ?? '',
              isUsed: isUsed,
              usedAt: t['usedAt'] != null ? DateTime.tryParse(t['usedAt']) : null,
              verifiedBy: t['verifiedBy'],
              slotTime: t['slotTime'] ?? m['slotTime'],
              date: t['date'] ?? m['date'],
            );
          }).toList();
          _shuttleBookings.add(ShuttleBooking(
            bookingId: m['bookingId'] ?? '',
            slotTime: m['slotTime'] ?? '',
            totalFare: (m['totalFare'] as num?)?.toDouble() ?? 0.0,
            seatCount: m['seatCount'] ?? 1,
            tickets: tickets,
            timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
            date: m['date'] ?? '',
            isCancelled: m['isCancelled'] ?? false,
          ));
        }
      }

      // Load darshan bookings
      final darshanRaw = prefs.getString('sannidhi_darshan_bookings');
      if (darshanRaw != null) {
        final list = jsonDecode(darshanRaw) as List<dynamic>;
        _darshanBookings.clear();
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          final ticketsRaw = m['tickets'] as List<dynamic>? ?? [];
          final tickets = ticketsRaw.map((t) {
            final tid = t['ticketId'] ?? '';
            final qr = t['qrPayload'] ?? '';
            final isUsed = (t['isUsed'] == true) ||
                (t['status'] == 'USED') ||
                usedIds.contains(tid) ||
                usedIds.contains(qr);
            return IndividualTicket(
              ticketId: tid,
              qrPayload: qr,
              ticketLabel: t['ticketLabel'] ?? '',
              isUsed: isUsed,
              usedAt: t['usedAt'] != null ? DateTime.tryParse(t['usedAt']) : null,
              verifiedBy: t['verifiedBy'],
              slotTime: t['slotTime'] ?? m['slotTime'],
              date: t['date'] ?? m['date'],
            );
          }).toList();
          _darshanBookings.add(DarshanBooking(
            bookingId: m['bookingId'] ?? '',
            darshanType: m['darshanType'] ?? 'Darshan',
            slotTime: m['slotTime'] ?? '',
            totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0.0,
            ticketCount: m['ticketCount'] ?? 1,
            tickets: tickets,
            timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
            date: m['date'] ?? '',
          ));
        }
      }

      // Load donations
      final donRaw = prefs.getString('sannidhi_donations');
      if (donRaw != null) {
        final list = jsonDecode(donRaw) as List<dynamic>;
        _donations.clear();
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          _donations.add(DonationReceiptModel(
            transactionId: m['transactionId'] ?? '',
            cause: m['cause'] ?? '',
            amount: m['amount'] ?? 0,
            timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
            qrPayload: m['qrPayload'] ?? '',
            ref80g: m['ref80g'] ?? '',
          ));
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[UserActivity] Error loading from SharedPreferences: $e');
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final shuttleJson = jsonEncode(_shuttleBookings
          .map((b) => {
                'bookingId': b.bookingId,
                'slotTime': b.slotTime,
                'totalFare': b.totalFare,
                'seatCount': b.seatCount,
                'date': b.date,
                'timestamp': b.timestamp.toIso8601String(),
                'isCancelled': b.isCancelled,
                'tickets': b.tickets
                    .map((t) => {
                          'ticketId': t.ticketId,
                          'qrPayload': t.qrPayload,
                          'ticketLabel': t.ticketLabel,
                          'isUsed': t.isUsed,
                          'usedAt': t.usedAt?.toIso8601String(),
                          'verifiedBy': t.verifiedBy,
                        })
                    .toList(),
              })
          .toList());
      await prefs.setString('sannidhi_shuttle_bookings', shuttleJson);

      final darshanJson = jsonEncode(_darshanBookings
          .map((b) => {
                'bookingId': b.bookingId,
                'darshanType': b.darshanType,
                'slotTime': b.slotTime,
                'totalAmount': b.totalAmount,
                'ticketCount': b.ticketCount,
                'date': b.date,
                'timestamp': b.timestamp.toIso8601String(),
                'tickets': b.tickets
                    .map((t) => {
                          'ticketId': t.ticketId,
                          'qrPayload': t.qrPayload,
                          'ticketLabel': t.ticketLabel,
                          'isUsed': t.isUsed,
                          'usedAt': t.usedAt?.toIso8601String(),
                          'verifiedBy': t.verifiedBy,
                        })
                    .toList(),
              })
          .toList());
      await prefs.setString('sannidhi_darshan_bookings', darshanJson);

      final donJson = jsonEncode(_donations
          .map((d) => {
                'transactionId': d.transactionId,
                'cause': d.cause,
                'amount': d.amount,
                'timestamp': d.timestamp.toIso8601String(),
                'qrPayload': d.qrPayload,
                'ref80g': d.ref80g,
              })
          .toList());
      await prefs.setString('sannidhi_donations', donJson);

      // Persist set of all used ticket IDs across the app
      final usedIds = <String>{};
      for (final b in _shuttleBookings) {
        for (final t in b.tickets) {
          if (t.isUsed) {
            usedIds.add(t.ticketId);
            usedIds.add(t.qrPayload);
          }
        }
      }
      for (final b in _darshanBookings) {
        for (final t in b.tickets) {
          if (t.isUsed) {
            usedIds.add(t.ticketId);
            usedIds.add(t.qrPayload);
          }
        }
      }
      final existingUsed = prefs.getStringList('sannidhi_used_ticket_ids') ?? [];
      usedIds.addAll(existingUsed);
      await prefs.setStringList('sannidhi_used_ticket_ids', usedIds.toList());
    } catch (e) {
      debugPrint('[UserActivity] Error saving to SharedPreferences: $e');
    }
  }

  // ── Sync with Backend ───────────────────────────────────────────────────────

  Future<void> syncFromBackend(String token) async {
    if (token.isEmpty) return;
    try {
      // Fetch bookings from backend SQLite
      final bResponse = await http.get(
        Uri.parse('${AuthProvider.backendUrl}/api/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (bResponse.statusCode == 200) {
        final bBody = jsonDecode(bResponse.body) as Map<String, dynamic>;
        final bookingsList = bBody['bookings'] as List<dynamic>? ?? [];

        for (final b in bookingsList) {
          final type = (b['type'] as String?)?.toUpperCase() ?? '';
          final bId = b['id'] as String;
          final ticketsData = (b['tickets'] as List<dynamic>? ?? []);
          final tickets = ticketsData
              .map((t) => IndividualTicket(
                    ticketId: t['id'] ?? '',
                    qrPayload: t['qr_payload'] ?? '',
                    ticketLabel: t['ticket_label'] ?? '',
                    isUsed: t['status'] == 'USED',
                    usedAt: t['verified_at'] != null ? DateTime.tryParse(t['verified_at']) : null,
                  ))
              .toList();

          if (type == 'SHUTTLE') {
            final existingIndex = _shuttleBookings.indexWhere((x) => x.bookingId == bId);
            if (existingIndex != -1) {
              for (final updatedTicket in tickets) {
                final tIndex = _shuttleBookings[existingIndex]
                    .tickets
                    .indexWhere((t) => t.ticketId == updatedTicket.ticketId);
                if (tIndex != -1 && updatedTicket.isUsed) {
                  _shuttleBookings[existingIndex].tickets[tIndex].isUsed = true;
                  _shuttleBookings[existingIndex].tickets[tIndex].usedAt = updatedTicket.usedAt;
                }
              }
            } else {
              _shuttleBookings.add(ShuttleBooking(
                bookingId: bId,
                slotTime: b['slot_time'] ?? '',
                totalFare: (b['total_amount'] as num?)?.toDouble() ?? 0.0,
                seatCount: b['tickets_count'] ?? 1,
                tickets: tickets,
                timestamp: DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now(),
                date: b['date'] ?? '',
                isCancelled: b['status'] == 'CANCELLED',
              ));
            }
          } else {
            final existingIndex = _darshanBookings.indexWhere((x) => x.bookingId == bId);
            if (existingIndex != -1) {
              for (final updatedTicket in tickets) {
                final tIndex = _darshanBookings[existingIndex]
                    .tickets
                    .indexWhere((t) => t.ticketId == updatedTicket.ticketId);
                if (tIndex != -1 && updatedTicket.isUsed) {
                  _darshanBookings[existingIndex].tickets[tIndex].isUsed = true;
                  _darshanBookings[existingIndex].tickets[tIndex].usedAt = updatedTicket.usedAt;
                }
              }
            } else {
              _darshanBookings.add(DarshanBooking(
                bookingId: bId,
                darshanType: b['title'] ?? 'Darshan',
                slotTime: b['slot_time'] ?? '',
                totalAmount: (b['total_amount'] as num?)?.toDouble() ?? 0.0,
                ticketCount: b['tickets_count'] ?? 1,
                tickets: tickets,
                timestamp: DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now(),
                date: b['date'] ?? '',
              ));
            }
          }
        }
      }

      // Fetch donations
      final dResponse = await http.get(
        Uri.parse('${AuthProvider.backendUrl}/api/donations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (dResponse.statusCode == 200) {
        final dBody = jsonDecode(dResponse.body) as Map<String, dynamic>;
        final donationsList = dBody['donations'] as List<dynamic>? ?? [];

        for (final d in donationsList) {
          final txId = d['transaction_id'] as String;
          if (!_donations.any((x) => x.transactionId == txId)) {
            _donations.add(DonationReceiptModel(
              transactionId: txId,
              cause: d['cause'] ?? '',
              amount: d['amount'] ?? 0,
              timestamp: DateTime.tryParse(d['created_at'] ?? '') ?? DateTime.now(),
              qrPayload: 'SANNIDHI|DONATION|$txId|${d['cause']}|₹${d['amount']}',
              ref80g: d['ref_80g'] ?? '80G/MRD/$txId',
            ));
          }
        }
      }

      await _saveToLocal();
      notifyListeners();
    } catch (e) {
      debugPrint('[UserActivity] Backend sync skipped: $e');
    }
  }

  // ── Add Methods ─────────────────────────────────────────────────────────────

  void addShuttleBooking(ShuttleBooking booking, {String? token, String? userId}) {
    _shuttleBookings.insert(0, booking);
    _saveToLocal();
    notifyListeners();

    // Async push to Cloud Firestore
    FirebaseService.instance.saveBookingToCloud(
      bookingId: booking.bookingId,
      userId: userId ?? 'anonymous_devotee',
      type: 'SHUTTLE',
      slotTime: booking.slotTime,
      date: booking.date,
      totalAmount: booking.totalFare,
      seatCount: booking.seatCount,
      tickets: booking.tickets,
    );

    // Async push to backend
    _pushBookingToBackend(
      id: booking.bookingId,
      type: 'SHUTTLE',
      title: 'Shuttle Bus',
      slotTime: booking.slotTime,
      date: booking.date,
      ticketsCount: booking.seatCount,
      totalAmount: booking.totalFare,
      tickets: booking.tickets,
      token: token,
      userId: userId,
    );

    // Push local notification for booking confirmation
    NotificationService.instance.notifyBookingConfirmed(
      bookingId: booking.bookingId,
      title: 'Shuttle Bus Pass',
      slotTime: booking.slotTime,
      date: booking.date,
      seatCount: booking.seatCount,
    );
  }

  void addDarshanBooking(DarshanBooking booking, {String? token, String? userId}) {
    _darshanBookings.insert(0, booking);
    _saveToLocal();
    notifyListeners();

    // Async push to Cloud Firestore
    FirebaseService.instance.saveBookingToCloud(
      bookingId: booking.bookingId,
      userId: userId ?? 'anonymous_devotee',
      type: booking.darshanType,
      slotTime: booking.slotTime,
      date: booking.date,
      totalAmount: booking.totalAmount,
      seatCount: booking.ticketCount,
      tickets: booking.tickets,
    );

    // Async push to backend
    _pushBookingToBackend(
      id: booking.bookingId,
      type: 'DARSHAN',
      title: booking.darshanType,
      slotTime: booking.slotTime,
      date: booking.date,
      ticketsCount: booking.ticketCount,
      totalAmount: booking.totalAmount,
      tickets: booking.tickets,
      token: token,
      userId: userId,
    );

    // Push local notification for booking confirmation
    NotificationService.instance.notifyBookingConfirmed(
      bookingId: booking.bookingId,
      title: booking.darshanType,
      slotTime: booking.slotTime,
      date: booking.date,
      seatCount: booking.ticketCount,
    );
  }

  void addDonationReceipt(DonationReceipt receipt) {
    _donationReceipts.insert(0, receipt);
    notifyListeners();
  }

  void cancelShuttleBooking(String bookingId) {
    final idx = _shuttleBookings.indexWhere((b) => b.bookingId == bookingId);
    if (idx != -1) {
      _shuttleBookings[idx].isCancelled = true;
      _saveToLocal();
      notifyListeners();
    }
  }

  // ── Legacy add methods ──────────────────────────────────────────────────────

  void addDonation(DonationReceiptModel receipt, {String? token, String? userId}) {
    _donations.insert(0, receipt);
    _saveToLocal();
    notifyListeners();

    _pushDonationToBackend(receipt, token: token, userId: userId);
  }

  // ── Backend push helpers ───────────────────────────────────────────────────

  Future<void> _pushBookingToBackend({
    required String id,
    required String type,
    required String title,
    required String slotTime,
    required String date,
    required int ticketsCount,
    required double totalAmount,
    required List<IndividualTicket> tickets,
    String? token,
    String? userId,
  }) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      await http.post(
        Uri.parse('${AuthProvider.backendUrl}/api/bookings'),
        headers: headers,
        body: jsonEncode({
          'id': id,
          'type': type,
          'title': title,
          'slot_time': slotTime,
          'date': date,
          'tickets_count': ticketsCount,
          'total_amount': totalAmount,
          'user_id': userId,
          'tickets': tickets
              .map((t) => {
                    'id': t.ticketId,
                    'qr_payload': t.qrPayload,
                    'ticket_label': t.ticketLabel,
                  })
              .toList(),
        }),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[UserActivity] Could not sync booking to backend: $e');
    }
  }

  Future<void> _pushDonationToBackend(
    DonationReceiptModel receipt, {
    String? token,
    String? userId,
  }) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      await http.post(
        Uri.parse('${AuthProvider.backendUrl}/api/donations'),
        headers: headers,
        body: jsonEncode({
          'cause': receipt.cause,
          'amount': receipt.amount,
          'transaction_id': receipt.transactionId,
          'ref_80g': receipt.ref80g,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[UserActivity] Could not sync donation to backend: $e');
    }
  }

  // ── Computed ────────────────────────────────────────────────────────────────

  int get totalDonated =>
      _donationReceipts.fold(0, (s, d) => s + d.amount) +
      _donations.fold(0, (s, d) => s + d.amount);

  int get activePassCount =>
      activeShuttleBookings.length + _darshanBookings.length;

  // ── Ticket ID generator ─────────────────────────────────────────────────────

  static String generateBookingId(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final suffix = (ts % 10000).toString().padLeft(4, '0');
    return '$prefix-$suffix';
  }

  static List<IndividualTicket> generateTickets({
    required String bookingId,
    required int count,
    required String type,
    required String slot,
    required String date,
  }) {
    return List.generate(count, (i) {
      final id = 'MRD-$type-${bookingId.split('-').last}-${i + 1}';
      final qr = 'SANNIDHI|$type|$id|$slot|$date|${i + 1}of$count';
      return IndividualTicket(
        ticketId: id,
        qrPayload: qr,
        ticketLabel: 'Ticket ${i + 1} of $count',
        slotTime: slot,
        date: date,
      );
    });
  }

  // ── Ticket Verification & Matching Helpers ─────────────────────────────────

  bool _matchesTicket(IndividualTicket t, String query) {
    final q = query.trim().toUpperCase();
    if (t.ticketId.toUpperCase() == q) return true;
    if (t.qrPayload.toUpperCase() == q) return true;
    if (q.contains(t.ticketId.toUpperCase())) return true;
    if (t.ticketId.length > 5 && t.ticketId.toUpperCase().contains(q)) return true;

    // Handle payload format: SANNIDHI|TYPE|TICKET_ID|SLOT|DATE|LABEL
    if (q.startsWith('SANNIDHI|')) {
      final parts = query.split('|');
      if (parts.length > 2 && parts[2].trim().toUpperCase() == t.ticketId.toUpperCase()) {
        return true;
      }
    }
    return false;
  }

  /// Check if a ticket has already been used (by ticket ID or QR payload)
  bool isTicketUsed(String ticketIdOrQr) {
    final clean = ticketIdOrQr.trim();
    if (clean.isEmpty) return false;

    // Check shuttle bookings
    for (final b in _shuttleBookings) {
      for (final t in b.tickets) {
        if (_matchesTicket(t, clean)) {
          return t.isUsed;
        }
      }
    }

    // Check darshan bookings
    for (final b in _darshanBookings) {
      for (final t in b.tickets) {
        if (_matchesTicket(t, clean)) {
          return t.isUsed;
        }
      }
    }

    return false;
  }

  /// Find matching ticket and its booking metadata by ticket ID or QR payload
  ({
    IndividualTicket ticket,
    String bookingId,
    String type,
    String slotTime,
    String date,
    String devoteeName,
  })? findTicketInfo(String ticketIdOrQr) {
    final clean = ticketIdOrQr.trim();
    if (clean.isEmpty) return null;

    for (final b in _shuttleBookings) {
      for (final t in b.tickets) {
        if (_matchesTicket(t, clean)) {
          return (
            ticket: t,
            bookingId: b.bookingId,
            type: 'Shuttle Bus Pass',
            slotTime: b.slotTime,
            date: b.date,
            devoteeName: 'Ramesh Kumar & Family',
          );
        }
      }
    }

    for (final b in _darshanBookings) {
      for (final t in b.tickets) {
        if (_matchesTicket(t, clean)) {
          return (
            ticket: t,
            bookingId: b.bookingId,
            type: '${b.darshanType} Pass',
            slotTime: b.slotTime,
            date: b.date,
            devoteeName: 'Ramesh Kumar & Family',
          );
        }
      }
    }

    return null;
  }

  /// Mark a ticket as USED in-memory and persistently in SharedPreferences
  Future<bool> markTicketUsed(
    String ticketIdOrQr, {
    DateTime? usedAt,
    String? verifiedBy,
  }) async {
    final clean = ticketIdOrQr.trim();
    if (clean.isEmpty) return false;

    final actualUsedAt = usedAt ?? DateTime.now();
    bool found = false;
    String? resolvedTicketId;
    String? resolvedTitle;

    // Check in shuttle bookings
    for (final b in _shuttleBookings) {
      for (final t in b.tickets) {
        if (_matchesTicket(t, clean)) {
          t.isUsed = true;
          t.usedAt = actualUsedAt;
          t.verifiedBy = verifiedBy ?? 'Gate Staff';
          resolvedTicketId = t.ticketId;
          resolvedTitle = 'Shuttle Bus (${b.slotTime})';
          found = true;
          break;
        }
      }
      if (found) break;
    }

    // Check in darshan bookings
    if (!found) {
      for (final b in _darshanBookings) {
        for (final t in b.tickets) {
          if (_matchesTicket(t, clean)) {
            t.isUsed = true;
            t.usedAt = actualUsedAt;
            t.verifiedBy = verifiedBy ?? 'Gate Staff';
            resolvedTicketId = t.ticketId;
            resolvedTitle = '${b.darshanType} (${b.slotTime})';
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }

    // Save to global used ticket IDs set in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final usedList = prefs.getStringList('sannidhi_used_ticket_ids') ?? [];
      final idToStore = resolvedTicketId ?? clean;
      if (!usedList.contains(idToStore)) {
        usedList.add(idToStore);
      }
      if (resolvedTicketId != null && !usedList.contains(clean)) {
        usedList.add(clean);
      }
      await prefs.setStringList('sannidhi_used_ticket_ids', usedList);
    } catch (e) {
      debugPrint('[UserActivity] Error saving used ticket ID: $e');
    }

    await _saveToLocal();
    notifyListeners();

    if (found) {
      NotificationService.instance.notifyPassScanned(
        passId: resolvedTicketId ?? clean,
        passTitle: resolvedTitle ?? 'Temple Entry Pass',
        verifiedBy: verifiedBy ?? 'Gate Staff',
      );
    }

    return found;
  }
}
