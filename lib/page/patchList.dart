import 'dart:async';
import 'package:eyepatch_app/database/dbHelper.dart';
import 'package:eyepatch_app/main.dart';
import 'package:eyepatch_app/model/ble.dart';
import 'package:eyepatch_app/model/eyePatch.dart';
import 'package:eyepatch_app/model/eyePatchList.dart';
import 'package:eyepatch_app/page/patchDetail.dart';
import 'package:eyepatch_app/controller/patchController.dart';
import 'package:eyepatch_app/style/palette.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:eyepatch_app/database/devices.dart';
import 'package:localstorage/localstorage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:http/http.dart' as http;

class PatchList extends StatefulWidget {
  const PatchList({super.key});

  @override
  State<PatchList> createState() => _PatchListState();
}

class _PatchListState extends State<PatchList> {
  // EyePatchList _eyePatchList = EyePatchList();
  DBHelper dbHelper = DBHelper();

  final url = Uri.parse('https://');

  var eyePatchCount = 0;
  var showAddDialog = false;

  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  late List<ScanResult> _resultList = []; // scanResult
  // late List<BluetoothDeviceState> _resultStateList = [];
  var selectedIndex = -1;
  // bool _isScanning = false;

  final LocalStorage storage = LocalStorage('patchList.json');
  BluetoothDevice device = BluetoothDevice.fromId('');
  late Timer _timer;
  late Future<List<ScanResult>> _scanPatch;

  final eyePatchController = Get.put(EyePatchController());

