import 'dart:collection';
// import { db } from 'config/firebase';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyepatch_app/database/dbHelper.dart';
import 'package:eyepatch_app/model/ble.dart';
import 'package:eyepatch_app/model/eyePatch.dart';
import 'package:eyepatch_app/controller/patchController.dart';
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
  final BluetoothDevice? device;
  // final EyePatch eyePatchInfo;
  final String ble;
  // final bool isConnected;
  const PatchDetail({
    super.key,
    this.device,
    required this.ble,
    // required this.eyePatchInfo,
  });

  @override
  State<PatchDetail> createState() => _PatchDetailState();
}

class Event {
  DateTime dateTime;
  bool patched;

  Event(this.dateTime, this.patched);
}

class _PatchDetailState extends State<PatchDetail> {
  final eyePatchController = Get.put(EyePatchController());
  // final alarmController = Get.put(AlarmController());

  late EyePatch _eyePatch;
  final BluetoothDevice _device = BluetoothDevice.fromId('');
  DBHelper dbHelper = DBHelper();
  TextEditingController timeField = TextEditingController();
  // final LocalStorage storage = LocalStorage('patchList.json');
  // late EyePatch eyePatch;
  // int index = 0;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  var _calendarFormat = CalendarFormat.month;

  bool openGraph = false;

  int _selectedAlarmHour = 0;
  int _selectedAlarmMinute = 0;
  final List<int> _minutes = [0, 30];
  // List<List<int>> _alarmTime = [];

  int _selectedRecordHour = 0; // 착용을 시작한 시간 (시)
  int _selectedRecordMinute = 0; // 착용을 시작한 시간 (분)

  int _selectedDurationHour = 0;
  int _selectedDurationMinute = 0;

  // durationField

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

  LinkedHashMap<DateTime?, List<Event>> events =
      LinkedHashMap(equals: isSameDay);

  // final data = [
  //   DateTimeRange(
  //     start: DateTime.fromMillisecondsSinceEpoch(1685340407522),
  //     end: DateTime(2023, 5, 29, 16, 11),
  //   )
  // ];
  List<DateTimeRange> data = [];
  Duration selectedDayPatchedTimeDuration = Duration.zero; // 착용한 시간.
  Duration todayPatchedTimeDuration = Duration.zero; // 오늘 지금까지 착용한 시간.

