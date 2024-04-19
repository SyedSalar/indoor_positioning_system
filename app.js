const mqtt = require('mqtt');
const visualizer = require('./visualizer');

const options = {
    host: 'fc0a35552030452d99489f74b27e1ebf.s1.eu.hivemq.cloud',
    port: 8883,
    protocol: 'mqtts',
    username: 'ESP32UWB',
    password: 'Alphaticesp32uwb'
};

const topic = 'tag1';

const client = mqtt.connect(options);

client.on('connect', function () {
    console.log('Connected to HiveMQ Cloud');
    client.subscribe(topic);
});

client.on('message', function (topic, message) {
    // This function is called every time a message is received
    console.log('Received message:', topic, message.toString());
    // Process the received message and send data to visualizer
    visualizer.updateTagPosition(JSON.parse(message.toString()));
});
