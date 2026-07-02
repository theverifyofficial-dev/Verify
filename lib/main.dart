import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Verify/Screens/Splash.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


Future<void> initLocalNotifications() async {

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings =
  DarwinInitializationSettings();

  const InitializationSettings settings =
  InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(settings);

  const AndroidNotificationChannel channel =
  AndroidNotificationChannel(
    'vehicle_alerts_v2',
    'Vehicle Alerts',
    description: 'Critical vehicle alert notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<String> getFCMToken() async {
  try {

    if (Platform.isIOS) {

      final apnsToken =
      await FirebaseMessaging.instance.getAPNSToken();

      debugPrint("APNS TOKEN: $apnsToken");

      if (apnsToken == null) {
        return "";
      }
    }

    final token =
    await FirebaseMessaging.instance.getToken();

    debugPrint("FCM TOKEN: $token");

    return token ?? "";

  } catch (e) {

    debugPrint("FCM ERROR: $e");

    return "";
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {

  await Firebase.initializeApp();

  await showVehicleAlert(message);
}

Future<void> showVehicleAlert(RemoteMessage message) async {

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,

    message.data['title'] ?? "Vehicle Alert",
    message.data['body'] ?? "Alert received",

    NotificationDetails(
      android: AndroidNotificationDetails(
        'vehicle_alerts_v2',
        'Vehicle Alerts',

        importance: Importance.max,
        priority: Priority.high,

        playSound: true,
        enableVibration: true,

        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,

        ticker: 'Vehicle Alert',
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await initLocalNotifications();

  /// Background notifications
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {

    try {

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isIOS) {

        final apnsToken =
        await FirebaseMessaging.instance.getAPNSToken();

        debugPrint("APNS TOKEN: $apnsToken");

        if (apnsToken != null) {
          await FirebaseMessaging.instance
              .subscribeToTopic("wollengod");
        }

      } else {

        await FirebaseMessaging.instance
            .subscribeToTopic("wollengod");
      }

    } catch (e) {

      debugPrint("FCM INIT ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Verify',

      /// FIXED LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,

        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onSurface: Colors.black87,
        ),
      ),

      home: SplashScreen(),
    );
  }
}