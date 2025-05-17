import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ligne/core/enums/menu_action.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/utils/dialogs/logout_dialog.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _events = {};

  List<String> _getEventsForDay(DateTime date) {
    return _events[DateTime(date.year, date.month, date.day)] ?? [];
  }
  
  void _addEvent(String event) {
    final day = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    if (_events[day] == null) {
      _events[day] = [];
    }

    _events[day]!.add(event);
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Administration'),
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogoutDialog(context);
                  
                  if (shouldLogout) {
                    if (context.mounted) {
                      context
                        .read<AuthBloc>()
                        .add(const AuthEventLogout());
                    }
                  }
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text('Logout'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1), 
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day), 
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8.0),
          if (_selectedDay != null)
            Expanded(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final controller = TextEditingController();
                      final result = await showDialog<String>(
                        context: context, 
                        builder: (context) => AlertDialog(
                          title: const Text('Add Event'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(hintText: 'Event Details'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context), 
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, controller.text), 
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                      if (result != null && result.trim().isNotEmpty) {
                        _addEvent(result.trim());
                      }
                    }, 
                    child: const Text('Add Event'),
                  ),
                  const SizedBox(height: 8.0),
                  Expanded(
                    child: ListView(
                      children: _getEventsForDay(_selectedDay!).map((event) => ListTile(
                        title: Text(event),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
