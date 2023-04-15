# Flutter watch
a program that watches a directory for changes and restarts the flutter app

## Installation
- clone the repo
- compile the program and put it in your path ;)
```
dart compile exe bin/flutter_watch.dart
```

## Usage
```bash
flutter_watch <path to flutter project> ...options
# Or
flutter_watch -- ...options
```

To skip the device selection, use the `-d` option
```bash
flutter_watch <path to flutter project> -d <device id> ...options
# Or
flutter_watch -- -d <device id> ...options
```

once the app is running, you can also type in 
- `h` for help
- `c` to clear the console
- `r` for manual hot reload
- `R` for manual hot restart
- `q` to quit the program