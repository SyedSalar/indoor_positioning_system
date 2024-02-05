// import 'dart:async';

// import 'package:mysql1/mysql1.dart';

// Future main() async {
//   // Open a connection (testdb should already exist)
//   final conn = await MySqlConnection.connect(ConnectionSettings(
//       host: 'localhost',
//       port: 3306,
//       user: 'root',
//       db: 'ips',
//       password: 'root'));

//   // Query the database using a parameterized query
//   var results = await conn.query(
//       'select UID, ConnectedTo, C_RSSI, O_RSSI, distance from ips order by UID DESC LIMIT 2');
//   for (var row in results) {
//     print('Name: ${row[0]}, email: ${row[1]} age: ${row[2]}');
//   }

//   // Finally, close the connection
//   await conn.close();
// }
