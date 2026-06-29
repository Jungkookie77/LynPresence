import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_styles.dart';

import '../core/services/attendance_service.dart';
import '../core/services/user_service.dart';
import '../core/services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AttendanceService _attendanceService;
  late final UserProfile _userProfile;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _attendanceService.addListener(_onStateChanged);
    _userProfile = UserProfile();
    _userProfile.addListener(_onStateChanged);
    _notificationService = NotificationService();
    _notificationService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _attendanceService.removeListener(_onStateChanged);
    _userProfile.removeListener(_onStateChanged);
    _notificationService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Header (Avatar + Name + Notifications)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF7A3FF3),
                        child: Text(
                          _userProfile.name.isNotEmpty ? _userProfile.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bonjour,',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          Text(
                            _userProfile.firstName,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppStyles.cardShadow,
                          ),
                          child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                        ),
                      if (_notificationService.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
              
              const SizedBox(height: 32),
              
              // Smart Assistant Card (Replaced the generic cloud card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppStyles.floatingShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28)
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .shimmer(duration: 2.seconds),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Assistant RH IA',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '"Vous avez été très ponctuel cette semaine. Souhaitez-vous générer votre rapport mensuel ?"',
                      style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => context.push('/chatbot'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF7A3FF3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Discuter', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
              
              const SizedBox(height: 32),
              
              // Tightly Grouped Action Buttons with Professional Proportions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/pointage'),
                      child: _buildActionButton(
                        icon: Icons.fingerprint,
                        iconColor: const Color(0xFFFF66B2),
                        label: 'Pointage',
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/leave'),
                      child: _buildActionButton(
                        icon: Icons.beach_access,
                        iconColor: const Color(0xFFFFB347),
                        label: 'Congés',
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/stats'),
                      child: _buildActionButton(
                        icon: Icons.insert_chart,
                        iconColor: const Color(0xFF66C2FF),
                        label: 'Stats',
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Recents section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Activité Récente',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Voir tout',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 20),
              
              if (_attendanceService.records.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('Aucune activité aujourd\'hui.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                ..._attendanceService.records.reversed.map((record) {
                  final isClockIn = record.type == 'IN';
                  final timeStr = '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildRecentCard(
                      icon: isClockIn ? Icons.login : Icons.logout,
                      iconColor: isClockIn ? const Color(0xFFFFB347) : const Color(0xFFFF66B2),
                      title: isClockIn ? 'Arrivée enregistrée' : 'Départ enregistré',
                      subtitle: 'Aujourd\'hui à $timeStr',
                    ).animate().fadeIn().slideX(begin: 0.1, end: 0),
                  );
                }),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppStyles.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
