import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_styles.dart';
import '../core/services/user_service.dart';
import '../core/services/leave_service.dart';
import '../core/services/attendance_service.dart';
import '../core/services/pdf_service.dart';
import '../core/services/notification_service.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final UserProfile _userProfile = UserProfile();
  final LeaveService _leaveService = LeaveService();
  final AttendanceService _attendanceService = AttendanceService();
  int _totalEmployees = 0;

  @override
  void initState() {
    super.initState();
    _userProfile.addListener(_updateState);
    _leaveService.addListener(_updateState);
    _attendanceService.addListener(_updateState);
  }

  @override
  void dispose() {
    _userProfile.removeListener(_updateState);
    _leaveService.removeListener(_updateState);
    _attendanceService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequests = _leaveService.allRequests.where((r) => r.status == 'En attente').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Espace Manager',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7A3FF3)),
                      ),
                      Text(
                        'Bonjour, ${_userProfile.firstName}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF7A3FF3),
                    child: Text(
                      _userProfile.name.isNotEmpty ? _userProfile.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideX(),

              const SizedBox(height: 32),

              // Stats
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  final total = snapshot.data?.docs.length ?? 0;
                  final managers = snapshot.data?.docs
                      .where((d) => (d.data() as Map)['isManager'] == true)
                      .length ?? 0;
                  final employees = total - managers;
                  if (_totalEmployees != total) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _totalEmployees = total);
                    });
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'En attente',
                          pendingRequests.length.toString(),
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Employés',
                          '$employees / $total',
                          Icons.people,
                          Colors.green,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY();
                },
              ),

              const SizedBox(height: 20),

              // Bouton Gestion Utilisateurs
              GestureDetector(
                onTap: () => context.push('/users'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppStyles.floatingShadow,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.people_alt_outlined, color: Colors.white, size: 26),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gérer les Collaborateurs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Créer des comptes et définir les rôles', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(),

              const SizedBox(height: 16),

              // Bouton Générer Rapport
              GestureDetector(
                onTap: () => _generateReport(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppStyles.softShadow,
                    border: Border.all(color: const Color(0xFF7A3FF3).withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF7A3FF3), size: 26),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Générer Rapport PDF', style: TextStyle(color: Color(0xFF7A3FF3), fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Exporter les présences et congés', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.download, color: Color(0xFF7A3FF3), size: 20),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms).slideY(),

              const SizedBox(height: 32),

              Text(
                'Demandes en attente',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 16),

              if (pendingRequests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(20), boxShadow: AppStyles.softShadow, border: Border.all(color: Colors.white, width: 2)),
                  child: const Center(
                    child: Text('Aucune demande en attente.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ).animate().fadeIn(delay: 600.ms)
              else
                ...pendingRequests.map((req) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(20), boxShadow: AppStyles.softShadow, border: Border.all(color: Colors.white, width: 2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(req.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                            Text(
                              '${DateFormat('dd MMM', 'fr_FR').format(req.startDate)} - ${DateFormat('dd MMM', 'fr_FR').format(req.endDate)}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                        if (req.reason != null && req.reason!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Motif: ${req.reason}', style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  _leaveService.rejectRequest(req.id);
                                  await NotificationService.sendNotification(
                                    userId: req.userId ?? '',
                                    title: 'Demande de congé refusée',
                                    message: 'Votre demande de congé du ${DateFormat('dd/MM').format(req.startDate)} au ${DateFormat('dd/MM').format(req.endDate)} a été refusée.',
                                    type: 'leave_rejected',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Refuser'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  _leaveService.approveRequest(req.id);
                                  await NotificationService.sendNotification(
                                    userId: req.userId ?? '',
                                    title: 'Demande de congé approuvée',
                                    message: 'Votre demande de congé du ${DateFormat('dd/MM').format(req.startDate)} au ${DateFormat('dd/MM').format(req.endDate)} a été approuvée.',
                                    type: 'leave_approved',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Approuver'),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideX();
                }).toList(),

              const SizedBox(height: 32),

              Text(
                'Pointages récents',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 16),

              if (_attendanceService.allRecords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(20), boxShadow: AppStyles.softShadow, border: Border.all(color: Colors.white, width: 2)),
                  child: const Center(
                    child: Text('Aucun pointage récent.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ).animate().fadeIn(delay: 600.ms)
              else
                ..._attendanceService.allRecords.take(5).map((record) {
                  final isClockIn = record.type == 'IN';
                  final timeStr = DateFormat('HH:mm').format(record.timestamp);
                  final name = record.userName ?? 'Employé inconnu';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(20), boxShadow: AppStyles.softShadow, border: Border.all(color: Colors.white, width: 2)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isClockIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          child: Icon(isClockIn ? Icons.login : Icons.logout, color: isClockIn ? Colors.green : Colors.red, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                              Text(isClockIn ? 'Entrée enregistrée' : 'Sortie enregistrée', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideX();
                }).toList(),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(20), boxShadow: AppStyles.softShadow, border: Border.all(color: Colors.white, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _generateReport(BuildContext context) async {
    bool isDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF7A3FF3)),
                  const SizedBox(height: 24),
                  const Text('Génération du rapport en cours...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Compilation des données de présence et des demandes de congé.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) => isDialogOpen = false);

    // Call actual PDF generation with real data
    try {
      final pendingCount = _leaveService.allRequests.where((r) => r.status == 'En attente').length;
      final today = DateTime.now();
      final presentToday = _attendanceService.allRecords
          .where((r) => r.type == 'IN' && r.timestamp.day == today.day && r.timestamp.month == today.month && r.timestamp.year == today.year)
          .map((r) => r.userId)
          .toSet()
          .length;
      await PdfService.generateAndPrintReport(
        _totalEmployees,
        presentToday,
        pendingCount,
        attendanceRecords: _attendanceService.allRecords,
        leaveRequests: _leaveService.allRequests,
      );
    } catch (e) {
      debugPrint('Erreur PDF: $e');
    }

    if (isDialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close dialog
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rapport PDF généré et téléchargé avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
  }
}
