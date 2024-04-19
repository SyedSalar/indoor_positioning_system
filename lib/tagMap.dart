// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:indoor_positioning_system/main.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

// import 'package:mqtt_client/mqtt_client.dart';

// class TagPosition extends StatefulWidget {
//   const TagPosition({
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<TagPosition> createState() => _TagPositionState();
// }

// class _TagPositionState extends State<TagPosition> {
//   late LatLng _currentLatLng;
//   final MapController mapController = MapController();
//   late MQTTClientWrapper _newClient;

//   @override
//   void initState() {
//     super.initState();
//     _newClient = MQTTClientWrapper();
//     _newClient.prepareMqttClient();
//     _subscribeToLocationUpdates();
//     _currentLatLng = LatLng(0, 0);
//   }

//   void _subscribeToLocationUpdates() {
//     _newClient.client.updates
//         ?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
//       final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
//       var message =
//           MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

//       // Parse the JSON string to a Dart Map
//       Map<String, dynamic> data = json.decode(message);

//       setState(() {
//         _currentLatLng = LatLng(data['latitude'], data['longitude']);
//       });
//     });
//   }

//   @override
//   void didUpdateWidget(TagPosition oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     _updateMapCenterAndZoom(_currentLatLng, 17);
//   }

//   void _updateMapCenterAndZoom(LatLng center, double zoom) {
//     // Animate to the new center and zoom
//     mapController.move(center, zoom);
//     _currentLatLng = center;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FlutterMap(
//       options: MapOptions(
//         initialCenter: _currentLatLng,
//         maxZoom: 17.0,
//       ),
//       mapController: mapController,
//       children: [
//         TileLayer(
//           urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//           subdomains: const ['a', 'b', 'c'],
//           tileProvider: CancellableNetworkTileProvider(),
//         ),
//         MarkerLayer(
//           markers: [
//             Marker(
//                 width: 80.0,
//                 height: 80.0,
//                 point: _currentLatLng,
//                 child: Icon(Icons.person)),
//           ],
//         ),
//       ],
//     );
//   }
// }

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

class TagPosition extends StatefulWidget {
  const TagPosition({Key? key}) : super(key: key);

  @override
  State<TagPosition> createState() => _TagPositionState();
}

class _TagPositionState extends State<TagPosition> {
  final MapController mapController = MapController();
  Map<String, LatLng> _devicePositions = {}; // Map to store device positions
  Map<String, Color> _deviceColors = {}; // Map to store device colors

  @override
  void initState() {
    super.initState();
    // Call the function to fetch GPS data when the widget initializes
    fetchGPSData();
  }

  Future<void> fetchGPSData() async {
    // Make an HTTP GET request to fetch GPS data
    final response =
        await http.get(Uri.parse('http://localhost:5000/get_gps_data'));

    if (response.statusCode == 200) {
      // Parse the JSON response
      final List<dynamic> jsonData = json.decode(response.body);

      // Update the device positions map with the retrieved data
      setState(() {
        _devicePositions.clear(); // Clear existing data
        for (final item in jsonData) {
          final String deviceId = item['name'];
          final double lat = double.parse(item['lat']);
          final double long = double.parse(item['long']);
          _devicePositions[deviceId] = LatLng(lat, long);
          _deviceColors[deviceId] = _generateRandomColor();
        }
      });
    } else {
      // Handle error or display a message
      print('Failed to fetch GPS data: ${response.statusCode}');
    }
  }

  Color _generateRandomColor() {
    Random random = Random();
    return Color.fromRGBO(
        random.nextInt(256), random.nextInt(256), random.nextInt(256), 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
          initialCenter: LatLng(0, 0), // Center the map at default coordinates
          maxZoom: 20.0,
          initialZoom: 2.0),
      mapController: mapController,
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          tileProvider: CancellableNetworkTileProvider(),
        ),
        MarkerLayer(
          markers: _devicePositions.entries.map((entry) {
            String deviceId = entry.key;
            print(deviceId);
            String displayName = '';
            if (deviceId == '1783') {
              displayName = 'Beacon3';
            } else if (deviceId == '1784') {
              displayName = 'Beacon4';
            } else if (deviceId == '1782') {
              displayName = 'Beacon2';
            } else if (deviceId == '1781') {
              displayName = 'Beacon1';
            } else if (deviceId == 'Tag1') {
              displayName = 'Tag1';
            } else if (deviceId == 'Tag2') {
              displayName = 'Tag2';
            }
            LatLng position = entry.value;
            Color color = _deviceColors[deviceId]!;

            // Create marker for each device position
            return Marker(
              width: 80.0,
              height: 80.0,
              point: position,
              child: Column(
                children: [
                  Text(displayName),
                  Icon(Icons.person, color: color),
                ],
              ),
              alignment: Alignment.topCenter,
              key: Key(
                  deviceId), // Use device ID as marker key to ensure uniqueness
            );
          }).toList(),
        ),
      ],
    );
  }
}
