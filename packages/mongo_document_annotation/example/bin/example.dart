import 'package:example/env/dump.dart';

Future<void> main() async {
  var env = Environment();
  // ignore: unused_local_variable
  String mongoUri = env.get('MONGO_URI') ?? "";
}

