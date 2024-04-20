import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flexify/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/utils.dart';
import 'package:flutter/material.dart';

class UploadRecordsButton extends StatelessWidget {
  final BuildContext pageContext;

  const UploadRecordsButton({
    super.key,
    required this.pageContext,
  });

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
                    onTap: () async {
                      Navigator.pop(context);
                      String csv = await android.invokeMethod('read');
                      List<List<dynamic>> rows =
                          const CsvToListConverter(eol: "\n").convert(csv);
                      if (rows.isEmpty) return;

                      final gymSets = rows.map(
                        (row) => GymSetsCompanion(
                          name: Value(row[1]),
                          reps: Value(row[2]),
                          weight: Value(row[3]),
                          created: Value(parseDate(row[4])),
                          unit: Value(row[5]),
                          bodyWeight: Value(row.elementAtOrNull(6) ?? 0),
                        ),
                      );
                      await db.batch(
                        (batch) => batch.insertAll(db.gymSets, gymSets),
                      );

                      final weightSet = await getBodyWeight();
                      if (weightSet != null)
                        (db.gymSets.update()
                              ..where((tbl) => tbl.bodyWeight.equals(0)))
                            .write(GymSetsCompanion(
                                bodyWeight: Value(weightSet.weight)));

                      if (!pageContext.mounted) return;
                      Navigator.pop(pageContext);
                      DefaultTabController.of(pageContext).animateTo(1);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('Plans'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      String csv = await android.invokeMethod('read');
                      List<List<dynamic>> rows =
                          const CsvToListConverter(eol: "\n").convert(csv);
                      if (rows.isEmpty) return;
                      try {
                        final plans = rows.map(
                          (row) => PlansCompanion(
                            days: Value(row[1]),
                            exercises: Value(row[2]),
                            title: Value(row.elementAtOrNull(3)),
                          ),
                        );
                        db.batch(
                          (batch) => batch.insertAll(db.plans, plans),
                        );
                        if (!pageContext.mounted) return;
                        Navigator.pop(pageContext);
                        DefaultTabController.of(pageContext).animateTo(0);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to upload csv.')),
                        );
                      }
                    },
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
