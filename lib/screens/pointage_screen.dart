import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/services/attendance_service.dart';
import 'package:geolocator/geolocator.dart';

class PointageScreen extends StatefulWidget {
  const PointageScreen({super.key});

  @override
  State<PointageScreen> createState() => _PointageScreenState();
}

class _PointageScreenState extends State<PointageScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  bool _isScanning = false;
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _attendanceService.addListener(_updateState);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _attendanceService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  Future<void> _handlePointage() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    // ⚠️ MODE DÉMO — géolocalisation désactivée temporairement
    // Pour réactiver : supprimer ce bloc et décommenter le bloc GPS ci-dessous
    if (!mounted) return;

    // Enregistrer le pointage
    final bool wasCheckedIn = _attendanceService.isClockedIn;
    try {
      if (wasCheckedIn) {
        await _attendanceService.clockOut();
      } else {
        await _attendanceService.clockIn();
      }
    } catch (e) {
      _showError('Erreur lors de l\'enregistrement du pointage.');
      return;
    }

    if (!mounted) return;
    setState(() => _isScanning = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        wasCheckedIn ? 'Pointage de Sortie enregistré ✓' : 'Pointage d\'Entrée enregistré ✓',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: wasCheckedIn ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showError(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() => _isScanning = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? Colors.red : Colors.orange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isCheckedIn = _attendanceService.isClockedIn;
    final Color statusColor = isCheckedIn ? Colors.green : Colors.grey;
    final String timeString = DateFormat('HH:mm:ss').format(_currentTime);
    final String dateString = DateFormat('EEEE, d MMMM yyyy', 'fr_FR').format(_currentTime);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pointage', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge de statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: statusColor, size: 12)
                        .animate(onPlay: (c) => isCheckedIn ? c.repeat(reverse: true) : null)
                        .fade(duration: 1.seconds),
                    const SizedBox(width: 8),
                    Text(
                      isCheckedIn ? 'EN LIGNE' : 'HORS LIGNE',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(),

              const SizedBox(height: 40),

              // Horloge temps réel
              Text(
                timeString,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dateString.toUpperCase(),
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 80),

              // Bouton de pointage
              GestureDetector(
                onTap: _handlePointage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Anneaux de pulsation (actifs seulement si pointé)
                    if (isCheckedIn && !_isScanning)
                      ...List.generate(3, (index) {
                        return Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 2),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .scaleXY(begin: 1, end: 1.5, duration: 2.seconds, delay: (index * 400).ms)
                            .fade(begin: 1, end: 0);
                      }),

                    // Bouton principal
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isCheckedIn
                            ? const LinearGradient(colors: [Colors.green, Color(0xFF43A047)])
                            : AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: (isCheckedIn ? Colors.green : const Color(0xFF7A3FF3)).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 10,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isScanning
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fingerprint, color: Colors.white.withValues(alpha: 0.9), size: 60),
                                  const SizedBox(height: 12),
                                  Text(
                                    isCheckedIn ? 'SORTIE' : 'ENTRÉE',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ).animate().scale(curve: Curves.elasticOut),
                      ),
                    ).animate(target: _isScanning ? 1 : 0).scaleXY(end: 0.95),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Appuyez sur le bouton pour enregistrer votre présence',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
