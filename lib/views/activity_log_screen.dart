import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/activity_log_service.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  // Por defecto, se filtran los registros del día actual.
  DateTime _filterDate = DateTime.now();

  // Filtra las entradas que tengan la misma fecha (año, mes y día) que _filterDate.
  List<ActivityLogEntry> get _filteredLog {
    return ActivityLogService().log.where((entry) {
      return entry.timestamp.year == _filterDate.year &&
          entry.timestamp.month == _filterDate.month &&
          entry.timestamp.day == _filterDate.day;
    }).toList();
  }

  Future<void> _selectFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _filterDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLog = _filteredLog;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Actividades"),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectFilterDate,
            tooltip: "Filtrar por fecha",
          ),
        ],
      ),
      body: filteredLog.isEmpty
          ? const Center(child: Text("No hay actividades registradas para la fecha seleccionada."))
          : ListView.builder(
        itemCount: filteredLog.length,
        itemBuilder: (context, index) {
          final entry = filteredLog[index];
          return ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(entry.formatted),
          );
        },
      ),
    );
  }
}
