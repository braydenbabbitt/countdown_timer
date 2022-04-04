import 'dart:async';

import 'package:countdown_timer/timer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ScreenType {
  mobile, tablet, desktop
}

ScreenType getScreenType(Size size) {
  if (size.width > 768) {
    return ScreenType.desktop;
  } else if (size.width > 480) {
    return ScreenType.tablet;
  } else {
    return ScreenType.mobile;
  }
}

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(const CountdownTimerApp());
}

class CountdownTimerApp extends StatelessWidget {
  const CountdownTimerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const CountdownTimerHomePage(title: 'Timer Page'),
    );
  }
}

class CountdownTimerHomePage extends StatefulWidget {
  const CountdownTimerHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<CountdownTimerHomePage> createState() => _CountdownTimerHomePageState();
}

class _CountdownTimerHomePageState extends State<CountdownTimerHomePage> with SingleTickerProviderStateMixin {
  static const selectedDurationLabel = 'selectedDuration';
  static const showMillisecondsLabel = 'showMilliseconds';
  static const maxDuration = Duration(hours: 999, minutes: 59, seconds: 59);
  static const spacer = SizedBox(height: 12);
  late final Future<SharedPreferences> _data;
  late final Ticker _ticker;
  late Duration _selectedDuration;
  // Test for accuracy of Ticker
  // DateTime? startTime;
  Duration _elapsedTime = Duration.zero;
  Duration _previousElapsedTime = Duration.zero;
  late bool _showMilliseconds;
  late TextEditingController _hoursController;
  late TextEditingController _minsController;
  late TextEditingController _secsController;

  Future<void> initData() async {
    _showMilliseconds = await _data.then((value) => value.getBool(showMillisecondsLabel) ?? false);
    String durationString = await _data.then((value) => value.getString(selectedDurationLabel) ?? (Duration.millisecondsPerMinute * 5).toString());
    _selectedDuration = Duration(milliseconds: int.parse(durationString));
    _hoursController = TextEditingController(text: _selectedDuration.inHours.toString());
    _minsController = TextEditingController(text: (_selectedDuration.inMinutes - (_selectedDuration.inHours * Duration.minutesPerHour)).toString());
    _secsController = TextEditingController(text: (_selectedDuration.inSeconds - (_selectedDuration.inMinutes * Duration.secondsPerMinute)).toString());
  }

