import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:eyepatch_app/database/devices.dart';
import 'package:eyepatch_app/page/patchList.dart';
import 'package:eyepatch_app/style/palette.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/route_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'database/dbHelper.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  _initializeNotification();
  tz.initializeTimeZones();

  runApp(const GetMaterialApp(home: MyApp()));
}

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print("백그라운드 메시지 처리: ${message.notification!.body}");
// }

_initializeNotification() async {
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidInitSettings =
      AndroidInitializationSettings('mipmap/ic_launcher');
  const iosInitSettings = DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
  );
  const initSettings = InitializationSettings(
    android: androidInitSettings,
    iOS: iosInitSettings,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
          'high_importance_channel', 'high_importance_notification',
          importance: Importance.max));

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  //     alert: true, badge: true, sound: true);
}

class FallbackCupertinoLocalisationsDelegate extends LocalizationsDelegate {
  const FallbackCupertinoLocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future load(Locale locale) => DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(FallbackCupertinoLocalisationsDelegate old) => false;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // LocalJsonLocalization.delegate.directories = ['lib/i18n'];
    // final Future<FirebaseApp> _initialization = Firebase.initializeApp();

    return MaterialApp(
      localizationsDelegates: const [
        // delegate from flutter_localization
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        FallbackCupertinoLocalisationsDelegate(),
      ],
      // localizationsDelegates: [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   // if it's a RTL language
      // ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        // include country code too
      ],
      debugShowCheckedModeBanner: false,
      title: 'Eye Patch Scan App',
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: const MyHomePage(title: 'Eye Patch Scan App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String messageString = "";
  @override
  void initState() {
    // getDeviceToken();

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    //   RemoteNotification? notification = message.notification;

    //   if (notification != null) {
    //     PermissionStatus status = await Permission.notification.request();
    //     if (status.isGranted) {
    //       FlutterLocalNotificationsPlugin().show(
    //           notification.hashCode,
    //           notification.title,
    //           notification.body,
    //           const NotificationDetails(
    //               android: AndroidNotificationDetails(
    //                   'high_importance_channel', 'high_importance_notification',
    //                   importance: Importance.max)));
    //     } else {
    //       print("알람 권한 허용이 거부되었습니다.");
    //     }
    //   }
    //   setState(() {
    //     messageString = message.notification!.body!;
    //     print("Foreground 메시지 수신: $messageString");
    //   });
    // });

    super.initState();
    // getPermission();
  }

  // getDeviceToken() async {
  //   final token = await FirebaseMessaging.instance.getToken();
  //   print("내 디바이스 토큰: $token");
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'EyePatch',
            style: TextStyle(fontSize: 20.0),
          ),
          foregroundColor: Palette.primary1,
          backgroundColor: Colors.white,
          elevation: 0.0,
          toolbarHeight: 70.0,
        ),
        body: const PatchList());
  }
}
