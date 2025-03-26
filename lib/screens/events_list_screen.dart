import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_model.dart';
import '../services/api_service.dart';
import '../widgets/nav_drawer.dart';
import 'event_chat_screen.dart';
import 'event_edit_screen.dart';
import 'event_entry_screen.dart';
import 'view_event_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final List<EventModel> _eventEntries = [];
  late final String userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId').toString();
    await _loadEventsList();
  }

  Future<void> _loadEventsList() async {
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.get('events/$userId');
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      final responseData = jsonDecode(apiResponse.body);
      setState(() {
        _eventEntries.clear();
        for (var event in responseData) {
          if (event['message'] == null) {
            _eventEntries.add(EventModel.fromJson(event));
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      final responseData = jsonDecode(apiResponse.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService.delete('event/$eventId');
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Event deleted successfully: $eventId');
        }
        setState(() {
          _isLoading = false;
        });
        _loadEventsList();
      } else {
        throw Exception('Failed to delete event');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting event: $e');
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EventChatScreen()),
              );
            },
          ),
        ],

        title: const Text('Events'),
      ),
      drawer: const NavDrawer(selectedIndex: 2),
      body:
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _eventEntries.length,
        itemBuilder: (context, index) {
          final event = _eventEntries[index];
          DateTime dateTime = DateTime.parse(event.createdAt).toLocal();
          var format = DateFormat('dd MMM, yyyy hh:MM a');
          String formattedDate = format.format(
            dateTime.toUtc().add(const Duration(hours: -8)),
          );
          return ListTile(
            title: Text(event.title),
            subtitle: Text(formattedDate),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => ViewEventScreen(
                    title: event.title,
                    eventEntry: event.eventEntry,
                    date: formattedDate,
                  ),
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Handle edit action
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => EventEditScreen(
                          eventId: event.eventId,
                          title: event.title,
                          eventEntry: event.eventEntry,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _deleteEvent(event.eventId);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const JournalEntryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}