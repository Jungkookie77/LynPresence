import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_styles.dart';
import '../core/widgets/organic_background.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Determine current index based on route
    final String location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/leave')) currentIndex = 1;
    if (location.startsWith('/stats')) currentIndex = 2;
    if (location.startsWith('/profile')) currentIndex = 3;

    return Scaffold(
      extendBody: true, // Important for floating nav bar
      body: OrganicBackground(child: child),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(40),
            boxShadow: AppStyles.floatingShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home_rounded, 0, currentIndex, '/dashboard'),
              _buildNavItem(context, Icons.beach_access_rounded, 1, currentIndex, '/leave'),
              
              // Center FAB-like button for Pointage
              GestureDetector(
                onTap: () => context.push('/pointage'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7A3FF3).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: const Icon(Icons.fingerprint, color: Colors.white, size: 28),
                ),
              ),

              _buildNavItem(context, Icons.insert_chart_rounded, 2, currentIndex, '/stats'), 
              _buildNavItem(context, Icons.person_rounded, 3, currentIndex, '/profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index, int currentIndex, String route) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () {
        if (!isSelected) context.go(route);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGradient.colors.first.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primaryGradient.colors.first : AppColors.textSecondary,
          size: 26,
        ),
      ),
    );
  }
}
