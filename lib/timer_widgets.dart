import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Widget buildPlayButton({required void Function() onPressed, required bool fillWidth}) {
  Size size = fillWidth ? const Size.fromHeight(40) : const Size(65, 65);
  OutlinedBorder? shape = fillWidth ? null : const CircleBorder();

  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(
        color: Colors.green,
      ),
      primary: Colors.green,
      padding: const EdgeInsets.all(10),
      minimumSize: size,
      shape: shape,
    ),
    child: const Icon(
      Icons.play_arrow,
    ),
  );
}

Widget buildPauseButton({required void Function() onPressed, required bool fillWidth}) {
  Size size = fillWidth ? const Size.fromHeight(40) : const Size(65, 65);
  OutlinedBorder? shape = fillWidth ? null : const CircleBorder();

  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(
        color: Colors.white70,
      ),
      primary: Colors.white70,
      padding: const EdgeInsets.all(10),
      minimumSize: size,
      shape: shape,
    ),
    child: const Icon(
      Icons.pause,
    ),
  );
}

Widget buildStopButton({required void Function() onPressed, required bool fillWidth}) {
  Size size = fillWidth ? const Size.fromHeight(40) : const Size(65, 65);
  OutlinedBorder? shape = fillWidth ? null : const CircleBorder();

  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(
        color: Colors.red,
      ),
      primary: Colors.red,
      padding: const EdgeInsets.all(10),
      minimumSize: size,
      shape: shape,
    ),
    child: const Icon(
      Icons.stop,
    ),
  );
}

Widget buildRestartButton({required void Function() onPressed, required bool fillWidth}) {
  Size size = fillWidth ? const Size.fromHeight(40) : const Size(65, 65);
  OutlinedBorder? shape = fillWidth ? null : const CircleBorder();

  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(
        color: Colors.green,
      ),
      primary: Colors.green,
      padding: const EdgeInsets.all(10),
      minimumSize: size,
      shape: shape,
    ),
    child: const Icon(
      Icons.replay,
    ),
  );
}

Widget buildTimerPainter({required double percentage, required Duration timeRemaining, required bool showMilliseconds}) {
  return CustomPaint(
    painter: _CustomTimerPainter(
      percentage: percentage,
    ),
    child: FractionallySizedBox(
      widthFactor: 0.6,
      heightFactor: 0.6,
      child: FittedBox(
        child: Text(
          durationToString(timeRemaining, showMilliseconds),
        ),
        fit: BoxFit.contain,
      ),
    ),
  );
}

String durationToString(Duration duration, bool showMilliseconds) {
  String result = "";
  int hoursRemaining = duration.inHours;
  int minsRemaining = duration.inMinutes.remainder(Duration.minutesPerHour);
  int secsRemaining = duration.inSeconds.remainder(Duration.secondsPerMinute);

  result += (hoursRemaining != 0) ? hoursRemaining.toString() + ":" : "";
  if (result.isNotEmpty) {
    result += intToTwoChar(minsRemaining) + ":";
  } else {
    result += (minsRemaining != 0) ? minsRemaining.toString() + ":" : "";
  }

  if (result.isNotEmpty) {
    result += intToTwoChar(secsRemaining);
  } else {
    result += secsRemaining.toString();
  }

  if (showMilliseconds) {
    String msString = duration.inMilliseconds.remainder(Duration.millisecondsPerSecond).toString();
    if (msString.length < 2) {
      result += ".0" + msString[0];
    } else {
      result += "." + msString[0] + msString[1];
    }
  }

  return result;
}

String intToTwoChar(int x) {
  if (x < 10) {
    return "0" + x.toString();
  } else {
    return x.toString();
  }
}

class _CustomTimerPainter extends CustomPainter {
  final double percentage;

  _CustomTimerPainter({
    required this.percentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white38
      ..strokeWidth = size.width * 0.075;

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.deepPurple
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round;

    final circleRect = Rect.fromCenter(center: Offset(size.width / 2, size.width / 2), width: size.width, height:  size.height);
    final arcAngle = (2 * pi * percentage);

    canvas.drawArc(circleRect, 0, 360, false, backgroundPaint);
    if (percentage  >= 0.01) canvas.drawArc(circleRect, (-90 * (pi / 180)), arcAngle, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final old = (oldDelegate as _CustomTimerPainter);
    return old.percentage != percentage;
  }

}