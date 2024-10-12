import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String project;
  final String title;
  final String date;
  final double opacity; // Add opacity parameter

  TaskCard({
    required this.project,
    required this.title,
    required this.date,
    this.opacity = 1.0, // Default opacity is fully visible
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity, // Set the opacity here
      child: Container(
        width: 250,
        height: 250,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.task, color: Colors.white),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 8),
                    Text(
                      project,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 22),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 60),
            Text(
              date,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
