import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final flutterReactiveBle = FlutterReactiveBle();
  StreamSubscription? _subscription;
  late final List<DiscoveredDevice> _deviceList = []; // 스캔한 기기의 목록
  late List<DeviceConnectionState> _deviceStateList = []; // 스캔한 기기의 연결 상태 목록
  // late final
  late DiscoveredDevice _device; // 현재 연결 기기
  // late ConnectionState _connectionState = ConnectionState.disconnected;
  late StreamSubscription _deviceSubscription;

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
    _deviceList.clear(); //초기화
    _deviceStateList.clear();

    if (await getPermission()) {
      // flutterReactiveBle.readCharacteristic(characteristic)
      _subscription = flutterReactiveBle.scanForDevices(
          withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
        if (!_deviceList.toString().contains(device.id.toString())) {
          //중복 x
          print(device);

          setState(() {
            _deviceList.add(device);
            _deviceStateList.add(DeviceConnectionState.disconnected);
          });
        }
        // print('서비스: ${flutterReactiveBle.discoverServices(_device.id)}');

        //code for handling results
      }, onError: (error) {
        print(error);
        //code for handling error
      });

      // flutterReactiveBle.readCharacteristic()o
    }
    // setState(() {
    //   _deviceStateList =
    //       List.filled(_deviceList.length, ConnectionState.disconnected);
    // });
    Timer(const Duration(seconds: 10), (() {
      stopScan();
    }));
    setState(() {});
    // return _deviceList;
    // return scanResult;
  }

  stopScan() {
    // 검색 중지
    _subscription?.cancel();
    _subscription = null;
  }

  Future<List<DiscoveredService>> discoverServices(String deviceId) =>
      flutterReactiveBle.discoverServices(deviceId);

  connect() {
    print('연결');
    // var services = flutterReactiveBle.discoverServices(_device.id);
    // services.forEach((element) {
    //   print(element);
    // });
    // var services = discoverServices(_device.id);
    // services.then((value) => print(value));

    // print('서비스: ${flutterReactiveBle.discoverServices(_device.id).then((value) => null)}');
    //해당 기기와 연결
    //flutterReactiveBle.connectToAdvertisingDevice -> 장치가 발견된 경우에만 연결
    _deviceSubscription = flutterReactiveBle
        .connectToDevice(
            id: _device.id, connectionTimeout: const Duration(seconds: 20))
        .listen((event) {
      print('연결 상태: ${event.connectionState}');

      int index = _deviceList.indexOf(_device);

      setState(() {
        _deviceStateList[index] = event.connectionState;
      });
      // 연결된 경우에만
      if (event.connectionState == DeviceConnectionState.connected) {
        // Notivy
        // final characteristic = QualifiedCharacteristic(
        //     serviceId: _device.,
        //     characteristicId: _device.serviceUuids[0],
        //     deviceId: _device.id);
        // flutterReactiveBle.subscribeToCharacteristic(characteristic).listen(
        //     (data) {
        //   print(data);
        //   // code to handle incoming data
        // }, onError: (dynamic error) {
        //   // code to handle errors
        // });
      }
    }, onError: (error) {
      print(error);
    });
    setState(() {});
  }

  disconnect() {
    try {
      // _subscription?.cancel();
      // _subscription = null;
      _deviceSubscription.cancel();
      int index = _deviceList.indexOf(_device);

      setState(() {
        _deviceStateList[index] = DeviceConnectionState.disconnected;
      });
    } on Exception catch (e, _) {
      print(e);
    }
  }

  clearBle() async {
    // await flutterReactiveBle.clearGattCache(deviceId);  //화면이 dispose 되는 경우에 적용시켜 캐시를 청소해
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
                          return ListTile(
                            title: Text(_deviceList[index].name),
                            subtitle: Text(_deviceList[index].id),
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
                                  _device = _deviceList[index]; // 선택한 기기
                                  setState(() {});
                                  if (_deviceStateList[index] ==
                                      DeviceConnectionState.disconnected) {
                                    connect();
                                  } else if (_deviceStateList[index] ==
                                      DeviceConnectionState.connected) {
                                    disconnect();
                                  }
                                },
                                child: Text(
                                  _deviceStateList[index].name,
                                  // _connectionState == ConnectionState.disconnected
                                  //     ? '연결하기'
                                  //     : '연결끊기',
                                  // connectButtonTextList[r.device.id.toString()].toString() == 'null'
                                  //     ? '연결하기'
                                  //     : connectButtonTextList[r.device.id.toString()].toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            // trailing: ,
                          );
                        },
                        separatorBuilder: (context, index) {
                          return const Divider();
                        },
                        itemCount: _deviceList.length))
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
