import 'package:eyepatch_app/model.dart/eyePatch.dart';
import 'package:eyepatch_app/model.dart/eyePatchList.dart';
import 'package:get/get.dart';
import 'package:localstorage/localstorage.dart';

class EyePatchController extends GetxController {
  EyePatchList eyePatchList = EyePatchList();
  final LocalStorage storage = LocalStorage('patchList.json');

  // List<List<int>> alarmTime = []; // 알람이 울릴 시간 배열

  // // 알람 추가하기
  // void addAlarm(int selectedHour, int selectedMinute) {
  //   alarmTime.add([selectedHour, selectedMinute]);
  //   update();
  // }

  // // 알람 지우기
  // void deleteAlarm(int index) {
  //   alarmTime.removeAt(index);
  //   update();
  // }

  // storage에 있는 리스트를 가져와서 상태 저장. 초기화 라고 보면 됨
  // 패치 목록 화면 켤 때 실행됨
  updateList(EyePatchList newList) {
    print("update list");
    eyePatchList = newList;
    update();
  }

  printPatchList() {
    print("??");
    // eyepatchlist를 프린트 하면 안되나? 될듯.
    storage.ready.then((_) {
      // print(storage.getItem('eyePatchList'));
      List<dynamic> eyePatchList = storage.getItem('eyePatchList');
      for (var item in eyePatchList) {
        print(item['ble']);
        print(item['name']);
        print(item['time']);
        print(item['birth']);
        print(item['connected']);
        print(item['leftRatio']);
        print(item['alarm']);
      }
    });
  }

  EyePatch getPatch(String pid) {
    // pid는 아이패치맥주소+사람이름 이렇게 해서 key라고 보면 됨. 지금은 적용 안된 상황이라 그냥 맥주소로 할게
    EyePatch eyePatch = EyePatch(
        ble: '',
        name: '',
        time: 0,
        birth: 0,
        connected: false,
        leftRatio: 0,
        alarm: []); // 초기화

    for (var item in eyePatchList.eyePatches) {
      if (item.ble == pid) {
        eyePatch = item;
      }
    }
    return eyePatch;
  }

  // 리스트 수정
  // bleAddress가 키가 된다.
  void updateElement(String ble, String attribute, var value) {
    int index = 0;
    late EyePatch eyePatch;
    storage.ready.then((_) {
      List<dynamic> storageEyePatchList = storage.getItem('eyePatchList');

      for (var item in storageEyePatchList) {
        if (item['ble'] == ble) {
          item[attribute] = value.toString();
        }
      }
    });

    for (var element in eyePatchList.eyePatches) {
      if (element.ble == ble) {
        index = eyePatchList.eyePatches.indexOf(element);
        if (attribute == "time") {
          eyePatch = EyePatch(
              ble: element.ble,
              name: element.name,
              time: value,
              birth: element.birth,
              connected: element.connected,
              leftRatio: element.leftRatio,
              alarm: element.alarm);
        } else if (attribute == "connected") {
          eyePatch = EyePatch(
              ble: element.ble,
              name: element.name,
              time: element.time,
              birth: element.birth,
              connected: value,
              leftRatio: element.leftRatio,
              alarm: element.alarm);
        } else if (attribute == "alarm") {
          // int hour = value[0];
          // int minute = value[1];
          eyePatch = EyePatch(
              ble: element.ble,
              name: element.name,
              time: element.time,
              birth: element.birth,
              connected: element.connected,
              leftRatio: element.leftRatio,
              alarm: value);
        }
      }
    }

    eyePatchList.eyePatches[index] = eyePatch;
    storage.ready.then(
        (_) => storage.setItem('eyePatchList', eyePatchList.toJSONEncodable()));
    update();
  }

  // void removeElement(String bleAddress) {
  //   storage.ready.then((_) async {

  //                       await storage.setItem(
  //                           'eyePatchList', eyePatchList.toJSONEncodable());
  //                     });
  // }
}
