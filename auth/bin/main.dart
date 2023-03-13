import 'dart:io';
import 'package:conduit/conduit.dart';
import 'package:auth/auth.dart';

void main(List<String> arguments) async {
  final int port = int.parse(Platform.environment["PORT"] ?? "8081");
  final service = Application<AppService>()..options.port = port;
  await service.start(numberOfInstances: 3, consoleLogging: true);
}