import 'dart:convert';
import 'dart:io';
import 'package:eyepatch_app/model.dart/ble.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';
import 'externalStorageHelpder.dart';

class DBHelper {
  dynamic _db;

  Future<Database> get database async {
    if (_db != null) return _db;
    _db = openDatabase(
      join(await getDatabasesPath(), 'Eyepatch.db'),
      onCreate: (db, version) => _createDb(db),
      version: 1,
    );
    return _db;
  }

  static void _createDb(Database db) {
    db.execute(
      "CREATE TABLE Eyepatch(id INTEGER PRIMARY KEY, device STRING, temp DOUBLE, rawData STRING, timeStamp INTEGER)",
    );
  }

  Future<void> insertBle(Ble ble) async {
    final db = await database;
    await db.insert('Eyepatch', ble.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Ble>> getAllBle() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Eyepatch');
    print('기록 가져오기');

    return List.generate(maps.length, (index) {
      return Ble(
          id: maps[index]['id'],
          device: maps[index]['device'],
          temp: maps[index]['temp'],
          rawData: maps[index]['rawData'],
          timeStamp: maps[index]['timeStamp']);
    });
  }

  Future getLastId(String tableName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Eyepatch');
    if (maps.isEmpty) {
      return 0;
    }
    return maps[maps.length - 1]['id'];
  }

  Future getListTemp() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Eyepatch');
    if (maps.isEmpty) {
      return null;
    }
    return maps[maps.length - 1]['temp'];
  }

  Future<void> deleteBle(String device) async {
    final db = await database;
    await db.delete(
      'Eyepatch',
      where: "device = ?",
      whereArgs: [device],
    );
  }

  Future<dynamic> getBle(String device) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = (await db.query(
      'Eyepatch',
      where: 'device = ?',
      whereArgs: [device],
    ));
    return maps.isNotEmpty ? maps : null;
  }

  Future<void> dropTable() async {
    final db = await database;
    db.delete('Eyepatch');
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
    var result = await db.query('Eyepatch');
    List<List<dynamic>> rows = [];
    List<dynamic> row = [];

    Object file = await ExternalStorageHelper.readFile(deviceName);

    if (file.toString().length == 3) {
      //2
      row.add("온도");
      row.add("rawData");
      row.add("시간");
      rows.add(row);
    } else {
      row.add('');
      rows.add(row);
    }

    for (int i = 0; i < result.length; i++) {
      List<dynamic> row = [];
      row.add(result[i]["temp"]);
      row.add(result[i]["rawData"]);
      row.add(result[i]["timeStamp"]);

      rows.add(row);
    }
    String csv = const ListToCsvConverter().convert(rows);
    ExternalStorageHelper.writeToFile(csv, deviceName);
  }
}
