import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:eyepatch_app/database/devices.dart';
import 'package:eyepatch_app/detailPage.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'database/dbHelper.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await initializeService();
  runApp(const MyApp());
}

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });

//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }

//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
// }

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: null,
//       onBackground: null,
//     ),
//   );

//   service.startService();
// }

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      
      debugShowCheckedModeBanner: false,
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

      // if (await getPermission()) {
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
      // } else {
      //   flutterBlue.stopScan();
      // }
    }
  }

  // setBleConnectionState(BluetoothDeviceState event) {
  //   // int index = _resultList.indexOf(_result);
  //   switch (event) {
  //     case BluetoothDeviceState.disconnected:
  //       Fluttertoast.showToast(msg: '연결이 끊어졌습니다.');
  //       insertCsv(_resultList[_deviceIndex], dbHelper, startedTime);
  //       break;
  //     case BluetoothDeviceState.connected:
  //       Fluttertoast.showToast(msg: '연결되었습니다.');
  //       break;
  //     case BluetoothDeviceState.connecting:
  //       break;
  //     case BluetoothDeviceState.disconnecting:
  //       break;
  //   }
  //   setState(() {
  //     _deviceStateList[_deviceIndex] = event;
  //   });
  // }

  connect() async {
    debugPrint('연결');
    Fluttertoast.showToast(msg: '연결하는 중입니다.');
    Future<bool>? returnValue;

    _resultList[_deviceIndex].device.state.listen((event) {
      if (_deviceStateList[_deviceIndex] == event) {
        return;
      }
      // setBleConnectionState(event);
    });

    try {
      await _resultList[_deviceIndex]
          .device
          .connect(autoConnect: false)
          .timeout(const Duration(milliseconds: 10000), onTimeout: () {
        returnValue = Future.value(false);
        // setBleConnectionState(BluetoothDeviceState.disconnected);
      }).then((value) => {
                if (returnValue == null)
                  {Fluttertoast.showToast(msg: '연결되었습니다.')}
              });
    } catch (e) {
      print('에러: $e');
    }
  }

  // disconnect() {
  //   _resultList[_deviceIndex].device.disconnect();
  //   insertCsv(_resultList[_deviceIndex], dbHelper,);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        toolbarHeight: 0.0,
      ),
      body: Stack(children: [
        Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(235, 184, 211, 236),
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24)),
          ),
          height: MediaQuery.of(context).size.height * 0.4,
        ),
        Positioned(
          child: Column(
            children: [
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    color: Colors.white,
                  ),
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
                            borderSide: BorderSide(color: Colors.transparent)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent)),
                        counterText: '',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color.fromARGB(199, 55, 85, 114),
                        ),
                        hintText: '기기의 번호를 입력하세요',
                        hintStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            color: Color.fromARGB(156, 95, 127, 158))),
                  ),
                ),
              ),
            ],
          ),
        ),
        _deviceStateList.isNotEmpty
            ? Positioned(
                top: 90,
                left: 22,
                right: 22,
                child: Container(
                  height: MediaQuery.of(context).size.height - 150,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 10.0,
                        offset:
                            const Offset(0, 0), // changes position of shadow
                      ),
                    ],
                  ),
                  child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // flutterBlue.turnOff();
                            flutterBlue.stopScan().then((value) => {
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
                          },
                          child: ListTile(
                            title: Text(
                              _resultList[index].device.name,
                              style: TextStyle(
                                  // color: Color.fromARGB(156, 5, 60, 110),
                                  color: Color.fromARGB(199, 55, 85, 114),
                                  fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              _resultList[index].device.id.toString(),
                              style: TextStyle(
                                  color: Color.fromARGB(156, 95, 127, 158)),
                            ),
                            leading: const CircleAvatar(
                              backgroundColor:
                                  Color.fromARGB(255, 153, 191, 224),
                              child: Icon(
                                Icons.bluetooth,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider(
                          color: Colors.transparent,
                        );
                      },
                      itemCount: _resultList.length),
                ),
              )
            : Container(),
      ]),
      floatingActionButton: Container(
        height: 60,
        width: 60,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: scan,
            backgroundColor: Color.fromARGB(235, 184, 211, 236),
            elevation: 0,
            tooltip: 'scan',
            child: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
          ),
        ),
      ),
    );
  }
}
