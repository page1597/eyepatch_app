import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:eyepatch_app/database/dbHelper.dart';
import 'package:eyepatch_app/model.dart/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hex/hex.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_ios/shared_preferences_ios.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

import 'package:device_info_plus/device_info_plus.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS) {
    // await flutterLocalNotificationsPlugin.initialize(
    //   const InitializationSettings(
    //     iOS: IOSInitializationSettings(),
    //   ),
    // );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setString("hello", "world");

  /// OPTIONAL when use custom notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  double temperature = 0.0;

  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
        /// the notification id must be equals with AndroidConfiguration when you call configure() method.
        flutterLocalNotificationsPlugin.show(
          888,
          'EyePatch App',
          '온도: 27.65 C°, 패치 착용 여부: O',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );

        // if you don't using custom notification, uncomment this
        // service.setForegroundNotificationInfo(
        //   title: "My App Service",
        //   content: "Updated at ${DateTime.now()}",
        // );
      }
    }

    /// you can see this log in logcat
    print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    // test using external plugin
    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

class DetailPage extends StatefulWidget {
  final ScanResult result;
  final FlutterBluePlus flutterblue;

  final DBHelper dbHelper;
  const DetailPage(
      {Key? key,
      required this.result,
      required this.flutterblue,
      required this.dbHelper})
      : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

double calculate(Uint8List advertisingData, bool isPatch) {
  if (advertisingData.isEmpty) return 0.0;

  ByteData byteData = advertisingData.buffer.asByteData();
  double ambientV =
      byteData.getUint16(12, Endian.little) * 0.001; // 내부 전압 -> 주변온도
  double patchV = byteData.getUint16(14, Endian.little) * 0.001; // 패치 전압
  // 온도 센서 전압 내부, 온도센서 전압 패치
  double batteryV = byteData.getUint8(16) * 0.1; // 배터리 전압

  double sensorT = 0.0; // result
  double ambientC = 0.0; // result 섭씨 온도
  double patchT = 0.0;
  double patchC = 0.0;
  double b = 4250.0;
  double t0 = 298.15;
  double r = 75000.0;
  double r0 = 100000.0;

  sensorT = (b * t0) /
      (b + (t0 * (log((ambientV * r) / (r0 * (batteryV - ambientV))))));
  ambientC = sensorT - 273.15;

  patchT = (b * t0) /
      (b + (t0 * (log((ambientV * r) / (r0 * (batteryV - patchV))))));
  patchC = patchT - 273.15;

  if (isPatch) {
    return patchC;
  } else {
    return ambientC;
  }
}

insertSql(ScanResult info, DBHelper dbHelper, bool justButton) async {
  if (!justButton) {
    dbHelper.insertBle(Ble(
      id: await dbHelper.getLastId(info.device.name) + 1,
      device: info.device.id.toString(),
      patchTemp: calculate(info.advertisementData.rawBytes, false),
      ambientTemp: calculate(info.advertisementData.rawBytes, true),
      rawData: HEX.encode(info.advertisementData.rawBytes),
      timeStamp: DateTime.now().millisecondsSinceEpoch,
    ));

    Fluttertoast.showToast(msg: 'sql에 저장', toastLength: Toast.LENGTH_SHORT);
  } else {
    // 그냥 버튼
    dbHelper.insertBle(Ble(
      id: await dbHelper.getLastId(info.device.name) + 1,
      device: info.device.id.toString(),
      patchTemp: 0.0,
      ambientTemp: 0.0,
      rawData: 'button clicked',
      timeStamp: DateTime.now().millisecondsSinceEpoch,
    ));
    Fluttertoast.showToast(msg: '버튼 클릭', toastLength: Toast.LENGTH_SHORT);
  }
}

// onButtonClick(DBHelper dbHelper) async {
//    dbHelper.insertBle(Ble(
//     id: await dbHelper.getLastId() + 1,
//     device: info.device.id.toString(),
//     temp: calculate(info.advertisementData.rawBytes),
//     rawData: HEX.encode(info.advertisementData.rawBytes),
//     timeStamp: DateTime.now().millisecondsSinceEpoch,
//   ));
// }

// 갑작스럽게 연결이 끊기거나, 끊을 때 저장
insertCsv(ScanResult info, DBHelper dbHelper) {
  dbHelper.sqlToCsv(info.device.name);
  Fluttertoast.showToast(msg: '기록된 온도 정보가 저장되었습니다.');
  dbHelper.dropTable();
}

class _DetailPageState extends State<DetailPage> {
  final StreamController<ScanResult> _dataController =
      StreamController<ScanResult>.broadcast();
  int beforePacketNumber = 0; // 이전 패킷 넘버
  int timerTick = 0;
  bool inserted = false;
  bool started = false; // 실험 시작

