import 'package:flutter/material.dart';

class PreferencesScreen extends StatelessWidget {
  final Map<String, dynamic> preferencesData;
  final String fileUrl;

  PreferencesScreen({Key? key, required this.preferencesData, required this.fileUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preferences"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Start and End Page
            buildPreferenceRow("Start Page", preferencesData['startPage']),
            buildPreferenceRow("End Page", preferencesData['endPage']),

            // Number of Copies
            buildPreferenceRow("No. of Copies", preferencesData['copies']),

            // Color Scheme
            buildPreferenceRow("Color Scheme", preferencesData['isColor'] ? "Color" : "B & W"),

            // Paper Size
            buildPreferenceRow("Paper Size", getPaperSize(preferencesData['paperSize'])),

            // Sides
            buildPreferenceRow("Sides", getSides(preferencesData['sides'])),

            // Display the File URL
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "File URL:",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // You can open the URL or perform an action
                      // For example, use `url_launcher` package to open the URL in a browser
                    },
                    child: Text(
                      fileUrl,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.blue.shade800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to display key-value pairs in a row
  Widget buildPreferenceRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            value.toString(),
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  // Convert the paper size value to human-readable format
  String getPaperSize(int paperSize) {
    switch (paperSize) {
      case 1:
        return "A4";
      case 2:
        return "A3";
      case 3:
        return "Legal";
      case 4:
        return "Letter";
      default:
        return "Unknown";
    }
  }

  // Convert the sides value to human-readable format
  String getSides(int sides) {
    switch (sides) {
      case 1:
        return "Front Only";
      case 2:
        return "Both Sides";
      case 3:
        return "Even Sides";
      case 4:
        return "Odd Sides";
      default:
        return "Unknown";
    }
  }
}
