import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveRequest {
  final String id;
  final String type; // 'Congé Payé', 'Maladie', 'Sans Solde'
  final DateTime startDate;
  final DateTime endDate;
  String status; // 'Approuvé', 'En attente', 'Rejeté'
  final String? reason;
  final String? userId; // Adding userId to associate leave with an employee

  LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    this.userId,
  });

  factory LeaveRequest.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return LeaveRequest(
      id: doc.id,
      type: data['type'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'En attente',
      reason: data['reason'],
      userId: data['userId'],
    );
  }
}

class LeaveService extends ChangeNotifier {
  static final LeaveService _instance = LeaveService._internal();
  factory LeaveService() => _instance;
  
  LeaveService._internal() {
    _listenToLeaves();
  }

  int _availableDays = 24;
  int get availableDays => _availableDays;

  List<LeaveRequest> _requests = [];
  List<LeaveRequest> get requests {
    if (_requests.isEmpty) {
      return [
        LeaveRequest(id: 'mock1', type: 'Congé Payé', startDate: DateTime.now().add(const Duration(days: 7)), endDate: DateTime.now().add(const Duration(days: 14)), status: 'Approuvé', reason: 'Vacances d\'été'),
        LeaveRequest(id: 'mock2', type: 'Maladie', startDate: DateTime.now().subtract(const Duration(days: 5)), endDate: DateTime.now().subtract(const Duration(days: 4)), status: 'Rejeté', reason: 'Rendez-vous médical'),
      ];
    }
    return _requests;
  }

  /// Toutes les demandes (pour le tableau de bord manager)
  List<LeaveRequest> _allRequests = [];
  List<LeaveRequest> get allRequests {
    if (_allRequests.isEmpty) {
      return [
        LeaveRequest(id: 'mock_m1', type: 'Congé Payé', startDate: DateTime.now().add(const Duration(days: 2)), endDate: DateTime.now().add(const Duration(days: 5)), status: 'En attente', reason: 'Voyage personnel', userId: 'user123'),
        LeaveRequest(id: 'mock_m2', type: 'Sans Solde', startDate: DateTime.now().add(const Duration(days: 10)), endDate: DateTime.now().add(const Duration(days: 12)), status: 'En attente', reason: 'Déménagement', userId: 'user456'),
      ];
    }
    return _allRequests;
  }

  void _listenToLeaves() {
    // Écouter les changements d'authentification
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _requests = [];
        _allRequests = [];
        notifyListeners();
        return;
      }

      // Demandes de l'utilisateur connecté (pour la vue Employé)
      FirebaseFirestore.instance
          .collection('leaves')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        _requests = snapshot.docs.map((doc) => LeaveRequest.fromFirestore(doc)).toList();
        _requests.sort((a, b) => b.startDate.compareTo(a.startDate));
        notifyListeners();
      });

      // Toutes les demandes (pour la vue Manager)
      FirebaseFirestore.instance
          .collection('leaves')
          .snapshots()
          .listen((snapshot) {
        _allRequests = snapshot.docs.map((doc) => LeaveRequest.fromFirestore(doc)).toList();
        _allRequests.sort((a, b) => b.startDate.compareTo(a.startDate));
        notifyListeners();
      });
    });
  }

  Future<void> submitRequest(String type, DateTime start, DateTime end, String reason) async {
    final days = end.difference(start).inDays + 1;
    final user = FirebaseAuth.instance.currentUser;
    
    await FirebaseFirestore.instance.collection('leaves').add({
      'type': type,
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(end),
      'status': 'En attente',
      'reason': reason,
      'userId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (type == 'Congé Payé') {
      _availableDays -= days;
      notifyListeners();
    }
  }

  Future<void> approveRequest(String id) async {
    await FirebaseFirestore.instance.collection('leaves').doc(id).update({
      'status': 'Approuvé'
    });
  }

  Future<void> rejectRequest(String id) async {
    final doc = await FirebaseFirestore.instance.collection('leaves').doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      final type = data['type'];
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();
      
      await FirebaseFirestore.instance.collection('leaves').doc(id).update({
        'status': 'Rejeté'
      });

      if (type == 'Congé Payé') {
        final days = end.difference(start).inDays + 1;
        _availableDays += days;
        notifyListeners();
      }
    }
  }
}
