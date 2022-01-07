import 'dart:async';
import 'dart:math';

import 'package:countdown_timer/test_package.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(title: 'Timer Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Future<SharedPreferences> _data;
  // late SharedPreferences data;
  late bool showMilliseconds;
  late double userHours;
  late double userMins;
  late double userSecs;
  late double _counter = getUserTime();
  Timer? _timer;
  late TextEditingController _hoursController;
  late TextEditingController _minsController;
  late TextEditingController _secsController;

  Future<void> loadFutures() async {
    showMilliseconds = await _data.then((value) => value.getBool('showMilliseconds') ?? false);
    userHours =  await _data.then((value) => value.getDouble('userHours') ?? 0);
    userMins = await _data.then((value) => value.getDouble('userMins') ?? 5);
    userSecs = await _data.then((value) => value.getDouble('userSecs') ?? 0);
  }

  Future<void> initData() async {
    await loadFutures();
    _hoursController = TextEditingController(text: userHours.toStringAsFixed(0));
    _minsController = TextEditingController(text: userMins.toStringAsFixed(0));
    _secsController = TextEditingController(text: userSecs.toStringAsFixed(0));

  }

  bool allDataInitiated() {
    try {
      // ignore: unused_local_variable
      Object? testVar;
      testVar = showMilliseconds;
      testVar = userHours;
      testVar = userMins;
      testVar = userSecs;
      testVar = null;
      return true;
    } catch (error) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _data = SharedPreferences.getInstance();
    initData();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minsController.dispose();
    _secsController.dispose();
    super.dispose();
  }

  double getUserTime() {
    return (userHours * (60 * 60)) + (userMins * 60) + userSecs;
  }

  void saveTime(int type) {
    switch (type) {
      case 0:
        _data.then((value) => value.setBool('showMilliseconds', showMilliseconds));
        break;
      case 1:
        _data.then((value) => value.setDouble('userHours', userHours));
        break;
      case 2:
        _data.then((value) => value.setDouble('userMins', userMins));
        break;
      case 3:
        _data.then((value) => value.setDouble('userSecs', userSecs));
        break;
      default:
        throw Error();
    }
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (_counter >= 0.01) {
        setState(() => _counter = _counter - 0.01);
      } else {
        pauseTimer();
      }
    });
  }

  void pauseTimer() {
    if (_timer?.isActive ?? false) {
      setState(() => _timer!.cancel());
    }
  }

  void resetTimer() {
    pauseTimer();
    setState(() => _counter = getUserTime());
  }

  String printTime(double timeVal, bool printMS) {
    int h, m, s, ms;

    h = timeVal ~/ 3600;
    m = ((timeVal - h * 3600)) ~/ 60;
    s = (timeVal - (h * 3600) - (m * 60)) ~/ 1;
    ms = ((timeVal - (h * 3600) - (m * 60) - s) * 100) ~/ 1;

    String msString = (printMS) ? '.' + intToDoubleDigit(ms) : '';

    if (h > 0) {
      return '$h:' + intToDoubleDigit(m) + ':' + intToDoubleDigit(s) + msString;
    } else if (m > 0) {
      return '$m:' + intToDoubleDigit(s) + msString;
    } else {
      return '$s' + msString;
    }
  }

  String intToDoubleDigit(int val) {
    if (val.toString().length < 2) {
      return '0$val';
    } else {
      return '$val';
    }
  }

  Widget buildTime(BuildContext context) {
    // print((getUserTime() < 1 || _counter < 0.01) ? 0 : _counter / getUserTime());
    // print('Percent: ' + (_counter / getUserTime()).toString());
    return AnimatedCircleProgressBar(
      value: (getUserTime() < 1 || _counter < 0.01) ? 0 : (_counter == getUserTime()) ? 1 : (_counter / getUserTime()),
      animationCurve: Curves.linear,
      animationDuration: const Duration(milliseconds: 1),
      fillColor: Colors.deepPurple,
      backgroundColor: Colors.white38,
      counterClockwise: true,
      child: FractionallySizedBox(
        widthFactor: 0.6,
        heightFactor: 0.6,
        child: FittedBox(
          child: Text(
            printTime(_counter, showMilliseconds),
          ),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget buildSidebar(BuildContext context) {
    MediaQueryData _mediaQueryData = MediaQuery.of(context);
    double _textFieldWidth = (_mediaQueryData.size.width < 500) ? 25 : _mediaQueryData.size.width * 0.05;
    double _iconWidth = (_textFieldWidth > 50) ? 30 : _textFieldWidth * 0.4;
    final isRunning = (_timer == null) ? false : _timer!.isActive;
    final playButton = IconButton(
      constraints: BoxConstraints(minWidth: _textFieldWidth),
      iconSize: _iconWidth,
      icon: const Icon(
        Icons.play_arrow,
      ),
      color: Theme.of(context).textTheme.bodyText1?.color ?? Colors.white,
      onPressed: () {
        startTimer();
      },
    );
    final pauseButton = IconButton(
      constraints: BoxConstraints(minWidth: _textFieldWidth),
      iconSize: _iconWidth,
      icon: const Icon(
        Icons.pause,
      ),
      color: Theme.of(context).textTheme.bodyText1?.color ?? Colors.white,
      onPressed: () {
        pauseTimer();
      },
    );
    final resetButton = IconButton(
      constraints: BoxConstraints(minWidth: _textFieldWidth),
      iconSize: _iconWidth,
      icon: const Icon(
        Icons.stop,
      ),
      color: Theme.of(context).errorColor,
      onPressed: () {
        resetTimer();
      }
    );
    final restartButton = IconButton(
      constraints: BoxConstraints(minWidth: _textFieldWidth),
      iconSize: _iconWidth,
      icon: const Icon(
        Icons.replay,
      ),
      color: Theme.of(context).textTheme.bodyText1?.color ?? Colors.white,
      onPressed: () {
        resetTimer();
        startTimer();
      }
    );

    List<Widget> settings = [];

    // Add the first button with soft interactions (play, pause, restart)
    if (isRunning) {
      settings.add(pauseButton);
    } else if (_counter < 0.01) {
      settings.add(restartButton);
    } else {
      settings.add(playButton);
    }

    // Add the stop button
    if (_counter != getUserTime()) settings.add(resetButton);

    settings.add(
      Expanded(child: Container()),
    );

    // Add time number controls
    settings.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 15, 0, 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            Text('Hours'),
          ],
        ),
      )
    );

    settings.add(
      RawKeyboardListener(
        onKey: (RawKeyEvent event) {
          if (event.runtimeType == RawKeyDownEvent) {
            bool isChanged = false;
            setState(() {
              if (event.logicalKey == LogicalKeyboardKey.arrowUp && userHours < 999) {
                setState(() {
                  userHours += 1;
                });
                isChanged = true;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && userHours > 0) {
                setState(() {
                  userHours -= 1;
                });
                isChanged = true;
              }
              if (isChanged) {
                saveTime(1);
                _hoursController.value = TextEditingValue(text: userHours.toStringAsFixed(0));
                _hoursController.selection = TextSelection(baseOffset: 0, extentOffset: _hoursController.text.length);
                resetTimer();
              }
            });
          }
        },
        focusNode: FocusNode(),
        child: SizedBox(
          width: _textFieldWidth,
          child: TextFormField(
            controller: _hoursController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              // labelText: 'Hours',
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
                  userHours = 0;
                  _hoursController.value = const TextEditingValue(text: '0');
                  _hoursController.selection = TextSelection(baseOffset: 0, extentOffset: _hoursController.text.length);
                } else {
                  userHours =  int.parse(newVal) as double;
                }
                if (_timer?.isActive ?? false) {
                  resetTimer();
                }
                saveTime(1);
                _counter = getUserTime();
              });
            },
          ),
        ),
      )
    );

    settings.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 15, 0, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
              Text('Minutes'),
            ],
          ),
        )
    );

    settings.add(
        RawKeyboardListener(
          onKey: (RawKeyEvent event) {
            if (event.runtimeType == RawKeyDownEvent) {
              bool isChanged = false;
              setState(() {
                if (event.logicalKey == LogicalKeyboardKey.arrowUp && userMins < 60) {
                  setState(() {
                    userMins += 1;
                  });
                  isChanged = true;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && userMins > 0) {
                  setState(() {
                    userMins -= 1;
                  });
                  isChanged = true;
                }
                if (isChanged) {
                  saveTime(2);
                  _minsController.value = TextEditingValue(text: userMins.toStringAsFixed(0));
                  _minsController.selection = TextSelection(baseOffset: 0, extentOffset: _minsController.text.length);
                  resetTimer();
                }
              });
            }
          },
          focusNode: FocusNode(),
          child: SizedBox(
            width: _textFieldWidth,
            child: TextFormField(
              controller: _minsController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                // labelText: 'Hours',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onTap: () {
                _minsController.selection = TextSelection(baseOffset: 0, extentOffset: _minsController.text.length);
              },
              onChanged: (newVal) {
                setState(() {
                  if (newVal.isEmpty) {
                    userMins = 0;
                    _minsController.value = const TextEditingValue(text: '0');
                    _minsController.selection = TextSelection(baseOffset: 0, extentOffset: _minsController.text.length);
                  } else if (int.parse(newVal) > 60) {
                    userHours += 1;
                    userMins = (int.parse(newVal) as double) - 60;
                    _hoursController.value = TextEditingValue(text: userHours.toStringAsFixed(0));
                    _minsController.value = TextEditingValue(text: userMins.toStringAsFixed(0));
                  } else {
                    userMins =  int.parse(newVal) as double;
                  }
                  if (_timer?.isActive ?? false) {
                    resetTimer();
                  }
                  saveTime(2);
                  _counter = getUserTime();
                });
              },
            ),
          ),
        )
    );

    settings.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 15, 0, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
              Text('Seconds'),
            ],
          ),
        )
    );

    settings.add(
        RawKeyboardListener(
          onKey: (RawKeyEvent event) {
            if (event.runtimeType == RawKeyDownEvent) {
              bool isChanged = false;
              setState(() {
                if (event.logicalKey == LogicalKeyboardKey.arrowUp && userSecs < 60) {
                  setState(() {
                    userSecs += 1;
                  });
                  isChanged = true;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && userSecs > 0) {
                  setState(() {
                    userSecs -= 1;
                  });
                  isChanged = true;
                }
                if (isChanged) {
                  saveTime(3);
                  _secsController.value = TextEditingValue(text: userSecs.toStringAsFixed(0));
                  _secsController.selection = TextSelection(baseOffset: 0, extentOffset: _secsController.text.length);
                  resetTimer();
                }
              });
            }
          },
          focusNode: FocusNode(),
          child: SizedBox(
            width: _textFieldWidth,
            child: TextFormField(
              controller: _secsController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                // labelText: 'Hours',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onTap: () {
                _secsController.selection = TextSelection(baseOffset: 0, extentOffset: _secsController.text.length);
              },
              onChanged: (newVal) {
                setState(() {
                  if (newVal.isEmpty) {
                    userSecs = 0;
                    _secsController.value = const TextEditingValue(text: '0');
                    _secsController.selection = TextSelection(baseOffset: 0, extentOffset: _secsController.text.length);
                  } else if (int.parse(newVal) > 60) {
                    userMins += 1;
                    userSecs = (int.parse(newVal) as double) - 60;
                    _minsController.value = TextEditingValue(text: userMins.toStringAsFixed(0));
                    _secsController.value = TextEditingValue(text: userSecs.toStringAsFixed(0));
                  } else {
                    userSecs =  int.parse(newVal) as double;
                  }
                  if (_timer?.isActive ?? false) {
                    resetTimer();
                  }
                  saveTime(3);
                  _counter = getUserTime();
                });
              },
            ),
          ),
        )
    );

    settings.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 15, 0, 5),
          child: Row(
            children: const [
              Text('Show MS'),
            ],
          ),
        )
    );

    settings.add(
      Switch(
        value: showMilliseconds,
        onChanged: (newVal) {
          setState(() {
            showMilliseconds = newVal;
          });
          saveTime(0);
        },
      )
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    const _textSizePercent = 0.6;
    MediaQueryData _mediaQueryData = MediaQuery.of(context);
    double _minSize = min(_mediaQueryData.size.width, _mediaQueryData.size.height);

    return FutureBuilder(
      future: _data.then((value) {
        Future.delayed(const Duration(seconds: 10));
        return value;
      }),
      builder: (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        if (snapshot.hasData && allDataInitiated()) {
          return Scaffold(
            body: Center(
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(
                        border: Border(
                            right: BorderSide(
                              width: 1,
                              color: Colors.white70,
                            )
                        )
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        child: buildSidebar(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        child: buildTime(context),
                        width: _minSize * _textSizePercent,
                        height: _minSize * _textSizePercent,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            body: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, _minSize * 0.05, 0, 0),
                      child: SizedBox(
                        width: _minSize * 0.6,
                        child: const FittedBox(
                          fit: BoxFit.contain,
                          child: Text('Loading Timer'),
                        ),
                      ),
                    ),
                  ]
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
