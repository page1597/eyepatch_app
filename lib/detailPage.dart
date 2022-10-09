import 'package:eyepatch_app/database/dbHelper.dart';
import 'package:eyepatch_app/model.dart/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hex/hex.dart';

class DetailPage extends StatefulWidget {
  final ScanResult result; // charicter정보도 받아와야하나
  final dynamic connectionState;
  const DetailPage(
      {Key? key, required this.result, required this.connectionState})
      : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

// 연결이 끊겼으면 나가게?

class _DetailPageState extends State<DetailPage> {
  final DBHelper _dbHelper = DBHelper();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.result.device.name),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('device id: ${widget.result.device.id.toString()}'),
              Text(
                  'raw data: ${HEX.encode(widget.result.advertisementData.rawBytes)}'),
              TextButton(
                  onPressed: () async {
                    _dbHelper.insertBle(Ble(
                        id: await _dbHelper
                            .getLastId(widget.result.device.name),
                        device: widget.result.device.id.toString(),
                        temp: 3.0,
                        timeStamp: 0));
                  },
                  child: const Text('sqlite에 넣기')),
              TextButton(
                  onPressed: () {
                    _dbHelper.sqlToCsv(widget.result.device.name);
                    print('기록된 온도 정보가 저장되었습니다.');
                    _dbHelper.dropTable();
                  },
                  child: Text('csv에 저장하기'))
            ],
          ),
        ),
      ),
    );
  }
}
