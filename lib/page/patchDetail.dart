import 'dart:collection';
// import { db } from 'config/firebase';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyepatch_app/database/dbHelper.dart';
import 'package:eyepatch_app/model.dart/ble.dart';
import 'package:eyepatch_app/model.dart/eyePatch.dart';
import 'package:eyepatch_app/patchController.dart';
import 'package:eyepatch_app/style/palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:get/get.dart';
// import 'package:pie_chart/pie_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:time_chart/time_chart.dart';

class PatchDetail extends StatefulWidget {
  final BluetoothDevice? connectedDevice;
  // final EyePatch eyePatchInfo;
  final String ble;
  final bool isConnected;
  const PatchDetail(
      {super.key,
      this.connectedDevice,
      required this.ble,
      // required this.eyePatchInfo,
      required this.isConnected});

  @override
  State<PatchDetail> createState() => _PatchDetailState();
}

class Event {
  DateTime dateTime;
  bool patched;

  Event(this.dateTime, this.patched);
}

class _PatchDetailState extends State<PatchDetail> {
  final controller = Get.put(Controller());
  // EyePatchList eyePatchList = controller.eyePatchList;

  BluetoothDevice _device = BluetoothDevice.fromId('');
  DBHelper dbHelper = DBHelper();
  TextEditingController timeField = TextEditingController();
  final LocalStorage storage = LocalStorage('patchList.json');
  // late EyePatch eyePatch;
  int index = 0;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  var _calendarFormat = CalendarFormat.month;

  bool openGraph = false;

  int _selectedHour = 0, _selectedMinute = 0;
  List<int> minutes = [0, 30];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final ValueNotifier<List<Event>> _selectedEvents;

  List<Event> _getEventsForDay(DateTime day) {
    return events[day] ?? [];
  }

// firestore에서 가져와서 여기에 저장하는걸로 바꾸기
// get firebase해서 가져와지는 정보 확인하기
// 문서(doc) 이름이랑 필드의 patched 항목만 체크해서
// events 안에 넣기
// data처럼 앞에서 final로 선언하지 말고 아래에서 add 형태로 추가하기
  // final events = LinkedHashMap(
  //   equals: isSameDay,
  // )..addAll({
  //     // DateTime.utc(2023, 5, 1): [Event(DateTime(2023, 5, 29, 16, 11), true)],
  //     DateTime.utc(2023, 5, 29): [
  //       // Event(DateTime.fromMillisecondsSinceEpoch(1685340407522), true),
  //       Event(DateTime(2023, 5, 29, 16, 11), true),
  //       Event(DateTime(2023, 5, 29, 17, 11), false),
  //       Event(DateTime(2023, 5, 29, 17, 30), true),
  //       Event(DateTime(2023, 5, 29, 18, 00), true),
  //       Event(DateTime(2023, 5, 29, 19, 00), false),
  //     ], // 시간으로 바꾸기....시간으로 바꾸기...?
  //   });

  LinkedHashMap<DateTime?, dynamic> events = LinkedHashMap(equals: isSameDay);

  // var data = events.forEach((key, value) {

  // });

