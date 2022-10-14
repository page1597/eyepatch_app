import 'dart:convert';
import 'dart:io';
import 'package:eyepatch_app/model.dart/ble.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';
import 'externalStorageHelpder.dart';

// 백그라운드로 바꾸기
// 기기 정보 리스트 다시 확인해서
// 큐알코드 다시 보내기 (아무래도 오늘 안에)
// 실수로 뒤로가기 눌렀을때 여태까지 했던거 다 csv 파일에 저장

class DBHelper {
  dynamic _db;

  Future<Database> get database async {
    if (_db != null) return _db;
    _db = openDatabase(
      join(await getDatabasesPath(), 'EyePatch.db'),
      onCreate: (db, version) => _createDb(db),
      version: 1,
    );
    return _db;
  }

  static void _createDb(Database db) {
    db.execute(
      "CREATE TABLE EyePatch(id INTEGER PRIMARY KEY, device STRING, patchTemp DOUBLE, ambientTemp DOUBLE, rawData STRING, timeStamp INTEGER)",
    );
  }

  Future<void> insertBle(Ble ble) async {
    final db = await database;
    await db.insert('EyePatch', ble.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Ble>> getAllBle() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('EyePatch');
    print('기록 가져오기');

    return List.generate(maps.length, (index) {
      return Ble(
          id: maps[index]['id'],
          device: maps[index]['device'],
          patchTemp: maps[index]['patchTemp'],
          ambientTemp: maps[index]['ambientTemp'],
          rawData: maps[index]['rawData'],
          timeStamp: maps[index]['timeStamp']);
    });
  }

  Future getLastId(String tableName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('EyePatch');
    if (maps.isEmpty) {
      return 0;
    }
    return maps[maps.length - 1]['id'];
  }

  Future getListTemp() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('EyePatch');
    if (maps.isEmpty) {
      return null;
    }
    return maps[maps.length - 1]['patchTemp'];
  }

  Future<void> deleteBle(String device) async {
    final db = await database;
    await db.delete(
      'EyePatch',
      where: "device = ?",
      whereArgs: [device],
    );
  }

  Future<dynamic> getBle(String device) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = (await db.query(
      'EyePatch',
      where: 'device = ?',
      whereArgs: [device],
    ));
    return maps.isNotEmpty ? maps : null;
  }

  Future<void> dropTable() async {
    final db = await database;
    db.delete('EyePatch');
  }

  ///////////////////////////////////////////////////////

// Future<List<Object>> readFile(String deviceName) async {
//   try {
//     final file = await _getlocalFile(deviceName); // return File
//     final contents = file.openRead();
//     final fields = await contents
//         .transform(utf8.decoder)
//         .transform(const CsvToListConverter()) //db에 담기 두 번 누르면 두 번 들어감
//         .toList();
//     // print("파일 읽기: $fields}");
//     return fields;
//   } catch (e) {
//     debugPrint('에러: $e');
//     return [];
//   }}

  Future<void> sqlToCsv(String deviceName) async {
    final db = await database;
    var result = await db.query('EyePatch');
    List<List<dynamic>> rows = [];
    List<dynamic> row = [];

    Object file = await ExternalStorageHelper.readFile(deviceName);

    if (file.toString().length == 2) {
      //2
      row.add("patchTemp");
      row.add("ambientTemp");
      row.add("rawData");
      row.add("timeStamp");
      rows.add(row);
    } else {
      row.add('');
      rows.add(row);
    }

    for (int i = 0; i < result.length; i++) {
      List<dynamic> row = [];
      row.add(result[i]["patchTemp"]);
      row.add(result[i]["ambientTemp"]);
      row.add(result[i]["rawData"]);
      row.add(result[i]["timeStamp"]);

      rows.add(row);
    }
    String csv = const ListToCsvConverter().convert(rows);
    ExternalStorageHelper.writeToFile(csv, deviceName);
  }
}
