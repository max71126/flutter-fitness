import 'package:drift/drift.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsTabs extends StatefulWidget {
  const SettingsTabs({super.key});

  @override
  createState() => _SettingsTabsState();
}

typedef TabSetting = ({
  String name,
  bool enabled,
});

class _SettingsTabsState extends State<SettingsTabs> {
  List<TabSetting> tabs = [
    (name: 'HistoryPage', enabled: false),
    (name: 'PlansPage', enabled: false),
    (name: 'GraphsPage', enabled: false),
    (name: 'TimerPage', enabled: false),
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsState>();
    final tabSplit = settings.value.tabs.split(',');

    final enabledTabs =
        tabSplit.map((tab) => (name: tab, enabled: true)).toList();
    final disabledTabs =
        tabs.where((tab) => !tabSplit.contains(tab.name)).toList();

    tabs = enabledTabs + disabledTabs;
  }

  setTab(String name, bool enabled) {
    if (!enabled && tabs.where((tab) => tab.enabled == true).length == 1)
      return toast(context, 'You need at least one tab');
    final index = tabs.indexWhere((tappedTab) => tappedTab.name == name);
    setState(() {
      tabs[index] = (name: name, enabled: enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tabs")),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: ReorderableListView.builder(
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) {
              newIndex--;
            }

            final temp = tabs[oldIndex];
            setState(() {
              tabs.removeAt(oldIndex);
              tabs.insert(newIndex, temp);
            });
          },
          itemBuilder: (context, index) {
            final tab = tabs[index];
            if (tab.name == 'HistoryPage') {
              return ListTile(
                key: Key(tab.name),
                onTap: () => setTab(tab.name, !tab.enabled),
                leading: Switch(
                  value: tab.enabled,
                  onChanged: (value) => setTab(tab.name, value),
                ),
                title: const Text("History"),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              );
            } else if (tab.name == 'PlansPage') {
              return ListTile(
                key: Key(tab.name),
                onTap: () => setTab(tab.name, !tab.enabled),
                leading: Switch(
                  value: tab.enabled,
                  onChanged: (value) => setTab(tab.name, value),
                ),
                title: const Text("Plans"),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              );
            } else if (tab.name == 'GraphsPage') {
              return ListTile(
                key: Key(tab.name),
                onTap: () => setTab(tab.name, !tab.enabled),
                leading: Switch(
                  value: tab.enabled,
                  onChanged: (value) => setTab(tab.name, value),
                ),
                title: const Text("Graphs"),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              );
            } else if (tab.name == 'TimerPage') {
              return ListTile(
                key: Key(tab.name),
                onTap: () => setTab(tab.name, !tab.enabled),
                leading: Switch(
                  value: tab.enabled,
                  onChanged: (value) => setTab(tab.name, value),
                ),
                title: const Text("Timer"),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              );
            } else
              return ErrorWidget("Invalid tab settings.");
          },
          itemCount: tabs.length,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await (db.settings.update().write(
                SettingsCompanion(
                  tabs: Value(
                    tabs
                        .where((tab) => tab.enabled)
                        .map((tab) => tab.name)
                        .join(','),
                  ),
                ),
              ));
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
