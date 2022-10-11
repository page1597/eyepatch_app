import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:eyepatch_app/database/dbHelper.dart';

class Ble {
  final int id;
  final String device;
  final double? temp;
  final String rawData;
  final int timeStamp;

  Ble(
      {required this.id,
      required this.device,
      this.temp,
      required this.timeStamp,
      required this.rawData});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device': device,
      'temp': temp,
      'rawData': rawData,
      'timeStamp': timeStamp,
    };
  }
}

class BleProvider extends ChangeNotifier {
  double temp = 0;
  String deviceId = "";
  int id = 0;
  DBHelper dbHelper = DBHelper();

  void setDeviceId(device) {
    deviceId = device;
    id++;
    notifyListeners();
  }

  void setTemp(temperature) {
    temp = temperature;
    id++;
    notifyListeners();
  }
}
