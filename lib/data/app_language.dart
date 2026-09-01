import 'package:flutter/foundation.dart';
import 'notifiers.dart';

class AppLanguage {
  static bool get isHindi => isHindiNotifier.value;

  static String text(String hindi, String english) {
    return isHindi ? hindi : english;
  }
}
