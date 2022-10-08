import 'package:flutter/material.dart';
import 'package:eyepatch_app/database/dbHelper.dart';

class Ble {
  final int id;
  final String device;
  final double temp;
  final int timeStamp;

  Ble(
      {required this.id,
      required this.device,
      required this.temp,
      required this.timeStamp});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device': device,
      'temp': temp,
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
