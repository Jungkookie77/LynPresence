import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile extends ChangeNotifier {
  static final UserProfile _instance = UserProfile._internal();
  factory UserProfile() => _instance;

  UserProfile._internal() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _firebaseUser = user;
      if (user != null) {
        _email = user.email ?? '';
        _loadUserData(user.uid);
      } else {
        _resetData();
      }
      notifyListeners();
    });
  }

  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;

  String _name = 'Employé(e)';
  String _email = '';
  String _role = 'Employé';
  String _department = 'Non défini';
  String _phone = '';
  String _avatarUrl = '';
  bool _notificationsEnabled = true;
  bool _isManager = false;
  bool _isProfileLoaded = false;

  String get name => _name;
  String get email => _email;
  String get role => _role;
  String get department => _department;
  String get phone => _phone;
  String get avatarUrl => _avatarUrl;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isManager => _isManager;
  bool get isProfileLoaded => _isProfileLoaded;
  String get firstName => _name.split(' ').first;

  void _resetData() {
    _name = 'Employé(e)';
    _role = 'Employé';
    _isManager = false;
    _isProfileLoaded = false;
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        loadFromMap(doc.data()!);
      } else {
        debugPrint("Aucun profil trouvé pour UID=$uid");
        _isProfileLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement du profil : $e");
      _isProfileLoaded = true;
      notifyListeners();
    }
  }

  /// Charge les données depuis une Map Firestore (utilisé par _DashboardSelector et _loadUserData).
  void loadFromMap(Map<String, dynamic> data) {
    _name = data['name'] ?? _name;
    _email = data['email'] ?? _email;
    _role = data['role'] ?? _role;
    _department = data['departement'] ?? data['department'] ?? _department;
    _phone = data['phone'] ?? _phone;
    _isManager = data['isManager'] ?? false;
    _isProfileLoaded = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Temporary for the UI mockups if needed
  void setManagerRole(bool value) {
    _isManager = value;
    if (_firebaseUser != null) {
      FirebaseFirestore.instance.collection('users').doc(_firebaseUser!.uid).update({'isManager': value});
    }
    notifyListeners();
  }

  void updateProfile({String? name, String? email, String? role, String? phone, String? department}) {
    if (name != null) _name = name;
    if (email != null) _email = email;
    if (role != null) _role = role;
    if (phone != null) _phone = phone;
    if (department != null) _department = department;
    
    if (_firebaseUser != null) {
      FirebaseFirestore.instance.collection('users').doc(_firebaseUser!.uid).update({
        if (name != null) 'name': name,
        if (role != null) 'role': role,
        if (phone != null) 'phone': phone,
        if (department != null) 'departement': department,
      });
    }
    notifyListeners();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }
}
