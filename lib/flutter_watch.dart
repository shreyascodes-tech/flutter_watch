import 'dart:io';

import 'package:pubspec_parse/pubspec_parse.dart';

void assertExists(final FileSystemEntity entity) {
  if (!entity.existsSync()) {
    writeln(
        '${entity is Directory ? 'Directory' : 'File'} ${entity.path} does not exist.');
    exit(1);
  }
}

bool dependenciesChanged(final Pubspec oldPubspec, final Pubspec newPubspec) {
  final oldDependencies = oldPubspec.dependencies;
  final newDependencies = newPubspec.dependencies;

  final oldDevDependencies = oldPubspec.devDependencies;
  final newDevDependencies = newPubspec.devDependencies;

  if (oldDependencies.length != newDependencies.length) return true;
  for (final dependency in oldDependencies.keys) {
    if (!newDependencies.containsKey(dependency)) return true;
    final oldVersion = oldDependencies[dependency]!;
    final newVersion = newDependencies[dependency]!;
    if (oldVersion.toString() != newVersion.toString()) return true;
  }

  if (oldDevDependencies.length != newDevDependencies.length) return true;
  for (final dependency in oldDevDependencies.keys) {
    if (!newDevDependencies.containsKey(dependency)) return true;
    final oldVersion = oldDevDependencies[dependency]!;
    final newVersion = newDevDependencies[dependency]!;
    if (oldVersion.toString() != newVersion.toString()) return true;
  }

  return false;
}

Future<void> runPubGet(
  final bool isFlutterProject,
  final Directory dir,
) async {
  if (isFlutterProject) {
    final p = await Process.run(
      'flutter',
      const ['pub', 'get'],
      workingDirectory: dir.absolute.path,
      runInShell: true,
    );
    if (p.exitCode != 0) {
      print(p.stdout);
      print(p.stderr);
      exit(p.exitCode);
    }
  } else {
    final p = await Process.run(
      'pub',
      const ['get'],
      workingDirectory: dir.absolute.path,
      runInShell: true,
    );
    if (p.exitCode != 0) {
      print(p.stdout);
      print(p.stderr);
      exit(p.exitCode);
    }
  }
}

int lines = 0;
int _prevLineLength = 0;
int reprint(Object? object, [bool done = false]) {
  final start = DateTime.now();

  final sb = StringBuffer();

  if (_prevLineLength > 0) {
    sb.write('\r${' ' * _prevLineLength}\r');
  }
  final line = object.toString();
  _prevLineLength = line.length;
  sb.write(line);

  if (done) {
    sb.write('\n');
    _prevLineLength = 0;
  } else {
    lines++;
  }

  stdout.write(sb.toString());

  return DateTime.now().millisecondsSinceEpoch - start.millisecondsSinceEpoch;
}

void writeln(Object? object) {
  stdout.writeln(object);
  lines++;
}

String? readln(String prompt) {
  stdout.write(prompt);
  lines++;
  return stdin.readLineSync();
}

bool assetsChanged(final Pubspec oldPubspec, final Pubspec newPubspec) {
  final oldAssets = oldPubspec.flutter?["assets"].toString();
  final newAssets = newPubspec.flutter?["assets"].toString();

  return oldAssets != newAssets;
}

void clear() {
  if (lines > 0) {
    // move cursor up lines times
    stdout.write('\x1B[${lines}A');
    // clear everything below cursor
    stdout.write('\x1B[0J');

    lines = 0;
  }
}
