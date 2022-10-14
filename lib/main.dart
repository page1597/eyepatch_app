import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:eyepatch_app/database/devices.dart';
import 'package:eyepatch_app/detailPage.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'database/dbHelper.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_ios/shared_preferences_ios.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

import 'package:device_info_plus/device_info_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

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

////////////////////////////////////////////////////////////////////////////////
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye Patch Scan App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  FlutterBluePlus flutterBlue2 = FlutterBluePlus.instance;

  late List<ScanResult> _resultList = [];
  late List<BluetoothDeviceState> _deviceStateList = []; //나중엥 변경하기
  // late ScanResult _result;
  late dynamic uuid;
  DBHelper dbHelper = DBHelper();
  TextEditingController _controller = TextEditingController();
  late StreamSubscription<ScanResult> _subscription;
  int _deviceIndex = 0;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    debugPrint('get permission');
    getPermission();
    initBle();
  }

  initBle() {
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
      setState(() {});
    });
  }

  getPermission() async {
    //권한 허용
    var scanStatus = await Permission.bluetoothScan.request();
    var advertiseStatus = await Permission.bluetoothAdvertise.request();
    var connectStatus = await Permission.bluetoothConnect.request();
    var storageStatus = await Permission.storage.request();

    return scanStatus.isGranted &&
        advertiseStatus.isGranted &&
        connectStatus.isGranted &&
        storageStatus.isGranted;
  }

  scan() async {
    if (!_isScanning) {
      setState(() {
        _resultList.clear(); //초기화
        _deviceStateList.clear();
        _resultList = [];
        _deviceStateList = [];
      });

      if (await getPermission()) {
        flutterBlue.startScan(timeout: const Duration(seconds: 7));
        // flutterBlue.scan()

        flutterBlue.scanResults.listen((results) {
          for (ScanResult r in results) {
            if (_controller.text.isEmpty) {
              if (!_resultList.contains(r)) {
                setState(() {
                  _resultList.add(r);
                  _deviceStateList.add(BluetoothDeviceState.disconnected);
                });
              }
            } else {
              if (r.device.id.toString() ==
                      devicesList[_deviceIndex]['address'].toString() &&
                  !_resultList.contains(r)) {
                setState(() {
                  _resultList.add(r);
                  _deviceStateList.add(BluetoothDeviceState.disconnected);
                });
              }
            }
          }
        });
      } else {
        flutterBlue.stopScan();
      }
    }
  }

  setBleConnectionState(BluetoothDeviceState event) {
    // int index = _resultList.indexOf(_result);
    switch (event) {
      case BluetoothDeviceState.disconnected:
        Fluttertoast.showToast(msg: '연결이 끊어졌습니다.');
        insertCsv(_resultList[_deviceIndex], dbHelper);
        break;
      case BluetoothDeviceState.connected:
        Fluttertoast.showToast(msg: '연결되었습니다.');
        break;
      case BluetoothDeviceState.connecting:
        break;
      case BluetoothDeviceState.disconnecting:
        break;
    }
    setState(() {
      _deviceStateList[_deviceIndex] = event;
    });
  }

  connect() async {
    debugPrint('연결');
    Fluttertoast.showToast(msg: '연결하는 중입니다.');
    Future<bool>? returnValue;

    _resultList[_deviceIndex].device.state.listen((event) {
      if (_deviceStateList[_deviceIndex] == event) {
        return;
      }
      setBleConnectionState(event);
    });

    try {
      await _resultList[_deviceIndex]
          .device
          .connect(autoConnect: false)
          .timeout(const Duration(milliseconds: 10000), onTimeout: () {
        returnValue = Future.value(false);
        setBleConnectionState(BluetoothDeviceState.disconnected);
      }).then((value) => {
                if (returnValue == null)
                  {Fluttertoast.showToast(msg: '연결되었습니다.')}
              });
    } catch (e) {
      print('에러: $e');
    }
  }

  disconnect() {
    _resultList[_deviceIndex].device.disconnect();
    insertCsv(_resultList[_deviceIndex], dbHelper);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                textInputAction: TextInputAction.search,
                controller: _controller,
                maxLength: 2,
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _deviceIndex = int.parse(_controller.text);
                    });
                  }
                },
                decoration: const InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color.fromRGBO(0, 80, 157, 100))),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color.fromRGBO(0, 80, 157, 100))),
                    counterText: '',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color.fromRGBO(0, 80, 157, 100),
                    ),
                    hintText: '연결할 기기의 번호를 입력하세요'),
              ),
            ),
            _deviceStateList.isNotEmpty
                ? Expanded(
                    child: ListView.separated(
                        shrinkWrap: false,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              // if (_deviceStateList[index] ==
                              //     BluetoothDeviceState.connected) {
                              flutterBlue.turnOff();
                              flutterBlue.stopScan().then((value) => {
                                    // if (value)
                                    // print(value)
                                    // if (flutterBlue.turnOff() == true)
                                    {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => DetailPage(
                                                    result: _resultList[index],
                                                    flutterblue: flutterBlue,
                                                    dbHelper: dbHelper,
                                                  )))
                                    }
                                  });

                              // } else {
                              //   Fluttertoast.showToast(
                              //       msg: '기기와 연결한 후 다시 시도하세요');
                              // }
                            },
                            child: ListTile(
                              title: Text(_resultList[index].device.name),
                              subtitle:
                                  Text(_resultList[index].device.id.toString()),
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.bluetooth,
                                  color: Colors.white,
                                ),
                              ),
                              // trailing: SizedBox(
                              //   width: 100,
                              //   height: 40,
                              //   child: ElevatedButton(
                              //     style: OutlinedButton.styleFrom(
                              //         elevation: 0,
                              //         shape: RoundedRectangleBorder(
                              //           borderRadius: BorderRadius.circular(12),
                              //         ),
                              //         side: const BorderSide(
                              //             color: Colors.transparent),
                              //         backgroundColor: Colors.blue),
                              //     onPressed: () {
                              //       // 연결, 연결 끊기
                              //       // _result = _resultList[index]; // 선택한 기기

                              //       setState(() {
                              //         _deviceIndex = index;
                              //       });
                              //       if (_deviceStateList[index] ==
                              //           BluetoothDeviceState.disconnected) {
                              //         connect();
                              //       } else if (_deviceStateList[index] ==
                              //               BluetoothDeviceState.connected ||
                              //           _deviceStateList[index] ==
                              //               BluetoothDeviceState.connecting) {
                              //         disconnect();
                              //       }
                              //     },
                              //     child: Text(
                              //       _deviceStateList[index] ==
                              //               BluetoothDeviceState.disconnected
                              //           ? '연결하기'
                              //           : '연결끊기',
                              //       style: const TextStyle(color: Colors.white),
                              //     ),
                              //   ),
                              // ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return const Divider();
                        },
                        itemCount: _resultList.length))
                : Container(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scan,
        tooltip: 'scan',
        child: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
      ),
    );
  }
}
