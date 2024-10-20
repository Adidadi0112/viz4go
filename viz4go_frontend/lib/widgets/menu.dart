import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:viz4go_frontend/home_screen.dart';
import 'package:viz4go_frontend/services/api_service.dart';

class MenuWidget extends StatefulWidget {
  final Future<void> Function() onLoadData;
  final TextEditingController goIdController;
  final List<String> activeFilters;
  final void Function(LayoutMode) onLayoutModeChanged;
  final void Function(List<dynamic>) onConnectionsUpdated;
  final void Function(Map<String, dynamic>?) onCsvConnectionsUpdated;

  const MenuWidget({
    super.key,
    required this.onLoadData,
    required this.goIdController,
    required this.activeFilters,
    required this.onLayoutModeChanged,
    required this.onConnectionsUpdated,
    required this.onCsvConnectionsUpdated,
  });

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> {
  LayoutMode _selectedLayoutMode = LayoutMode.random;

  Map<String, dynamic>? connectionsCsv;

  String? molecularFunctionFileName;
  String? biologicalProcessFileName;
  String? cellularComponentFileName;

  PlatformFile? molecularFunctionFile;
  PlatformFile? biologicalProcessFile;
  PlatformFile? cellularComponentFile;

  // Funkcja do wybrania pliku
  Future<void> pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'], // Ograniczamy do plików CSV
    );

    if (result != null) {
      PlatformFile file = result.files.single;

      setState(() {
        // Aktualizacja zmiennych na podstawie typu pliku
        switch (type) {
          case 'molecular_function':
            molecularFunctionFile = file;
            molecularFunctionFileName = file.name;
            break;
          case 'biological_process':
            biologicalProcessFile = file;
            biologicalProcessFileName = file.name;
            break;
          case 'cellular_component':
            cellularComponentFile = file;
            cellularComponentFileName = file.name;
            break;
        }
      });
    }
  }

  Future<void> showAttachFileDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Attach Files'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Molecular Function
                    ListTile(
                      title: const Text('Molecular Function'),
                      subtitle:
                          Text(molecularFunctionFileName ?? 'No file selected'),
                      trailing: IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () async {
                          await pickFile('molecular_function');
                          // Aktualizacja stanu dialogu
                          setState(() {});
                        },
                      ),
                    ),
                    const Divider(),
                    // Biological Process
                    ListTile(
                      title: const Text('Biological Process'),
                      subtitle:
                          Text(biologicalProcessFileName ?? 'No file selected'),
                      trailing: IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () async {
                          await pickFile('biological_process');
                          // Aktualizacja stanu dialogu
                          setState(() {});
                        },
                      ),
                    ),
                    const Divider(),
                    // Cellular Component
                    ListTile(
                      title: const Text('Cellular Component'),
                      subtitle:
                          Text(cellularComponentFileName ?? 'No file selected'),
                      trailing: IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () async {
                          await pickFile('cellular_component');
                          // Aktualizacja stanu dialogu
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Attach'),
                  onPressed: () async {
                    // Wywołanie requestu i przypisanie odpowiedzi do zmiennej
                    connectionsCsv =
                        await ApiService().sendNodeConnectionsRequest(
                      molecularFunctionFile!,
                      biologicalProcessFile!,
                      cellularComponentFile!,
                      0.4,
                    );

                    // Sprawdzenie, czy odpowiedź nie jest nullem
                    if (connectionsCsv != null) {
                      // Zrobienie czegoś z odpowiedzią, np. przekazanie do innej funkcji lub użycie w widoku
                      print('Received response: $connectionsCsv');
                    } else {
                      print('Failed to fetch connections.');
                    }
                    widget.onCsvConnectionsUpdated(connectionsCsv);
                    // Zamknięcie dialogu
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _loadGraph() async {
    List<String> goIds = widget.goIdController.text.split(' ');
    goIds = goIds.map((e) => e.replaceAll('\n', '')).toList();
    final connections = await ApiService().fetchGoConnections(goIds);
    widget.onConnectionsUpdated(connections);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          width: 260,
          decoration: BoxDecoration(
            color: Colors.blueGrey[700],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _loadGraph,
                icon: const Icon(
                  Icons.refresh,
                  color: Color.fromARGB(255, 237, 224, 219),
                ),
                label: const Text(
                  'Load data',
                  style: TextStyle(
                    color: Color.fromARGB(255, 237, 224, 219),
                  ),
                ),
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
                onPressed: () => showAttachFileDialog(context),
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
              _buildRelationFilter('has_part'),
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
                      DropdownMenuItem(
                        value: LayoutMode.tree,
                        child: Text(
                          'Tree',
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
        title: Text(
          relation,
          style: const TextStyle(
            color: Color.fromARGB(255, 237, 224, 219),
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color.fromARGB(255, 237, 224, 219),
        checkColor: Colors.blueGrey[700],
        value: widget.activeFilters.contains(relation),
        onChanged: (bool? value) {
          setState(() {
            if (value != null && value) {
              widget.activeFilters.add(relation);
            } else {
              widget.activeFilters.remove(relation);
            }
          });
        },
      ),
    );
  }
}