  @override
  void initState() {
    super.initState();
    _data = SharedPreferences.getInstance();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsedTime = elapsed;
        if (_previousElapsedTime + _elapsedTime >= _selectedDuration) {
          stopTimer();
        }
      });
    });
    initData();
  }

  void startTimer() {
    setState(() {
      _ticker.start();
      // Test for accuracy of Ticker
      // startTime = DateTime.now();
    });
  }

  void stopTimer() {
    setState(() {
      _ticker.stop();
      // Test for accuracy of Ticker
      // print("Difference:  " + (DateTime.now().difference(startTime!).inMilliseconds - (_previousElapsedTime + _elapsedTime).inMilliseconds).toString());
      _previousElapsedTime += _elapsedTime;
      _elapsedTime = Duration.zero;
    });
  }

  void resetTimer() {
    setState(() {
      if (_ticker.isActive) stopTimer();
      _elapsedTime = Duration.zero;
      _previousElapsedTime = Duration.zero;
    });
  }

  void restartTimer() {
    setState(() {
      resetTimer();
      startTimer();
    });
  }

  void saveTime({required String label, required Duration toSave}) {
    _data.then((value) => value.setString(label, toSave.inMilliseconds.toString()));
  }

  void updateTextFields() {
    _hoursController.value = TextEditingValue(text: _selectedDuration.inHours.toString());
    _minsController.value = TextEditingValue(text: (_selectedDuration.inMinutes - (_selectedDuration.inHours * Duration.minutesPerHour)).toString());
    _secsController.value = TextEditingValue(text: (_selectedDuration.inSeconds - (_selectedDuration.inMinutes * Duration.secondsPerMinute)).toString());
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> controls;
    if (_ticker.isActive) {
      controls = [
        buildPauseButton(onPressed: stopTimer),
        spacer,
        buildStopButton(onPressed: resetTimer),
      ];
    } else if (_elapsedTime + _previousElapsedTime == Duration.zero) {
      controls = [
        buildPlayButton(onPressed: startTimer),
      ];
    } else if (_elapsedTime + _previousElapsedTime >= _selectedDuration) {
      controls = [
        buildRestartButton(onPressed: restartTimer),
        spacer,
        buildStopButton(onPressed: resetTimer),
      ];
    } else {
      controls = [
        buildPlayButton(onPressed: startTimer),
        spacer,
        buildStopButton(onPressed: resetTimer),
      ];
    }

    return Scaffold(
      body: FutureBuilder(
        future: _data.then((value) => value),
        builder: (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
          if (snapshot.hasData) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                switch (getScreenType(constraints.biggest)) {
                  case ScreenType.desktop:
                    return Scaffold(
                      body: Row(
                          children: [
                            Padding(
                                padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                                child: SizedBox(
                                  width: 100,
                                  child: Column(
                                    children: [
                                      Column(
                                        children: controls,
                                      ),
                                      Expanded(
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 5), child: Text('Hours')),
                                              RawKeyboardListener(
                                                onKey: (RawKeyEvent event) {
                                                  if (event.runtimeType == RawKeyDownEvent) {
                                                    bool isChanged = false;
                                                    setState(() {
                                                      if (event.logicalKey == LogicalKeyboardKey.arrowUp && _selectedDuration.inHours < maxDuration.inHours) {
                                                        _selectedDuration += const Duration(hours: 1);
                                                        isChanged = true;
                                                      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && _selectedDuration.inHours > 0) {
                                                        _selectedDuration -= const Duration(hours: 1);
                                                        isChanged = true;
                                                      }
                                                      if (isChanged) {
                                                        resetTimer();
                                                        saveTime(label: selectedDurationLabel, toSave: _selectedDuration);
                                                        updateTextFields();
                                                      }
                                                    });
                                                  }
                                                },
                                                focusNode: FocusNode(),
                                                child: TextFormField(
                                                  controller: _hoursController,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                    LengthLimitingTextInputFormatter(3),
                                                  ],
                                                  onTap: () {
                                                    _hoursController.selection = TextSelection(baseOffset: 0, extentOffset: _hoursController.text.length);
                                                  },
                                                  onChanged: (newVal) {
                                                    setState(() {
                                                      if (newVal.isEmpty) {
                                                        _selectedDuration -= Duration(hours: _selectedDuration.inHours);
                                                        _hoursController.value = const TextEditingValue(text: '0');
                                                        _hoursController.selection = TextSelection(baseOffset: 0, extentOffset: _hoursController.text.length);
                                                      } else {
                                                        _selectedDuration = Duration(hours: int.parse(newVal), minutes: int.parse(_minsController.text), seconds: int.parse(_secsController.text));
                                                      }
                                                      resetTimer();
                                                      saveTime(label: selectedDurationLabel, toSave: _selectedDuration);
                                                    });
                                                  },
                                                ),
                                              ),
                                              spacer,
                                              const Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 5), child: Text('Minutes')),
                                              RawKeyboardListener(
                                                onKey: (RawKeyEvent event) {
                                                  if (event.runtimeType == RawKeyDownEvent) {
                                                    bool isChanged = false;
                                                    setState(() {
                                                      if (event.logicalKey == LogicalKeyboardKey.arrowUp && _selectedDuration.inMinutes < maxDuration.inMinutes) {
                                                        _selectedDuration += const Duration(minutes: 1);
                                                        isChanged = true;
                                                      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && _selectedDuration.inMinutes > 0) {
                                                        _selectedDuration -= const Duration(minutes: 1);
                                                        isChanged = true;
                                                      }
                                                      if (isChanged) {
                                                        resetTimer();
                                                        saveTime(label: selectedDurationLabel, toSave: _selectedDuration);
                                                        updateTextFields();
                                                      }
                                                    });
                                                  }
                                                },
                                                focusNode: FocusNode(),
                                                child: TextFormField(
                                                  controller: _minsController,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                    // LengthLimitingTextInputFormatter(2),
                                                  ],
                                                  onTap: () {
                                                    _minsController.selection = TextSelection(baseOffset: 0, extentOffset: _minsController.text.length);
                                                  },
                                                  onChanged: (newVal) {
                                                    setState(() {
                                                      if (newVal.isEmpty) {
                                                        _selectedDuration -= Duration(minutes: _selectedDuration.inMinutes - (_selectedDuration.inHours * Duration.minutesPerHour));
                                                        _minsController.value = const TextEditingValue(text: '0');
                                                        _minsController.selection = TextSelection(baseOffset: 0, extentOffset: _minsController.text.length);
                                                      } else {
                                                        _selectedDuration = Duration(hours: int.parse(_hoursController.text), minutes: int.parse(newVal), seconds: int.parse(_secsController.text));
                                                      }
                                                      resetTimer();
                                                      saveTime(label: selectedDurationLabel, toSave: _selectedDuration);
                                                    });
                                                  },
                                                ),
                                              ),
                                              spacer,
                                              const Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 5), child: Text('Seconds')),
                                              RawKeyboardListener(
                                                onKey: (RawKeyEvent event) {
                                                  if (event.runtimeType == RawKeyDownEvent) {
                                                    bool isChanged = false;
                                                    setState(() {
                                                      if (event.logicalKey == LogicalKeyboardKey.arrowUp && _selectedDuration.inSeconds < maxDuration.inSeconds) {
                                                        _selectedDuration += const Duration(seconds: 1);
                                                        isChanged = true;
                                                      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && _selectedDuration.inSeconds > 0) {
                                                        _selectedDuration -= const Duration(seconds: 1);
                                                        isChanged = true;
                                                      }
                                                      if (isChanged) {
                                                        resetTimer();
                                                        saveTime(label: selectedDurationLabel, toSave: _selectedDuration);
                                                        updateTextFields();
                                                      }
                                                    });
                                                  }
                                                },
                                                focusNode: FocusNode(),
                                                child: TextFormField(
                                                  controller: _secsController,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                    // LengthLimitingTextInputFormatter(2),
                                                  ],
                                                  onTap: () {
                                                    _secsController.selection = TextSelection(baseOffset: 0, extentOffset: _secsController.text.length);
                                                  },
                                                  onChanged: (newVal) {
                                                    setState(() {
                                                      if (newVal.isEmpty) {
                                                        _selectedDuration -= Duration(seconds: _selectedDuration.inSeconds - (_selectedDuration.inMinutes * Duration.secondsPerMinute));
                                                        _secsController.value = const TextEditingValue(text: '0');
                                                        _secsController.selection = TextSelection(baseOffset: 0, extentOffset: _secsController.text.length);
                                                      } else {
                                                        _selectedDuration = Duration(hours: int.parse(_hoursController.text), minutes: int.parse(_minsController.text), seconds: int.parse(newVal));
                                                      }
                                                      resetTimer();
                                                      saveTime(label: selectedDurationLabel, toSave: _selectedDuration);
                                                    });
                                                  },
                                                ),
                                              ),
                                              spacer,
                                              const Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 5), child: Text('Show MS')),
                                              Switch(
                                                value: _showMilliseconds,
                                                onChanged: (newVal) {
                                                  setState(() {
                                                    _showMilliseconds = newVal;
                                                  });
                                                  _data.then((value) => value.setBool(showMillisecondsLabel, newVal));
                                                },
                                              ),
                                            ]
                                        ),
                                      )
                                    ],
                                  ),
                                )
                            ),
                            Expanded(
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.65,
                                    heightFactor: 0.65,
                                    child: buildTimerPainter(
                                      percentage: (_selectedDuration - _elapsedTime - _previousElapsedTime).inMilliseconds / _selectedDuration.inMilliseconds,
                                      timeRemaining: _selectedDuration - _elapsedTime - _previousElapsedTime,
                                      showMilliseconds: _showMilliseconds,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ]
                      ),
                    );
                  case ScreenType.tablet:
                    return const Center(
                      child: Text(
                        "Tablet Layout",
                        style: TextStyle(
                          fontSize: 32,
                        ),
                      ),
                    );
                  default:
                    return const Center(
                      child: Text(
                        "Mobile Layout",
                        style: TextStyle(
                          fontSize: 32,
                        ),
                      ),
                    );
                }
              },
            );
          } else {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hoursController.dispose();
    _minsController.dispose();
    _secsController.dispose();
    super.dispose();
  }
}
