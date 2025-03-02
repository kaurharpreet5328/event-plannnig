import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class DemoAIScreen extends StatefulWidget {
  const DemoAIScreen({super.key});

  @override
  State<DemoAIScreen> createState() => _DemoAIScreenState();
}

class _DemoAIScreenState extends State<DemoAIScreen> {
  String output = 'Output from Gemini will show here';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Gemini.instance.promptStream(parts: [
  Part.text('Write a story about a magic backpack'),
]).listen((value) {setState(() {
  output = value?.output??'';
});});
        },
        child: const Icon(Icons.add),
      ),
      body:  SafeArea(
        child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              output,
              textAlign: TextAlign.center,
                
              ),
              
            ),
          ),
        ),
      ),
    );
  }
}
