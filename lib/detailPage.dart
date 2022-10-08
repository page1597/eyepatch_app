import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DetailPage extends StatefulWidget {
  final DiscoveredDevice device; // charicter정보도 받아와야하나
  final DeviceConnectionState connectionState;
  const DetailPage(
      {Key? key, required this.device, required this.connectionState})
      : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

// 연결이 끊겼으면 나가게?

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.id),
      ),
      body: Center(
        child: Text(widget.device.id),
      ),
    );
  }
}