  // final data = [
  //   DateTimeRange(
  //     start: DateTime.fromMillisecondsSinceEpoch(1685340407522),
  //     end: DateTime(2023, 5, 29, 16, 11),
  //   )
  // ];
  List<DateTimeRange> data = [];
  List<Event> eventEntries = [];
  @override
  void initState() {
    super.initState();
    debugPrint('initstate');
    // _device = widget.connectedDevice!;
    for (var element in controller.eyePatchList.eyePatches) {
      // print(widget.connectedDevice?.id.toString());
      if (element.ble == widget.ble) {
        index = controller.eyePatchList.eyePatches.indexOf(element);
      }
    }
    // print('index: ' + index.toString());
    // EyePatch eyePatch = controller.eyePatchList.eyePatches
    // .where((element) => element.bleAddress == widget.bleAddress)

    // print(eyePatch.bleAddress);
    // int index =x/
    // controller.eyePatchList.eyePatches.forEach((element) {
    // if (element.bleAddress == widget.bleAddress) {

    // }
    // })
    timeField = TextEditingController(
        text: controller.eyePatchList.eyePatches[index].time.toString());

    if (widget.isConnected) {
      // indicate
    }

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));

    const source = Source.cache;
    DateTime recordedDay = DateTime.now();
    _firestore
        .collection("qq:bb:cc:dd:20181010") // 해당 기기로 바꾸기
        .get(const GetOptions(source: source))
        .then((querySnapshot) {
      for (var docSnapshot in querySnapshot.docs) {
        recordedDay =
            DateTime.fromMillisecondsSinceEpoch(int.parse(docSnapshot.id));

        eventEntries.add(Event(
            DateTime.fromMillisecondsSinceEpoch(int.parse(docSnapshot.id)),
            docSnapshot["patched"] == 1 ? true : false));
      }
      events.addAll({
        DateTime.utc(recordedDay.year, recordedDay.month, recordedDay.day):
            eventEntries
      });
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  insertSql() async {
    print('insert sql');
    dbHelper.insertBle(Ble(
      id: await dbHelper.getLastId(_device.name) + 1,
      ble: _device.id.id,
      patched: 'O',
      timeStamp: DateTime.now().millisecondsSinceEpoch,
      rawData: 'test',
      // dateTime: DateFormat('kk:mm:ss').format(DateTime.now()),
    ));
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

  // 원형 그래프에 쓰일
  // timestamp의 int
  // patched의 bool
  // Map<String, double> dataMap = {
  //   "1685340407517": 1,
  //   "1685340407518": 1,
  //   "1685340407519": 1,
  //   "1685340407520": 1,
  //   "1685340407521": 1,
  //   "1685340407522": 1,
  //   "1685340407523": 1,
  //   "1685340407524": 1,

  //   // DateTim
  // };

  @override
  Widget build(BuildContext context) {
    // Controller controller = Get.put(Controller());
// controller.eyePatchList.eyePatches[0].bleAddress,
    return GetBuilder<Controller>(builder: (controller) {
      // var eyePatch = widget.connectedDevice.id
      // EyePatch eyePatch = controller.eyePatchList.eyePatches
      // .where((element) => element.bleAddress == widget.connectedDevice!.id.toString()) as EyePatch; // 맞나..?
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
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Stack(children: [
                            Positioned(
                              right: 0,
                              top: 0,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
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
                                        controller
                                            .eyePatchList.eyePatches[index].ble,
                                        // eyePatch.bleAddress,
                                        // widget.connectedDevice.id.toString(),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // const SizedBox(height: 8),
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
                                      controller
                                          .eyePatchList.eyePatches[index].time
                                          .toString(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                    TextButton(
                                        child: const Text("시간변경"),
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                    title: const Text('시간 변경'),
                                                    content: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          width: 24,
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                              color: Palette
                                                                  .primary1),
                                                          child: Center(
                                                              child: TextButton(
                                                            onPressed: () {
                                                              if (timeField
                                                                      .text ==
                                                                  "0") {
                                                                return;
                                                              }
                                                              timeField.text =
                                                                  (int.parse(timeField
                                                                              .text) -
                                                                          1)
                                                                      .toString();
                                                            },
                                                            child: const Text(
                                                              "-",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10),
                                                            ),
                                                          )),
                                                        ),
                                                        SizedBox(
                                                          width: 40,
                                                          height: 34,
                                                          child: TextFormField(
                                                            textAlign: TextAlign
                                                                .center,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: [
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly
                                                            ],
                                                            controller:
                                                                timeField,
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 24,
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                              color: Palette
                                                                  .primary1),
                                                          child: Center(
                                                              child: TextButton(
                                                            onPressed: () {
                                                              timeField.text =
                                                                  (int.parse(timeField
                                                                              .text) +
                                                                          1)
                                                                      .toString();
                                                            },
                                                            child: const Text(
                                                              "+",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10),
                                                            ),
                                                          )),
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        const Text('시간'),
                                                      ],
                                                    ),
                                                    actions: [
                                                      SizedBox(
                                                          child: TextButton(
                                                        child: const Text("확인"),
                                                        onPressed: () {
                                                          Get.find<Controller>()
                                                              .updateElement(
                                                                  controller
                                                                      .eyePatchList
                                                                      .eyePatches[
                                                                          index]
                                                                      .ble,
                                                                  "time",
                                                                  int.parse(
                                                                      timeField
                                                                          .text));

                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                      )
                                                          // });
                                                          )
                                                    ]);
                                              });
                                        }),
                                  ],
                                ),
                                // const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text(
                                      '착용비율 좌:우',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${controller.eyePatchList.eyePatches[index].leftRatio.toInt()}:${(100 - controller.eyePatchList.eyePatches[index].leftRatio).toInt()}",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),

                TableCalendar(
                  locale: 'ko_KR',
                  headerStyle: const HeaderStyle(formatButtonVisible: false),
                  firstDay: DateTime.now()
                      .subtract(const Duration(days: 365 * 10 + 2)),
                  lastDay:
                      DateTime.now().add(const Duration(days: 365 * 10 + 2)),
                  focusedDay: _focusedDay,
                  calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Palette.grey,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                          fontWeight: FontWeight.bold, color: Palette.black),
                      markerSize: 10,
                      markerDecoration: BoxDecoration(
                          color: Palette.red, shape: BoxShape.circle)),
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                  onDaySelected: (selectedDay, focusedDay) {
                    data = [];
                    data.clear();
                    setState(() {});
                    // data.clear();
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      openGraph = true;
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _selectedEvents.value = _getEventsForDay(selectedDay);

                      // 파이어베이스에서 값들 가져와서 값 가공하기

                      const source = Source.cache;

                      _firestore
                          .collection("qq:bb:cc:dd:20181010")
                          .get(const GetOptions(source: source))
                          .then((querySnapshot) {
                        for (var docSnapshot in querySnapshot.docs) {
                          // print(_selectedDay.millisecondsSinceEpoch.toString());
                          // 같은 날 필터링
                          if (DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(docSnapshot.id))
                                      .year ==
                                  _selectedDay.year &&
                              DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(docSnapshot.id))
                                      .month ==
                                  _selectedDay.month &&
                              DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(docSnapshot.id))
                                      .day ==
                                  _selectedDay.day) {
                            // 같은 날이면
                            // print("O");
                            events.forEach((key, value) {
                              // 왜 세번 돌아가는 거지
                              // print('key: $key');
                              // boolea continue = false;
                              bool conti = false; //continue
                              DateTime initial = DateTime.now();
                              DateTime start = initial;
                              DateTime end = initial;
                              data = [];
                              data.clear();
                              setState(() {});
                              for (Event i in value) {
                                if (i.patched) {
                                  // 패치 착용 하고
                                  if (conti) {
                                    conti = false;
                                  } else {
                                    start = i.dateTime;
                                    conti = true;
                                  }
                                } else {
                                  // 패치 착용 안하고 있으면
                                  end = i.dateTime;
                                  conti = false;
                                }

                                if ((start != initial && end != initial) &&
                                    start.isBefore(end)) {
                                  // print('start: $start : end: $end');
                                  data.add(DateTimeRange(
                                      start: start,
                                      end: end)); // 착용 전까지 잘라야됨..계속 이어붙여야함..
                                }
                              }

                              // setState(() {});

                              // print(d)
                              for (var element in data) {
                                print(element);
                              }
                              // final data = [
                              //   DateTimeRange(
                              //     start: DateTime.fromMillisecondsSinceEpoch(
                              //         1685340407522),
                              //     end: DateTime(2023, 5, 29, 16, 11),
                              //   )
                              // ];
                            });
                          } // 같은 날이 아닐 경우
                          // print("X");
                          // debugPrint(
                          //     '${docSnapshot.id} => ${docSnapshot.data()}');
                        }
                      });

                      // final events = LinkedHashMap(
                      //   equals: isSameDay,
                      // )..addAll({
                      //     DateTime.utc(2023, 5, 1): [
                      //       Event(DateTime(2023, 5, 29, 16, 11))
                      //     ],
                      //     DateTime.utc(2023, 5, 25): [
                      //       Event(DateTime.fromMillisecondsSinceEpoch(
                      //           1685340407522)),
                      //       Event(DateTime(2023, 5, 29, 16, 11))
                      //     ], // 시간으로 바꾸기....시간으로 바꾸기...?
                      // });
                      // var data = events.forEach((key, value) {
                      //   DateTimeRange(start: , end: );
                      // });

                      // final data = [
                      //   DateTimeRange(
                      //     start: DateTime.fromMillisecondsSinceEpoch(
                      //         1685340407522),
                      //     end: DateTime(2023, 5, 29, 16, 11),
                      //   )
                      // ];
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  eventLoader: _getEventsForDay,
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          // 착용 완료 시만 표시되게
                          right: 1,
                          top: 5,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Palette.primary1),
                          ),
                        );
                      } else {
                        // return Positioned(
                        //   right: 1,
                        //   top: 1,
                        //   child: Container(
                        //     width: 10,
                        //     height: 10,
                        //     decoration: const BoxDecoration(
                        //         shape: BoxShape.circle, color: Palette.red),
                        //   ),
                        // );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                    // 설정한 변수가 변할 때마다 builder를 호출하여 ui를 자동으로 업데이트.
                    // StreamBuilder보다 단순함.
                    child: ValueListenableBuilder<List<Event>>(
                        valueListenable: _selectedEvents,
                        builder: (context, value, child) {
                          // return ListView.builder(
                          //     itemCount: value.length,
                          //     itemBuilder: ((context, index) {
                          //       return Container(
                          //         decoration: BoxDecoration(
                          //           border: Border.all(),
                          //           borderRadius: BorderRadius.circular(12.0),
                          //         ),
                          //         child: ListTile(
                          //           onTap: () => print('${value[index].obs}'),
                          //           title: Text('${value[index].completed}'),
                          //         ),
                          //       );
                          //     }));
                          // return PieChart(
                          //   dataMap: dataMap,
                          //   ringStrokeWidth: 20,
                          //   // chartType: ChartType.ring,
                          //   // colorList: [Palette.primary1, Palette.primary1],
                          //   chartValuesOptions: const ChartValuesOptions(
                          //     showChartValues: false,
                          //     showChartValueBackground: false,
                          //     showChartValuesInPercentage: false,
                          //     showChartValuesOutside: false,
                          //   ),
                          //   legendOptions:
                          //       const LegendOptions(showLegends: false),
                          // );
                          return value.isNotEmpty
                              ? SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 350,
                                          child: TimeChart(
                                            data: data.reversed
                                                .toList(), // 최근 날짜 -> 과거 날자 순서로 넣어야함
                                            viewMode: ViewMode.weekly,
                                            chartType: ChartType.time,
                                            height: 300,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // child: Expanded(
                                    //   child: SizedBox(
                                    //     height: 200,
                                    //     child: ListView.builder(
                                    //       itemCount: data.length,
                                    //       itemBuilder: (ctx, idx) {
                                    //         return Text(
                                    //             'start: ${data[idx].start} - end: ${data[idx].end}');
                                    //       },
                                    //     ),
                                    //   ),
                                    // ),
                                  ),
                                )
                              : const SizedBox();
                        })),

                // TextButton(
                //     onPressed: () async {
                //       if (widget.connectedDevice != null) {
                //         _device.discoverServices();
                //         List<BluetoothService> services =
                //             await _device.discoverServices();
                //         services.forEach((service) async {
                //           // print(characteristics);
                //           var characteristics = service.characteristics;

                //           for (BluetoothCharacteristic c in characteristics) {
                //             List<int> value = await c.read();
                //             if (c.properties.indicate) {
                //               await c.setNotifyValue(true);

                //               c.value.listen((value) async {
                //                 print('value: ${value}');

                //                 insertSql();
                //               });
                //             }
                //           }
                //         });

                //         // //read function
                //         // services?.forEach((service) async {
                //         //   // print(service);

                //         // });
                //       }
                //     },
                //     child: Text('set noti')),
                // TextButton(
                //     onPressed: () {
                //       dbHelper.getAllBle();
                //     },
                //     child: Text('sqlite 에 있는 것들 보기')),
                // TextButton(
                //     onPressed: () {
                //       showAlarmDialog(context);
                //     },
                //     child: Text('알림 설정')),

                // TextButton(
                //     onPressed: () async {
                //       await _firestore
                //           .collection("qq:bb:cc:dd:20181010")
                //           .doc(DateTime.now().millisecondsSinceEpoch.toString())
                //           .set({
                //         "id": "124",
                //         "ble": "qq:bb:cc:dd",
                //         "ambientTemp": 35,
                //         "patchTemp": 36,
                //         "patched": 0,
                //         "rawData": ''
                //       });
                //     },
                //     child: const Text('set 파이어베이스')),
                TextButton(
                    onPressed: () {
                      const source = Source.cache;

                      _firestore
                          .collection("qq:bb:cc:dd:20181010")
                          .get(const GetOptions(source: source))
                          .then((querySnapshot) {
                        for (var docSnapshot in querySnapshot.docs) {
                          print(_selectedDay.millisecondsSinceEpoch.toString());
                          if (DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(docSnapshot.id))
                                      .year ==
                                  _selectedDay.year &&
                              DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(docSnapshot.id))
                                      .month ==
                                  _selectedDay.month &&
                              DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(docSnapshot.id))
                                      .day ==
                                  _selectedDay.day) {
                            // 같은 날이면
                            print("O");
                            print(
                                '${DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day)} : ${[
                              Event(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(docSnapshot.id)),
                                  docSnapshot["patched"] == 1 ? true : false)
                            ]}');

                            events.addAll({
                              DateTime.utc(_selectedDay.year,
                                  _selectedDay.month, _selectedDay.day): [
                                Event(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.parse(docSnapshot.id)),
                                    docSnapshot["patched"] == 1 ? true : false)
                              ]
                            });
                          } // 같은 날이 아닐 경우
                          print("X");
                          debugPrint(
                              '${docSnapshot.id} => ${docSnapshot.data()}');
                        }
                      });
                      // if (_selectedDay == )
                      // debugPrint('${_selectedDay.month}월 ${_selectedDay.day}일');
                    },
                    child: const Text('get 파이어베이스')),
              ],
            ),
          ));
    });
  }

  Widget _buildEventsMarkerNum(List events) {
    return Container(
      child: Text('${events.length}'),
      decoration: BoxDecoration(color: Colors.amber),
    );
  }

  Future<dynamic> showAlarmDialog(BuildContext context) {
    // Duration initialTimer = Duration(hours: 0, minutes: 0);

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  title: const Text('아이패치 착용 알림 설정',
                      style: TextStyle(
                          color: Palette.primary1,
                          fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        const Text('알람을 받을 시간을 설정하세요.',
                            style: TextStyle(
                                color: Palette.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        TextButton(
                            onPressed: () {
                              // DatePicker.showDatePick
                              showCupertinoModalPopup(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Container(
                                        color: Colors.white,
                                        height: MediaQuery.of(context)
                                                .copyWith()
                                                .size
                                                .height /
                                            3,
                                        // height: 200,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 40.0, right: 40.0),
                                          child:
                                              // Column(
                                              // children: [
                                              Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                Expanded(
                                                  child: CupertinoPicker(
                                                    squeeze: 1,
                                                    // offAxisFraction: 0.5,
                                                    scrollController:
                                                        FixedExtentScrollController(
                                                            initialItem:
                                                                _selectedHour),
                                                    itemExtent: 55.0,
                                                    backgroundColor:
                                                        Colors.white,
                                                    onSelectedItemChanged:
                                                        (value) {
                                                      setState(() {
                                                        _selectedHour = value;
                                                      });
                                                      print(_selectedHour);
                                                    },
                                                    children: List.generate(
                                                      24,
                                                      (index) => Center(
                                                        child: Text(
                                                          '$index',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 24),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  child: Text(
                                                    '시',
                                                    style: TextStyle(
                                                        fontSize: 24,
                                                        color: Palette.black),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 24,
                                                ),
                                                Expanded(
                                                  child: CupertinoPicker(
                                                    squeeze: 1,
                                                    scrollController:
                                                        FixedExtentScrollController(
                                                            initialItem:
                                                                _selectedMinute),
                                                    itemExtent: 55,
                                                    backgroundColor:
                                                        Colors.white,
                                                    onSelectedItemChanged:
                                                        (index) {
                                                      setState(() {
                                                        _selectedMinute =
                                                            minutes[index];
                                                      });
                                                      print(_selectedMinute);
                                                    },
                                                    // children: List.generate(
                                                    //   60,
                                                    //   (index) => Text('$index'),
                                                    // ),
                                                    children: List.generate(
                                                        minutes.length,
                                                        (index) => Center(
                                                              child: Text(
                                                                '${minutes[index]}',
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            24),
                                                              ),
                                                            )),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  child: Text(
                                                    '분',
                                                    style: TextStyle(
                                                        fontSize: 24,
                                                        color: Palette.black),
                                                  ),
                                                ),
                                              ]),
                                          // Container(
                                          //   color: Colors.yellow,
                                          //   height: 50,
                                          //   child: TextButton(
                                          //       onPressed: () {
                                          //         print(_selectedHour);
                                          //         print(_selectedMinute);

                                          //         Navigator.pop(context);
                                          //       },
                                          //       child: Text('확인')),
                                          // )
                                          // ],
                                          // ),
                                        ));
                                  });

                              // }

                              // child: Column(
                              //   children: [
                              //     SizedBox(
                              //       height: MediaQuery.of(context)
                              //                   .copyWith()
                              //                   .size
                              //                   .height /
                              //               3 -
                              //           80,
                              //       child: SizedBox.expand(
                              //           child:
                              //               //     CupertinoTimerPicker(

                              //               //   onTimerDurationChanged:
                              //               //       (changedTimer) {
                              //               //     // print(changedTimer);
                              //               //     setState(() {
                              //               //       initialTimer = changedTimer;
                              //               //     });
                              //               //     print(initialTimer);
                              //               //   },
                              //               //   mode:
                              //               //       CupertinoTimerPickerMode.hm,
                              //               //   minuteInterval: 30,
                              //               //   initialTimerDuration:
                              //               //       initialTimer,
                              //               // )
                              //               CupertinoPicker(
                              //         itemExtent: 33,
                              //         onSelectedItemChanged:
                              //             (value) {},
                              //         children: List.generate(34, (index) => Text('$index')),
                              //       )),
                              //     ),
                              //     CupertinoButton(
                              //         child: const Text("확인"),
                              //         onPressed: () {
                              //           Navigator.of(context).pop();
                              //           print(
                              //               initialTimer.toString());
                              //         }),
                              //   ],
                              // ));
                              // });
                              // showTimePicker(
                              //     context: context,
                              //     initialTime: TimeOfDay.now(),
                              //     // useRootNavigator: false
                              //     initialEntryMode:
                              //         TimePickerEntryMode.inputOnly);
                            },
                            child: Text(
                              "$_selectedHour시 $_selectedMinute분",
                              style: const TextStyle(fontSize: 30),
                            )),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('확인'),
                    )
                  ]);
            },
          );
        });
  }

  // Future<dynamic> alarmModal(BuildContext context) {
  //   Duration initialTimer = const Duration(hours: 0, minutes: 0);
  //   return showCupertinoModalPopup(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return Container(
  //             color: Colors.white,
  //             height: MediaQuery.of(context).copyWith().size.height / 3,
  //             child: Column(
  //               children: [
  //                 SizedBox(
  //                   height:
  //                       MediaQuery.of(context).copyWith().size.height / 3 - 80,
  //                   child: SizedBox.expand(
  //                       child: CupertinoTimerPicker(
  //                     onTimerDurationChanged: (changedTimer) {
  //                       print(changedTimer);
  //                       setState(() {
  //                         initialTimer = changedTimer;
  //                       });
  //                     },
  //                     mode: CupertinoTimerPickerMode.hm,
  //                     minuteInterval: 30,
  //                     initialTimerDuration: initialTimer,
  //                   )),
  //                 ),
  //                 CupertinoButton(
  //                     child: const Text("확인"),
  //                     onPressed: () {
  //                       Navigator.of(context).pop();
  //                       print(initialTimer.toString());
  //                     }),
  //                 Text(
  //                   initialTimer.toString(),
  //                   style: TextStyle(fontSize: 10),
  //                 )
  //               ],
  //             ));
  //       });
}
// }
