import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:flexify/database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v17.dart' as v17;

void main() {
  test(
    'upgrade from all versions',
    () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final currentVersion =
          AppDatabase(executor: NativeDatabase.memory()).schemaVersion;

      for (int from = 1; from <= currentVersion; from++) {
        if (from == 8 || from == 9) continue;

        for (int to = from + 1; to <= currentVersion; to++) {
          if (to == 8 || to == 9) continue;
          final connection = await verifier.startAt(from);
          final db = AppDatabase(executor: connection);
          await verifier.migrateAndValidate(db, to);
          await db.close();
        }
      }
    },
    skip: true,
  );

  test('upgrade 17->18 with data', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    final schema = await verifier.schemaAt(17);
    final oldDb = v17.DatabaseAtV17(schema.newConnection());
    await oldDb.gymSets.insertAll([
      GymSetsCompanion.insert(
        created: DateTime.now(),
        name: 'Bench press',
        reps: 2,
        unit: 'kg',
        weight: 90,
      ),
    ]);
    await oldDb.plans.insertAll([
      PlansCompanion.insert(
        days: 'Monday,Tuesday,Wednesday',
        exercises: 'Bench press',
      ),
    ]);
    await oldDb.close();

    final db = AppDatabase(executor: schema.newConnection());

    await verifier.migrateAndValidate(db, 18);
    await db.close();
  });
}
