import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_provider.dart';

class NotificationInboxPage extends StatelessWidget {
  const NotificationInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
        actions: [
          if (notificationProvider.hasUnread)
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(),
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gold,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppTheme.paper2,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.gold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Inbox is Empty',
                      style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Daily ledger reminders, budget warnings, and recurring transaction notices will appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = notifications[idx];
                return _buildNotificationCard(context, item, notificationProvider);
              },
            ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification, NotificationProvider provider) {
    IconData icon = Icons.notifications_rounded;
    Color iconColor = AppTheme.gold;
    if (notification.type == 'budget') {
      icon = Icons.pie_chart_outline_rounded;
      iconColor = AppTheme.brick;
    } else if (notification.type == 'reminder') {
      icon = Icons.alarm_rounded;
      iconColor = AppTheme.gold;
    } else if (notification.type == 'alert') {
      icon = Icons.warning_amber_rounded;
      iconColor = AppTheme.brick;
    }

    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? AppTheme.paperCard : AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: notification.isRead ? AppTheme.line : AppTheme.gold.withOpacity(0.5),
          width: notification.isRead ? 1.0 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () {
            if (!notification.isRead) {
              provider.markAsRead(notification.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.gold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.muted,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormatter.format(notification.date),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.muted.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
