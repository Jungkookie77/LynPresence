import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_styles.dart';
import '../core/services/attendance_service.dart';
import '../core/services/leave_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final AttendanceService _attendance;
  late final LeaveService _leave;

  @override
  void initState() {
    super.initState();
    _attendance = AttendanceService();
    _leave = LeaveService();
    _attendance.addListener(_refresh);
    _leave.addListener(_refresh);
  }

  @override
  void dispose() {
    _attendance.removeListener(_refresh);
    _leave.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// Calcule les heures travaillées ce mois à partir des records IN/OUT
  double _computeHoursThisMonth() {
    final now = DateTime.now();
    final records = _attendance.records
        .where((r) => r.timestamp.month == now.month && r.timestamp.year == now.year)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double total = 0;
    for (int i = 0; i + 1 < records.length; i++) {
      if (records[i].type == 'IN' && records[i + 1].type == 'OUT') {
        total += records[i + 1].timestamp.difference(records[i].timestamp).inMinutes / 60.0;
        i++; // sauter le OUT
      }
    }
    return total;
  }

  /// Heures par jour de la semaine courante (Lun=0..Ven=4)
  List<double> _hoursPerDayThisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final hours = List<double>.filled(5, 0);

    final weekRecords = _attendance.records
        .where((r) {
          final d = r.timestamp;
          return d.isAfter(monday.subtract(const Duration(seconds: 1))) &&
              d.isBefore(monday.add(const Duration(days: 5)));
        })
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 0; i + 1 < weekRecords.length; i++) {
      if (weekRecords[i].type == 'IN' && weekRecords[i + 1].type == 'OUT') {
        final dayIndex = weekRecords[i].timestamp.weekday - 1; // 0=Mon
        if (dayIndex < 5) {
          hours[dayIndex] += weekRecords[i + 1].timestamp
              .difference(weekRecords[i].timestamp)
              .inMinutes / 60.0;
        }
        i++;
      }
    }
    return hours;
  }

  @override
  Widget build(BuildContext context) {
    final records = _attendance.records;
    final totalPointages = records.length;
    final heuresMois = _computeHoursThisMonth();
    final congesRestants = _leave.availableDays;
    final demandesEnAttente = _leave.requests.where((r) => r.status == 'En attente').length;
    final heuresSemaine = _hoursPerDayThisWeek();
    final maxH = heuresSemaine.reduce((a, b) => a > b ? a : b).clamp(1.0, 12.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mes Statistiques',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Cards row 1
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Pointages\nTotal',
                      value: totalPointages.toString(),
                      icon: Icons.fingerprint,
                      color: const Color(0xFF7A3FF3),
                    ).animate().fadeIn().slideY(begin: 0.1),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Heures\nCe mois',
                      value: '${heuresMois.toStringAsFixed(1)}h',
                      icon: Icons.access_time,
                      color: const Color(0xFF66C2FF),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // KPI Cards row 2
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Congés\nRestants',
                      value: '${congesRestants}j',
                      icon: Icons.beach_access,
                      color: const Color(0xFFFFB347),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Demandes\nEn attente',
                      value: demandesEnAttente.toString(),
                      icon: Icons.pending_actions,
                      color: Colors.redAccent,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Text(
                'Heures cette semaine',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 8),
              Text(
                totalPointages == 0
                    ? 'Faites votre premier pointage pour voir vos stats !'
                    : 'Lundi → Vendredi de la semaine courante',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: 24),

              // Graphique hebdomadaire
              Container(
                height: 250,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 30, bottom: 20, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppStyles.cardShadow,
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxH + 1,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF7A3FF3).withOpacity(0.9),
                        tooltipBorderRadius: BorderRadius.circular(8),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toStringAsFixed(1)}h',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const style = TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12);
                            const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'];
                            final idx = value.toInt();
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(idx < days.length ? days[idx] : '', style: style),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(5, (i) => _buildBarGroup(i, heuresSemaine[i])),
                  ),
                ),
              ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              // Historique des demandes de congés
              const Text(
                'Historique des Congés',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 16),

              if (_leave.requests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppStyles.softShadow,
                  ),
                  child: const Center(
                    child: Text('Aucune demande de congé.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ).animate().fadeIn(delay: 700.ms)
              else
                ..._leave.requests.map((req) => _buildLeaveHistoryItem(req)).toList(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveHistoryItem(LeaveRequest req) {
    final fmt = (DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    Color statusColor;
    IconData statusIcon;
    switch (req.status) {
      case 'Approuvé':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Rejeté':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.type,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
                Text(
                  '${fmt(req.startDate)} → ${fmt(req.endDate)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(req.status,
                style: TextStyle(
                    color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 16,
          gradient: y > 0 ? AppColors.primaryGradient : null,
          color: y == 0 ? AppColors.textSecondary.withOpacity(0.1) : null,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            color: AppColors.textSecondary.withOpacity(0.05),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppStyles.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
        ],
      ),
    );
  }
}
