import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_styles.dart';
import '../core/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _notificationService.addListener(_onStateChanged);
    
    // Mark all as read when opening the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.markAllAsRead();
    });
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'leave_approved': return Icons.check_circle_outline;
      case 'leave_rejected': return Icons.cancel_outlined;
      case 'reminder': return Icons.access_time;
      default: return Icons.info_outline;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'leave_approved': return Colors.green;
      case 'leave_rejected': return Colors.red;
      case 'reminder': return Colors.orange;
      default: return const Color(0xFF7A3FF3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _notificationService.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        child: notifications.isEmpty
            ? const Center(child: Text('Aucune notification.', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final iconColor = _getColorForType(notif.type);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notif.isRead ? AppColors.glassWhite : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppStyles.softShadow,
                      border: notif.isRead ? null : Border.all(color: const Color(0xFF7A3FF3).withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: notif.isRead ? Colors.grey.shade100 : iconColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIconForType(notif.type), color: notif.isRead ? Colors.grey : iconColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd/MM HH:mm').format(notif.timestamp),
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif.message,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX();
                },
              ),
      ),
    );
  }
}
