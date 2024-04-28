import 'package:drift/drift.dart';
import 'package:flexify/database.dart';
import 'package:flexify/main.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';

class EditGymSet extends StatefulWidget {
  final GymSetsCompanion gymSet;

  const EditGymSet({super.key, required this.gymSet});

  @override
  createState() => _EditGymSetState();
}

class _EditGymSetState extends State<EditGymSet> {
  late TextEditingController _nameController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _bodyWeightController;
  late TextEditingController _distanceController;
  late TextEditingController _durationController;
  late String _unit;
  late DateTime _created;
  late bool _cardio;

  @override
  void initState() {
    super.initState();
    _repsController =
        TextEditingController(text: widget.gymSet.reps.value.toString());
    _nameController =
        TextEditingController(text: widget.gymSet.name.value.toString());
    _weightController =
        TextEditingController(text: widget.gymSet.weight.value.toString());
    _bodyWeightController =
        TextEditingController(text: widget.gymSet.bodyWeight.value.toString());
    _durationController =
        TextEditingController(text: widget.gymSet.duration.value.toString());
    _distanceController =
        TextEditingController(text: widget.gymSet.distance.value.toString());
    _unit = widget.gymSet.unit.value;
    _created = widget.gymSet.created.value;
    _cardio = widget.gymSet.cardio.value;
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    Navigator.pop(context);
    final gymSet = widget.gymSet.copyWith(
      name: Value(_nameController.text),
      unit: Value(_unit),
      created: Value(_created),
      reps: Value(double.parse(_repsController.text)),
      weight: Value(double.parse(_weightController.text)),
      bodyWeight: Value(double.parse(_bodyWeightController.text)),
      distance: Value(double.parse(_distanceController.text)),
      duration: Value(double.parse(_durationController.text)),
    );
    db.update(db.gymSets).replace(gymSet);
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _created,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      _selectTime(pickedDate);
    }
  }

  Future<void> _selectTime(DateTime pickedDate) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_created),
    );

    if (pickedTime != null) {
      setState(() {
        _created = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.gymSet.name.value}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: Text(
                        'Are you sure you want to delete ${widget.gymSet.name.value}?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                      ),
                      TextButton(
                        child: const Text('Delete'),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await db.delete(db.gymSets).delete(widget.gymSet);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: material.Column(
          children: [
            if (!_cardio) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.sentences,
              ),
              TextField(
                controller: _repsController,
                decoration: const InputDecoration(labelText: 'Reps'),
                keyboardType: TextInputType.number,
                onTap: () => _repsController.selection = TextSelection(
                    baseOffset: 0, extentOffset: _repsController.text.length),
              ),
              TextField(
                controller: _weightController,
                decoration: InputDecoration(
                    labelText: _nameController.text == 'Weight'
                        ? 'Value ($_unit)'
                        : 'Weight ($_unit)'),
                keyboardType: TextInputType.number,
                onTap: () => _weightController.selection = TextSelection(
                    baseOffset: 0, extentOffset: _weightController.text.length),
              ),
            ],
            if (_cardio) ...[
              TextField(
                controller: _distanceController,
                decoration: const InputDecoration(labelText: 'Distance'),
                keyboardType: TextInputType.number,
                onTap: () => _distanceController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _distanceController.text.length),
              ),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration'),
                keyboardType: TextInputType.number,
                onTap: () => _durationController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _durationController.text.length),
              ),
            ],
            if (_nameController.text != 'Weight')
              TextField(
                controller: _bodyWeightController,
                decoration: InputDecoration(labelText: 'Body weight ($_unit)'),
                keyboardType: TextInputType.number,
                onTap: () => _bodyWeightController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _bodyWeightController.text.length),
              ),
            DropdownButtonFormField<String>(
              value: _unit,
              decoration: const InputDecoration(labelText: 'Unit'),
              items:
                  (_cardio ? ['km', 'mi'] : ['kg', 'lb']).map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _unit = newValue!;
                });
              },
            ),
            ListTile(
              title: const Text('Created Date'),
              subtitle: Text(_created.toString()),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(),
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
