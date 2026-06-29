import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AttendanceRecord {
  final String id;
  final DateTime timestamp;
  final String type; // 'IN' or 'OUT'
  final String? userId;
  final String? userName;
  final double? latitude;
  final double? longitude;
  
  AttendanceRecord({required this.id, required this.timestamp, required this.type, this.userId, this.userName, this.latitude, this.longitude});

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'] ?? 'IN',
      userId: data['userId'],
      userName: data['userName'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }
}

class AttendanceService extends ChangeNotifier {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  
  AttendanceService._internal() {
    _listenToAttendance();
  }

  List<AttendanceRecord> _records = [];
  bool _firestoreLoaded = false;

  // isClockedIn se base uniquement sur les vraies données Firestore.
  // Avant le chargement, l'état par défaut est "pas pointé" (false).
  bool get isClockedIn => _records.isNotEmpty && _records.last.type == 'IN';

  List<AttendanceRecord> get records {
    if (!_firestoreLoaded || _records.isEmpty) {
      return [
        AttendanceRecord(id: 'mock1', timestamp: DateTime.now().subtract(const Duration(hours: 8)), type: 'IN'),
        AttendanceRecord(id: 'mock2', timestamp: DateTime.now().subtract(const Duration(hours: 4)), type: 'OUT'),
        AttendanceRecord(id: 'mock3', timestamp: DateTime.now().subtract(const Duration(hours: 3)), type: 'OUT'),
      ];
    }
    return _records;
  }

  List<AttendanceRecord> _allRecords = [];
  List<AttendanceRecord> get allRecords {
    if (_allRecords.isEmpty) {
      return [
        AttendanceRecord(id: 'mock_a1', timestamp: DateTime.now().subtract(const Duration(minutes: 5)), type: 'IN', userName: 'Alice Martin'),
        AttendanceRecord(id: 'mock_a2', timestamp: DateTime.now().subtract(const Duration(minutes: 45)), type: 'OUT', userName: 'Paul Dubois'),
        AttendanceRecord(id: 'mock_a3', timestamp: DateTime.now().subtract(const Duration(hours: 1)), type: 'IN', userName: 'Sarah Connor'),
      ];
    }
    return _allRecords;
  }

  void _listenToAttendance() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        FirebaseFirestore.instance
            .collection('attendance')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: false)
            .snapshots()
            .listen((snapshot) {
          _records = snapshot.docs.map((doc) => AttendanceRecord.fromFirestore(doc)).toList();
          _firestoreLoaded = true;
          notifyListeners();
        });

        // Toutes les présences (pour le Manager)
        FirebaseFirestore.instance
            .collection('attendance')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots()
            .listen((snapshot) {
          _allRecords = snapshot.docs.map((doc) => AttendanceRecord.fromFirestore(doc)).toList();
          notifyListeners();
        });
      } else {
        _records = [];
        _allRecords = [];
        _firestoreLoaded = false;
        notifyListeners();
      }
    });
  }

  Future<void> clockIn({double? latitude, double? longitude}) async {
    if (!isClockedIn) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('attendance').add({
          'type': 'IN',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'userName': UserProfile().name,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        });
      }
    }
  }

  Future<void> clockOut({double? latitude, double? longitude}) async {
    if (isClockedIn) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('attendance').add({
          'type': 'OUT',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'userName': UserProfile().name,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        });
      }
    }
  }
}
