import 'package:flutter/material.dart';
import 'package:viz4go_frontend/home_screen.dart';

class MenuWidget extends StatefulWidget {
  final Future<void> Function() onLoadData;
  final TextEditingController goIdController;
  final List<String> activeFilters;
  final void Function(LayoutMode) onLayoutModeChanged;

  const MenuWidget({
    super.key,
    required this.onLoadData,
    required this.goIdController,
    required this.activeFilters,
    required this.onLayoutModeChanged, // Dodane
  });

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> {
  LayoutMode _selectedLayoutMode = LayoutMode.random; // default

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          width: 300,
          decoration: BoxDecoration(
            color: Colors.blueGrey[700],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: widget.onLoadData,
                icon: const Icon(Icons.refresh,
                    color: Color.fromARGB(255, 237, 224, 219)),
                label: const Text('Load data',
                    style:
                        TextStyle(color: Color.fromARGB(255, 237, 224, 219))),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.goIdController,
                minLines: 5,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'GO id\'s',
                  labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 237, 224, 219)),
                  fillColor: Colors.blueGrey[300],
                  filled: true,
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 237, 224, 219), width: 2.0),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 237, 224, 219), width: 2.0),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 237, 224, 219), width: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.file_present_outlined,
                  color: Color.fromARGB(255, 237, 224, 219),
                ),
                label: const Text(
                  'Attach file',
                  style: TextStyle(
                    color: Color.fromARGB(255, 237, 224, 219),
                  ),
                ),
              ),
              _buildRelationFilter('is_a'),
              _buildRelationFilter('part_of'),
              _buildRelationFilter('negatively_regulates'),
              _buildRelationFilter('regulates'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text(
                    "Layout mode: ",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<LayoutMode>(
                    dropdownColor: Colors.blueGrey[700],
                    style: const TextStyle(color: Colors.white),
                    value: _selectedLayoutMode,
                    items: const [
                      DropdownMenuItem(
                        value: LayoutMode.random,
                        child: Text(
                          'Random',
                        ),
                      ),
                      DropdownMenuItem(
                        value: LayoutMode.circular,
                        child: Text(
                          'Circular',
                        ),
                      ),
                      DropdownMenuItem(
                        value: LayoutMode.twoColumn,
                        child: Text(
                          'Two Column',
                        ),
                      ),
                    ],
                    onChanged: (LayoutMode? newMode) {
                      setState(() {
                        _selectedLayoutMode = newMode!;
                        widget.onLayoutModeChanged(_selectedLayoutMode);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelationFilter(String relation) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey[600],
        borderRadius: BorderRadius.circular(10),
      ),
      child: CheckboxListTile(
        side: const BorderSide(
          color: Color.fromARGB(255, 237, 224, 219),
          width: 2,
        ),
        title: Text(
          relation,
          style: const TextStyle(
            color: Color.fromARGB(255, 237, 224, 219),
          ),
        ),
        value: widget.activeFilters.contains(relation),
        onChanged: (bool? value) {
          setState(
            () {
              if (value == true) {
                widget.activeFilters.add(relation);
              } else {
                widget.activeFilters.remove(relation);
              }
            },
          );
        },
        activeColor: Colors.blueGrey[700],
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
