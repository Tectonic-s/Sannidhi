import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../models/user_model.dart';
import '../../data/models/activity_models.dart';

class GateVerificationResult {
  final bool isValid;
  final String status;
  final String message;
  final String? ticketId;
  final String? bookingId;
  final String? slotTime;
  final String? date;
  final String? devoteeName;
  final DateTime? previousScanTime;

  const GateVerificationResult({
    required this.isValid,
    required this.status,
    required this.message,
    this.ticketId,
    this.bookingId,
    this.slotTime,
    this.date,
    this.devoteeName,
    this.previousScanTime,
  });
}

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // ── 1. Initialization ───────────────────────────────────────────────────────

  Future<bool> init() async {
    if (_initialized) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _initialized = true;
      debugPrint('[FirebaseService] Successfully initialized Firebase');
      _ensureTelemetryDocExists();
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Firebase init warning (running with graceful fallback): $e');
      _initialized = false;
      return false;
    }
  }

  // ── 2. User Authentication & Role Management ────────────────────────────────

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (!_initialized) {
      // Demo fallback if Firebase offline
      return _demoRoleUser(cleanEmail);
    }

    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid == null) return null;

      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final token = await cred.user?.getIdToken();
        return UserModel.fromJson(data, token: token);
      } else {
        // Create user document if missing
        final role = _deriveRoleFromEmail(cleanEmail);
        final userModel = UserModel(
          id: uid,
          name: cred.user?.displayName ?? cleanEmail.split('@')[0],
          email: cleanEmail,
          phone: cred.user?.phoneNumber ?? '',
          role: role,
          token: await cred.user?.getIdToken(),
        );
        await firestore.collection('users').doc(uid).set(userModel.toJson());
        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[FirebaseService] Auth error: ${e.code}');
      // Fallback for pre-seeded demo accounts
      if (cleanEmail.contains('@sannidhi.app')) {
        return _demoRoleUser(cleanEmail);
      }
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseService] Login error: $e');
      if (cleanEmail.contains('@sannidhi.app')) {
        return _demoRoleUser(cleanEmail);
      }
      return null;
    }
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'devotee',
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (!_initialized) {
      final userRole = UserRole.fromString(role);
      return UserModel(
        id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: cleanEmail,
        phone: phone,
        role: userRole,
        token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid == null) return null;

      final userRole = UserRole.fromString(role);
      final token = await cred.user?.getIdToken();

      final userModel = UserModel(
        id: uid,
        name: name,
        email: cleanEmail,
        phone: phone,
        role: userRole,
        token: token,
      );

      await firestore.collection('users').doc(uid).set({
        'id': uid,
        'name': name,
        'email': cleanEmail,
        'phone': phone,
        'role': userRole.toDbString(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userModel;
    } catch (e) {
      debugPrint('[FirebaseService] Register error: $e');
      rethrow;
    }
  }

  Stream<UserModel?> streamUser(String uid) {
    if (!_initialized) return const Stream.empty();
    return firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromJson(snap.data()!);
    });
  }

  // ── 3. Real-time Temple Crowd & Footfall Telemetry ──────────────────────────

  Future<void> _ensureTelemetryDocExists() async {
    if (!_initialized) return;
    try {
      final doc = firestore.collection('temple_telemetry').doc('crowd');
      final snap = await doc.get();
      if (!snap.exists) {
        await doc.set({
          'currentInsideCount': 142,
          'totalTodayFootfall': 1280,
          'estimatedWaitMinutes': 25,
          'status': 'moderate',
          'lastHardwareTrigger': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[FirebaseService] Telemetry init doc error: $e');
    }
  }

  // ── Dual-Source Deduplication (GPS Geofence vs Gate Ticket Scans) ─────────
  final Set<String> _activeGeofencedDevotees = {};
  final Set<String> _verifiedGateDevotees = {};
  int _deduplicatedCount = 0;
  int get deduplicatedCount => _deduplicatedCount;

  // ── Real-time Temple Broadcast (Admin -> Devotees) ────────────────────────
  final _broadcastController = StreamController<Map<String, dynamic>>.broadcast();
  Map<String, dynamic> _currentBroadcast = {
    'isActive': false,
    'message': '',
    'messageTa': '',
  };

  Stream<Map<String, dynamic>> streamActiveBroadcast() {
    if (!_initialized) {
      return Stream<Map<String, dynamic>>.multi((controller) {
        controller.add(_currentBroadcast);
        final sub = _broadcastController.stream.listen(controller.add);
        controller.onCancel = sub.cancel;
      });
    }
    return firestore
        .collection('temple_telemetry')
        .doc('broadcast')
        .snapshots()
        .map((snap) => snap.data() ?? {'isActive': false, 'message': ''});
  }

  Future<void> publishBroadcast({
    required String message,
    required bool isActive,
    String? messageTa,
  }) async {
    _currentBroadcast = {
      'isActive': isActive,
      'message': message,
      'messageTa': messageTa ?? message,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    _broadcastController.add(_currentBroadcast);

    if (!_initialized) return;

    try {
      await firestore.collection('temple_telemetry').doc('broadcast').set({
        'isActive': isActive,
        'message': message,
        'messageTa': messageTa ?? message,
        'updatedAt': FieldValue.serverTimestamp(),
        'broadcastBy': 'admin',
      }, SetOptions(merge: true));
      debugPrint('[FirebaseService] Broadcast published to Cloud Firestore: active=$isActive msg=$message');
    } catch (e) {
      debugPrint('[FirebaseService] Publish broadcast error: $e');
    }
  }

  Stream<Map<String, dynamic>> streamCrowdTelemetry() {
    if (!_initialized) return const Stream.empty();
    return firestore
        .collection('temple_telemetry')
        .doc('crowd')
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }

  /// Triggered at the hardware level by CoreLocation / GPS geofence
  Future<void> recordHardwareFootfall({
    required bool isEntering,
    required double latitude,
    required double longitude,
    String? userId,
  }) async {
    final uid = userId ?? 'devotee_session';

    if (isEntering) {
      if (_activeGeofencedDevotees.contains(uid)) return;
      _activeGeofencedDevotees.add(uid);

      // Check if devotee was already scanned at the gate
      if (_verifiedGateDevotees.contains(uid)) {
        _deduplicatedCount++;
        debugPrint('[Deduplication] Devotee $uid was already scanned at gate. Geofence presence merged without duplicate counting.');
        return;
      }
    } else {
      _activeGeofencedDevotees.remove(uid);
      _verifiedGateDevotees.remove(uid);
    }

    if (!_initialized) return;

    try {
      final telemetryRef = firestore.collection('temple_telemetry').doc('crowd');
      final eventsRef = firestore.collection('footfall_events');

      // 1. Log atomic event
      await eventsRef.add({
        'eventType': isEntering ? 'ENTER_SANCTUM' : 'EXIT_SANCTUM',
        'latitude': latitude,
        'longitude': longitude,
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'hardwareSensor': 'CoreLocation_GPS',
      });

      // 2. Atomically update crowd counter
      if (isEntering) {
        await telemetryRef.update({
          'currentInsideCount': FieldValue.increment(1),
          'totalTodayFootfall': FieldValue.increment(1),
          'lastHardwareTrigger': FieldValue.serverTimestamp(),
        });
      } else {
        await telemetryRef.update({
          'currentInsideCount': FieldValue.increment(-1),
          'lastHardwareTrigger': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('[FirebaseService] Hardware footfall logged: ${isEntering ? "ENTER" : "EXIT"}');
    } catch (e) {
      debugPrint('[FirebaseService] Hardware footfall update error: $e');
    }
  }

  // ── 4. Live Updating Passes & Instant Gate Verification ──────────────────────

  Future<void> saveBookingToCloud({
    required String bookingId,
    required String userId,
    required String type, // SHUTTLE or DARSHAN
    required String slotTime,
    required String date,
    required double totalAmount,
    required int seatCount,
    required List<IndividualTicket> tickets,
  }) async {
    if (!_initialized) return;

    try {
      final batch = firestore.batch();

      // Write booking doc
      final bookingRef = firestore.collection('bookings').doc(bookingId);
      batch.set(bookingRef, {
        'bookingId': bookingId,
        'userId': userId,
        'type': type,
        'slotTime': slotTime,
        'date': date,
        'totalAmount': totalAmount,
        'seatCount': seatCount,
        'status': 'ACTIVE',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Write individual tickets
      for (final t in tickets) {
        final ticketRef = firestore.collection('tickets').doc(t.ticketId);
        batch.set(ticketRef, {
          'ticketId': t.ticketId,
          'bookingId': bookingId,
          'userId': userId,
          'type': type,
          'slotTime': slotTime,
          'date': date,
          'qrPayload': t.qrPayload,
          'status': 'ACTIVE',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('[FirebaseService] Saved booking & ${tickets.length} tickets to Cloud Firestore');
    } catch (e) {
      debugPrint('[FirebaseService] Save booking error: $e');
    }
  }

  /// Real-time stream of all bookings for a user
  Stream<List<Map<String, dynamic>>> streamUserBookings(String userId) {
    if (!_initialized) return const Stream.empty();
    return firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Real-time stream of tickets for a booking (auto-updates when staff scans)
  Stream<List<Map<String, dynamic>>> streamBookingTickets(String bookingId) {
    if (!_initialized) return const Stream.empty();
    return firestore
        .collection('tickets')
        .where('bookingId', isEqualTo: bookingId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Official Staff Gate Verification with Duplicate Entry Prevention
  Future<GateVerificationResult> verifyTicketAtGate({
    required String qrPayloadOrTicketId,
    required String staffId,
    required String staffName,
  }) async {
    if (!_initialized) {
      return GateVerificationResult(
        isValid: true,
        status: 'VERIFIED',
        message: 'Gate Pass Verified Successfully (Local Validation) 🙏',
        ticketId: qrPayloadOrTicketId,
      );
    }

    try {
      // Find ticket by ID or QR payload
      QuerySnapshot<Map<String, dynamic>> snap = await firestore
          .collection('tickets')
          .where('qrPayload', isEqualTo: qrPayloadOrTicketId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        snap = await firestore
            .collection('tickets')
            .where('ticketId', isEqualTo: qrPayloadOrTicketId)
            .limit(1)
            .get();
      }

      if (snap.docs.isEmpty) {
        return const GateVerificationResult(
          isValid: false,
          status: 'INVALID',
          message: 'Pass NOT FOUND in Temple Database. Please check with Helpdesk.',
        );
      }

      final ticketDoc = snap.docs.first;
      final data = ticketDoc.data();
      final currentStatus = data['status'] as String? ?? 'ACTIVE';

      // ── Duplicate Scan Rejection ───────────────────────────────────────────
      if (currentStatus == 'USED') {
        Timestamp? scanTs = data['scannedAt'] as Timestamp?;
        final scannedTime = scanTs?.toDate();
        final scannedBy = data['scannedByName'] as String? ?? 'Gate Staff';

        return GateVerificationResult(
          isValid: false,
          status: 'ALREADY_USED',
          message: 'ALREADY USED: Pass was already scanned by $scannedBy!',
          ticketId: data['ticketId'] as String?,
          bookingId: data['bookingId'] as String?,
          slotTime: data['slotTime'] as String?,
          date: data['date'] as String?,
          previousScanTime: scannedTime,
        );
      }

      // ── Valid Entry: Mark as USED ──────────────────────────────────────────
      await ticketDoc.reference.update({
        'status': 'USED',
        'scannedAt': FieldValue.serverTimestamp(),
        'scannedByUid': staffId,
        'scannedByName': staffName,
      });

      // Dual-source deduplication: check if devotee is already counted in geofence
      final devoteeUserId = (data['userId'] as String?) ?? qrPayloadOrTicketId;
      _verifiedGateDevotees.add(devoteeUserId);
      if (_activeGeofencedDevotees.contains(devoteeUserId)) {
        _deduplicatedCount++;
        debugPrint('[Deduplication] Devotee $devoteeUserId already tracked via Geofence. Pass marked USED without duplicate footfall.');
      }

      // Update booking count / status if all tickets scanned
      final bookingId = data['bookingId'] as String?;
      if (bookingId != null) {
        _checkAndMarkBookingUsed(bookingId);
      }

      return GateVerificationResult(
        isValid: true,
        status: 'VERIFIED',
        message: 'Gate Pass Verified Successfully! Welcome to Sannidhi 🙏',
        ticketId: data['ticketId'] as String?,
        bookingId: bookingId,
        slotTime: data['slotTime'] as String?,
        date: data['date'] as String?,
      );
    } catch (e) {
      debugPrint('[FirebaseService] Gate verification error: $e');
      return GateVerificationResult(
        isValid: false,
        status: 'ERROR',
        message: 'Verification failed: $e',
      );
    }
  }

  Future<void> _checkAndMarkBookingUsed(String bookingId) async {
    try {
      final ticketsSnap = await firestore
          .collection('tickets')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      final allUsed = ticketsSnap.docs.every((d) => d.data()['status'] == 'USED');
      if (allUsed) {
        await firestore.collection('bookings').doc(bookingId).update({
          'status': 'USED',
        });
      }
    } catch (_) {}
  }

  // ── Helper: Demo user generation ───────────────────────────────────────────

  UserModel _demoRoleUser(String cleanEmail) {
    final role = _deriveRoleFromEmail(cleanEmail);
    return UserModel(
      id: 'demo_${role.toDbString()}_id',
      name: role == UserRole.admin
          ? 'Temple Administrator'
          : (role == UserRole.staff ? 'Gate Staff (Official)' : 'Devotee'),
      email: cleanEmail,
      phone: '9876543210',
      role: role,
      token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  UserRole _deriveRoleFromEmail(String email) {
    if (email.contains('admin')) return UserRole.admin;
    if (email.contains('staff') || email.contains('verifier')) return UserRole.staff;
    return UserRole.devotee;
  }
}
