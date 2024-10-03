import 'package:flexify/settings/settings_page.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/weight_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppSearch extends StatefulWidget {
  final Set<dynamic> selected;

  final Function(String) onChange;
  final Function onClear;
  final Function onEdit;
  final Function onDelete;
  final Function onSelect;
  final Function onShare;
  final Function? onRefresh;
  final Widget? filter;
  const AppSearch({
    super.key,
    required this.selected,
    required this.onChange,
    required this.onClear,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
    required this.onShare,
    this.onRefresh,
    this.filter,
  });

  @override
  State<AppSearch> createState() => _AppSearchState();
}

class _AppSearchState extends State<AppSearch> {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SearchBar(
        hintText: "Search...",
        controller: searchController,
        padding: WidgetStateProperty.all(
          const EdgeInsets.only(right: 8.0),
        ),
        textCapitalization: TextCapitalization.sentences,
        onChanged: widget.onChange,
        leading:
            widget.selected.isEmpty && searchController.text.isEmpty == true
                ? const Padding(
                    padding: EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(Icons.search),
                  )
                : IconButton(
                    onPressed: () {
                      widget.onClear();
                      searchController.text = '';
                      widget.onChange('');
                    },
                    icon: const Icon(Icons.arrow_back),
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 8.0,
                    ),
                  ),
        trailing: [
          if (widget.selected.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Delete selected",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text(
                        'Are you sure you want to delete ${widget.selected.length} records? This action is not reversible.',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        TextButton(
                          child: const Text('Delete'),
                          onPressed: () async {
                            Navigator.pop(context);
                            widget.onDelete();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          if (widget.selected.isEmpty && widget.filter != null) widget.filter!,
          Badge.count(
            count: widget.selected.length,
            isLabelVisible: widget.selected.isNotEmpty,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Selector<SettingsState, bool>(
              selector: (p0, settings) => settings.value.showBodyWeight,
              builder: (context, showBodyWeight, child) => PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                tooltip: "Show menu",
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.done_all),
                      title: const Text('Select all'),
                      onTap: () async {
                        Navigator.pop(context);
                        widget.onSelect();
                      },
                    ),
                  ),
                  if (widget.selected.isNotEmpty) ...[
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit'),
                        onTap: () async {
                          await widget.onEdit();
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text('Share'),
                        onTap: () async {
                          await widget.onShare();
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.clear_all),
                        title: const Text('Clear'),
                        onTap: () async {
                          Navigator.pop(context);
                          widget.onClear();
                        },
                      ),
                    ),
                  ],
                  if (widget.selected.isEmpty && showBodyWeight)
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.scale),
                        title: const Text('Weight'),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WeightPage(),
                            ),
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  if (widget.selected.isEmpty)
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          if (widget.onRefresh != null) widget.onRefresh!();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4

// Auto-generated comment for change 4
