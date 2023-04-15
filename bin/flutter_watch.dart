import 'dart:convert';
import 'dart:io';
import 'package:flutter_watch/flutter_watch.dart';
import 'package:flutter_watch/runner.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:watcher/watcher.dart';

void main(List<String> arguments) async {
  final dir = arguments.isEmpty || arguments.first == "--"
      ? Directory.current
      : Directory(
          arguments.first,
        );

  final pubFile = File(join(dir.path, 'pubspec.yaml'));
  assertExists(pubFile);

  var pubFileContent = await pubFile.readAsString();
  var pubspec = Pubspec.parse(pubFileContent);

  final isFlutterProject =
      pubspec.flutter != null || pubspec.dependencies.containsKey('flutter');

  final watcher = DirectoryWatcher(dir.path);

  final args = arguments.skip(1).toList();
  Process? flutterProcess =
      isFlutterProject ? await createFlutterProcess(dir, args) : null;

  if (flutterProcess == null) {
    await runDartProcess(dir, args);
  }

  final int start = DateTime.now().millisecondsSinceEpoch;
  watcher.events.listen((event) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - start < 50) return;

    if (equals(pubFile.path, event.path)) {
      final updatedPubFileContent = await pubFile.readAsString();
      if (pubFileContent == updatedPubFileContent) return;
      pubFileContent = updatedPubFileContent;
      final updatedPubspec = Pubspec.parse(pubFileContent);

      if (dependenciesChanged(pubspec, updatedPubspec) ||
          assetsChanged(pubspec, updatedPubspec)) {
        final ms = reprint('Pubspec changed, running pub get...');
        runPubGet(isFlutterProject, dir);
        reprint("Pubspec changed, Got dependencies in ${ms}ms", true);
        if (flutterProcess != null) {
          flutterProcess.stdin.writeln('R');
        } else {
          await runDartProcess(dir, args);
        }
      }
      pubspec = updatedPubspec;
    } else if (event.path.contains(".dart-tool/") ||
        event.path.contains(".dart-tool\\") ||
        event.path.contains("build/") ||
        event.path.contains("build\\")) {
      return;
    } else {
      if (flutterProcess != null) {
        flutterProcess.stdin.writeln('r');
      } else {
        await runDartProcess(dir, args);
      }
    }
  });
  stdin.echoMode = false;
  stdin.lineMode = false;
  stdin.transform(utf8.decoder).listen((event) async {
    if (event == 'q') {
      if (flutterProcess != null) {
        flutterProcess.stdin.writeln('q');
        await Future.delayed(Duration(milliseconds: 50));
        flutterProcess.kill();
      } else {
        exit(0);
      }
    } else if (event == 'r') {
      if (flutterProcess != null) {
        flutterProcess.stdin.writeln('r');
        await runDartProcess(dir, args);
      }
    } else if (event == 'R') {
      if (flutterProcess != null) {
        flutterProcess.stdin.writeln('R');
        await runDartProcess(dir, args);
      }
    } else if (event == "h") {
      writeln("\n q: quit");
      if (flutterProcess != null) {
        writeln(" r: hot reload");
        writeln(" R: hot restart");
      } else {
        writeln(" r: re-run");
      }
      writeln(" c: clear console");
    } else if (event == "c") {
      clear();
    }
  });
}
