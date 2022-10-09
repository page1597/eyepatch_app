import 'dart:math';
import 'dart:typed_data';

import 'package:eyepatch_app/database/dbHelper.dart';
import 'package:eyepatch_app/model.dart/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hex/hex.dart';

class DetailPage extends StatefulWidget {
  final ScanResult result; // charicter정보도 받아와야하나
  final dynamic connectionState;
  const DetailPage(
      {Key? key, required this.result, required this.connectionState})
      : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

double calculate(Uint8List advertisingData) {
  print('advertisingData :${HEX.encode(advertisingData)}');

  ByteData byteData = advertisingData.buffer.asByteData();
  double sensorV = byteData.getUint16(12, Endian.little) * 0.001; // 센서 내부 온도 전압
  double batteryV = byteData.getUint8(16) * 0.1; // 배터리 전압
  print(sensorV);
  print(batteryV);

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
  // var temp = log(10);
}

// 연결이 끊겼으면 나가게?

class _DetailPageState extends State<DetailPage> {
  final DBHelper _dbHelper = DBHelper();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.result.device.name),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('device id: ${widget.result.device.id.toString()}'),
              Text(
                  'raw data: ${HEX.encode(widget.result.advertisementData.rawBytes)}'),
              Text(
                  'temperature: ${calculate(widget.result.advertisementData.rawBytes)}'),
              TextButton(
                  onPressed: () async {
                    _dbHelper.insertBle(Ble(
                        id: await _dbHelper
                            .getLastId(widget.result.device.name),
                        device: widget.result.device.id.toString(),
                        temp:
                            calculate(widget.result.advertisementData.rawBytes),
                        timeStamp: (DateTime.now().millisecondsSinceEpoch +
                                DateTime.now().timeZoneOffset.inMilliseconds) ~/
                            1000));
                  },
                  child: const Text('sqlite에 넣기')),
              TextButton(
                  onPressed: () {
                    _dbHelper.sqlToCsv(widget.result.device.name);
                    print('기록된 온도 정보가 저장되었습니다.');
                    _dbHelper.dropTable();
                  },
                  child: Text('csv에 저장하기'))
            ],
          ),
        ),
      ),
    );
  }
}
