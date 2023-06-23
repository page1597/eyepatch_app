import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:eyepatch_app/database/dbHelper.dart';

class Ble {
  final int id;
  final String ble; // // device -> ble로 변경
  final double? ambientTemp;
  final double? patchTemp;
  final String patched;
  final String rawData;

  final int timeStamp;
  // final String dateTime;

  Ble({
    required this.id,
    required this.ble, // device -> ble로 변경
    this.patchTemp,
    this.ambientTemp,
    required this.patched,
    required this.timeStamp,
    required this.rawData,
    // required this.dateTime
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ble': ble, // device -> ble로 변경
      'patchTemp': patchTemp,
      'ambientTemp': ambientTemp,
      'patched': patched,
      'rawData': rawData,
      'timeStamp': timeStamp,
      // 'dateTime': dateTime,
    };
  }
}

class BleProvider extends ChangeNotifier {
  double temp = 0;
  String deviceId = "";
  int id = 0;
  DBHelper dbHelper = DBHelper();

  void setDeviceId(ble) {
    deviceId = ble;
    id++;
    notifyListeners();
  }

  void setTemp(temperature) {
    temp = temperature;
    id++;
    notifyListeners();
  }
}