  late Uint8List lastData = Uint8List.fromList([]);

  @override
  void initState() {
    super.initState();
    widget.dbHelper.dropTable();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Timer.periodic(const Duration(seconds: 7), (timer) {
      // 40
      widget.flutterblue.startScan();
      widget.flutterblue.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.device.id == widget.result.device.id) {
            //스캔 하는 시간때문에 딜레이가 걸림..
            // 스캔을 하는 상태여서 계속 딜레이가 걸림.. 그래서 중구난방으로 저장됨
            _dataController.sink.add(r);
          }
        }
      });

      widget.flutterblue.stopScan();
    });

    return StreamBuilder<ScanResult>(
        stream: _dataController.stream,
        builder: (context, snapshot) {
          // setState(() {
          //   temperature = 0.0;
          // });
          if (started) {
            if (snapshot.data!.advertisementData.rawBytes != lastData) {
              insertSql(snapshot.data!, widget.dbHelper, false);

              // setState(() {
              lastData = snapshot.data!.advertisementData.rawBytes;
              // });
            }
          }
          return WillPopScope(
            onWillPop: () async {
              if (snapshot.hasData && started) {
                Fluttertoast.showToast(
                    msg: '실험이 진행중입니다. 실험 종료 버튼을 누르고 뒤로가기 버튼을 눌러주세요.');

                // insertCsv(snapshot.data!, widget.dbHelper);
                return false;
              }
              return true;
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(widget.result.device.name),
              ),
              body: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          widget.result.device.id.toString(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Text(
                            'advertising data: ${HEX.encode(widget.result.advertisementData.rawBytes)}'),
                        const SizedBox(height: 24),
                        const Text(
                          '온도 정보: ',
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                              fontSize: 16),
                        ),

                        // if (snapshot.hasData) {

                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (snapshot.hasData)
                              Text(
                                '패치: ${calculate(snapshot.data!.advertisementData.rawBytes, true)}C°',
                                style: const TextStyle(
                                    fontSize: 42, color: Colors.blue),
                              ),
                            const SizedBox(height: 20),
                            if (snapshot.hasData)
                              Text(
                                '주변: ${calculate(snapshot.data!.advertisementData.rawBytes, false)}C°',
                                style: const TextStyle(
                                    fontSize: 42, color: Colors.blue),
                              ),
                            const SizedBox(height: 50),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                    style: TextButton.styleFrom(
                                      elevation: 5,
                                      backgroundColor: !started
                                          ? const Color.fromARGB(
                                              255, 61, 137, 199)
                                          : const Color.fromARGB(
                                              255, 199, 29, 17),
                                    ),
                                    onPressed: () {
                                      if (snapshot.hasData) {
                                        insertCsv(
                                            snapshot.data!, widget.dbHelper);
                                        setState(() {
                                          started = !started;
                                        });
                                      } else {
                                        Fluttertoast.showToast(
                                            msg: '아직 온도정보를 불러오기 전입니다.');
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Text(
                                        !started ? '실험 시작' : '실험 종료',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                        ),
                                      ),
                                    )),
                                const SizedBox(width: 50),
                                TextButton(
                                    style: TextButton.styleFrom(
                                      elevation: 5,
                                      backgroundColor:
                                          Color.fromARGB(255, 87, 86, 87),
                                    ),
                                    onPressed: () {
                                      // 그냥 버튼 눌렀다는 표시와 타임스탬프를 넣는다.
                                      if (snapshot.hasData) {
                                        insertSql(snapshot.data!,
                                            widget.dbHelper, true);
                                      } else
                                        Fluttertoast.showToast(
                                            msg: '아직 온도 정보를 불러오기 전입니다.');
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(7.0),
                                      child: const Text(
                                        '버튼',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ))
                              ],
                            ),
                          ],
                        )
                      ])),
            ),
          );
        });
  }
}
