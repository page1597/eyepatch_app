import 'dart:math';
import 'dart:typed_data';

import 'package:eyepatch_app/database/dbHelper.dart';
import 'package:eyepatch_app/model.dart/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hex/hex.dart';

class DetailPage extends StatefulWidget {
  final ScanResult result;
  final BluetoothDeviceState deviceState;
  final DBHelper dbHelper;
  const DetailPage(
      {Key? key,
      required this.result,
      required this.deviceState,
      required this.dbHelper})
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

save() {}

// 온도가 갱신될 때마다 저장
insertSql(var info, DBHelper dbHelper) async {
  dbHelper.insertBle(Ble(
      id: await dbHelper.getLastId(info.device.name),
      device: info.device.id.toString(),
      temp: calculate(info.advertisementData.rawBytes),
      timeStamp: (DateTime.now().millisecondsSinceEpoch +
              DateTime.now().timeZoneOffset.inMilliseconds) ~/
          1000));
}

// 갑작스럽게 연결이 끊기거나, 끊을 때 저장
insertCsv(var info, DBHelper dbHelper) {
  dbHelper.sqlToCsv(info.device.name);
  print('기록된 온도 정보가 저장되었습니다.');
  dbHelper.dropTable();
}

// 연결이 끊겼으면 나가게?

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.result.device.name),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.result.device.id.toString()}',
                style: const TextStyle(fontSize: 18),
              ),
              // Text(
              //     'raw data: ${HEX.encode(widget.result.advertisementData.rawBytes)}'),
              const SizedBox(height: 10),
              Text(
                '${calculate(widget.result.advertisementData.rawBytes).toStringAsFixed(2)}C°',
                style: const TextStyle(fontSize: 42, color: Colors.blue),
              ),
              TextButton(
                  onPressed: () {
                    insertSql(widget.result, widget.dbHelper);
                  },
                  child: const Text('sqlite에 넣기')), // 이걸 주기적으로 해야됨
              TextButton(
                  onPressed: () {
                    insertCsv(widget.result, widget.dbHelper);
                  },
                  child: const Text('csv에 저장하기'))
            ],
          ),
        ),
      ),
    );
  }
}