  List<Event> eventEntries = [];
  @override
  void initState() {
    super.initState();
    debugPrint('initstate: ${widget.ble}');

    // print(DateTime(2023, 5, 29, 17, 30, 00).millisecondsSinceEpoch);
    // for (var element in eyePatchController.eyePatchList.eyePatches) {
    //   if (element.ble == widget.ble) {
    //     index = eyePatchController.eyePatchList.eyePatches.indexOf(element);
    //   }
    // }
    _eyePatch = eyePatchController.getPatch(widget.ble);

    timeField =
        TextEditingController(text: _eyePatch.prescribedDuration.toString());

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));

    const source = Source.serverAndCache;
    DateTime recordedDay = DateTime.now();
    // print("지금 타임스탬프: ${recordedDay.millisecondsSinceEpoch}");
    _firestore
        .collection(widget.ble) // 해당 기기 이름+착용자 생년월일로 바꾸기
        .get(const GetOptions(source: source))
        .then((querySnapshot) {
      for (var docSnapshot in querySnapshot.docs) {
        // bool isSameDay = false;

        LinkedHashMap<DateTime?, List<Event>> temp =
            LinkedHashMap(equals: isSameDay);
        // 같은 날짜끼리 같은 eventEntries 리스트에 담는다.
        recordedDay =
            DateTime.fromMillisecondsSinceEpoch(int.parse(docSnapshot.id));

        if (events.isEmpty) {
          // 처음에만 여기로 들어감.
          events.addAll({
            DateTime.utc(recordedDay.year, recordedDay.month, recordedDay.day):
                [
              Event(recordedDay, docSnapshot["patched"] == 1 ? true : false)
            ] // 하나 만들면 루프 또 돌때 위쪽 if 문으로 들어가겠지..?
          });
        } else {
          bool isExistDay = false;
          events.forEach((key, value) {
            if (DateUtils.isSameDay(key, recordedDay)) {
              // 같은날
              isExistDay = true;
            }
          });

          if (isExistDay) {
            events[DateTime.utc(
                    recordedDay.year, recordedDay.month, recordedDay.day)]
                ?.add(Event(
                    recordedDay, docSnapshot["patched"] == 1 ? true : false));
          } else {
            temp.addAll({
              DateTime.utc(
                  recordedDay.year, recordedDay.month, recordedDay.day): [
                Event(recordedDay, docSnapshot["patched"] == 1 ? true : false)
              ]
            });
          }
          events.addEntries(temp.entries);
        }
      }

      events.forEach((key, value) {
        print("[$key]");
        value.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });

      events.forEach((key, value) {
        print("[$key]");
        for (var element in value) {
          print("${element.dateTime} - ${element.patched}");
        }
      });

      // eventEntries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      // print(eventEntries);
      // print(event)
      // events.addAll({
      //   DateTime.utc(recordedDay.year, recordedDay.month, recordedDay.day):
      //       eventEntries
      // });

      // events.forEach((key, value) {
      //   print("$key : ${value}");
      // });
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // insertSql() async {
  //   // insertSql(ScanResult info, DBHelper dbHelper)
  //   print('insert sql');
  //   dbHelper.insertRecord(, Ble(
  //     // id: await dbHelper.getLastId(_device.name) + 1,
  //     ble: _device.id.id, // 기기 맥주소 + 착용자 이름으로 바꾸기
  //     patched: 1, // 모델 적용해서 착용여부 계산해서 넣기.
  //     timeStamp: DateTime.now().millisecondsSinceEpoch, // 현재 시간.
  //     rawData: 'test', // rawData
  //     // dateTime: DateFormat('kk:mm:ss').format(DateTime.now()),
  //   ));
  // }

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
    // advertising mode로 해야되니까 여기서 필터링해서 착용하고 있는지 아닌지 계속 확인해서 저장하기. (insertSql() 통해서)
    // 여기에서 n초 주기로 계속 받아오기

    // Controller controller = Get.put(Controller());
    // controller.eyePatchList.eyePatches[0].bleAddress,
    return GetBuilder<EyePatchController>(builder: (eyePatchController) {
      // var eyePatch = widget.device.id
      // EyePatch eyePatch = controller.eyePatchList.eyePatches
      // .where((element) => element.bleAddress == widget.device!.id.toString()) as EyePatch; // 맞나..?
      return Scaffold(
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
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          color: Palette.grey,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Stack(children: [
                            // Positioned(
                            //   right: 0,
                            //   top: 0,
                            //   child: Container(
                            //     width: 20,
                            //     height: 20,
                            //     decoration: BoxDecoration(
                            //       borderRadius: BorderRadius.circular(50),
                            //       color: widget.isConnected
                            //           // color: widget.device.state.
                            //           ? Palette.primary1
                            //           : Palette.red,
                            //     ),
                            //   ),
                            // ),
                            Column(
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
                                        _eyePatch.ble,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Text(
                                      '환자번호',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _eyePatch.pid,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                GetBuilder<EyePatchController>(
                                    builder: (controller) {
                                  return Row(
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
                                        '${controller.getPatch(widget.ble).prescribedDuration.toString()}시간',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      TextButton(
                                          style: TextButton.styleFrom(
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              padding: EdgeInsets.zero),
                                          onPressed: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                      title:
                                                          const Text('시간 변경'),
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
                                                                child:
                                                                    TextButton(
                                                              onPressed: () {
                                                                if (timeField
                                                                        .text ==
                                                                    "0") {
                                                                  return;
                                                                }
                                                                timeField.text =
                                                                    (int.parse(timeField.text) -
                                                                            1)
                                                                        .toString();
                                                              },
                                                              child: const Text(
                                                                "-",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        10),
                                                              ),
                                                            )),
                                                          ),
                                                          SizedBox(
                                                            width: 40,
                                                            height: 34,
                                                            child:
                                                                TextFormField(
                                                              textAlign:
                                                                  TextAlign
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
                                                              child: TextButton(
                                                                onPressed: () {
                                                                  timeField
                                                                          .text =
                                                                      (int.parse(timeField.text) +
                                                                              1)
                                                                          .toString();
                                                                },
                                                                child:
                                                                    const Text(
                                                                  "+",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          10),
                                                                ),
                                                              )),
                                                          const SizedBox(
                                                              width: 10),
                                                          const Text('시간'),
                                                        ],
                                                      ),
                                                      actions: [
                                                        SizedBox(
                                                            child: TextButton(
                                                          child:
                                                              const Text("확인"),
                                                          onPressed: () {
                                                            setState(() {
                                                              eyePatchController
                                                                  .updateElement(
                                                                      _eyePatch
                                                                          .ble,
                                                                      "prescribedDuration",
                                                                      int.parse(
                                                                          timeField
                                                                              .text));
                                                            });

                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        )
                                                            // });
                                                            )
                                                      ]);
                                                });
                                          },
                                          child: const Icon(
                                            Icons.edit,
                                            color: Color.fromARGB(
                                                255, 155, 155, 155),
                                            size: 20,
                                          )),
                                      // const Text(
                                      //   '지금 ~시간 착용중', //시간 단위로?
                                      //   style: TextStyle(
                                      //       color: Colors.black,
                                      //       fontSize: 16,
                                      //       fontWeight: FontWeight.bold),
                                      // ),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Text(
                                      '착용비율 (좌:우)',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${_eyePatch.leftRatio.toInt()}:${(100 - _eyePatch.leftRatio).toInt()}",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Text(
                                      '전화번호',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _eyePatch.phone,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                // const SizedBox(height: 10),
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
                      // ㄴ 왜 한번 더 가져와야 되지..?

                      events.forEach((day, value) {
                        // print("[$day]");
                        // value.forEach((element) {
                        //   print("${element.dateTime} - ${element.patched}");
                        // });
                        if (DateUtils.isSameDay(day, _selectedDay)) {
                          bool conti = false; //continue
                          DateTime initial = DateTime.now();
                          DateTime start = initial;
                          DateTime end = initial;

                          data = [];
                          data.clear();
                          selectedDayPatchedTimeDuration = Duration.zero;
                          setState(() {});

                          for (Event i in value) {
                            if (i.patched) {
                              // 패치 착용을 했다고 되어 있으면
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
                        }
                        // value.forEach((element) {
                        //   print("${element.dateTime} - ${element.patched}");
                        // });
                      });
                      for (var element in data) {
                        selectedDayPatchedTimeDuration += element.duration;
                      }

                      // const source = Source.server;
                      // _firestore
                      //     .collection(widget.ble)
                      //     .get(const GetOptions(source: source))
                      //     .then((querySnapshot) {
                      //   for (var docSnapshot in querySnapshot.docs) {
                      //     // print(_selectedDay.millisecondsSinceEpoch.toString());
                      //     // 같은 날 필터링
                      //     DateTime dataDate = DateTime.fromMillisecondsSinceEpoch(
                      //                     int.parse(docSnapshot.id));
                      //     if (DateUtils.isSameDay(selectedDay, dataDate)) {
                      //       // 같은 날이면
                      //       // print("O");
                      //       events.forEach((key, value) {
                      //         // 왜 세번 돌아가는 거지
                      //         // print('key: $key');
                      //         bool conti = false; //continue
                      //         DateTime initial = DateTime.now();
                      //         DateTime start = initial;
                      //         DateTime end = initial;
                      //         data = [];
                      //         data.clear();
                      //         setState(() {});
                      //         for (Event i in value) {
                      //           if (i.patched) {
                      //             // 패치 착용 하고
                      //             if (conti) {
                      //               conti = false;
                      //             } else {
                      //               start = i.dateTime;
                      //               conti = true;
                      //             }
                      //           } else {
                      //             // 패치 착용 안하고 있으면
                      //             end = i.dateTime;
                      //             conti = false;
                      //           }

                      //           if ((start != initial && end != initial) &&
                      //               start.isBefore(end)) {
                      //             // print('start: $start : end: $end');
                      //             data.add(DateTimeRange(
                      //                 start: start,
                      //                 end: end)); // 착용 전까지 잘라야됨..계속 이어붙여야함..
                      //           }
                      //         }

                      //         for (var element in data) {
                      //           print(element);
                      //         }
                      //         // final data = [
                      //         //   DateTimeRange(
                      //         //     start: DateTime.fromMillisecondsSinceEpoch(
                      //         //         1685340407522),
                      //         //     end: DateTime(2023, 5, 29, 16, 11),
                      //         //   )
                      //         // ];
                      //       });
                      //     } // 같은 날이 아닐 경우
                      //     // print("X");
                      //     // debugPrint(
                      //     //     '${docSnapshot.id} => ${docSnapshot.data()}');
                      //   }
                      // });

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
                // Text(
                //     "${selectedDayPatchedTimeDuration.inHours.toString()}시간 ${(selectedDayPatchedTimeDuration.inMinutes - selectedDayPatchedTimeDuration.inHours * 60).toString()}분 착용함"),
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
                //       if (widget.device != null) {
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
                TextButton(
                    onPressed: () {
                      // dbHelper.dropTable(
                      //     widget.ble.replaceAll(RegExp("[^a-zA-Z]"), ''));
                      // print(widget.ble);
                      // print(widget.ble.replaceAll(RegExp("[^a-zA-Z]"), ''));
                      dbHelper.getAllBle(
                          widget.ble.replaceAll(RegExp("[^a-zA-Z]"), ''));
                      // eyePatchController.printPatchList();
                    },
                    child: Text('eyepatchlist에 잇는것들 보기')),
                TextButton(
                    onPressed: () {
                      showAlarmDialog(context);
                    },
                    child: Text('알림 설정')),
                TextButton(
                    onPressed: () {
                      writeRecord(context);
                    },
                    child: Text('수기 작성')),

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
                // TextButton(
                //     onPressed: () {
                //       const source = Source.cache;

                //       _firestore
                //           .collection("qq:bb:cc:dd:20181010")
                //           .get(const GetOptions(source: source))
                //           .then((querySnapshot) {
                //         for (var docSnapshot in querySnapshot.docs) {
                //           print(_selectedDay.millisecondsSinceEpoch.toString());
                //           if (DateTime.fromMillisecondsSinceEpoch(
                //                           int.parse(docSnapshot.id))
                //                       .year ==
                //                   _selectedDay.year &&
                //               DateTime.fromMillisecondsSinceEpoch(
                //                           int.parse(docSnapshot.id))
                //                       .month ==
                //                   _selectedDay.month &&
                //               DateTime.fromMillisecondsSinceEpoch(
                //                           int.parse(docSnapshot.id))
                //                       .day ==
                //                   _selectedDay.day) {
                //             // 같은 날이면
                //             print("O");
                //             print(
                //                 '${DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day)} : ${[
                //               Event(
                //                   DateTime.fromMillisecondsSinceEpoch(
                //                       int.parse(docSnapshot.id)),
                //                   docSnapshot["patched"] == 1 ? true : false)
                //             ]}');

                //             events.addAll({
                //               DateTime.utc(_selectedDay.year,
                //                   _selectedDay.month, _selectedDay.day): [
                //                 Event(
                //                     DateTime.fromMillisecondsSinceEpoch(
                //                         int.parse(docSnapshot.id)),
                //                     docSnapshot["patched"] == 1 ? true : false)
                //               ]
                //             });
                //           } // 같은 날이 아닐 경우
                //           print("X");
                //           debugPrint(
                //               '${docSnapshot.id} => ${docSnapshot.data()}');
                //         }
                //       });
                //       // if (_selectedDay == )
                //       // debugPrint('${_selectedDay.month}월 ${_selectedDay.day}일');
                //     },
                //     child: const Text('get 파이어베이스')),
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

  Future<dynamic> writeRecord(BuildContext context) {
    TextEditingController startTimeField = TextEditingController();
    TextEditingController durationField = TextEditingController();

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return GetBuilder<EyePatchController>(builder: (controller) {
            EyePatch eyePatch = controller.getPatch(widget.ble);
            return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                title: const Text('기록 수기 작성'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text(
                    '착용을 시작한 시간을 입력해주세요.', // 캘린더도 넣어야할 것 같은 불길한 느낌..  -> 맞아. ^__^
                    style: TextStyle(
                        color: Palette.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                      onPressed: () {
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: Column(
                                      children: [
                                        Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: CupertinoPicker(
                                                  squeeze: 1,
                                                  scrollController:
                                                      FixedExtentScrollController(
                                                          initialItem:
                                                              _selectedRecordHour),
                                                  itemExtent: 55.0,
                                                  backgroundColor: Colors.white,
                                                  onSelectedItemChanged:
                                                      (value) {
                                                    setState(() {
                                                      _selectedRecordHour =
                                                          value;
                                                    });
                                                    print(_selectedRecordHour);
                                                  },
                                                  children: List.generate(
                                                    24,
                                                    (index) => Center(
                                                      child: Text(
                                                        '$index',
                                                        style: const TextStyle(
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
                                                  looping: true,
                                                  squeeze: 1,
                                                  scrollController:
                                                      FixedExtentScrollController(
                                                          initialItem:
                                                              _selectedRecordMinute),
                                                  itemExtent: 55,
                                                  backgroundColor: Colors.white,
                                                  onSelectedItemChanged:
                                                      (index) {
                                                    setState(() {
                                                      _selectedRecordMinute =
                                                          index;
                                                    });
                                                    print(
                                                        _selectedRecordMinute);
                                                  },
                                                  // 텍스트로도 입력할 수 있게하기
                                                  children: List.generate(
                                                      60,
                                                      (index) => Center(
                                                            child: Text(
                                                              '${index}',
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
                                      ],
                                    ),
                                  ));
                            });
                      },
                      child: Text(
                        "$_selectedRecordHour시 $_selectedRecordMinute분",
                        style: const TextStyle(fontSize: 30),
                      )),
                  const SizedBox(height: 20),

                  const Text(
                    '착용한 시간(분단위)을 입력해주세요.',
                    style: TextStyle(
                        color: Palette.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  // TextFormField(
                  //   keyboardType: TextInputType.number,
                  //   controller: durationField,
                  // ),
                  TextButton(
                      onPressed: () {
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: Column(
                                      children: [
                                        Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: CupertinoPicker(
                                                  squeeze: 1,
                                                  scrollController:
                                                      FixedExtentScrollController(
                                                          initialItem:
                                                              _selectedDurationHour),
                                                  itemExtent: 55.0,
                                                  backgroundColor: Colors.white,
                                                  onSelectedItemChanged:
                                                      (value) {
                                                    setState(() {
                                                      _selectedDurationHour =
                                                          value;
                                                    });
                                                    print(
                                                        _selectedDurationHour);
                                                  },
                                                  children: List.generate(
                                                    24,
                                                    (index) => Center(
                                                      child: Text(
                                                        '$index',
                                                        style: const TextStyle(
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
                                                  looping: true,
                                                  squeeze: 1,
                                                  scrollController:
                                                      FixedExtentScrollController(
                                                          initialItem:
                                                              _selectedDurationMinute),
                                                  itemExtent: 55,
                                                  backgroundColor: Colors.white,
                                                  onSelectedItemChanged:
                                                      (index) {
                                                    setState(() {
                                                      _selectedDurationMinute =
                                                          index;
                                                    });
                                                    print(
                                                        _selectedDurationMinute);
                                                  },
                                                  // 텍스트로도 입력할 수 있게하기
                                                  children: List.generate(
                                                      60,
                                                      (index) => Center(
                                                            child: Text(
                                                              '$index',
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
                                      ],
                                    ),
                                  ));
                            });
                      },
                      child: Text(
                        "$_selectedDurationHour시간 $_selectedDurationMinute분",
                        style: const TextStyle(fontSize: 30),
                      )),
                ]),
                actions: [
                  TextButton(
                      // 근데 그 시간이 중복된 시간이라면 덮어씌우는 것도 생각해야 함.
                      onPressed: () async {
                        // 착용을 시작한 시간
                        // var duration = durationField.text;
                        int duration = _selectedDurationMinute +
                            (_selectedDurationHour * 60);
                        // var duration = 1;
                        DateTime startTime = DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            _selectedRecordHour,
                            _selectedRecordMinute);

                        // dbHelper.getPartialRecord(startTime, 1);

                        dbHelper.insertPartialRecord(
                            widget.ble,
                            widget.ble.replaceAll(RegExp("[^a-zA-Z]"), ''),
                            startTime,
                            duration);
                        // 키가 중복인 경우 이렇게 하면 저장이 안되려나? key를 timestamp값으로 지금 변경 해 놓음.

                        // dbHelper.dropTable();
                        Navigator.pop(context);
                      },
                      child: const Text('확인'))
                ],
              );
            });
          });
        });
  }

  Future<dynamic> showAlarmDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return GetBuilder<EyePatchController>(builder: (controller) {
            EyePatch eyePatch = controller.getPatch(widget.ble);
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
                          const SizedBox(height: 20),
                          Expanded(
                              child: ListView.builder(
                                  itemCount: eyePatch.alarm == null
                                      ? 0
                                      : eyePatch.alarm!.length,
                                  shrinkWrap: true,
                                  itemBuilder: ((context, index) {
                                    if (eyePatch.alarm?[index] != null) {
                                      return Text(
                                          '${(eyePatch.alarm![index] / 60).floor()}시 ${(eyePatch.alarm![index] % 60)}분',
                                          style: const TextStyle(
                                              color: Palette.primary1,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18));
                                    }
                                  }))),
                          Row(
                            children: [
                              TextButton(
                                  onPressed: () {
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
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(0),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                CupertinoPicker(
                                                              squeeze: 1,
                                                              scrollController:
                                                                  FixedExtentScrollController(
                                                                      initialItem:
                                                                          _selectedAlarmHour),
                                                              itemExtent: 55.0,
                                                              backgroundColor:
                                                                  Colors.white,
                                                              onSelectedItemChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  _selectedAlarmHour =
                                                                      value;
                                                                });
                                                                print(
                                                                    _selectedAlarmHour);
                                                              },
                                                              children:
                                                                  List.generate(
                                                                24,
                                                                (index) =>
                                                                    Center(
                                                                  child: Text(
                                                                    '$index',
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            24),
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
                                                                  color: Palette
                                                                      .black),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 24,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                CupertinoPicker(
                                                              squeeze: 1,
                                                              scrollController:
                                                                  FixedExtentScrollController(
                                                                      initialItem:
                                                                          _selectedAlarmMinute),
                                                              itemExtent: 55,
                                                              backgroundColor:
                                                                  Colors.white,
                                                              onSelectedItemChanged:
                                                                  (index) {
                                                                setState(() {
                                                                  _selectedAlarmMinute =
                                                                      _minutes[
                                                                          index];
                                                                });
                                                                print(
                                                                    _selectedAlarmMinute);
                                                              },
                                                              children:
                                                                  List.generate(
                                                                      _minutes
                                                                          .length,
                                                                      (index) =>
                                                                          Center(
                                                                            child:
                                                                                Text(
                                                                              '${_minutes[index]}',
                                                                              style: const TextStyle(fontSize: 24),
                                                                            ),
                                                                          )),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            child: Text(
                                                              '분',
                                                              style: TextStyle(
                                                                  fontSize: 24,
                                                                  color: Palette
                                                                      .black),
                                                            ),
                                                          ),
                                                        ]),
                                                  ],
                                                ),
                                              ));
                                        });
                                  },
                                  child: Text(
                                    "$_selectedAlarmHour시 $_selectedAlarmMinute분",
                                    style: const TextStyle(fontSize: 30),
                                  )),
                              Container(
                                color: Colors.black12,
                                height: 50,
                                child: TextButton(
                                    onPressed: () {
                                      // DateTime
                                      DateTime now = DateTime.now();
                                      // Timestamp alarmTime = Timestamp.fromDate(
                                      //     DateTime(
                                      //         now.year,
                                      //         now.month,
                                      //         now.day,
                                      //         _selectedAlarmHour,
                                      //         _selectedAlarmMinute,
                                      //         0,
                                      //         0,
                                      //         0));
                                      int alarmTime =
                                          (_selectedAlarmHour * 60) +
                                              _selectedAlarmMinute;
                                      print(alarmTime);
                                      List<dynamic> eyePatchAlarmList =
                                          eyePatch.alarm ?? [];
                                      controller.updateElement(
                                          widget.ble,
                                          "alarm",
                                          [...eyePatchAlarmList, alarmTime]);

                                      setState(() {});
                                    },
                                    child: const Text('추가')),
                              )
                            ],
                          ),
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
        });
  }

  // Future<dynamic> alarmModal(BuildContext context) {
  //   Duration initialTimer = const Duration(hours: 0, _minutes: 0);
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
