import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:eyepatch_app/database/dbHelper.dart';
import 'package:eyepatch_app/model.dart/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hex/hex.dart';

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

double calculate(Uint8List advertisingData) {
  if (advertisingData.isEmpty) return 0.0;

  ByteData byteData = advertisingData.buffer.asByteData();
  double sensorV = byteData.getUint16(12, Endian.little) * 0.001; // 센서 내부 온도 전압
  double batteryV = byteData.getUint8(16) * 0.1; // 배터리 전압

  double t = 0.0; // result
  double c = 0.0; // result 섭씨 온도
  double b = 4250.0;
  double t0 = 298.15;
  double r = 75000.0;
  double r0 = 100000.0;

  t = (b * t0) /
      (b + (t0 * (log((sensorV * r) / (r0 * (batteryV - sensorV))))));
  c = t - 273.15;

  return c;
}

insertSql(ScanResult info, DBHelper dbHelper) async {
  dbHelper.insertBle(Ble(
    id: await dbHelper.getLastId(info.device.name) + 1,
    device: info.device.id.toString(),
    temp: calculate(info.advertisementData.rawBytes),
    rawData: HEX.encode(info.advertisementData.rawBytes),
    timeStamp: DateTime.now().millisecondsSinceEpoch,
  ));
  Fluttertoast.showToast(msg: 'sql에 저장', toastLength: Toast.LENGTH_SHORT);
}

// 갑작스럽게 연결이 끊기거나, 끊을 때 저장
insertCsv(ScanResult info, DBHelper dbHelper) {
  dbHelper.sqlToCsv(info.device.name);
  Fluttertoast.showToast(msg: '기록된 온도 정보가 저장되었습니다.');
  dbHelper.dropTable();
  Fluttertoast.showToast(msg: '파일에 저장');
}

class _DetailPageState extends State<DetailPage> {
  final StreamController<ScanResult> _dataController =
      StreamController<ScanResult>.broadcast();
  int beforePacketNumber = 0; // 이전 패킷 넘버
  int timerTick = 0;
  bool inserted = false;
  bool started = false; // 실험 시작

  late Uint8List lastData = Uint8List.fromList([]);

  @override
  void initState() {
    super.initState();
    widget.dbHelper.dropTable();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      // 40
      widget.flutterblue.startScan();
      widget.flutterblue.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.device.id == widget.result.device.id) {
            //스캔 하는 시간때문에 딜레이가 걸림..
            // 스캔을 하는 상태여서 계속 딜레이가 걸림.. 그래서 중구난방으로 저장됨
            _dataController.sink.add(r);
          }
        }
      });

      widget.flutterblue.stopScan();
    });

    return Scaffold(
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
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Text(
                  'advertising data: ${HEX.encode(widget.result.advertisementData.rawBytes)}'),
              const SizedBox(height: 24),
              const Text(
                '온도 정보: ',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontSize: 16),
              ),
              StreamBuilder<ScanResult>(
                  stream: _dataController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (started) {
                        if (snapshot.data!.advertisementData.rawBytes !=
                            lastData) {
                          insertSql(snapshot.data!, widget.dbHelper);

                          // setState(() {
                          lastData = snapshot.data!.advertisementData.rawBytes;
                          // });
                        }
                      }
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '${calculate(snapshot.data!.advertisementData.rawBytes)}C°',
                            style: const TextStyle(
                                fontSize: 42, color: Colors.blue),
                          ),
                          const SizedBox(height: 50),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: !started
                                        ? const Color.fromARGB(
                                            255, 61, 137, 199)
                                        : const Color.fromARGB(
                                            255, 199, 29, 17),
                                  ),
                                  onPressed: () {
                                    insertCsv(snapshot.data!, widget.dbHelper);
                                    setState(() {
                                      started = !started;
                                    });
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
                            ],
                          ),
                        ],
                      );
                    } else {
                      return const Text(
                        'loading...(30초)',
                        style: TextStyle(fontSize: 42, color: Colors.blue),
                      );
                    }
                  }),
            ],
          ),
        ));
  }
}
