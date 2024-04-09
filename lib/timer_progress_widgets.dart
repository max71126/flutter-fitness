import 'package:flexify/app_state.dart';
import 'package:flexify/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimerProgressIndicator extends StatelessWidget {
  const TimerProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerState>(builder: (context, timerState, child) {
      final duration = timerState.nativeTimer.getDuration();
      final elapsed = timerState.nativeTimer.getElapsed();
      final remaining = timerState.nativeTimer.getRemaining();

      return Visibility(
        visible: duration > Duration.zero,
        child: TweenAnimationBuilder(
          key: UniqueKey(),
          tween: Tween<double>(
            begin: 1, // Start at 1 (full progress)
            end: elapsed.inMilliseconds /
                duration.inMilliseconds, // End at the current progress
          ),
          duration: remaining,
          builder: (context, value, child) => LinearProgressIndicator(
            value: value,
          ),
        ),
      );
    });
  }
}

class TimerCircularProgressIndicator extends StatelessWidget {
  const TimerCircularProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerState>(builder: (context, timerState, child) {
      final duration = timerState.nativeTimer.getDuration();
      final elapsed = timerState.nativeTimer.getElapsed();
      final remaining = timerState.nativeTimer.getRemaining();

      return duration > Duration.zero
          ? TweenAnimationBuilder(
              key: UniqueKey(),
              tween: Tween<double>(
                begin: 1, // Start at 1 (full progress)
                end: elapsed.inMilliseconds /
                    duration.inMilliseconds, // End at the current progress
              ),
              duration: remaining,
              builder: (context, value, child) =>
                  _TimerCircularProgressIndicatorTile(
                value: value,
                timerState: timerState,
              ),
            )
          : _TimerCircularProgressIndicatorTile(
              value: 0,
              timerState: timerState,
            );
    });
  }
}

class _TimerCircularProgressIndicatorTile extends StatelessWidget {
  final double value;
  final TimerState timerState;

  String generateTitleText(Duration remaining) {
    final minutes = (remaining.inMinutes).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  const _TimerCircularProgressIndicatorTile({
    required this.value,
    required this.timerState,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          height: 300,
          width: 300,
          child: CircularProgressIndicator(
            strokeCap: StrokeCap.round,
            value: value, // Use the updated value
            strokeWidth: 20,
            backgroundColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 32.0),
            Text(
              generateTitleText(timerState.nativeTimer.getRemaining()),
              style: TextStyle(
                fontSize: 50.0,
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () async {
                await requestNotificationPermission();
                await timerState.addOneMinute();
              },
              child: const Text('+1 min'),
            ),
          ],
        ),
      ],
    );
  }
}
