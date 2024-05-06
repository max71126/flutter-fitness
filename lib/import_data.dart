import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flexify/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/utils.dart';
import 'package:flutter/material.dart';

class ImportData extends StatelessWidget {
  final BuildContext pageContext;

  const ImportData({
    super.key,
    required this.pageContext,
  });

  _importGraphs(BuildContext context) async {
    Navigator.pop(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    File file = File(result.files.single.path!);
    var csv = await file.readAsString();
    List<List<dynamic>> rows = const CsvToListConverter(eol: "\n").convert(csv);

    if (rows.length <= 1) return;

    final columns = rows.first;

    final gymSets = rows.skip(1).map(
      (row) {
        Value<double> reps;
        if (row[2] is String)
          reps = Value(double.parse(row[2]));
        else
          reps = Value(row[2]);

        Value<double> weight;
        if (row[3] is String)
          weight = Value(double.parse(row[3]));
        else
          weight = Value(row[3]);

        Value<bool> hidden;
        Value<double> bodyWeight;
        if (columns.elementAtOrNull(6) == 'hidden') {
          if (row.elementAtOrNull(6) is double)
            hidden = Value(row[6] == 1.0);
          else
            hidden = Value(row[6] == "1");
        } else {
          hidden = const Value(false);
          bodyWeight = Value(row.elementAtOrNull(6) ?? 0);
        }

        if (columns.elementAtOrNull(7) == 'bodyWeight')
          bodyWeight = Value(double.tryParse(row.elementAtOrNull(7)) ?? 0);
        else
          bodyWeight = const Value(0);

        if (columns.elementAtOrNull(10) == 'hidden')
          hidden = Value(bool.parse(row[10]));

        return GymSetsCompanion(
          name: Value(row[1]),
          reps: reps,
          weight: weight,
          created: Value(parseDate(row[4])),
          unit: Value(row[5]),
          hidden: hidden,
          bodyWeight: bodyWeight,
          duration: columns.elementAtOrNull(7) == 'duration'
              ? Value(row[7])
              : const Value(0),
          distance: columns.elementAtOrNull(8) == 'distance'
              ? Value(row[8])
              : const Value(0),
          cardio: columns.elementAtOrNull(9) == 'cardio'
              ? Value(bool.parse(row[9]))
              : const Value(false),
        );
      },
    );
    await db.gymSets.deleteAll();
    await db.gymSets.insertAll(gymSets);

    final weightSet = await getBodyWeight();
    if (weightSet != null)
      (db.gymSets.update()..where((tbl) => tbl.bodyWeight.equals(0)))
          .write(GymSetsCompanion(bodyWeight: Value(weightSet.weight)));

    if (!pageContext.mounted) return;
    Navigator.pop(pageContext);
  }

  _importPlans(BuildContext context) async {
    Navigator.pop(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    File file = File(result.files.single.path!);
    var csv = await file.readAsString();
    List<List<dynamic>> rows = const CsvToListConverter(eol: "\n").convert(csv);

    if (rows.length <= 1) return;
    List<PlansCompanion> plans = [];
    for (final row in rows.skip(1)) {
      var sequence = row.elementAtOrNull(4);
      if (sequence is String) sequence = 0;
      plans.add(PlansCompanion(
        days: Value(row[1]),
        exercises: Value(row[2]),
        title: Value(row.elementAtOrNull(3)),
        sequence: Value(sequence),
      ));
    }
    await db.plans.deleteAll();
    await db.plans.insertAll(plans);
    if (!pageContext.mounted) return;
    Navigator.pop(pageContext);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.insights),
                    title: const Text('Graphs'),
                    onTap: () => _importGraphs(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('Plans'),
                    onTap: () => _importPlans(context),
                  ),
                ],
              );
            },
          );
        },
        icon: const Icon(Icons.upload),
        label: const Text('Import data'));
  }
}
