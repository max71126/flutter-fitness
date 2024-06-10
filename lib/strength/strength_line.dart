import 'package:drift/drift.dart';
import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flexify/constants.dart';
import 'package:flexify/edit_gym_set.dart';
import 'package:flexify/strength/strength_data.dart';
import 'package:flexify/main.dart';
import 'package:flexify/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StrengthLine extends StatefulWidget {
  final String name;
  final StrengthMetric metric;
  final String targetUnit;
  final Period period;
  final DateTime? startDate;
  final DateTime? endDate;

  const StrengthLine({
    super.key,
    required this.name,
    required this.metric,
    required this.targetUnit,
    required this.period,
    this.startDate,
    this.endDate,
  });

  @override
  createState() => _StrengthLineState();
}

class _StrengthLineState extends State<StrengthLine> {
  late Stream<List<StrengthData>> _graphStream;
  late SettingsState _settings;
  final _ormCol = db.gymSets.weight /
      (const Variable(1.0278) - const Variable(0.0278) * db.gymSets.reps);
  final _volumeCol =
      const CustomExpression<double>("ROUND(SUM(weight * reps), 2)");
  final _relativeCol = db.gymSets.weight.max() / db.gymSets.bodyWeight;

  DateTime _lastTap = DateTime.fromMicrosecondsSinceEpoch(0);

  @override
  void didUpdateWidget(covariant StrengthLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setStream();
  }

