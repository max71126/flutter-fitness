import 'package:drift/drift.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';

List<Widget> getWorkouts(
  String term,
  Setting settings,
  TextEditingController maxSetsController,
) {
  return [
    if ('sets per exercise'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          controller: maxSetsController,
          decoration: const InputDecoration(
            labelText: 'Sets per exercise',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          onTap: () => selectAll(maxSetsController),
          onChanged: (value) => db.settings.update().write(
                SettingsCompanion(
                  maxSets: Value(int.parse(value)),
                ),
              ),
        ),
      ),
    if ('plan trailing display'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<PlanTrailing>(
          value: PlanTrailing.values
              .byName(settings.planTrailing.replaceFirst('PlanTrailing.', '')),
          decoration: const InputDecoration(
            labelStyle: TextStyle(),
            labelText: 'Plan trailing display',
          ),
          items: const [
            DropdownMenuItem(
              value: PlanTrailing.reorder,
              child: Row(
                children: [
                  Text("Re-order"),
                  SizedBox(width: 8),
                  Icon(Icons.menu, size: 18),
                ],
              ),
            ),
            DropdownMenuItem(
              value: PlanTrailing.count,
              child: Row(
                children: [
                  Text("Count"),
                  SizedBox(width: 8),
                  Text("(5)"),
                ],
              ),
            ),
            DropdownMenuItem(
              value: PlanTrailing.percent,
              child: Row(
                children: [
                  Text("Percent"),
                  SizedBox(width: 8),
                  Text("(50%)"),
                ],
              ),
            ),
            DropdownMenuItem(
              value: PlanTrailing.ratio,
              child: Row(
                children: [
                  Text("Ratio"),
                  SizedBox(width: 8),
                  Text("(5 / 10)"),
                ],
              ),
            ),
            DropdownMenuItem(
              value: PlanTrailing.none,
              child: Text("None"),
            ),
          ],
          onChanged: (value) => db.settings.update().write(
                SettingsCompanion(
                  planTrailing: Value(value.toString()),
                ),
              ),
        ),
      ),
    if ('group history'.contains(term.toLowerCase()))
      ListTile(
        title: const Text('Group history'),
        leading: const Icon(Icons.expand_more),
        onTap: () => db.settings.update().write(
              SettingsCompanion(
                groupHistory: Value(!settings.groupHistory),
              ),
            ),
        trailing: Switch(
          value: settings.groupHistory,
          onChanged: (value) => db.settings.update().write(
                SettingsCompanion(
                  groupHistory: Value(value),
                ),
              ),
        ),
      ),
    if ('show units'.contains(term.toLowerCase()))
      ListTile(
        title: const Text('Show units'),
        leading: const Icon(Icons.scale_sharp),
        onTap: () => db.settings
            .update()
            .write(SettingsCompanion(showUnits: Value(!settings.showUnits))),
        trailing: Switch(
          value: settings.showUnits,
          onChanged: (value) => db.settings
              .update()
              .write(SettingsCompanion(showUnits: Value(value))),
        ),
      ),
    if ('hide weight'.contains(term.toLowerCase()))
      ListTile(
        title: const Text('Hide weight'),
        leading: const Icon(Icons.scale_outlined),
        onTap: () => db.settings
            .update()
            .write(SettingsCompanion(hideWeight: Value(!settings.hideWeight))),
        trailing: Switch(
          value: settings.hideWeight,
          onChanged: (value) => db.settings
              .update()
              .write(SettingsCompanion(hideWeight: Value(value))),
        ),
      ),
    if ('hide history tab'.contains(term.toLowerCase()))
      ListTile(
        title: const Text('Hide history tab'),
        leading: const Icon(Icons.history),
        onTap: () => db.settings.update().write(
              SettingsCompanion(
                hideHistoryTab: Value(!settings.hideHistoryTab),
              ),
            ),
        trailing: Switch(
          value: settings.hideHistoryTab,
          onChanged: (value) => db.settings
              .update()
              .write(SettingsCompanion(hideHistoryTab: Value(value))),
        ),
      ),
  ];
}

class SettingsWorkout extends StatefulWidget {
  const SettingsWorkout({super.key});

  @override
  State<SettingsWorkout> createState() => _SettingsWorkoutState();
}

class _SettingsWorkoutState extends State<SettingsWorkout> {
  late var settings = context.read<SettingsState>().value;

  late final maxSetsController =
      TextEditingController(text: settings.maxSets.toString());

  @override
  Widget build(BuildContext context) {
    settings = context.watch<SettingsState>().value;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Workouts"),
      ),
      body: ListView(
        children: getWorkouts('', settings, maxSetsController),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    maxSetsController.dispose();
  }
}