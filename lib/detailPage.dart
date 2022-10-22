import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'dart:typed_data';
import 'package:eyepatch_app/database/dbHelper.dart';
import 'package:eyepatch_app/model.dart/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hex/hex.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

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
      dateTime: DateFormat('kk시 mm분').format(DateTime.now()),
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
      dateTime: DateFormat('kk시 mm분').format(DateTime.now()),
    ));
    Fluttertoast.showToast(msg: '버튼 클릭', toastLength: Toast.LENGTH_SHORT);
  }
}

// 갑작스럽게 연결이 끊기거나, 끊을 때 저장
insertCsv(ScanResult info, DBHelper dbHelper) {
  dbHelper.sqlToCsv(info.device.name);
  Fluttertoast.showToast(msg: '기록된 온도 정보가 저장되었습니다.');
  dbHelper.dropTable();
  // Fluttertoast.showToast(msg: '파일에 저장');
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

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
}

class _DetailPageState extends State<DetailPage> {
  final StreamController<ScanResult> _dataController =
      StreamController<ScanResult>.broadcast();
  int beforePacketNumber = 0; // 이전 패킷 넘버
  int timerTick = 0;
  bool inserted = false; // in sql
  bool started = false; // 실험 시작
  bool noIncomingData = false;

  int count = 0;
  late Uint8List lastData = Uint8List.fromList([]);
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    setState(() {
      inserted = false;
    });

    widget.dbHelper.dropTable();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Fluttertoast.showToast(msg: '${timer.tick}');
      // timer.tick
      // 40
      count += 1;
      if (!inserted && count == 6 && started) {
        // 데이터가 1분을 초과할 동안 들어오지 않는 상황

        setState(() {
          noIncomingData = true;
        });
      }

      widget.flutterblue.startScan();
      widget.flutterblue.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.device.id == widget.result.device.id) {
            //스캔 하는 시간때문에 딜레이가 걸림..
            // 스캔을 하는 상태여서 계속 딜레이가 걸림.. 그래서 중구난방으로 저장됨
            _dataController.sink.add(r);
            flutterLocalNotificationsPlugin.show(
              888,
              'Eyepatch 어플이 실행중입니다.',
              '패치 온도: ${calculate(r.advertisementData.rawBytes, true).toStringAsFixed(2)}C° / 주변 온도: ${calculate(r.advertisementData.rawBytes, false).toStringAsFixed(2)}C° / ${noIncomingData ? '데이터 오류' : '데이터 정상'}',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'my_foreground',
                  'MY FOREGROUND SERVICE',
                  icon: 'app_icon',
                  ongoing: true,
                ),
              ),
            );

            if (started) {
              insertSql(r, widget.dbHelper, false);
              setState(() {
                inserted = true;
                count = 0;
              });
            }
          }
        }
      });
      widget.flutterblue.stopScan();
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    // _minuteTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ScanResult>(
        stream: _dataController.stream,
        builder: (context, snapshot) {
          return WillPopScope(
            onWillPop: () async {
              if (snapshot.hasData && started) {
                Fluttertoast.showToast(
                    msg: '실험이 진행중입니다. 실험 종료 버튼을 누르고 뒤로가기 버튼을 눌러주세요.');
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
                              'advertising data: ${snapshot.hasData ? HEX.encode(snapshot.data!.advertisementData.rawBytes) : ''}'),
                          const SizedBox(height: 24),
                          const Text(
                            '온도 정보: ',
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: 16),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                '패치: ${snapshot.hasData ? calculate(snapshot.data!.advertisementData.rawBytes, true) : ''}C°',
                                style: const TextStyle(
                                    fontSize: 42, color: Colors.blue),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '주변: ${snapshot.hasData ? calculate(snapshot.data!.advertisementData.rawBytes, false) : ''}C°',
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
                                          FlutterBackgroundService()
                                              .invoke("setAsBackground");
                                          insertCsv(
                                              snapshot.data!, widget.dbHelper);
                                          setState(() {
                                            started = !started;
                                          });
                                        } else {
                                          Fluttertoast.showToast(
                                              msg: '아직 온도 정보를 불러오기 전입니다.');
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
                                        backgroundColor: const Color.fromARGB(
                                            255, 87, 86, 87),
                                      ),
                                      onPressed: () {
                                        // 그냥 버튼 눌렀다는 표시와 타임스탬프를 넣는다.
                                        if (snapshot.hasData) {
                                          insertSql(snapshot.data!,
                                              widget.dbHelper, true);
                                        } else {
                                          Fluttertoast.showToast(
                                              msg: '아직 온도 정보를 불러오기 전입니다.');
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(7.0),
                                        child: Text(
                                          '버튼',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                          ),
                                        ),
                                      ))
                                ],
                              ),
                            ],
                          )
                        ]))),
          );
        });
  }
}
