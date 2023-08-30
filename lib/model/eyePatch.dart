import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:eyepatch_app/database/dbHelper.dart';

class EyePatch {
  // final int id;

  final String ble; // 모듈 주소
  final String pid;
  final String name; // 패치 착용자 이름
  final String phone;
  final int prescribedDuration; // 착용시간 (추후 단위 변경하기)
  final double leftRatio;
  final List<dynamic>? alarm; // 알림

  EyePatch({
    // required this.id,
    required this.ble,
    required this.pid,
    required this.phone,
    required this.name,
    required this.prescribedDuration,
    required this.leftRatio,
    this.alarm,
  });

  // EyePatch.fromJson(Map<String, dynamic> json)
  //     : bleAddress = json['bleAddress'],
  //       name = json['name'],
  //       prescribedDuration = json['prescribedDuration'];
  // // alarm = json['alarm'];

  // Map<String, dynamic> toMap() {
  //   return {
  //     'bleAddress': bleAddress,
  //     'name': name,
  //     'prescribedDuration': prescribedDuration,
  //     // 'alarm': alarm,
  //   };
  // }

  Map<String, dynamic> toJSONEncodable() {
    Map<String, dynamic> eyePatch = {};

    eyePatch['ble'] = ble;
    eyePatch['pid'] = pid;
    eyePatch['name'] = name;
    eyePatch['phone'] = phone;
    eyePatch['prescribedDuration'] = prescribedDuration;
    eyePatch['leftRatio'] = leftRatio;
    eyePatch['alarm'] = alarm;

    return eyePatch;
  }
}
