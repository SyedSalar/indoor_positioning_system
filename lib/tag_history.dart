import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyTagHistory extends StatefulWidget {
  @override
  _MyTagHistoryState createState() => _MyTagHistoryState();
}

class _MyTagHistoryState extends State<MyTagHistory> {
  List<Map<String, dynamic>> tagHistoryData = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response =
        await http.get(Uri.parse('http://localhost:5000/get_data'));
    if (response.statusCode == 200) {
      setState(() {
        tagHistoryData =
            List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      // Handle error
      print('Failed to fetch data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tag History'),
      ),
      body: tagHistoryData.isEmpty
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: tagHistoryData.length,
              itemBuilder: (context, index) {
                final item = tagHistoryData[index];
                return TagHistoryItem(
                  name: item['name'],
                  beacon: item['beacon'],
                  distance: item['distance'],
                );
              },
            ),
    );
  }
}

class TagHistoryItem extends StatelessWidget {
  final String name;
  final String beacon;
  final String distance;

  const TagHistoryItem({
    Key? key,
    required this.name,
    required this.beacon,
    required this.distance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: $name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Beacon: $beacon',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Distance: $distance',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
