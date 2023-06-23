import 'package:eyepatch_app/model.dart/eyePatch.dart';
import 'package:eyepatch_app/model.dart/eyePatchList.dart';
import 'package:get/get.dart';
import 'package:localstorage/localstorage.dart';

class Controller extends GetxController {
  EyePatchList eyePatchList = EyePatchList();
  final LocalStorage storage = LocalStorage('patchList.json');

  // storage에 있는 리스트를 가져와서 상태 저장. 초기화 라고 보면 됨
  void updateList(EyePatchList newList) {
    print("update list");
    eyePatchList = newList;
    update();
  }

  // // 시간만 변경 가능?
  // void updateTime(String bleAddress, int time) {
  //   int index = 0;
  //   late EyePatch eyePatch;

  //   List<dynamic> storageEyePatchList = storage.getItem('eyePatchList');

  //   for (var item in storageEyePatchList) {
  //     print(item["time"]);
  //     item["time"] = time;
  //   }

  //   for (var element in eyePatchList.eyePatches) {
  //     if (element.bleAddress == bleAddress) {
  //       index = eyePatchList.eyePatches.indexOf(element);
  //       eyePatch = EyePatch(
  //           bleAddress: element.bleAddress,
  //           name: element.name,
  //           time: time,
  //           birth: element.birth,
  //           connected: element.connected,
  //           leftRatio: element.leftRatio);
  //     }
  //   }
  //   eyePatchList.eyePatches[index] = eyePatch;
  //   update();
  // }

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
              leftRatio: element.leftRatio);
        } else if (attribute == "connected") {
          eyePatch = EyePatch(
              ble: element.ble,
              name: element.name,
              time: element.time,
              birth: element.birth,
              connected: value,
              leftRatio: element.leftRatio);
        }
      }
    }

    eyePatchList.eyePatches[index] = eyePatch;
    update();
  }

  // void removeElement(String bleAddress) {
  //   storage.ready.then((_) async {

  //                       await storage.setItem(
  //                           'eyePatchList', eyePatchList.toJSONEncodable());
  //                     });
  // }
}
