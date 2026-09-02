import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_provider.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class NotificationInboxPage extends StatelessWidget {
  const NotificationInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
        actions: [
          if (notificationProvider.hasUnread)
            TextButton(
              onPressed: () {
                HapticsService.selection();
                notificationProvider.markAllAsRead();
              },
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.gold,
                ),
              ),
            ),
          if (notifications.isNotEmpty)
            IconButton(
              tooltip: 'Clear All Notifications',
              icon: Icon(Icons.delete_sweep_outlined, color: context.textMuted, size: 22),
              onPressed: () async {
                HapticsService.mediumImpact();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: ctx.cardBg,
                    title: Text('Clear All Notifications?', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: ctx.textPrimary)),
                    content: Text('This will remove all notifications from your inbox.', style: GoogleFonts.inter(fontSize: 13, color: ctx.textMuted)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: ctx.textMuted))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brick, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  for (final n in List.of(notifications)) {
                    await notificationProvider.delete(n.id);
                  }
                }
              },
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
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_none_rounded, size: 48, color: context.gold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Inbox is Empty',
                      style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Daily ledger reminders, budget warnings, and recurring transaction notices will appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
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
    Color iconColor = context.gold;
    if (notification.type == 'budget') {
      icon = Icons.pie_chart_outline_rounded;
      iconColor = context.brick;
    } else if (notification.type == 'reminder') {
      icon = Icons.alarm_rounded;
      iconColor = context.gold;
    } else if (notification.type == 'alert') {
      icon = Icons.warning_amber_rounded;
      iconColor = context.brick;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: notification.isRead ? context.line : context.gold.withValues(alpha: 0.5),
          width: notification.isRead ? 1.0 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () {
            HapticsService.selection();
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
                    color: iconColor.withValues(alpha: 0.12),
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
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.gold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textMuted,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormatter.format(notification.date),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: context.textMuted.withValues(alpha: 0.7),
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
