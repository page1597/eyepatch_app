import 'package:eyepatch_app/model/eyePatch.dart';

class EyePatchList {
  List<EyePatch> eyePatches = [];

  toJSONEncodable() {
    return eyePatches.map((item) {
      return item.toJSONEncodable();
    }).toList();
  }
}
