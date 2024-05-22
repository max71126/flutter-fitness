import 'package:drift/drift.dart';
import 'package:flexify/cardio_data.dart';
import 'package:flexify/constants.dart';
import 'package:flexify/main.dart';

class GymSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get reps => real()();
  RealColumn get weight => real()();
  TextColumn get unit => text()();
  DateTimeColumn get created => dateTime()();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  RealColumn get bodyWeight => real().withDefault(const Constant(0.0))();
  RealColumn get duration => real().withDefault(const Constant(0.0))();
  RealColumn get distance => real().withDefault(const Constant(0.0))();
  BoolColumn get cardio => boolean().withDefault(const Constant(false))();
  IntColumn get restMs => integer().withDefault(
        Constant(const Duration(minutes: 3, seconds: 30).inMilliseconds),
      )();
  IntColumn get maxSets => integer().withDefault(const Constant(3))();
  IntColumn get incline => integer().nullable()();
}

double _getValue(TypedResult row, CardioMetric metric) {
  if (metric == CardioMetric.distance) {
    return row.read(db.gymSets.distance.sum())!;
  } else if (metric == CardioMetric.duration) {
    return row.read(db.gymSets.duration.sum())!;
  } else if (metric == CardioMetric.pace) {
    return row.read(db.gymSets.distance.sum() / db.gymSets.duration.sum()) ?? 0;
  } else {
    throw Exception("Metric not supported.");
  }
}

Stream<List<CardioData>> watchCardio({
  Period groupBy = Period.day,
  String name = "",
  CardioMetric metric = CardioMetric.pace,
  DateTime? startDate,
  DateTime? endDate,
}) {
  Expression<String> createdCol = const CustomExpression<String>(
    "STRFTIME('%Y-%m-%d', DATE(created, 'unixepoch', 'localtime'))",
  );
  if (groupBy == Period.month)
    createdCol = const CustomExpression<String>(
      "STRFTIME('%Y-%m', DATE(created, 'unixepoch', 'localtime'))",
    );
  else if (groupBy == Period.week)
    createdCol = const CustomExpression<String>(
      "STRFTIME('%Y-%m-%W', DATE(created, 'unixepoch', 'localtime'))",
    );
  else if (groupBy == Period.year)
    createdCol = const CustomExpression<String>(
      "STRFTIME('%Y', DATE(created, 'unixepoch', 'localtime'))",
    );

  return (db.selectOnly(db.gymSets)
        ..addColumns([
          db.gymSets.duration.sum(),
          db.gymSets.distance.sum(),
          db.gymSets.distance.sum() / db.gymSets.duration.sum(),
          db.gymSets.created,
          db.gymSets.unit,
        ])
        ..where(db.gymSets.name.equals(name))
        ..where(db.gymSets.hidden.equals(false))
        ..where(
          db.gymSets.created.isBiggerOrEqualValue(startDate ?? DateTime(0)),
        )
        ..where(
          db.gymSets.created.isSmallerThanValue(
            endDate ?? DateTime.now().toLocal().add(const Duration(days: 1)),
          ),
        )
        ..orderBy([
          OrderingTerm(
            expression: db.gymSets.created.date,
            mode: OrderingMode.desc,
          ),
        ])
        ..limit(11)
        ..groupBy([createdCol]))
      .watch()
      .map(
        (results) => results
            .map(
              (result) => CardioData(
                created: result.read(db.gymSets.created)!,
                value:
                    double.parse(_getValue(result, metric).toStringAsFixed(2)),
                unit: result.read(db.gymSets.unit)!,
              ),
            )
            .toList(),
      );
}
