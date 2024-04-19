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
  MQTTClientWrapper newclient = new MQTTClientWrapper();
  newclient.prepareMqttClient();
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
    client.keepAlivePeriod = 100;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.autoReconnect = true;
    client.onDisconnected = _onDisconnected;
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
      Map<String, dynamic> data = json.decode(receivedMessage);

      // Send data to API
      _sendDataToAPI(data);
    });
  }

  void _sendDataToAPI(data) async {
    // Convert the data to JSON
    String jsonData = jsonEncode(data);

    // Set up your API endpoint
    Uri url = Uri.parse('http://localhost:5000/post_gps_data');

    try {
      // Send a POST request to your API
      http.Response response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonData,
      );

      // Check the response
      if (response.statusCode == 200) {
        print('Data sent to API successfully');
      } else {
        print('Failed to send data to API. Status code: ${response.body}');
      }
    } catch (e) {
      print('Error sending data to API: $e');
    }
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
  }

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

              Positioned(top: 120, child: IframeScreen())
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel the timer to avoid memory leaks
    _timer.cancel();
    super.dispose();
  }
}
