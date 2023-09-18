import 'package:tdffi/td.dart';

extension UserExt on User {
  String get fullName {
    return "$first_name $last_name".trim();
  }
}
