import 'dart:async';
import 'package:eyepatch_app/main.dart';
import 'package:eyepatch_app/model.dart/eyePatch.dart';
import 'package:eyepatch_app/model.dart/eyePatchList.dart';
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
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class PatchList extends StatefulWidget {
  const PatchList({super.key});

  @override
  State<PatchList> createState() => _PatchListState();
}

class _PatchListState extends State<PatchList> {
  // EyePatchList _eyePatchList = EyePatchList();
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
  late Future<List<ScanResult>> _scan1;

  final eyePatchController = Get.put(EyePatchController());

  @override
  void initState() {
    super.initState();
    initializeNotification();
    // Future.delayed(const Duration(seconds: 3), {})

    debugPrint('initstate');
    getPermission();
    initBle();

    _scan1 = scan1();

    // 현재 연결되어 있는 기기

    // _resultList.clear()

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    // 화면상에 목록으로 띄우기 위해서
    storage.ready.then((_) {
      print(storage.getItem('eyePatchList'));
      // storage.dispose();
      // storage.clear();
      List<dynamic> eyePatchList = storage.getItem('eyePatchList');
      print(storage.getItem('eyePatchList').length);
      print(storage.getItem('eyePatchList')[0]['time']);
      EyePatchList temp = EyePatchList();
      bool connected = false;

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
              name: item['name'],
              time: item['time'],
              birth: item['birth'],
              connected: item['connected'],
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
      // _isScanning = isScanning;
      setState(() {});
    });
  }

