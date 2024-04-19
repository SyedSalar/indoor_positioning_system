import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:indoor_positioning_system/components/MyDropdown.dart';
import 'package:indoor_positioning_system/constants.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:indoor_positioning_system/myIframe.dart';

import 'package:indoor_positioning_system/navigations/MainScreen.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';
// import 'package:webview_flutter/webview_flutter.dart';

main() {
  // Ensure that the platform is set for webview_flutter
  // MQTTClientWrapper newclient = new MQTTClientWrapper();
  // newclient.prepareMqttClient();
  runApp(const MyApp());
}

enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState { IDLE, SUBSCRIBED }

class MQTTClientWrapper {
  late MqttBrowserClient client;
  late String receivedMessage;

  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;

  // using async tasks, so the connection won't hinder the code flow
  void prepareMqttClient() async {
    _setupMqttClient();
    await _connectClient();
    _subscribeToTopic('gps_data');
  }

  // waiting for the connection, if an error occurs, print it and disconnect
  Future<void> _connectClient() async {
    try {
      print('client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect('ESP32UWB', 'Alphaticesp32uwb');
    } on Exception catch (e) {
      print('client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }

    // when connected, print a confirmation, else print an error
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print('client connected');
    } else {
      print(
          'ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }
  }

  void _setupMqttClient() {
    client = MqttBrowserClient.withPort(
        'wss://fc0a35552030452d99489f74b27e1ebf.s1.eu.hivemq.cloud:8884/mqtt',
        'ESP32UWB',
        8884);
    // the next 2 lines are necessary to connect with tls, which is used by HiveMQ Cloud
    // client.secure = true;
    // client.securityContext = SecurityContext.defaultContext;
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  void _subscribeToTopic(String topicName) {
    print('Subscribing to the $topicName topic');
    client.subscribe(topicName, MqttQos.atMostOnce);

    // print the message when it is received
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      receivedMessage =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('YOU GOT A NEW MESSAGE:');
      print(receivedMessage); // Print the received message
    });
  }

  String getReceivedMessage() {
    return receivedMessage;
  }

  void _publishMessage(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('Publishing message "$message" to topic ${'gps_data'}');
    client.publishMessage('gps_data', MqttQos.exactlyOnce, builder.payload!);
  }

  // callbacks for different events
  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

  void _onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was sucessful');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainScreen(),
    );
  }
}

class NodePositionForm extends StatefulWidget {
  @override
  _NodePositionFormState createState() => _NodePositionFormState();
}

class _NodePositionFormState extends State<NodePositionForm> {
  final List<String> positions = [
    'Top Left',
    'Top Right',
    'Bottom Left',
    'Bottom Right'
  ];
  String? positionAValue;
  String? positionBValue;
  String? positionCValue;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomDropdownButton2(
                hint: 'Beacon A Position',
                value: positionAValue,
                dropdownItems: positions,
                onChanged: (value) {
                  setState(() {
                    positionAValue = value;
                  });
                },
              ),
              SizedBox(
                height: defaultPadding,
              ),
              CustomDropdownButton2(
                hint: 'Beacon B Position',
                value: positionBValue,
                dropdownItems: positions,
                onChanged: (value) {
                  setState(() {
                    positionBValue = value;
                  });
                },
              ),
              SizedBox(
                height: defaultPadding,
              ),
              CustomDropdownButton2(
                hint: 'Beacon C Position',
                value: positionCValue,
                dropdownItems: positions,
                onChanged: (value) {
                  setState(() {
                    positionCValue = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Do something with the positions, e.g., navigate to the main screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => IndoorPositioningApp()),
                    );
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IndoorPositioningApp extends StatefulWidget {
  @override
  _IndoorPositioningAppState createState() => _IndoorPositioningAppState();
}

class _IndoorPositioningAppState extends State<IndoorPositioningApp> {
  String nodeName = ''; // Node near the person
  double distance = 0.0; // Distance from the person to the node
  double personPositionX = 0.0; // X-coordinate of person's position
  double personPositionY = 0.0; // Y-coordinate of person's position
  late Timer _timer;
  final Random _random = Random(); // Create an instance of the Random class
  String? connectedTo;
  String? area;
  @override
  void initState() {
    super.initState();

    // Set up a timer to update the person's position every 4 seconds
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      // updatePersonPosition();
      // mysqlConnect();
      // fetchData();
    });
  }

  // mysqlConnect() async {
  //   // Open a connection (testdb should already exist)
  //   final conn = await MySqlConnection.connect(ConnectionSettings(
  //       host: 'localhost',
  //       port: 3306,
  //       user: 'root',
  //       db: 'ips',
  //       password: 'test123'));

  //   // Query the database using a parameterized query
  //   var results = await conn.query(
  //       'select UID, ConnectedTo, C_RSSI, O_RSSI, distance from sensordata order by updatedAt DESC LIMIT 1');
  //   for (var row in results) {
  //     print(
  //         'UID: ${row[0]}, ConnectedTo: ${row[1]} C_RSSI: ${row[2]} ${row[3]} ${row[4]}');
  //     distance = extractNumber(row[2]);
  //     print(distance);
  //     connectedTo = row[1];
  //     area = row[4];
  //   }

  // Finally, close the connection
  //   await conn.close();
  // }

  // double extractNumber(String input) {
  //   RegExp regExp = RegExp(r'(-?\d+)');
  //   RegExpMatch? match = regExp.firstMatch(input);

  //   if (match != null) {
  //     String? numberString = match.group(0);
  //     return double.parse(numberString!).abs();
  //   } else {
  //     // Handle the case where no number is found
  //     return 0; // or throw an exception, return a default value, etc.
  //   }
  // }

  // // Function to update person's position
  // void updatePersonPosition() {
  //   // Simulate a changing distance randomly

  //   // Calculate person's position based on distance and node information
  //   // Update nodeName based on your database information

  //   // For example:
  //   // nodeName = 'A';

  //   // Calculate the position based on your specific logic
  //   // Here, we'll simply set X-coordinate based on distance and Y-coordinate based on a constant
  //   double x1 = 100;
  //   double y1 = connectedTo == 'BeaconD1'
  //       ? 130
  //       : connectedTo == 'BeaconD2'
  //           ? 130
  //           : 30;
  //   double x2Positive = x1 + sqrt(pow(distance, 2) - pow(0, 2));
  //   double y2Positive = y1 + sqrt(pow(distance, 2) - pow(x2Positive - x1, 2));
  //   print(x2Positive);
  //   print(y2Positive);
  //   setState(() {});
  //   personPositionX = area == 'immediate'
  //       ? x2Positive
  //       : area == 'near'
  //           ? x2Positive * 1.2
  //           : x2Positive * 1.3;
  //   distance * 20.0; // Adjust the multiplier based on your scale
  //   personPositionY = area == 'immediate'
  //       ? y2Positive
  //       : area == 'near'
  //           ? y2Positive * 1.2
  //           : y2Positive * 1.3; // Adjust as needed

  //   setState(() {
  //     // Update UI with the new position
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              // Render nodes or any other elements as needed
              Positioned(top: 10, left: 50, child: Text('Room 1')),
              Positioned(
                  top: 10,
                  right: 50,
                  child: ElevatedButton.icon(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(primaryColor)),
                      icon: Icon(
                        Icons.add,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NodePositionForm(),
                            ));
                      },
                      label: Text(
                        'Add Room',
                        style: TextStyle(color: Colors.black),
                      ))),
              // Positioned(
              //   top: 100,
              //   child: Image.asset('assets/dotted bg.png'),
              // ),
              Positioned(top: 120, child: IframeScreen())
              // Positioned(
              //   top: 130.0,
              //   left: 100.0,
              //   child: Column(
              //     children: [
              //       Image.asset(
              //         'assets/beacon.png',
              //         scale: 30,
              //       ),
              //       Text('Beacon A'),
              //     ],
              //   ),
              // ),
              // Positioned(
              //   top: 130.0,
              //   right: 100.0,
              //   child: Column(
              //     children: [
              //       Image.asset(
              //         'assets/beacon.png',
              //         scale: 30,
              //       ),
              //       Text('Beacon B'),
              //     ],
              //   ),
              // ),
              // Positioned(
              //   bottom: 30.0,
              //   left: 100.0,
              //   child: Column(
              //     children: [
              //       Image.asset(
              //         'assets/beacon.png',
              //         scale: 30,
              //       ),
              //       Text('Beacon C'),
              //     ],
              //   ),
              // ),
              // Positioned(
              //   bottom: 30.0,
              //   right: 100.0,
              //   child: Column(
              //     children: [
              //       Image.asset(
              //         'assets/beacon.png',
              //         scale: 30,
              //       ),
              //       Text('Beacon D'),
              //     ],
              //   ),
              // ),
              // // Render person's icon at the calculated position
              // Positioned(
              //   bottom: connectedTo == 'BeaconD1'
              //       ? null
              //       : connectedTo == 'BeaconD2'
              //           ? null
              //           : personPositionY,
              //   top: connectedTo == 'BeaconD1'
              //       ? personPositionY
              //       : connectedTo == 'BeaconD2'
              //           ? personPositionY
              //           : null,
              //   left: connectedTo == 'BeaconD1'
              //       ? personPositionX
              //       : connectedTo == 'BeaconD3'
              //           ? personPositionX
              //           : null,
              //   right: connectedTo == 'BeaconD1'
              //       ? null
              //       : connectedTo == 'BeaconD3'
              //           ? null
              //           : personPositionX,
              //   child: Image.asset(
              //     'assets/person.png',
              //     scale: 20,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // Future fetchData() async {
  //   // final baseUrl = 'http://alphatic.tech/ipsdash/fetch-esp-data.php';
  //   final baseUrl = 'http://192.168.1.39/ipsdash/fetch-esp-data.php';

  //   // Construct the URL with query parameters
  //   final url = Uri.parse(baseUrl);

  //   try {
  //     final response = await http.get(
  //       url,
  //     );

  //     if (response.statusCode == 200) {
  //       // Successful response
  //       final jsonData = jsonDecode(response.body);
  //       print(jsonData);
  //       final newData = Map<String, dynamic>.from(jsonData);
  //       distance = extractNumber(newData['C_RSSI']);
  //       print(distance);
  //       area = newData['distance'];
  //       print(area);
  //       connectedTo = newData['ConnectedTo'];
  //       print(connectedTo);
  //       // for (var row in newData) {
  //       //   print(
  //       //       'UID: ${row[0]}, ConnectedTo: ${row[1]} C_RSSI: ${row[2]} ${row[3]} ${row[4]}');
  //       //   distance = extractNumber(row[2]);
  //       //   print(distance);
  //       //   connectedTo = row[1];
  //       //   area = row[4];
  //       // }
  //     } else {
  //       // Request failed with an error
  //       print('API Request failed with status ${response.body}');
  //     }
  //   } catch (e) {
  //     // Handle exceptions, such as network errors or invalid URLs
  //     print('Error: $e');
  //   }
  // }

  @override
  void dispose() {
    // Cancel the timer to avoid memory leaks
    _timer.cancel();
    super.dispose();
  }
}
