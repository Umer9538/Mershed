import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DestinationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(destination['name'] ?? 'Destination')),
      body: Center(child: Text(destination['description'] ?? 'No description')),
    );
  }
}