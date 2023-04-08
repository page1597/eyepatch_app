import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:eyepatch_app/database/dbHelper.dart';

class EyePatch {
  // final int id;

  final String bleAddress; // 모듈 주소
  final String name; // 패치 착용자 이름
  final int time; // 착용시간 (추후 단위 변경하기)
  final int birth;
  final bool connected;
  // final List<int>? alarm; // 알림

  EyePatch({
    // required this.id,
    required this.bleAddress,
    required this.name,
    required this.time,
    required this.birth,
    required this.connected,
    // this.alarm,
  });

  // EyePatch.fromJson(Map<String, dynamic> json)
  //     : bleAddress = json['bleAddress'],
  //       name = json['name'],
  //       time = json['time'];
  // // alarm = json['alarm'];

  // Map<String, dynamic> toMap() {
  //   return {
  //     'bleAddress': bleAddress,
  //     'name': name,
  //     'time': time,
  //     // 'alarm': alarm,
  //   };
  // }

  Map<String, dynamic> toJSONEncodable() {
    Map<String, dynamic> eyePatch = {};

    eyePatch['bleAddress'] = bleAddress;
    eyePatch['name'] = name;
    eyePatch['time'] = time;
    eyePatch['birth'] = birth;
    eyePatch['connected'] = connected;

    return eyePatch;
  }
}
