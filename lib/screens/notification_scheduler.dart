
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationDemo extends StatefulWidget {
  const NotificationDemo({super.key});

  @override
  _NotificationDemoState createState() => _NotificationDemoState();
}

class _NotificationDemoState extends State<NotificationDemo> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  TimeOfDay _selectedTime = TimeOfDay.now();
  List<PendingNotificationRequest> _pendingNotifications = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    tz.initializeTimeZones();
    _loadPendingNotifications();
  }

  Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  // ✅ FIXED: Use named 'settings:' parameter (required in v20.x)
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,                    // ← THIS WAS MISSING
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('Notification tapped: ${response.payload}');
    },
    // You can also add this if you ever need background handling:
    // onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) {
    //   print('Background notification tapped: ${response.payload}');
    // },
  );
}

  Future<void> _scheduleDailyNotification() async {
  final now = DateTime.now();
  var scheduledDate = DateTime(
    now.year,
    now.month,
    now.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'reminder_channel_id',
    'Daily Practice Reminders',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);

  final int id = scheduledDate.millisecondsSinceEpoch ~/ 1000;

  // ✅ FIXED: Use named parameters (required in v20.x)
  await flutterLocalNotificationsPlugin.zonedSchedule(
    id: id,
    title: 'Time to Practice!',
    body: "Don't forget your daily WordSteps session",
    scheduledDate: tzScheduledDate,
    notificationDetails: notificationDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  await _loadPendingNotifications();
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily reminder set!')),
    );
  }
}

  Future<void> _loadPendingNotifications() async {
    final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    setState(() {
      _pendingNotifications = pending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Reminders')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Reminder Time'),
                subtitle: Text(_selectedTime.format(context)),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) {
                      setState(() => _selectedTime = picked);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scheduleDailyNotification,
              child: const Text('Set Daily Reminder'),
            ),
            const SizedBox(height: 30),
            const Text('Scheduled Reminders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: _pendingNotifications.isEmpty
                  ? const Center(child: Text('No reminders set'))
                  : ListView.builder(
                      itemCount: _pendingNotifications.length,
                      itemBuilder: (context, index) {
                        final notif = _pendingNotifications[index];
                        return ListTile(
                          title: Text('Reminder #${notif.id}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await flutterLocalNotificationsPlugin.cancel(
                                id: notif.id,
                              );
                              await _loadPendingNotifications();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}