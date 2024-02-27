import 'package:drift/drift.dart';
import 'package:flexify/database.dart';
import 'package:flexify/edit_plan_page.dart';
import 'package:flexify/main.dart';
import 'package:flexify/start_plan_page.dart';
import 'package:flutter/material.dart';

class PlanTile extends StatelessWidget {
  const PlanTile({
    super.key,
    required this.plan,
    required this.weekday,
    required this.index,
    required this.countStream,
    required this.navigatorKey,
  });

  final Plan plan;
  final String weekday;
  final int index;
  final Stream<List<TypedResult>> countStream;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: plan.days.split(',').length == 7
          ? const Text("Daily")
          : RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: plan.days.split(',').expand((day) {
                  return [
                    TextSpan(
                      text: day.trim(),
                      style: TextStyle(
                        fontWeight:
                            weekday == day.trim() ? FontWeight.bold : null,
                        decoration: weekday == day.trim()
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                    const TextSpan(text: ', '),
                  ];
                }).toList(),
              ),
            ),
      subtitle: Text(plan.exercises.split(',').join(', ')),
      onTap: () {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
              builder: (context) => StartPlanPage(
                    plan: plan,
                    countStream: countStream,
                  )),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditPlanPage(
                                plan: plan.toCompanion(false),
                              )),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text(
                              'Are you sure you want to delete this plan?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Delete'),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await database
                                    .delete(database.plans)
                                    .delete(plan);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
