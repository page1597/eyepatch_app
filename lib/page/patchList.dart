import 'dart:async';
import 'dart:convert';
import 'package:eyepatch_app/model.dart/eyePatch.dart';
import 'package:eyepatch_app/model.dart/eyePatchList.dart';
import 'package:eyepatch_app/page/patchDetail.dart';
import 'package:eyepatch_app/style/palette.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:eyepatch_app/database/devices.dart';
import 'package:localstorage/localstorage.dart';
import 'package:flutter/cupertino.dart';
import 'package:loading_indicator/loading_indicator.dart';

class PatchList extends StatefulWidget {
  const PatchList({super.key});

  @override
  State<PatchList> createState() => _PatchListState();
}

class _PatchListState extends State<PatchList> {
  EyePatchList _eyePatchList = EyePatchList();
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
  @override
  void initState() {
    super.initState();
    debugPrint('initstate');
    getPermission();
    initBle();

    _scan1 = scan1();

    // _resultList.clear();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    storage.ready.then((_) {
      // storage.dispose();
      List<dynamic> eyePatchList = storage.getItem('eyePatchList');
      EyePatchList temp = EyePatchList();

      for (var item in eyePatchList) {
        temp.eyePatches.add(EyePatch(
            bleAddress: item['bleAddress'],
            name: item['name'],
            time: item['time'],
            birth: item['birth'],
            connected: item['connected']));
      }
      setState(() {
        _eyePatchList = temp;
      });

      // _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      //   // 안드로이드에서 특히, 몇시간 동안 돌려보기 꺼지는지 확인 . 백그라운드 동작하게 하기.
      //   bool isNearbyDevice = false;
      //   var connectedDevices = flutterBlue.connectedDevices; // 현재 연결되어있는 기기

      //   // device.connect();
      //   // 4/4 4:17 device.connect(autoConnect: true); 로 변경하기

      //   // 스캔해서 가까이 있는 기기가 있으면 자동 연결
      //   connectedDevices.then((value) async {
      //     if (value.isEmpty) {
      //       var subscription = await scan();
      //       subscription.onData((data) {
      //         for (var element in data) {
      //           for (var patch in _eyePatchList.eyePatches) {
      //             if (element.device.id.id == patch.bleAddress) {
      //               isNearbyDevice = true;
      //               setState(() {
      //                 device = BluetoothDevice.fromId(element.device.id.id);
      //               });
      //               connect(device); // 근데 하나만 연결해야됨
      //               subscription.cancel();
      //             } else {
      //               isNearbyDevice = false;
      //             }
      //           }
      //         }
      //       });
      //     } else {
      //       isNearbyDevice = true; // 이미 연결된 기기가 있을 경우
      //     }
      //   });
      //   if (!isNearbyDevice) {
      //     Fluttertoast.showToast(msg: '주변에 있는 기기(패치)가 없습니다.');
      //   }
      // });
    });
    // });

    if (storage.getItem('eyePatchList') != null) {}
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

  @override
  Widget build(BuildContext context) {
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
        TextButton(
            onPressed: () {
              scan();
            },
            child: const Text('scan')),
        Flexible(
          child: Container(
            color: Palette.background,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                itemCount: _eyePatchList.eyePatches.length + 1,
                itemBuilder: ((context, index) {
                  return index == _eyePatchList.eyePatches.length
                      ? addEyePatch()
                      : eyePatch(index);
                }),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
  }

  Future<List<ScanResult>> scan1() async {
    setState(() {
      _resultList.clear();
      _resultList = [];
    });

    await flutterBlue.startScan(timeout: const Duration(seconds: 7));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        print(r);
        for (var element in devicesList) {
          if (!_resultList.contains(r)) {
            _resultList.add(r);
          }
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
        print(r.advertisementData);
        r.device.state.listen((event) {
          if (BluetoothDeviceState.connected == event) {
            disconnect(r.device); // 모든 기기 연결 해제
          }
        });

        if (r.device.name == 'DS') {
          print('advertisement 데이터 입니다.');
          print(r.advertisementData);
        }
        // print(r);
        if (!_resultList.contains(r)) {
          print(r);
          if (mounted) {
            setState(() {
              _resultList.add(r);
            });
          }
        } else
          print("???");
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
    Future<bool>? returnValue;

    bool isNearbyDevice = false;

    device.state.listen((event) {
      if (BluetoothDeviceState.connected == event) return;
    });

    var connectDeviceIndex = 0;

    for (var patch in _eyePatchList.eyePatches) {
      if (patch.bleAddress == device.id.id) {
        connectDeviceIndex = _eyePatchList.eyePatches.indexOf(patch);
      }
      var index = _eyePatchList.eyePatches.indexOf(patch);

      setState(() {
        _eyePatchList.eyePatches[index] = EyePatch(
            bleAddress: patch.bleAddress,
            name: patch.name,
            time: patch.time,
            birth: patch.birth,
            connected: false); // 전부 connected: false
      });
    }
    storage.ready.then((_) =>
        storage.setItem('eyePatchList', _eyePatchList.toJSONEncodable()));

    print(connectDeviceIndex);

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
                        '${_eyePatchList.eyePatches[connectDeviceIndex].name} 와 연결되었습니다.'),
                debugPrint('연결되었습니다: $connectDeviceIndex'),
                setState(() {
                  _eyePatchList.eyePatches[connectDeviceIndex] = EyePatch(
                      bleAddress: _eyePatchList
                          .eyePatches[connectDeviceIndex].bleAddress,
                      name: _eyePatchList.eyePatches[connectDeviceIndex].name,
                      time: _eyePatchList.eyePatches[connectDeviceIndex].time,
                      birth: _eyePatchList.eyePatches[connectDeviceIndex].birth,
                      connected: true);
                }),
                storage.ready.then((_) => storage.setItem(
                    'eyePatchList', _eyePatchList.toJSONEncodable())),
              }
            else
              debugPrint('timeOut error'),
          });
    } catch (e) {
      debugPrint('에러: $e');
    }
  }

  disconnect(BluetoothDevice device) {
    device.disconnect().then((value) {
      for (var patch in _eyePatchList.eyePatches) {
        if (patch.bleAddress == device.id.id) {
          var index = _eyePatchList.eyePatches.indexOf(patch);
          setState(() {
            _eyePatchList.eyePatches[index] = EyePatch(
                bleAddress: patch.bleAddress,
                name: patch.name,
                time: patch.time,
                birth: patch.birth,
                connected: false);
          });
        }
      }
      storage.ready.then((_) =>
          storage.setItem('eyePatchList', _eyePatchList.toJSONEncodable()));
    });
    setState(() {
      selectedIndex = -1;
    });
  }

  GestureDetector eyePatch(var index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatchDetail(
                  connectedDevice: device,
                  eyePatchInfo: _eyePatchList.eyePatches[index],
                  isConnected:
                      _eyePatchList.eyePatches[index].connected ? true : false),
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
                      storage.ready.then((_) async {
                        setState(() {
                          _eyePatchList.eyePatches.removeAt(index);
                        });
                        await storage.setItem(
                            'eyePatchList', _eyePatchList.toJSONEncodable());
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
                        color: _eyePatchList.eyePatches[index].connected
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
                _eyePatchList.eyePatches[index].name,
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
                        if (_eyePatchList.eyePatches[index].bleAddress ==
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
                      Fluttertoast.showToast(msg: '주변에 있는 기기(패치)가 없습니다.');
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
    var selectedBleAddress = '';
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
                                                      selectedBleAddress =
                                                          _resultList[index]
                                                              .device
                                                              .id
                                                              .toString();
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
                            inputDialog(context, selectedBleAddress);
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

  Future<dynamic> inputDialog(BuildContext context, var bleAddress) {
    TextEditingController nameField = TextEditingController();
    TextEditingController timeField = TextEditingController();
    TextEditingController birthField = TextEditingController();

    var name = '';
    var time = 00;
    var birth = 000000;

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              title: const Text('아이패치 추가',
                  style: TextStyle(
                      color: Palette.primary1, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
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
                  TextFormField(
                    controller: birthField,
                  ),
                  const SizedBox(height: 50),
                  const Text('하루 착용 시간을 설정하세요.',
                      style: TextStyle(
                          color: Palette.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),

                  TextFormField(
                    controller: timeField,
                  ),
                  const SizedBox(height: 50),

                  const Text('왼쪽 / 오른쪽 눈  설정',
                      style: TextStyle(
                          color: Palette.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      TextButton(onPressed: () {}, child: Text('왼쪽')),
                      TextButton(onPressed: () {}, child: Text('오른쪽')),
                    ],
                  )
                  // TimePickerTheme(data: data, child: child)
                ]),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (nameField.text.isNotEmpty &&
                        timeField.text.isNotEmpty &&
                        birthField.text.isNotEmpty) {
                      name = nameField.text;
                      time = int.parse(timeField.text);
                      birth = int.parse(birthField.text);
                      var newEyePatch = EyePatch(
                          name: name,
                          time: time,
                          birth: birth,
                          bleAddress: bleAddress,
                          connected: false);
                      setState(() {
                        _eyePatchList.eyePatches.add(newEyePatch);
                        storage.ready.then((_) {
                          storage.setItem(
                              'eyePatchList', _eyePatchList.toJSONEncodable());
                        });

                        // storage.ready
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('확인'),
                )
              ]);
        });
  }
}