  @override
  void initState() {
    super.initState();
    initializeNotification();
    // Future.delayed(const Duration(seconds: 3), {})

    debugPrint('initstate');
    getPermission();
    initBle();

    _scanPatch = scanPatch();

    // 현재 연결되어 있는 기기

    // _resultList.clear()

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    // 화면상에 목록으로 띄우기 위해서
    storage.ready.then((_) {
      print("storage.ready.then");
      print(storage.getItem('eyePatchList'));
      // storage.dispose();
      // storage.clear();
      List<dynamic> eyePatchList = storage.getItem('eyePatchList');
      print(storage.getItem('eyePatchList').length);
      print(storage.getItem('eyePatchList')[0]['prescribedDuration']);
      EyePatchList temp = EyePatchList();
      // bool connected = false;

      for (var item in eyePatchList) {
        print(item['ble']);
        // flutterBlue.connectedDevices.then((devices) => {
        //       devices.forEach((device) {
        //         if (device.id == item["ble"]) {
        //           connected = true;
        //         }
        //       })
        //       // if (devices.contains(item))
        //       // devices.contains(item)
        //     });

        temp.eyePatches.add(
          EyePatch(
              ble: item['ble'],
              pid: item['pid'],
              name: item['name'],
              phone: item['phone'],
              prescribedDuration: item['prescribedDuration'],
              // connected: item['connected'],
              leftRatio: item['leftRatio'],
              alarm: item['alarm']),
        );
      }
      Get.find<EyePatchController>().updateList(temp);

      // Get.find<Controller>().setState(() {
      //   _eyePatchList = temp;
      // });

// 안드로이드에서 특히, 몇시간 동안 돌려보기 꺼지는지 확인 .
      // 백그라운드 동작하게 하기.
      // device.connect();
      // 4/4 4:17 device.connect(autoConnect: true); 로 변경하기

      // _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      //   var connectedDevices = flutterBlue.connectedDevices; // 현재 연결되어있는 기기

      //   connectedDevices.then((devices) async {
      //     // 연결되어 있는 기기가 없을 때
      //     if (devices.isEmpty) {
      //       for (var element in eyePatchList) {
      //         device = BluetoothDevice.fromId(element['ble']);
      //         connect(device);
      //       }

      //       // var subscription = await scan();
      //       // subscription.onData((data) {
      //       //   for (var element in data) {
      //       //     for (var patch in _eyePatchList.eyePatches) {
      //       //       if (element.device.id.id == patch.ble) {
      //       //         isNearbyDevice = true;
      //       //         setState(() {
      //       //           device = BluetoothDevice.fromId(element.device.id.id);
      //       //         });
      //       //         connect(device); // 근데 하나만 연결해야됨
      //       //         subscription.cancel();
      //       //       } else {
      //       //         isNearbyDevice = false;
      //       //       }
      //       //     }
      //       //   }
      //       // });
      //     } else {
      //       // isNearbyDevice = true; // 이미 연결된 기기가 있을 경우
      //     }
      //   });
      //   // if (!isNearbyDevice) {
      //   //   Fluttertoast.showToast(msg: '주변에 있는 기기(패치)가 없습니다.');
      //   // }
      // });
    });
    // });

    // if (storage.getItem('eyePatchList') != null) {}
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  initBle() {
    flutterBlue.isScanning.listen((isScanning) {
      setState(() {});
    });
  }

  getPermission() async {
    debugPrint('권한 허용');
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

  makeDate(hour, min, sec) {
    var now = tz.TZDateTime.now(tz.local);
    print(now);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, min, sec);
    if (when.isBefore(now)) {
      print("isbefore");
      return when.add(const Duration(days: 1));
    } else {
      print("isAfter");
      return when;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("빌드");
    // EyePatchList eyePatchList = controller.eyePatchList;
    // print(eyePatchList);
    // bool connected = false;
    // flutterBlue.connectedDevices.then((devices) => {
    //       devices.forEach((device) {
    //         for (var element in eyePatchController.eyePatchList.eyePatches) {
    //           print(element.ble);
    //           if (element.ble == device.id.toString()) {
    //             // connected = true;
    //             Get.find<
    //                     EyePatchController>() // 이거 그냥 eyePatchController로 바꿔도 되는거 아님..?
    //                 .updateElement(element.ble, "connected", true);
    //           }
    //         }

    //         // if (device.id == item["ble"]) {
    //         //   connected = true;
    //         // }
    //       })
    //       // if (devices.contains(item))
    //       // devices.contains(item)
    //     });
    return GetBuilder<EyePatchController>(
      builder: (controller) {
        debugPrint('알림');

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          PermissionStatus status = await Permission.notification.request();

          if (status.isGranted) {
            tz.initializeTimeZones();
            tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

            var androidDetails = const AndroidNotificationDetails(
              'alarm',
              'alarm',
              priority: Priority.high,
              importance: Importance.max,
              color: Color.fromARGB(255, 255, 0, 0),
            );

            // 알림 id, 제목, 내용 맘대로 채우기
            // _flutterLocalNotificationsPlugin.show(1, '제목1', '내용1',
            //     NotificationDetails(android: androidDetails));
            for (var patch in controller.eyePatchList.eyePatches) {
              // 하나의 패치마다
              print(patch.ble);
              print(patch.alarm);
              if (patch.alarm != null) {
                for (var alarm in patch.alarm!) {
                  // 설정된 여러 알림
                  FlutterLocalNotificationsPlugin().zonedSchedule(
                      2123,
                      alarm / 60 <= 10
                          ? '${patch.ble}패치의 오늘 착용 시간은 n시간 입니다.'
                          : '${patch.ble} - 오늘 하루 n1시간 중 n2시간을 착용했어요.',
                      '${(alarm / 60).floor()}시 ${alarm % 60}분 알림입니다.',
                      // tz.TZDateTime.now(tz.local).add(Duration(seconds: 5)),

                      // 아이폰도 추가하기
                      makeDate((alarm / 60).floor(), alarm % 60, 0),
                      NotificationDetails(android: androidDetails),
                      uiLocalNotificationDateInterpretation:
                          UILocalNotificationDateInterpretation.absoluteTime,
                      matchDateTimeComponents:
                          DateTimeComponents.time //주기적으로 알람
                      );
                }
              }
            }
          }
        });

        return Column(
          children: [
            Container(
              height: 55,
              alignment: Alignment.center,
              child: const Text(
                '내 아이패치 목록',
                style: TextStyle(
                    color: Palette.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
                onPressed: () {
                  // dbHelper.insertRecord(Ble(
                  //     timeStamp: 00,
                  //     ble: 'testBle',
                  //     patched: 1,
                  //     rawData: '테스트'));
                  // dbHelper.getAllBle();
                  print(storage.getItem('eyePatchList'));
                  // flutterBlue.connectedDevices
                  //     .then((value) => {print(value)}); // 현재 연결되어 있는 기기
                },
                child: const Text('eyePatchList_')),
            // TextButton(
            //     onPressed: () async {
            //       // scan();
            //       // eyePatchController.printPatchList();
            //       // alarmController.alarmTime.forEach((element) {
            //       //   print(element); // 이게 이제 맥주소+이름 이렇게 바뀌어야 함.
            //       // });
            //       print('알림');
            //       PermissionStatus status =
            //           await Permission.notification.request();

            //       if (status.isGranted) {
            //         tz.initializeTimeZones();
            //         tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

            //         var androidDetails = const AndroidNotificationDetails(
            //           'alarm',
            //           'alarm',
            //           priority: Priority.high,
            //           importance: Importance.max,
            //           color: Color.fromARGB(255, 255, 0, 0),
            //         );

            //         // 알림 id, 제목, 내용 맘대로 채우기
            //         // _flutterLocalNotificationsPlugin.show(1, '제목1', '내용1',
            //         //     NotificationDetails(android: androidDetails));
            //         for (var patch in controller.eyePatchList.eyePatches) {
            //           // 하나의 패치마다
            //           print(patch.ble);
            //           print(patch.alarm);
            //           for (var alarm in patch.alarm!) {
            //             // 설정된 여러 알림
            //             FlutterLocalNotificationsPlugin().zonedSchedule(
            //                 2123,
            //                 alarm / 60 <= 10
            //                     ? '${patch.ble}패치의 오늘 착용 시간은 n시간 입니다.'
            //                     : '${patch.ble} - 오늘 하루 n1시간 중 n2시간을 착용했어요.',
            //                 '${(alarm / 60).floor()}시 ${alarm % 60}분 알림입니다.',
            //                 // tz.TZDateTime.now(tz.local).add(Duration(seconds: 5)),

            //                 makeDate((alarm / 60).floor(), 18, 0),
            //                 NotificationDetails(android: androidDetails),
            //                 uiLocalNotificationDateInterpretation:
            //                     UILocalNotificationDateInterpretation
            //                         .absoluteTime,
            //                 matchDateTimeComponents:
            //                     DateTimeComponents.time //주기적으로 알람
            //                 );
            //           }
            //         }
            //       } else {}
            //     },
            //     child: const Text('알림')),
            Flexible(
              child: Container(
                color: Palette.primary3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    itemCount:
                        eyePatchController.eyePatchList.eyePatches.length + 1,
                    itemBuilder: ((context, index) {
                      return index ==
                              eyePatchController.eyePatchList.eyePatches.length
                          ? addEyePatch()
                          : eyePatch(index);
                    }),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 7 / 6,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20),
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              height: 120,
            )
          ],
        );
      },
      // child:
    );
  }

  Future<List<ScanResult>> scanPatch() async {
    setState(() {
      _resultList.clear();
    });

    await flutterBlue.startScan(timeout: const Duration(seconds: 7));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!_resultList.contains(r)) {
          _resultList.add(r);
        }
      }
    });
    return _resultList;
  }

  // 기기(아이패치) 스캔
  Future<StreamSubscription<List<ScanResult>>> scan() async {
    if (mounted) {
      setState(() {
        _resultList.clear();
        _resultList = [];
      });
    }

    await flutterBlue.startScan(timeout: const Duration(seconds: 7));
    debugPrint('scan');

    var subscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        r.device.state.listen((event) {
          if (BluetoothDeviceState.connected == event) {
            disconnect(r.device); // 모든 기기 연결 해제
          }
        });

        if (r.device.name == 'DS') {
          print('advertisement 데이터 입니다.');
          // print(r.advertisementData);
        }
        // print(r);
        if (!_resultList.contains(r)) {
          // print(r);
          if (mounted) {
            setState(() {
              _resultList.add(r);
            });
          }
        }
        // else
        // print("???");
      }
    });
    flutterBlue.stopScan();
    debugPrint('스캔 완료');
    return subscription;
  }

  // 두 가지 경우
  // 1. 스캔 후 연결
  // 2. 바로 연결

  connect(BluetoothDevice device) async {
    EyePatchList eyePatchList = eyePatchController.eyePatchList;
    Future<bool>? returnValue;
    // bool isNearbyDevice = false;

    device.state.listen((event) {
      if (BluetoothDeviceState.connected == event) return;
    });

    var connectDeviceIndex = 0;

    for (var patch in eyePatchList.eyePatches) {
      if (patch.ble == device.id.id) {
        connectDeviceIndex = eyePatchList.eyePatches.indexOf(patch);
      }
      var index = eyePatchList.eyePatches.indexOf(patch);

      setState(() {
        eyePatchList.eyePatches[index] = EyePatch(
            ble: patch.ble,
            pid: patch.pid,
            phone: patch.phone,
            name: patch.name,
            prescribedDuration: patch.prescribedDuration,
            // connected: false,
            leftRatio: patch.leftRatio,
            alarm: patch.alarm); // 전부 connected: false
      });
    }
    storage.ready.then(
        (_) => storage.setItem('eyePatchList', eyePatchList.toJSONEncodable()));

    try {
      await device.connect(autoConnect: true).timeout(
          const Duration(milliseconds: 10000), onTimeout: () {
        returnValue = Future.value(false);
        // isNearbyDevice = false;
      }).then((value) => {
            if (returnValue == null)
              {
                // isNearbyDevice = false,
                Fluttertoast.showToast(
                    msg:
                        '${eyePatchList.eyePatches[connectDeviceIndex].name} 와 연결되었습니다.'),
                debugPrint('연결되었습니다: $connectDeviceIndex'),
                setState(() {
                  eyePatchList.eyePatches[connectDeviceIndex] = EyePatch(
                      ble: eyePatchList.eyePatches[connectDeviceIndex].ble,
                      pid: eyePatchList.eyePatches[connectDeviceIndex].pid,
                      name: eyePatchList.eyePatches[connectDeviceIndex].name,
                      phone: eyePatchList.eyePatches[connectDeviceIndex].phone,
                      prescribedDuration: eyePatchList
                          .eyePatches[connectDeviceIndex].prescribedDuration,
                      // connected: true,
                      leftRatio:
                          eyePatchList.eyePatches[connectDeviceIndex].leftRatio,
                      alarm: eyePatchList.eyePatches[connectDeviceIndex].alarm);
                }),
                storage.ready.then((_) => storage.setItem(
                    'eyePatchList', eyePatchList.toJSONEncodable())),
              }
            else
              // debugPrint('timeOut error'),
              Fluttertoast.showToast(msg: "연결 시간이 초과되었습니다.")
          });
    } catch (e) {
      debugPrint('에러: $e');
    }
  }

  disconnect(BluetoothDevice device) {
    EyePatchList eyePatchList = eyePatchController.eyePatchList;
    device.disconnect().then((value) {
      for (var patch in eyePatchList.eyePatches) {
        if (patch.ble == device.id.id) {
          var index = eyePatchList.eyePatches.indexOf(patch);
          setState(() {
            eyePatchList.eyePatches[index] = EyePatch(
                ble: patch.ble,
                pid: patch.pid,
                name: patch.name,
                phone: patch.phone,
                prescribedDuration: patch.prescribedDuration,
                leftRatio: patch.leftRatio,
                alarm: patch.alarm);
          });
        }
      }
      storage.ready.then((_) =>
          storage.setItem('eyePatchList', eyePatchList.toJSONEncodable()));
    });
    setState(() {
      selectedIndex = -1;
    });
  }

  GestureDetector eyePatch(var index) {
    EyePatchList eyePatchList = eyePatchController.eyePatchList;
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatchDetail(
                device: device,
                ble: eyePatchList.eyePatches[index].ble,
                // eyePatchInfo: eyePatchList.eyePatches[index],
                // isConnected:
                //     eyePatchList.eyePatches[index].connected ? true : false
              ),
            ));
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      flutterBlue.connectedDevices
                          .then((value) => value.forEach((element) {
                                if (element.id.toString() ==
                                    eyePatchList.eyePatches[index].ble) {
                                  // 지우면 연결도 끊기
                                  disconnect(element);
                                }
                              }));

                      storage.ready.then((_) async {
                        setState(() {
                          eyePatchList.eyePatches.removeAt(index);
                        });
                        await storage.setItem(
                            'eyePatchList', eyePatchList.toJSONEncodable());
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      color: Color.fromARGB(255, 148, 148, 148),
                      size: 23,
                    ),
                  ),
                  // Container(
                  //   decoration: BoxDecoration(
                  //       color: eyePatchList.eyePatches[index].connected
                  //           ? Palette.primary1
                  //           : Palette.red,
                  //       borderRadius: BorderRadius.circular(50)),
                  //   height: 20,
                  //   width: 20,
                  // ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                eyePatchList.eyePatches[index].name,
                style: const TextStyle(
                    color: Palette.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(eyePatchList.eyePatches[index].pid,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 164, 164, 164),
                    fontSize: 12,
                  )),
              // TextButton(
              //     onPressed: () async {
              //       debugPrint('연결하기: $index');
              //       bool isNearbyDevice = false;
              //       var subscription = await scan();
              //       subscription.onData((data) {
              //         for (var element in data) {
              //           if (eyePatchList.eyePatches[index].ble ==
              //               element.device.id.id) {
              //             isNearbyDevice = true;
              //             debugPrint(
              //                 'element.device.id.id: ${element.device.id.id}');
              //             setState(() {
              //               device =
              //                   BluetoothDevice.fromId(element.device.id.id);
              //             });
              //             connect(device);
              //             subscription.cancel();
              //           } else {
              //             isNearbyDevice = false;
              //             // print('스캔에서 못찾음');
              //           }
              //         }
              //       });
              //       if (!isNearbyDevice) {
              //         // Fluttertoast.showToast(msg: '주변에 있는 기기(패치)가 없습니다.');
              //       }
              //     },
              //     child: const Text('연결하기')),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector addEyePatch() {
    var selectedble = '';
    return GestureDetector(
      onTap: () {
        setState(() {
          _resultList.clear();
        });

        // 아이패치 등록하는 창
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: const Text(
                      '아이패치 추가',
                      style: TextStyle(
                          color: Palette.primary1, fontWeight: FontWeight.bold),
                    ),
                    content: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '연결 가능한 아이패치를 선택하세요.',
                            style: TextStyle(
                                color: Palette.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  _scanPatch = scanPatch();
                                  selectedIndex = -1;
                                });
                              },
                              child: const Text('스캔')),
                          FutureBuilder(
                            future: _scanPatch,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                return Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Palette.greyLine),
                                      borderRadius: BorderRadius.circular(10)),
                                  width: double.maxFinite,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: _resultList.isNotEmpty
                                        ? ListView.separated(
                                            shrinkWrap: true,
                                            itemBuilder: (buildContext, index) {
                                              return GestureDetector(
                                                onTap: () async {
                                                  setState(() {
                                                    selectedble =
                                                        _resultList[index]
                                                            .device
                                                            .id
                                                            .toString();
                                                    print(selectedble);
                                                    selectedIndex = index;
                                                  });
                                                },
                                                child: Container(
                                                  height: 70,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color:
                                                          index == selectedIndex
                                                              ? Palette.primary3
                                                              : Palette.grey),
                                                  child: ListTile(
                                                    title: Text(
                                                      _resultList[index]
                                                          .device
                                                          .name,
                                                      style: const TextStyle(
                                                          color: Palette.black,
                                                          fontSize: 14),
                                                    ),
                                                    subtitle: Text(
                                                      _resultList[index]
                                                          .device
                                                          .id
                                                          .id,
                                                      style: const TextStyle(
                                                          color: Palette.black,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            separatorBuilder: (context, index) {
                                              return const Divider(
                                                  color: Colors.transparent);
                                            },
                                            itemCount: _resultList.length)
                                        : Container(),
                                  ),
                                );
                              } else if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: SizedBox(
                                    height: 50,
                                    child: LoadingIndicator(
                                        indicatorType: Indicator.ballPulse,
                                        colors: [Palette.primary1],
                                        strokeWidth: 1,
                                        backgroundColor: Colors.white,
                                        pathBackgroundColor: Colors.white),
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            },
                          )
                        ]),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            inputDialog(context, selectedble);
                          },
                          child: const Text('다음'))
                    ],
                  );
                },
              );
            });
      },
      child: Card(
        color: Palette.lightGrey,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
        child: const Icon(Icons.add_circle_outline_outlined,
            color: Palette.primary2, size: 60),
      ),
    );
  }

  Future<dynamic> inputDialog(BuildContext context, var ble) {
    TextEditingController nameField = TextEditingController();
    TextEditingController pidField = TextEditingController();
    TextEditingController phoneField = TextEditingController();

    TextEditingController timeField = TextEditingController(text: "1");

    String name = '';
    String pid = '';
    String phone = '';
    int prescribedDuration = 00;
    String side = 'right'; // which side? left/right

    // DateTime selectDate = DateTime.now();

    double currentSliderValue = 20;
    EyePatchList eyePatchList = eyePatchController.eyePatchList;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: const Text('아이패치 추가',
                style: TextStyle(
                    color: Palette.primary1, fontWeight: FontWeight.bold)),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                    child: ListBody(children: [
                  const Text('착용자의 이름을 입력하세요.',
                      style: TextStyle(
                          color: Palette.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: nameField,
                  ),
                  const SizedBox(height: 50),
                  const Text('착용자의 환자번호를 입력하세요.',
                      style: TextStyle(
                          color: Palette.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: pidField,
                  ),
                  const SizedBox(height: 50),
                  const Text('착용자/보호자의 전화번호를 입력하세요.',
                      style: TextStyle(
                          color: Palette.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: phoneField,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [MaskedInputFormatter('###-####-####')],
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 50),
                  const Text('하루 착용 시간을 입력하세요.',
                      style: TextStyle(
                          color: Palette.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Palette.primary1),
                        child: Center(
                            child: TextButton(
                          onPressed: () {
                            if (timeField.text == "0") {
                              return;
                            }
                            timeField.text =
                                (int.parse(timeField.text) - 1).toString();
                          },
                          child: const Text(
                            "-",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        )),
                      ),
                      SizedBox(
                        width: 40,
                        height: 34,
                        child: TextFormField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          controller: timeField,
                          // ),
                          // Text('시간'),
                          // ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Palette.primary1),
                        child: Center(
                            child: TextButton(
                          onPressed: () {
                            timeField.text =
                                (int.parse(timeField.text) + 1).toString();
                          },
                          child: const Text(
                            "+",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        )),
                      ),
                      const SizedBox(width: 10),
                      const Text('시간'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text('좌우 착용 비율을 설정하세요.',
                      style: TextStyle(
                          color: Palette.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                          child: Center(
                              child:
                                  Text(currentSliderValue.toInt().toString()))),
                      Slider(
                          value: currentSliderValue,
                          max: 100,
                          divisions: 10,
                          onChanged: ((value) {
                            setState(() {
                              currentSliderValue = value;
                            });
                          })),
                      Expanded(
                          child: Center(
                        child:
                            Text((100 - currentSliderValue).toInt().toString()),
                      )),
                    ],
                  )
                ]));
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (nameField.text.isNotEmpty &&
                      timeField.text.isNotEmpty &&
                      phoneField.text.isNotEmpty) {
                    name = nameField.text;
                    pid = pidField.text;
                    phone = phoneField.text;
                    prescribedDuration = int.parse(timeField.text);
                    var newEyePatch = EyePatch(
                        name: name,
                        pid: pid,
                        phone: phone,
                        prescribedDuration: prescribedDuration,
                        ble: ble,
                        // connected: false,
                        leftRatio: currentSliderValue);

                    // 백엔드에 post 요청하기

                    eyePatchList.eyePatches.add(newEyePatch);
                    storage.ready.then((_) {
                      storage.setItem(
                          'eyePatchList', eyePatchList.toJSONEncodable());
                    });

                    setState(() {});
                  }
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              )
            ]);
      },
    );
    // });
  }
}
