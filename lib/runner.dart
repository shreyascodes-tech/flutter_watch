import 'dart:convert';
import 'dart:io';

import 'package:flutter_watch/flutter_watch.dart';

class Capabilities {
  final bool hotReload;
  final bool hotRestart;
  final bool screenshot;
  final bool fastStart;
  final bool flutterExit;
  final bool hardwareRendering;
  final bool startPaused;

  Capabilities({
    required this.hotReload,
    required this.hotRestart,
    required this.screenshot,
    required this.fastStart,
    required this.flutterExit,
    required this.hardwareRendering,
    required this.startPaused,
  });

  factory Capabilities.fromJson(Map<String, dynamic> json) {
    return Capabilities(
      hotReload: json['hotReload'],
      hotRestart: json['hotRestart'],
      screenshot: json['screenshot'],
      fastStart: json['fastStart'],
      flutterExit: json['flutterExit'],
      hardwareRendering: json['hardwareRendering'],
      startPaused: json['startPaused'],
    );
  }
}

class Device {
  final String name;
  final String id;
  final bool isSupported;
  final String targetPlatform;
  final bool emulator;
  final String sdk;
  final Capabilities capabilities;

  Device({
    required this.name,
    required this.id,
    required this.isSupported,
    required this.targetPlatform,
    required this.emulator,
    required this.sdk,
    required this.capabilities,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      name: json['name'],
      id: json['id'],
      isSupported: json['isSupported'],
      targetPlatform: json['targetPlatform'],
      emulator: json['emulator'],
      sdk: json['sdk'],
      capabilities: Capabilities.fromJson(
        json['capabilities'] as Map<String, dynamic>,
      ),
    );
  }
}

Future<Device> getDevices() async {
  final p = await Process.run(
    'flutter',
    const ['devices', '--machine'],
    runInShell: true,
  );
  final output = p.stdout.toString();
  final json = jsonDecode(output) as List;
  final devices = json.map((e) => Device.fromJson(e)).toList();
  if (devices.isEmpty) {
    writeln('No devices found.');
    exit(1);
  }
  var device = devices.first;

  if (devices.length > 1) {
    writeln('Multiple devices found:');
    for (var i = 0; i < devices.length; i++) {
      final device = devices[i];
      writeln('  $i: ${device.name} (${device.targetPlatform})');
    }
    final input = readln('Select a device: ');
    if (input == null) {
      writeln('Invalid input.');
      exit(1);
    }
    final index = int.tryParse(input);
    if (index == null || index < 0 || index >= devices.length) {
      writeln('Invalid input.');
      exit(1);
    }
    device = devices[index];
    clear();
  }
  return device;
}

Future<Process> createFlutterProcess(
  final Directory dir,
  final List<String> args,
) async {
  if (args.contains("-d")) {}

  final p = await Process.start(
    'flutter',
    [
      "run",
      if (!args.contains("-d")) "-d",
      (await getDevices()).id,
      ...args,
    ],
    workingDirectory: dir.absolute.path,
    runInShell: true,
    mode: ProcessStartMode.normal,
  );

  var log = true;
  var started = false;

  p.stderr.pipe(stderr);
  p.stdout.transform(utf8.decoder).listen((event) {
    if (event.startsWith("Flutter run key commands.")) {
      log = false;
    }
    if (event.startsWith("An Observatory debugger and profiler on")) {
      log = true;
      started = true;
    }

    if (log) {
      stdout.write(event);
      lines++;
    }
  });

  p.exitCode.then((value) {
    writeln('exited.');
    exit(value);
  });

  while (!started) {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  return p;
}

Future<void> runDartProcess(
  final Directory dir,
  final List<String> args, [
  final String? file,
]) async {
  writeln('\nRunning dart process...');
  final p = await Process.start(
    'dart',
    [
      "run",
      if (file != null) file,
      ...args,
    ],
    workingDirectory: dir.absolute.path,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );

  await p.exitCode;
}