  getPermission() async {
    print('구ㅓㄴ한 허용');
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
    bool connected = false;
    flutterBlue.connectedDevices.then((devices) => {
          devices.forEach((device) {
            eyePatchController.eyePatchList.eyePatches.forEach((element) {
              print(element.ble);
              if (element.ble == device.id.toString()) {
                // connected = true;
                Get.find<
                        EyePatchController>() // 이거 그냥 eyePatchController로 바꿔도 되는거 아님..?
                    .updateElement(element.ble, "connected", true);
              }
            });

            // if (device.id == item["ble"]) {
            //   connected = true;
            // }
          })
          // if (devices.contains(item))
          // devices.contains(item)
        });
    return GetBuilder<EyePatchController>(
      builder: (controller) {
        print('알림');

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
                    matchDateTimeComponents: DateTimeComponents.time //주기적으로 알람
                    );
              }
            }
          } else {}
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
                  print(storage.getItem('eyePatchList'));
                  flutterBlue.connectedDevices
                      .then((value) => {print(value)}); // 현재 연결되어 있는 기기
                },
                child: const Text('eyePatchList')),
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

  Future<List<ScanResult>> scan1() async {
    setState(() {
      _resultList.clear();
      _resultList = [];
    });

    await flutterBlue.startScan(timeout: const Duration(seconds: 7));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        // print(r);
        // for (var element in devicesList) {
        if (!_resultList.contains(r)) {
          _resultList.add(r);
          // }
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
            name: patch.name,
            time: patch.time,
            birth: patch.birth,
            connected: false,
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
                      name: eyePatchList.eyePatches[connectDeviceIndex].name,
                      time: eyePatchList.eyePatches[connectDeviceIndex].time,
                      birth: eyePatchList.eyePatches[connectDeviceIndex].birth,
                      connected: true,
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
                name: patch.name,
                time: patch.time,
                birth: patch.birth,
                connected: false,
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
                  connectedDevice: device,
                  ble: eyePatchList.eyePatches[index].ble,
                  // eyePatchInfo: eyePatchList.eyePatches[index],
                  isConnected:
                      eyePatchList.eyePatches[index].connected ? true : false),
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
                  Container(
                    decoration: BoxDecoration(
                        color: eyePatchList.eyePatches[index].connected
                            ? Palette.primary1
                            : Palette.red,
                        borderRadius: BorderRadius.circular(50)),
                    height: 20,
                    width: 20,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                eyePatchList.eyePatches[index].name,
                style: const TextStyle(
                    color: Palette.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              TextButton(
                  onPressed: () async {
                    debugPrint('연결하기: $index');
                    bool isNearbyDevice = false;
                    var subscription = await scan();
                    subscription.onData((data) {
                      for (var element in data) {
                        if (eyePatchList.eyePatches[index].ble ==
                            element.device.id.id) {
                          isNearbyDevice = true;
                          debugPrint(
                              'element.device.id.id: ${element.device.id.id}');
                          setState(() {
                            device =
                                BluetoothDevice.fromId(element.device.id.id);
                          });

                          connect(device);
                          subscription.cancel();
                        } else {
                          isNearbyDevice = false;
                          // print('스캔에서 못찾음');
                        }
                      }
                    });
                    if (!isNearbyDevice) {
                      // Fluttertoast.showToast(msg: '주변에 있는 기기(패치)가 없습니다.');
                    }
                  },
                  child: const Text('연결하기')),
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
          // _resultList = [];
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
                    content: SizedBox(
                      height: 400,
                      child: Column(
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
                                    _scan1 = scan1();
                                    selectedIndex = -1;
                                  });
                                },
                                child: const Text('스캔')),
                            FutureBuilder(
                              future: _scan1,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  return Container(
                                    height: 300,
                                    decoration: BoxDecoration(
                                        border:
                                            Border.all(color: Palette.greyLine),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    width: double.maxFinite,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: _resultList.isNotEmpty
                                          ? ListView.separated(
                                              shrinkWrap: true,
                                              itemBuilder:
                                                  (buildContext, index) {
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
                                                            BorderRadius
                                                                .circular(8),
                                                        color: index ==
                                                                selectedIndex
                                                            ? Palette.primary3
                                                            : Palette.grey),
                                                    child: ListTile(
                                                      title: Text(
                                                        _resultList[index]
                                                            .device
                                                            .name,
                                                        style: const TextStyle(
                                                            color:
                                                                Palette.black,
                                                            fontSize: 14),
                                                      ),
                                                      subtitle: Text(
                                                        _resultList[index]
                                                            .device
                                                            .id
                                                            .id,
                                                        style: const TextStyle(
                                                            color:
                                                                Palette.black,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              separatorBuilder:
                                                  (context, index) {
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
                                } else
                                  return Container();
                              },
                            )
                          ]),
                    ),
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
    TextEditingController timeField = TextEditingController(text: "1");
    // TextEditingController birthField = TextEditingController();

    String name = '';
    int time = 00;
    // var birth = 000000;
    String side = 'right'; // which side? left/right

    DateTime selectDate = DateTime.now();

    double _currentSliderValue = 20;
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
                  const Text('착용자 이름을 입력하세요.',
                      style: TextStyle(
                          color: Palette.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: nameField,
                  ),
                  const SizedBox(height: 50),
                  const Text('착용자 생년월일을 입력하세요.',
                      style: TextStyle(
                          color: Palette.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  // TextFormField(
                  //   controller: birthField,
                  // ),
                  TextButton(
                      onPressed: () {
                        showCupertinoModalPopup(
                            // shape: RoundedRectangleBorder(
                            //     borderRadius: BorderRadius.circular(20)),
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                height: MediaQuery.of(context)
                                        .copyWith()
                                        .size
                                        .height /
                                    3,
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.of(context)
                                                  .copyWith()
                                                  .size
                                                  .height /
                                              3 -
                                          50,
                                      child: SizedBox.expand(
                                        child: CupertinoDatePicker(
                                          onDateTimeChanged: (dateTime) {
                                            setState(() {
                                              selectDate = dateTime;
                                            });
                                          },
                                          mode: CupertinoDatePickerMode.date,
                                          minimumYear: 1980,
                                          maximumYear: DateTime.now().year,
                                          maximumDate: DateTime.now(),
                                          initialDateTime: selectDate,
                                        ),
                                      ),
                                    ),
                                    CupertinoButton(
                                      child: const Text("확인"),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    )
                                  ],
                                ),
                              );
                            }).whenComplete(() {
                          print(DateFormat('yyyy년 MM월 dd일').format(selectDate));
                        });
                      },
                      child: Text(
                          // isSameDay(a, b)
                          selectDate.difference(DateTime.now()).inDays == 0
                              ? '선택'
                              : DateFormat('yyyy년 MM월 dd일')
                                  .format(selectDate))),
                  const SizedBox(height: 50),
                  const Text('하루 착용 시간을 입력하세요.',
                      style: TextStyle(
                          color: Palette.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Row(
                  //   children: [
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
                          child: Text(
                            "-",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        )),
                      ),
                      Container(
                        width: 40,
                        height: 34,
                        child: TextFormField(
                          textAlign: TextAlign.center,
                          // textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          // initialValue: "1",
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
                          child: Text(
                            "+",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        )),
                      ),
                      SizedBox(width: 10),
                      Text('시간'),
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
                              child: Text(
                                  _currentSliderValue.toInt().toString()))),
                      Slider(
                          value: _currentSliderValue,
                          max: 100,
                          divisions: 10,
                          onChanged: ((value) {
                            setState(() {
                              _currentSliderValue = value;
                            });
                          })),
                      Expanded(
                          child: Center(
                        child: Text(
                            (100 - _currentSliderValue).toInt().toString()),
                      )),
                    ],
                  )

                  // Row(
                  //   children: [
                  //     TextButton(
                  //       onPressed: () {
                  //         setState(() {
                  //           side = 'left';
                  //         });
                  //       },
                  //       style: ButtonStyle(
                  //           backgroundColor: MaterialStateProperty.all(
                  //               side == 'left'
                  //                   ? Palette.background
                  //                   : Palette.lightGrey)),
                  //       child: const Text(
                  //         '왼쪽',
                  //         style: TextStyle(color: Palette.black),
                  //       ),
                  //     ),
                  //     const SizedBox(
                  //       width: 12,
                  //     ),
                  //     TextButton(
                  //       onPressed: () {
                  //         setState(() {
                  //           side = 'right';
                  //         });
                  //       },
                  //       style: ButtonStyle(
                  //           backgroundColor: MaterialStateProperty.all(
                  //               side == 'right'
                  //                   ? Palette.background
                  //                   : Palette.lightGrey)),
                  //       child: const Text(
                  //         '오른쪽',
                  //         style: TextStyle(color: Palette.black),
                  //       ),
                  //     )
                  //   ],
                  // )

                  // TimePickerTheme(data: data, child: child)
                ]));
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (nameField.text.isNotEmpty &&
                      timeField.text.isNotEmpty &&
                      // birthField.text.isNotEmpty
                      selectDate.difference(DateTime.now()).inDays != 0) {
                    name = nameField.text;
                    time = int.parse(timeField.text);
                    // birth = int.parse(birthField.text);
                    var newEyePatch = EyePatch(
                        name: name,
                        time: time,
                        birth: selectDate.millisecondsSinceEpoch,
                        ble: ble,
                        connected: false,
                        leftRatio: _currentSliderValue);
                    // setState(() {
                    eyePatchList.eyePatches.add(newEyePatch);
                    storage.ready.then((_) {
                      storage.setItem(
                          'eyePatchList', eyePatchList.toJSONEncodable());
                      // });

                      // storage.ready
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
