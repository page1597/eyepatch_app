import 'package:eyepatch_app/model.dart/eyePatch.dart';

class EyePatchList {
  List<EyePatch> eyePatches = [];

  toJSONEncodable() {
    return eyePatches.map((item) {
      return item.toJSONEncodable();
    }).toList();
  }
}