  @override
  void initState() {
    super.initState();
    _setStream();
    _settings = context.read<SettingsState>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setStream() {
    Expression<String> createdCol = const CustomExpression<String>(
      "STRFTIME('%Y-%m-%d', DATE(created, 'unixepoch', 'localtime'))",
    );
    if (widget.period == Period.month)
      createdCol = const CustomExpression<String>(
        "STRFTIME('%Y-%m', DATE(created, 'unixepoch', 'localtime'))",
      );
    else if (widget.period == Period.week)
      createdCol = const CustomExpression<String>(
        "STRFTIME('%Y-%m-%W', DATE(created, 'unixepoch', 'localtime'))",
      );
    else if (widget.period == Period.year)
      createdCol = const CustomExpression<String>(
        "STRFTIME('%Y', DATE(created, 'unixepoch', 'localtime'))",
      );

    setState(() {
      _graphStream = (db.selectOnly(db.gymSets)
            ..addColumns([
              db.gymSets.weight.max(),
              _volumeCol,
              _ormCol,
              db.gymSets.created,
              if (widget.metric == StrengthMetric.bestReps)
                db.gymSets.reps.max(),
              if (widget.metric != StrengthMetric.bestReps) db.gymSets.reps,
              db.gymSets.unit,
              _relativeCol,
            ])
            ..where(db.gymSets.name.equals(widget.name))
            ..where(db.gymSets.hidden.equals(false))
            ..where(
              db.gymSets.created
                  .isBiggerOrEqualValue(widget.startDate ?? DateTime(0)),
            )
            ..where(
              db.gymSets.created.isSmallerThanValue(
                widget.endDate ??
                    DateTime.now().toLocal().add(const Duration(days: 1)),
              ),
            )
            ..orderBy([
              OrderingTerm(
                expression: createdCol,
                mode: OrderingMode.desc,
              ),
            ])
            ..limit(11)
            ..groupBy([createdCol]))
          .watch()
          .map(
        (results) {
          List<StrengthData> list = [];
          for (final result in results.reversed) {
            final unit = result.read(db.gymSets.unit)!;
            var value = _getValue(result, widget.metric);

            if (unit == 'lb' && widget.targetUnit == 'kg') {
              value *= 0.45359237;
            } else if (unit == 'kg' && widget.targetUnit == 'lb') {
              value *= 2.20462262;
            }

            double reps = 0.0;
            try {
              reps = result.read(db.gymSets.reps)!;
            } catch (_) {}

            list.add(
              StrengthData(
                created: result.read(db.gymSets.created)!.toLocal(),
                value: value,
                unit: unit,
                reps: reps,
              ),
            );
          }
          return list;
        },
      );
    });
  }

  double _getValue(TypedResult row, StrengthMetric metric) {
    switch (metric) {
      case StrengthMetric.oneRepMax:
        return row.read(_ormCol)!;
      case StrengthMetric.volume:
        return row.read(_volumeCol)!;
      case StrengthMetric.relativeStrength:
        return row.read(_relativeCol) ?? 0;
      case StrengthMetric.bestWeight:
        return row.read(db.gymSets.weight.max())!;
      case StrengthMetric.bestReps:
        try {
          return row.read(db.gymSets.reps.max())!;
        } catch (error) {
          return 0;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    _settings = context.watch<SettingsState>();

    return StreamBuilder(
      stream: _graphStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        if (snapshot.data?.isEmpty == true)
          return ListTile(
            title: Text("No data yet for ${widget.name}"),
            subtitle: const Text("Complete some plans to view graphs here"),
            contentPadding: EdgeInsets.zero,
          );
        if (snapshot.hasError) return ErrorWidget(snapshot.error.toString());

        List<FlSpot> spots = [];
        final rows = snapshot.data!;

        for (var index = 0; index < snapshot.data!.length; index++) {
          spots.add(FlSpot(index.toDouble(), snapshot.data![index].value));
        }

        return SizedBox(
          height: 380,
          child: Padding(
            padding: const EdgeInsets.only(right: 32.0, top: 16.0),
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 27,
                      interval: 1,
                      getTitlesWidget: (value, meta) =>
                          _bottomTitleWidgets(value, meta, rows),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (event, touchResponse) async {
                    if (event is ScaleUpdateDetails) return;
                    if (event is! FlPanDownEvent) return;
                    if (widget.metric != StrengthMetric.bestWeight) return;
                    if (DateTime.now().difference(_lastTap) <
                        const Duration(milliseconds: 300)) {
                      final index = touchResponse?.lineBarSpots?[0].spotIndex;
                      if (index == null) return;
                      final row = rows[index];
                      final gymSet = await (db.gymSets.select()
                            ..where((tbl) => tbl.created.equals(row.created))
                            ..where((tbl) => tbl.reps.equals(row.reps))
                            ..where((tbl) => tbl.weight.equals(row.value))
                            ..where((tbl) => tbl.name.equals(widget.name))
                            ..limit(1))
                          .getSingle();

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditGymSet(
                            gymSet: gymSet,
                          ),
                        ),
                      );
                    }
                    setState(() {
                      _lastTap = DateTime.now();
                    });
                  },
                  touchTooltipData: _tooltipData(context, rows),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: _settings.curveLines,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bottomTitleWidgets(
    double value,
    TitleMeta meta,
    List<StrengthData> rows,
  ) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;

    int middleIndex = (rows.length / 2).floor();
    List<int> indices;

    if (rows.length % 2 == 0) {
      indices = [0, rows.length - 1];
    } else {
      indices = [0, middleIndex, rows.length - 1];
    }

    if (indices.contains(value.toInt())) {
      DateTime createdDate = rows[value.toInt()].created;
      text = Text(
        DateFormat(_settings.shortDateFormat).format(createdDate),
        style: style,
      );
    } else {
      text = const Text('', style: style);
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  LineTouchTooltipData _tooltipData(
    BuildContext context,
    List<StrengthData> rows,
  ) {
    return LineTouchTooltipData(
      getTooltipColor: (touch) => Theme.of(context).colorScheme.surface,
      getTooltipItems: (touchedSpots) {
        final row = rows.elementAt(touchedSpots.first.spotIndex);
        final created =
            DateFormat(_settings.shortDateFormat).format(row.created);
        final formatter = NumberFormat("#,###.00");

        String text =
            "${row.reps} x ${row.value.toStringAsFixed(2)}${widget.targetUnit} $created";
        switch (widget.metric) {
          case StrengthMetric.bestReps:
          case StrengthMetric.relativeStrength:
            text = "${row.value.toStringAsFixed(2)} $created";
            break;
          case StrengthMetric.volume:
          case StrengthMetric.oneRepMax:
            text =
                "${formatter.format(row.value)}${widget.targetUnit} $created";
            break;
          case StrengthMetric.bestWeight:
            break;
        }

        return [
          LineTooltipItem(
            text,
            TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
          ),
        ];
      },
    );
  }
}
