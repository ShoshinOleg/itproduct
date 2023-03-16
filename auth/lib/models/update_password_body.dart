import 'package:conduit_core/conduit_core.dart';

class UpdatePasswordBody extends Serializable {
  String oldPassword = "";
  String newPassword = "";

  @override
  Map<String, dynamic> asMap() {
    return {
      "oldPassword": oldPassword,
      "newPassword": newPassword
    };
  }
  
  @override
  void readFromMap(Map<String, dynamic> map) {
    oldPassword = map["oldPassword"];
    newPassword = map["newPassword"];
  }
}