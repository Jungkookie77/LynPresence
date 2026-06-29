import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_styles.dart';
import '../firebase_options.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppStyles.softShadow,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gestion des Collaborateurs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Comptes et rôles', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddUserDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            ),

            const SizedBox(height: 24),

            // User list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Aucun utilisateur trouvé.', style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data = users[index].data() as Map<String, dynamic>;
                      final docId = users[index].id;
                      final isManager = data['isManager'] == true;
                      final name = data['name'] ?? 'Sans nom';
                      final email = data['email'] ?? '';
                      final role = data['role'] ?? 'Employé';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppStyles.softShadow,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF7A3FF3).withOpacity(0.1),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7A3FF3)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                  Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isManager ? const Color(0xFF7A3FF3).withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isManager ? const Color(0xFF7A3FF3) : Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Toggle Manager/Employé
                            Column(
                              children: [
                                Text(
                                  'Manager',
                                  style: TextStyle(fontSize: 10, color: isManager ? const Color(0xFF7A3FF3) : AppColors.textSecondary),
                                ),
                                Switch(
                                  value: isManager,
                                  onChanged: (val) => _updateRole(context, docId, val),
                                  activeColor: const Color(0xFF7A3FF3),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: index * 80)).slideX(begin: 0.2, end: 0);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRole(BuildContext context, String docId, bool isManager) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'isManager': isManager,
      'role': isManager ? 'Manager' : 'Employé',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isManager ? 'Rôle mis à jour : Manager ✓' : 'Rôle mis à jour : Employé ✓'),
        backgroundColor: const Color(0xFF7A3FF3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Employé');
    bool isManager = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Ajouter un Collaborateur', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Nom complet', Icons.person_outline),
                const SizedBox(height: 12),
                _dialogField(emailCtrl, 'Adresse email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _dialogField(passCtrl, 'Mot de passe', Icons.lock_outline, obscure: true),
                const SizedBox(height: 12),
                _dialogField(roleCtrl, 'Poste / Titre', Icons.work_outline),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Droits Manager ?', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Switch(
                      value: isManager,
                      onChanged: (v) => setLocalState(() => isManager = v),
                      activeColor: const Color(0xFF7A3FF3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setLocalState(() => isLoading = true);
                await _createUser(
                  context: context,
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  role: roleCtrl.text.trim(),
                  isManager: isManager,
                  dialogCtx: ctx,
                );
                setLocalState(() => isLoading = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A3FF3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Créer le Compte'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createUser({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String role,
    required bool isManager,
    required BuildContext dialogCtx,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Veuillez remplir tous les champs obligatoires.'), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    try {
      // Créer le compte sans déconnecter l'admin : on utilise une seconde instance FirebaseApp
      final secondaryApp = await Firebase.initializeApp(
        name: 'TempApp-${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(email: email, password: password);
      final newUid = credential.user!.uid;
      await secondaryApp.delete(); // Ferme l'instance temporaire

      // Créer le profil Firestore
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'name': name,
        'email': email,
        'role': role.isNotEmpty ? role : (isManager ? 'Manager' : 'Employé'),
        'department': 'Non défini',
        'phone': '',
        'isManager': isManager,
      });

      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compte créé pour $name !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Une erreur est survenue.';
      if (e.code == 'email-already-in-use') msg = 'Cet email est déjà utilisé.';
      if (e.code == 'weak-password') msg = 'Mot de passe trop faible (6 caractères minimum).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF7A3FF3)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7A3FF3))),
      ),
    );
  }
}
