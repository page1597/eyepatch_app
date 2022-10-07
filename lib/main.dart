import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

enum ConnectionState { connected, disconnected, connecting, disconnecting }

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
  late List<DiscoveredDevice> _scanResultList = []; // 스캔한 기기의 목록
  late DiscoveredDevice _device; // 현재 연결 기기
  late ConnectionState _connectionState = ConnectionState.disconnected;

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
    _scanResultList.clear(); //초기화

    if (await getPermission()) {
      _subscription = flutterReactiveBle.scanForDevices(
          withServices: [], scanMode: ScanMode.balanced).listen((device) {
        if (!_scanResultList.toString().contains(device.id.toString())) {
          //중복 x
          print(device);
          _scanResultList.add(device);
          setState(() {});
        }

        //code for handling results
      }, onError: (error) {
        print(error);
        //code for handling error
      });
    }
    Timer(const Duration(seconds: 10), (() {
      stopScan();
    }));
    setState(() {});
    // return _scanResultList;
    // return scanResult;
  }

  stopScan() {
    // 검색 중지
    _subscription?.cancel();
    _subscription = null;
    setState(() {
      _connectionState = ConnectionState.disconnected;
    });
  }

  connect() {
    //해당 기기와 연결
    //flutterReactiveBle.connectToAdvertisingDevice -> 장치가 발견된 경우에만 연결
    flutterReactiveBle
        .connectToDevice(
            id: _device.id, connectionTimeout: const Duration(seconds: 20))
        .listen((event) {
      print('연결 상태: ${event.connectionState}');
      switch (event.connectionState) {
        case DeviceConnectionState.connected:
          setState(() {
            _connectionState = ConnectionState.connected;
          });
          break;
        case DeviceConnectionState.connecting:
          setState(() {
            _connectionState = ConnectionState.connecting;
          });
          break;
        case DeviceConnectionState.disconnecting:
          setState(() {
            _connectionState = ConnectionState.disconnecting;
          });
          break;
        case DeviceConnectionState.disconnected:
          setState(() {
            _connectionState = ConnectionState.disconnected;
          });
          // TODO: Handle this case.
          break;
      }
    }, onError: (error) {
      print(error);
    });
  }

  disconnect() {
    try {
      _subscription?.cancel();
      _subscription = null;

      setState(() {
        _connectionState = ConnectionState.disconnected;
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
            Expanded(
                child: ListView.separated(
                    shrinkWrap: false,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_scanResultList[index].name),
                        subtitle: Text(_scanResultList[index].id),
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
                                side:
                                    const BorderSide(color: Colors.transparent),
                                backgroundColor: Colors.blue),
                            onPressed: () {
                              // 연결, 연결 끊기
                              _device = _scanResultList[index]; // 선택한 기기
                              setState(() {});
                              if (_connectionState ==
                                  ConnectionState.disconnected) {
                                connect();
                              } else if (_connectionState ==
                                  ConnectionState.connected) {
                                disconnect();
                              }
                            },
                            child: Text(
                              _connectionState.name,
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
                    itemCount: _scanResultList.length)),
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
