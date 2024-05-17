import 'package:drift/drift.dart';
import 'package:flexify/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/unit_selector.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';

class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key});

  @override
  createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final TextEditingController _nameController = TextEditingController();
  String _unit = 'kg';
  bool _cardio = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _save() async {
    Navigator.pop(context);
    db.gymSets.insertOne(
      GymSetsCompanion.insert(
        created: DateTime.now().toLocal(),
        reps: 0,
        weight: 0,
        name: _nameController.text,
        unit: _unit,
        cardio: Value(_cardio),
        hidden: const Value(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add exercise'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: material.Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            UnitSelector(
              value: _unit,
              cardio: _cardio,
              onChanged: (String? newValue) {
                setState(() {
                  _unit = newValue!;
                });
              },
            ),
            ListTile(
              title: const Text('Cardio'),
              onTap: () {
                setState(() {
                  _cardio = !_cardio;
                  if (_cardio)
                    _unit = 'km';
                  else
                    _unit = 'kg';
                });
              },
              trailing: Switch(
                value: _cardio,
                onChanged: (value) => setState(() {
                  _cardio = value;
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),
    );
  }
}
