import 'package:data/data.dart';
import 'package:data/utils/app_env.dart';
import 'package:conduit_core/conduit_core.dart';

void main(List<String> arguments) async {
  final int port = int.tryParse(AppEnv.port) ?? 6200;
  final service = Application<AppService>()..options.port = port;
  await service.start(numberOfInstances: 3, consoleLogging: true);
}