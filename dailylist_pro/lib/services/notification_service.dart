import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Here you could navigate to specific task or handle the notification tap
  }

  // Request notification permissions
  static Future<bool> requestPermissions() async {
    try {
      // For Android 13+ we need to request notification permission
      final status = await Permission.notification.request();
      
      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        // Permission denied, but can be requested again
        return false;
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied, open app settings
        await openAppSettings();
        return false;
      }
      
      return status.isGranted;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Schedule a notification for a task
  static Future<void> scheduleNotification(Task task) async {
    // Skip scheduling for now since Task model doesn't have reminder/dueDate properties
    return;

    // TODO: Uncomment and implement when Task model has reminder, dueDate, dueTime properties
    /*
    if (!task.reminder || task.completed) return;

    try {
      await initialize();

      // Parse the due date and time
      final DateTime? dueDateTime = _parseTaskDateTime(task);
      if (dueDateTime == null || dueDateTime.isBefore(DateTime.now())) {
        return; // Don't schedule past notifications
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        sound: RawResourceAndroidNotificationSound('mixkit_facility_alarm_sound_999'),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'mixkit_facility_alarm_sound_999.wav',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        task.id.hashCode, // Use task ID hash as notification ID
        'Task Reminder',
        task.title,
        _convertToTZDateTime(dueDateTime),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id,
      );

      print('Scheduled notification for task: ${task.title} at $dueDateTime');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
    */
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(String taskId) async {
    try {
      await _notifications.cancel(taskId.hashCode);
      print('Cancelled notification for task: $taskId');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('Cancelled all notifications');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  // Reschedule notifications for all tasks
  static Future<void> rescheduleNotifications(List<Task> tasks, bool notificationsEnabled) async {
    await cancelAllNotifications();
    
    if (!notificationsEnabled) return;

    // TODO: Implement when Task model has reminder property
    // for (final task in tasks) {
    //   if (task.reminder && !task.completed) {
    //     await scheduleNotification(task);
    //   }
    // }
  }

  // Parse task date and time into DateTime
  static DateTime? _parseTaskDateTime(Task task) {
    // TODO: Implement when Task model has dueDate and dueTime properties
    return null;
    
    /*
    try {
      if (task.dueDate.isEmpty || task.dueTime.isEmpty) return null;

      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');
      
      final date = dateFormat.parse(task.dueDate);
      final time = timeFormat.parse(task.dueTime);
      
      return DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    } catch (e) {
      print('Error parsing task date/time: $e');
      return null;
    }
    */
  }

  // Convert DateTime to TZDateTime (required for scheduling)
  static dynamic _convertToTZDateTime(DateTime dateTime) {
    // For this implementation, we'll use the local timezone
    // In a production app, you might want to use a proper timezone library
    return dateTime;
  }

  // Check if notifications are enabled on the device
  static Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
}