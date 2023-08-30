import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:eyepatch_app/database/dbHelper.dart';

class Ble {
  // final int id;
  final int timeStamp;
  final String ble; // // device -> ble로 변경
  final double? ambientTemp;
  final double? patchTemp;
  final int patched;
  final String rawData;
  // final String dateTime;

  Ble({
    // required this.id,
    required this.timeStamp,
    required this.ble, // device -> ble로 변경
    this.patchTemp,
    this.ambientTemp,
    required this.patched,
    required this.rawData,
    // required this.dateTime
  });

  Map<String, dynamic> toMap() {
    return {
      'timeStamp': timeStamp,
      'ble': ble, // device -> ble로 변경
      'patchTemp': patchTemp,
      'ambientTemp': ambientTemp,
      'patched': patched,
      'rawData': rawData,
      // 'dateTime': dateTime,
    };
  }
}

// class BleProvider extends ChangeNotifier {
//   double temp = 0;
//   String deviceId = "";
//   int id = 0;
//   DBHelper dbHelper = DBHelper();

//   void setDeviceId(ble) {
//     deviceId = ble;
//     id++;
//     notifyListeners();
//   }

//   void setTemp(temperature) {
//     temp = temperature;
//     id++;
//     notifyListeners();
//   }
// }
