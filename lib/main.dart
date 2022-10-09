import 'dart:async';
import 'dart:typed_data';
import 'dart:math';

import 'package:eyepatch_app/detailPage.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter/fl';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hex/hex.dart';
import 'package:convert/convert.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'database/dbHelper.dart';

// import 'flutterb';

void main() {
  runApp(const MyApp());
}

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
  late List<ScanResult> _resultList = [];
  late List<BluetoothDeviceState> _deviceStateList = []; //나중엥 변경하기
  late ScanResult _result;
  late dynamic uuid;
  DBHelper dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    print('get permission');
    getPermission();
  }

  getPermission() async {
    //권한 허용
    var scanStatus = await Permission.bluetoothScan.request();
    var advertiseStatus = await Permission.bluetoothAdvertise.request();
    var connectStatus = await Permission.bluetoothConnect.request();
    // var storageStatus = await Permission.storage.request();

    return scanStatus.isGranted &&
        advertiseStatus.isGranted &&
        connectStatus.isGranted;
    // &&
    // storageStatus.isGranted;
  }

  scan() async {
    setState(() {
      _resultList.clear(); //초기화
      _deviceStateList.clear();
      _resultList = [];
      _deviceStateList = [];
    });

    if (await getPermission()) {
      flutterBlue.startScan(timeout: const Duration(seconds: 10));

      flutterBlue.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (!_resultList.contains(r)) {
            setState(() {
              _resultList.add(r);
              _deviceStateList.add(BluetoothDeviceState.disconnected);
            });
          }
        }
      });
      flutterBlue.stopScan();
    }
  }

  // stopScan() {
  //   // 검색 중지
  //   _subscription?.cancel();
  //   _subscription = null;
  // }

  // Future<void> discoverServices() async {
  //   print('discover service..');
  //   // await flutterReactiveBle.discoverServices(_device.id).then((value) => {
  //   //       QualifiedCharacteristic(
  //   //           characteristicId: value, serviceId: serviceId, deviceId: deviceId)
  //   //     });
  // }

  // read() async {
  //   try {
  //     List<BluetoothService> services = await _result.device.discoverServices();
  //     // services
  //     services.forEach((service) async {
  //       // print(service.uuid);
  //       // if (service.uuid == '0000fff0-0000-1000-8000-00805f9b34fb') {
  //       var characteristics = service.characteristics;

  //       // for (BluetoothCharacteristic c in characteristics) {
  //       //   // List<int> value = await c.read();
  //       //   // print(value);
  //       //   print(c);
  //       //   if (c.uuid.toString().contains('fff0')) {
  //       //     print('set notify');
  //       //     await c.setNotifyValue(true);
  //       //     c.value.listen((value) async {
  //       //       print('value: $value');
  //       //     });
  //       //   }
  //       // }
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }
  setBleConnectionState(BluetoothDeviceState event) {
    int index = _resultList.indexOf(_result);
    switch (event) {
      case BluetoothDeviceState.disconnected:
        Fluttertoast.showToast(msg: '연결이 끊어졌습니다.');
        // exit();
        insertCsv(_resultList[index], dbHelper);
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
      _deviceStateList[index] = event;
    });
  }

  connect() async {
    print('연결');
    Fluttertoast.showToast(msg: '연결하는 중입니다.');
    int index = _resultList.indexOf(_result);
    Future<bool>? returnValue;

    _result.device.state.listen((event) {
      if (_deviceStateList[index] == event) {
        return;
      }
      setBleConnectionState(event);
    });

    try {
      await _result.device.connect(autoConnect: false).timeout(
          const Duration(milliseconds: 10000), onTimeout: () {
        returnValue = Future.value(false);
        setBleConnectionState(BluetoothDeviceState.disconnected);
      }).then((value) => {
            if (returnValue == null) {Fluttertoast.showToast(msg: '연결되었습니다.')}
          });
    } catch (e) {
      print('에러: $e');
    }
  }

  disconnect() {
    int index = _resultList.indexOf(_result);
    // setState(() {
    //   _deviceStateList[index] = BluetoothDeviceState.disconnecting;
    // });

    _result.device.disconnect();
    insertCsv(_resultList[index], dbHelper);
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
                // controller: _inputController,
                maxLength: 2,
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  // setState(() {
                  //   _connectingDevice = int.parse(_inputController.text);
                  // });
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
                              if (_deviceStateList[index] ==
                                  BluetoothDeviceState.connected) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => DetailPage(
                                              result: _resultList[index],
                                              deviceState: BluetoothDeviceState
                                                  .connected,
                                              dbHelper: dbHelper,
                                            )));
                              } else {
                                Fluttertoast.showToast(
                                    msg: '기기와 연결한 후 다시 시도하세요');
                              }
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
                              trailing: SizedBox(
                                width: 100,
                                height: 40,
                                child: ElevatedButton(
                                  style: OutlinedButton.styleFrom(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: const BorderSide(
                                          color: Colors.transparent),
                                      backgroundColor: Colors.blue),
                                  onPressed: () {
                                    // 연결, 연결 끊기
                                    _result = _resultList[index]; // 선택한 기기
                                    setState(() {});
                                    if (_deviceStateList[index] ==
                                        BluetoothDeviceState.disconnected) {
                                      connect();
                                    } else if (_deviceStateList[index] ==
                                            BluetoothDeviceState.connected ||
                                        _deviceStateList[index] ==
                                            BluetoothDeviceState.connecting) {
                                      disconnect();
                                    }
                                  },
                                  child: Text(
                                    _deviceStateList[index] ==
                                            BluetoothDeviceState.disconnected
                                        ? '연결하기'
                                        : '연결끊기',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              // trailing: ,
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
        child: const Icon(Icons.bluetooth_searching),
      ),
    );
  }
}
