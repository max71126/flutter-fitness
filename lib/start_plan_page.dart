import 'package:drift/drift.dart' as drift;
import 'package:flexify/app_state.dart';
import 'package:flexify/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'exercise_tile.dart';

class StartPlanPage extends StatefulWidget {
  final Plan plan;
  final Stream<List<drift.TypedResult>> countStream;
  final Future<void> Function() onReorder;

  const StartPlanPage(
      {Key? key,
      required this.plan,
      required this.countStream,
      required this.onReorder})
      : super(key: key);

  @override
  createState() => _StartPlanPageState();
}

class _StartPlanPageState extends State<StartPlanPage> {
  late TextEditingController repsController;
  late TextEditingController weightController;
  late List<String> planExercises;

  String unit = 'kg';
  int selectedIndex = 0;

  final repsNode = FocusNode();
  final weightNode = FocusNode();

  @override
  void initState() {
    super.initState();
    repsController = TextEditingController(text: "0.0");
    weightController = TextEditingController(text: "0.0");
    planExercises = widget.plan.exercises.split(',');
    getLast(context.read<AppState>());
  }

  @override
  void dispose() {
    repsController.dispose();
    weightController.dispose();
    repsNode.dispose();
    weightNode.dispose();
    super.dispose();
  }

  void selectWeight() {
    weightController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: weightController.text.length,
    );
  }

  Future<void> getLast(AppState appState) async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    var last = await (database.gymSets.select()
          ..where((tbl) => database.gymSets.name.isIn(planExercises))
          ..where((tbl) =>
              database.gymSets.created.isBiggerOrEqualValue(startOfToday))
          ..where((tbl) =>
              database.gymSets.created.isSmallerThanValue(startOfTomorrow))
          ..orderBy([
            (u) => drift.OrderingTerm(
                expression: u.created, mode: drift.OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    last ??= await (database.gymSets.select()
          ..where((tbl) => database.gymSets.name.equals(planExercises[0]))
          ..orderBy([
            (u) => drift.OrderingTerm(
                expression: u.created, mode: drift.OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (last == null) {
      appState.selectExercise(planExercises[0]);
      return setState(() {});
    }
    repsController.text = last.reps.toString();
    weightController.text = last.weight.toString();
    setState(() {
      unit = last!.unit;
    });
    final index = planExercises.indexOf(last.name);
    setState(() {
      selectedIndex = index;
    });
    appState.selectExercise(planExercises[index]);
  }

  Future<void> select(int index) async {
    setState(() {
      selectedIndex = index;
    });
    final exercise = planExercises.elementAt(index);
    final exerciseState = context.read<AppState>();
    exerciseState.selectExercise(exercise);
    final last = await (database.gymSets.select()
          ..where((tbl) => database.gymSets.name.equals(exercise))
          ..orderBy([
            (u) => drift.OrderingTerm(
                expression: u.created, mode: drift.OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    setState(() {
      repsController.text = last != null ? last.reps.toString() : "0.0";
      weightController.text = last != null ? last.weight.toString() : "0.0";
    });
  }

  Future<void> save(TimerState timerState, SettingsState settingsState) async {
    final reps = double.parse(repsController.text);
    final weight = double.parse(weightController.text);
    final exercise = planExercises[selectedIndex];

    final gymSet = GymSetsCompanion.insert(
      name: exercise,
      reps: reps,
      weight: weight,
      unit: unit,
      created: DateTime.now(),
    );

    database.into(database.gymSets).insert(gymSet);
    await requestNotificationPermission();

    if (settingsState.restTimers)
      await timerState.startTimer(exercise, settingsState.timerDuration);
  }

  @override
  Widget build(BuildContext context) {
    var title = widget.plan.days.replaceAll(",", ", ");
    title = title[0].toUpperCase() + title.substring(1).toLowerCase();

    final timerState = context.read<TimerState>();
    final settingsState = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            TextField(
              controller: weightController,
              focusNode: weightNode,
              decoration: InputDecoration(labelText: 'Weight ($unit)'),
              keyboardType: TextInputType.number,
              onTap: () {
                selectWeight();
              },
              onSubmitted: (value) {
                repsNode.requestFocus();
                repsController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: repsController.text.length,
                );
              },
            ),
            TextField(
              controller: repsController,
              focusNode: repsNode,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
              onSubmitted: (value) async =>
                  await save(timerState, settingsState),
              onTap: () {
                repsController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: repsController.text.length,
                );
              },
            ),
            Visibility(
              visible: settingsState.showUnits,
              child: DropdownButtonFormField<String>(
                value: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: ['kg', 'lb'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    unit = newValue!;
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: widget.countStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        exerciseList(planExercises, snapshot),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await save(timerState, settingsState),
        tooltip: "Save this set",
        child: const Icon(Icons.save),
      ),
    );
  }

  exerciseList(List<String> planExercises,
      AsyncSnapshot<List<drift.TypedResult>> snapshot) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: planExercises.length,
      itemBuilder: (context, index) {
        final exercise = planExercises[index];
        final gymSets = snapshot.data?.where(
            (element) => element.read(database.gymSets.name) == exercise);
        var count = 0;
        if (gymSets != null && gymSets.isNotEmpty)
          count = gymSets.first.read(database.gymSets.name.count())!;
        return ExerciseTile(
          index: index,
          exercise: exercise,
          isSelected: index == selectedIndex,
          count: count,
          onTap: () {
            select(index);
          },
          key: Key(exercise),
        );
      },
      onReorder: (int oldIndex, int newIndex) async {
        if (oldIndex < newIndex) {
          newIndex--;
        }

        if (oldIndex == selectedIndex)
          selectedIndex = newIndex;
        else if (oldIndex < selectedIndex && newIndex >= selectedIndex)
          selectedIndex--;
        else if (oldIndex > selectedIndex && newIndex <= selectedIndex)
          selectedIndex++;

        final temp = planExercises[oldIndex];
        planExercises.removeAt(oldIndex);
        planExercises.insert(newIndex, temp);

        final plan = widget.plan.copyWith(exercises: planExercises.join(','));
        await database.update(database.plans).replace(plan);
        await widget.onReorder();
      },
    );
  }
}
