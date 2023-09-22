import 'dart:convert';
import 'dart:io';
import 'package:eyepatch_app/model/ble.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';
import 'externalStorageHelpder.dart';

// 백그라운드로 바꾸기
class DBHelper {
  // dynamic _db;
  var _db;

  Future<Database> getDatabase(String tableName) async {
    if (_db != null) return _db;
    _db = openDatabase(
      join(await getDatabasesPath(), '$tableName.db'),
      onCreate: (db, version) => _createDb(db, tableName),
      version: 1,
    );
    return _db;
  }

  static void _createDb(Database db, String tableName) {
    db.execute(
      "CREATE TABLE $tableName(timeStamp INTEGER PRIMARY KEY, ble STRING, patchTemp DOUBLE, ambientTemp DOUBLE, patched STRING, rawData STRING)",
    );
  }

  Future<void> insertRecord(String tableName, Ble ble) async {
    print('insert ble');

    final db = await getDatabase(tableName);
    await db.insert(tableName, ble.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 부분 업데이트 (사용: 사용자가 수기로 기록을 입력할 때)
  // 어떤 건 기록에 아예 없을 수도 있고, 어떤건 포함되고 어떤건 포함 안될 수도 있자나
  Future<void> insertPartialRecord(String bleName, String tableName,
      DateTime startTime, int duration) async {
    List<Ble> partialRecord =
        await getPartialRecord(tableName, startTime, duration);
    // duration 단위: 분
    print('insert partial record');

    int lastTimeStamp = await getLastTimeStamp(tableName);
    DateTime lastTime = DateTime.fromMillisecondsSinceEpoch(lastTimeStamp);
    // String ble = await getLastBle(tableName);
    // print(ble);

    for (DateTime i = startTime;
        i.isBefore(startTime.add(Duration(minutes: duration)));
        i = i.add(const Duration(seconds: 30))) {
      insertRecord(
          tableName,
          Ble(
              timeStamp: i.millisecondsSinceEpoch,
              ble: bleName,
              patched: 1,
              rawData: '수기 입력'));
    }
  }

  Future<List<Ble>> getAllBle(String tableName) async {
    final db = await getDatabase(tableName);
    print(tableName);
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    String path = await getDatabasesPath();

    print('기록 가져오기: $path');

    List<Ble> bleList = List.generate(maps.length, (index) {
      return Ble(
        // id: maps[index]['id'],
        timeStamp: maps[index]['timeStamp'],
        ble: maps[index]['ble'],
        patchTemp: maps[index]['patchTemp'],
        ambientTemp: maps[index]['ambientTemp'],
        patched: maps[index]['patched'],
        rawData: maps[index]['rawData'],
        // dateTime: maps[index]['dateTime']
      );
    });

    bleList.forEach((element) {
      print(
          'timeStamp: ${element.timeStamp}, ble: ${element.ble}, patchTemp: ${element.patchTemp}, ambientTemp: ${element.ambientTemp}, patched: ${element.patched}, rawData: ${element.rawData}');
    });
    return bleList;
  }

  Future<List<Ble>> getPartialRecord(
      String tableName, DateTime startTime, int duration) async {
    // getPartBle
    final db = await getDatabase(tableName);
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    String path = await getDatabasesPath();
    print('기록 가져오기: $path');
    List<Map<String, dynamic>> partialMap = [];
    maps.forEach((element) {
      element.forEach((key, value) {
        if (key.toString() == 'timeStamp' &&
            value >= startTime.microsecondsSinceEpoch &&
            value <=
                startTime
                    .add(Duration(minutes: duration))
                    .microsecondsSinceEpoch) {
          partialMap.add(element);
          // print(key.toString() +
          //     ": " +
          //     value.toString() +
          //     ' / ' +
          //     startTime.millisecondsSinceEpoch.toString());
        }
      });
    });

    List<Ble> bleList = List.generate(partialMap.length, (index) {
      return Ble(
        // id: maps[index]['id'],
        timeStamp: maps[index]['timeStamp'],
        ble: maps[index]['ble'],
        patchTemp: maps[index]['patchTemp'],
        ambientTemp: maps[index]['ambientTemp'],
        patched: maps[index]['patched'],
        rawData: maps[index]['rawData'],
        // dateTime: maps[index]['dateTime']
      );
    });

    bleList.forEach((element) {
      print(
          'timeStamp: ${element.timeStamp}, ble: ${element.ble}, patchTemp: ${element.patchTemp}, ambientTemp: ${element.ambientTemp}, patched: ${element.patched}, rawData: ${element.rawData}');
    });
    return bleList;
  }

  Future getLastTimeStamp(String tableName) async {
    final db = await getDatabase(tableName);
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    if (maps.isEmpty) {
      return 0;
    }
    return maps[maps.length - 1]['timeStamp'];
  }

  Future getLastBle(String tableName) async {
    final db = await getDatabase(tableName);
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    if (maps.isEmpty) {
      return 'unknown'; // ble 이름으로 바꿔야됨.
    }
    return maps[maps.length - 1]['ble'];
  }
  // Future getLastId(String tableName) async {
  //   final db = await database;
  //   final List<Map<String, dynamic>> maps = await db.query('RECORD');
  //   if (maps.isEmpty) {
  //     return 0;
  //   }
  //   return maps[maps.length - 1]['id'];
  // }

  // Future getListTemp() async {
  //   final db = await database;
  //   final List<Map<String, dynamic>> maps = await db.query('Eyepatch');
  //   if (maps.isEmpty) {
  //     return null;
  //   }
  //   return maps[maps.length - 1]['temp'];
  // }

  // Future<void> deleteRecord(String tableName, String record) async {
  //   final db = await database(tableName);
  //   await db.delete(
  //     'RECORD',
  //     where: "record = ?",
  //     whereArgs: [record],
  //   );
  // }

  // Future<dynamic> getBle(String ble) async {
  //   final db = await database('testBle');

  //   final List<Map<String, dynamic>> maps = (await db.query(
  //     'RECORD',
  //     where: 'ble = ?',
  //     whereArgs: [ble],
  //   ));
  //   return maps.isNotEmpty ? maps : null;
  // }

  Future<void> dropTable(String tableName) async {
    final db = await getDatabase(tableName);
    db.delete(tableName);
    // db.d
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

  Future<void> sqlToCsv(
      String tableName, String deviceName, int startedTime) async {
    final db = await getDatabase(tableName);
    // var result = await db.query('RECORD');
    var result = await db.query(tableName);
    List<List<dynamic>> rows = [];
    List<dynamic> row = [];
    DateTime now = DateTime.now();

    Object file = await ExternalStorageHelper.readFile(deviceName, now);

    if (file.toString().length == 2) {
      //2
      row.add("timeStamp");
      row.add("patchTemp");
      row.add("ambientTemp");
      row.add("patched");
      row.add("rawData");
      // row.add('dateTime');
      rows.add(row);
    } else {
      row.add('');
      rows.add(row);
    }

    for (int i = 0; i < result.length; i++) {
      if (int.parse(result[i]["timeStamp"].toString()) >= startedTime) {
        // 이게 뭐지 걸리네
        List<dynamic> row = [];
        row.add(result[i]["timeStamp"]);
        row.add(result[i]["patchTemp"]);
        row.add(result[i]["ambientTemp"]);
        row.add(result[i]["patched"]);
        row.add(result[i]["rawData"]);
        // row.add(result[i]["dateTime"]);

        rows.add(row);
      }
    }
    // print(rows);
    String csv = const ListToCsvConverter().convert(rows);
    print(csv);
    ExternalStorageHelper.writeToFile(csv, deviceName);
  }
}
