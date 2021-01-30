import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:geolocator/geolocator.dart';

const dbSchemaColumns = [
  'longitude numeric',
  'latitude numeric',
  'timestamp integer',
  'accuracy numeric',
  'altitude numeric',
  'floor integer'
      'heading numeric',
  'speed numeric',
  'speed_accuracy numeric'
];

// https://github.com/flutter/website/issues/2774
// Hi, if you like to make an unified database instance for the whole application, I suggest this way:
Future<Database> database() async {
  return openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'cattracks_database.db'),

    // When the database is first created, create a table to store cats.
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE IF NOT EXISTS cattracks (id INTEGER PRIMARY KEY," +
            dbSchemaColumns.join(", ") +
            ")",
      );
    },

    // [onConfigure] is the first callback invoked when opening the database. It allows you to perform database initialization such as enabling foreign keys or write-ahead logging
    onConfigure: (db) {
      return rmrfDb();
    },

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );
}

Future<void> rmrfDb() async {
  final Database db = await database();
  return db.execute("DROP TABLE IF EXISTS cattracks");
}

Future<void> insertTrack(Position position) async {
  final Database db = await database();
  final Map<String, dynamic> m = position.toJson();

  // App-specific key/value demands.
  if (!m.containsKey('timestamp') || m['timestamp'] == null) {
    return;
  }

  // App-specific mutations.
  m['timestamp'] = m['timestamp'] / 1000;
  m.remove('is_mocked');

  await db.insert(
    'cattracks',
    m,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
