import 'package:dotenv/dotenv.dart' as dotenv;

class Environment {
  static final Environment _instance = Environment._internal();
  late dotenv.DotEnv _env;

  factory Environment() => _instance;

  Environment._internal() {
    _env = dotenv.DotEnv(includePlatformEnvironment: true)
      ..load(['app-server-dev.env']);
  }

  void load(String fileName) {
    _env.load([fileName]);
  }

  String? get(String key) => _env[key];
}
