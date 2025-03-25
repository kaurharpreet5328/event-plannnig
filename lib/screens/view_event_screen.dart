import 'package:flutter/material.dart';

class ViewEventScreen extends StatefulWidget {
  final String title;
  final String eventEntry;
  final String date;

  const ViewEventScreen({
    super.key,
    required this.title,
    required this.eventEntry,
    required this.date,
  });

  @override
  State<ViewEventScreen> createState() => _ViewEventScreenState();
}

class _ViewEventScreenState extends State<ViewEventScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
              widget.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.topLeft,child: Text(widget.date.toString(), style: const TextStyle(fontSize: 16))),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: Text(widget.eventEntry, style: const TextStyle(fontSize: 18)))),
          ],
        ),
      ),
    );
  }
}