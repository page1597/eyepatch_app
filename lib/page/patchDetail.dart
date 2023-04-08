import 'package:eyepatch_app/model.dart/eyePatch.dart';
import 'package:eyepatch_app/style/palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PatchDetail extends StatefulWidget {
  final BluetoothDevice? connectedDevice;
  final EyePatch eyePatchInfo;
  final bool isConnected;
  const PatchDetail(
      {super.key,
      this.connectedDevice,
      required this.eyePatchInfo,
      required this.isConnected});

  @override
  State<PatchDetail> createState() => _PatchDetailState();
}

class _PatchDetailState extends State<PatchDetail> {
  BluetoothDevice _device = BluetoothDevice.fromId('');
  @override
  void initState() {
    super.initState();
    debugPrint('initstate');
    _device = widget.connectedDevice!;

    if (widget.isConnected) {
      // indicate
    }
  }

  // void _showDialog(Widget child) {
  //   showCupertinoModalPopup<void>(
  //       context: context,
  //       builder: (BuildContext context) => Container(
  //             height: 216,
  //             padding: const EdgeInsets.only(top: 6.0),
  //             // The bottom margin is provided to align the popup above the system
  //             // navigation bar.
  //             margin: EdgeInsets.only(
  //               bottom: MediaQuery.of(context).viewInsets.bottom,
  //             ),
  //             // Provide a background color for the popup.
  //             color: CupertinoColors.systemBackground.resolveFrom(context),
  //             // Use a SafeArea widget to avoid system overlaps.
  //             child: SafeArea(
  //               top: false,
  //               child: child,
  //             ),
  //           ));
  // }

  Duration initialTimer = new Duration();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'EyePatch',
            style: TextStyle(fontSize: 20.0),
          ),
          foregroundColor: Palette.primary1,
          backgroundColor: Colors.white,
          elevation: 0.0,
          toolbarHeight: 70.0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        color: Palette.grey,
                      ),
                      height: 130,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: widget.isConnected
                                      // color: widget.connectedDevice.state.
                                      ? Palette.primary1
                                      : Palette.red,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  '아이패치',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.eyePatchInfo.bleAddress,
                                    // widget.connectedDevice.id.toString(),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text(
                                  '착용시간',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.eyePatchInfo.time.toString(),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                  onPressed: () async {
                    if (widget.connectedDevice != null) {
                      _device.discoverServices();
                      // List<BluetoothService> services =
                      //     await _device.discoverServices();
                      // services.forEach((services) {});
                      // print(a);
                      // print('??');

                      // //read function
                      // services?.forEach((service) async {
                      //   // print(service);

                      //   var characteristics = service.characteristics;
                      //   // print(characteristics);
                      //   for (BluetoothCharacteristic c in characteristics) {
                      //     List<int> value = await c.read();
                      //     if (c.properties.indicate) {
                      //       await c.setNotifyValue(true);

                      //       c.value.listen((value) async {
                      //         print('value: ${value}');
                      //       });
                      //     }
                      //   }
                      // });
                    }
                  },
                  child: Text('set noti')),
              TextButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              title: const Text('아이패치 착용 알림 설정',
                                  style: TextStyle(
                                      color: Palette.primary1,
                                      fontWeight: FontWeight.bold)),
                              content: SingleChildScrollView(
                                child: ListBody(children: [
                                  const Text('알람을 받을 시간을 설정하세요.',
                                      style: TextStyle(
                                          color: Palette.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  TextButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Container(
                                                  height: MediaQuery.of(context)
                                                          .copyWith()
                                                          .size
                                                          .height /
                                                      3,
                                                  child: SizedBox.expand(
                                                      child:
                                                          CupertinoTimerPicker(
                                                    onTimerDurationChanged:
                                                        (Duration
                                                            changedTimer) {
                                                      setState(() {
                                                        initialTimer =
                                                            changedTimer;
                                                      });
                                                    },
                                                    mode:
                                                        CupertinoTimerPickerMode
                                                            .hm,
                                                    minuteInterval: 30,
                                                    initialTimerDuration:
                                                        initialTimer,
                                                  )));
                                            }).whenComplete(() {
                                          print(initialTimer.toString());
                                        });
                                      },
                                      child: Text('시간 설정'))
                                ]),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('확인'),
                                )
                              ]);
                        });
                  },
                  child: Text('알림 설정'))
            ],
          ),
        ));
  }
}
