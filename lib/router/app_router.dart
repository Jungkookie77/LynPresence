import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/manager_dashboard.dart';
import '../screens/pointage_screen.dart';
import '../screens/leave_screen.dart';
import '../core/services/user_service.dart';
import '../screens/main_shell.dart';
import '../screens/stats_screen.dart';
import '../screens/chatbot_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/notifications_screen.dart';
import '../core/widgets/organic_background.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const _DashboardSelector(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/leave',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LeaveScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const StatsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const NotificationsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/chatbot',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ChatbotScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutBack)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/pointage',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OrganicBackground(child: PointageScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutBack)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/users',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OrganicBackground(child: UserManagementScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutBack)),
            child: child,
          );
        },
      ),
    ),
  ],
);

/// Widget qui écoute le document Firestore de l'utilisateur connecté en temps réel.
/// Cela évite toute race condition entre l'auth et le chargement du profil.
class _DashboardSelector extends StatelessWidget {
  const _DashboardSelector();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const DashboardScreen();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // En attente de la réponse Firestore
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF3EEFF),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7A3FF3)),
            ),
          );
        }

        // Erreur de permission ou autre : afficher employee par défaut
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const DashboardScreen();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isManager = data['isManager'] == true;

        // Mettre à jour UserProfile silencieusement pour les autres écrans
        final profile = UserProfile();
        profile.loadFromMap(data);

        return isManager ? const ManagerDashboard() : const DashboardScreen();
      },
    );
  }
}
