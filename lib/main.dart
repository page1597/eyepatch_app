import 'dart:async';
import 'package:eyepatch_app/detailPage.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
  // final flutterReactiveBle = FlutterReactiveBle();
  // StreamSubscription? _subscription;
  // late final List<DiscoveredDevice> _deviceList = []; // 스캔한 기기의 목록
  // late List<DeviceConnectionState> _deviceStateList = []; // 스캔한 기기의 연결 상태 목록
  // late DiscoveredDevice _device; // 현재 연결 기기
  // late StreamSubscription _deviceSubscription;

  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  late final List<ScanResult> _resultList = [];
  late List<bool> _deviceStateList = []; //나중엥 변경하기
  late ScanResult _result;

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
    _resultList.clear(); //초기화p
    _deviceStateList.clear();
    setState(() {});
    // ;

    if (await getPermission()) {
      flutterBlue.startScan(timeout: const Duration(seconds: 10));

      var subscription = flutterBlue.scanResults.listen((results) {
        for (ScanResult r in results) {
          print(r);
          print(
              'r.advertisementData: ${r.advertisementData.manufacturerData[0]}');

          setState(() {
            _resultList.add(r);
            _deviceStateList.add(false);
          });
        }
      });

      flutterBlue.stopScan();
    }
    // setState(() {
    //   _deviceStateList = List.filled(_deviceList.length, false);
    // });
    // print(_deviceList);
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

  read() async {
    print('이거!!: ${_result.advertisementData}');
    // _result.advertisementData.

    List<BluetoothService> services = await _result.device.discoverServices();
    // services
    services.forEach((service) async {
      var characteristics = service.characteristics;
      print(characteristics);
      // for (BluetoothCharacteristic c in characteristics) {
      //   List<int> value = await c.read();
      //   print(value);
      // }
    });
  }

  connect() async {
    print('연결');
    try {
      await _result.device.connect();
      int index = _resultList.indexOf(_result);
      _deviceStateList[index] = true;
      setState(() {});
      print('연결되었습니다.');
    } catch (e) {
      print('에러: $e');
    }
    // print(a.)

    read();
  }

  disconnect() {
    _result.device.disconnect();
    int index = _resultList.indexOf(_result);

    _deviceStateList[index] = false;
    setState(() {});
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
                              // if (_deviceStateList[index] == true) {
                              //   Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //           builder: (context) => DetailPage(
                              //               device: _deviceList[index],
                              //               connectionState:
                              //                   _deviceStateList[index])));
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
                                    if (_deviceStateList[index] == false) {
                                      connect();
                                    } else if (_deviceStateList[index] ==
                                        true) {
                                      disconnect();
                                    }
                                  },
                                  child: Text(
                                    _deviceStateList[index].toString(),
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
