import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Veuillez renseigner votre email et mot de passe.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Si on arrive ici, l'auth a réussi.
      // UserService va charger le profil et AppRouter gérera la redirection.
      if (mounted) context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error: ${e.code} - ${e.message}');
      _showError('Email ou mot de passe incorrect.');
    } catch (e) {
      debugPrint('Login unexpected error: $e');
      _showError('Erreur de connexion. Vérifiez votre connexion internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated Background Circles
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.accentPinkGradient,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 0.8, end: 1.2, duration: 4.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .moveY(begin: 0, end: -50, duration: 5.seconds, curve: Curves.easeInOut),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppStyles.cardShadow,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo / Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(Icons.fingerprint, size: 48, color: Colors.white),
                      ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 24),
                      
                      // App Name
                      const Text(
                        'RUThere',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ).animate().fadeIn(delay: 400.ms),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Connectez-vous pour continuer',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 500.ms),
                      
                      const SizedBox(height: 32),
                      
                      // Email Field
                      _buildTextField(Icons.email_outlined, 'Adresse Email', controller: _emailController)
                        .animate().fadeIn(delay: 600.ms).slideX(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // Password Field
                      _buildTextField(Icons.lock_outline, 'Mot de passe', obscureText: true, controller: _passwordController)
                        .animate().fadeIn(delay: 700.ms).slideX(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 32),
                      
                      // Login Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: AppColors.primaryGradient,
                          boxShadow: AppStyles.floatingShadow,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _login,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.9, 0.9)),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(IconData icon, String hint, {bool obscureText = false, TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
