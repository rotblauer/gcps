import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:geolocator/geolocator.dart';

const _cDatabaseName = 'cattracks_database.db';
const _cTableName = "cattracks";
const dbSchemaColumns = [
  'odometer real',
  'activity_confidence integer',
  'activity_type string',
  'battery_level real',
  'battery_is_charging bool',
  'timestamp integer',
  'longitude real',
  'latitude real',
  'accuracy real',
  'altitude real',
  'altitude_accuracy real',
  'heading real',
  'heading_accuracy real',
  'speed real',
  'speed_accuracy real',
  'event string'
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
        // "DROP TABLE IF EXISTS $_cTableName;" +
        'CREATE TABLE IF NOT EXISTS $_cTableName (id INTEGER PRIMARY KEY,' +
            dbSchemaColumns.join(", ") +
            ")",
      );
    },

    // // [onConfigure] is the first callback invoked when opening the database. It allows you to perform database initialization such as enabling foreign keys or write-ahead logging
    // onConfigure: (db) {
    // },

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );
}

Future<void> resetDB() async {
  var p = join(await getDatabasesPath(), _cDatabaseName);
  if (await databaseExists(p)) return deleteDatabase(p);
}

Future<void> insertTrack(Position position) async {
  final Database db = await database();
  final Map<String, dynamic> m = position.toJson();

  // App-specific key/value demands.
  if (!m.containsKey('timestamp') || m['timestamp'] == null) {
    return;
  }

  // App-specific mutations.
  m.remove('is_mocked');

  await db.insert(
    _cTableName,
    m,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

abstract class AppPoint {
  final double accuracy;
  final double latitude;
  final double longitude;
  final double speed;
  final double speed_accuracy;
  final double heading;
  final double heading_accuracy;
  final double altitude;
  final double altitude_accuracy;

  AppPoint({
    this.accuracy,
    this.lat,
    this.lng,
    this.speed,
    this.speed_accuracy,
    this.heading,
    this.heading_accuracy,
    this.altitude,
    this.altitude_accuracy,
  });

  // toMap creates a dynamic map for persistence.
  Map<String, dynamic> toMap() {
    return {
      'accuracy': accuracy,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'speed_accuracy': speed_accuracy,
      'heading': heading,
      'heading_accuracy': heading_accuracy,
      'altitude': altitude,
      'altitude_accuracy': altitude_accuracy,
    };
  }

  /// Converts the supplied [Map] to an instance of the [Position] class.
  static AppPoint fromMap(dynamic message) {
    if (message == null) {
      return null;
    }

    final Map<dynamic, dynamic> appMap = message;

    if (!appMap.containsKey('latitude')) {
      throw ArgumentError.value(appMap, 'appMap',
          'The supplied map doesn\'t contain the mandatory key `latitude`.');
    }

    if (!appMap.containsKey('longitude')) {
      throw ArgumentError.value(appMap, 'appMap',
          'The supplied map doesn\'t contain the mandatory key `longitude`.');
    }

    final timestamp = appMap['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(appMap['timestamp'].toInt(),
            isUtc: true)
        : null;

    return AppPoint(
      latitude: appMap['latitude'],
      longitude: appMap['longitude'],
      timestamp: timestamp,
      altitude: appMap['altitude'] ?? 0.0,
      accuracy: appMap['accuracy'] ?? 0.0,
      heading: appMap['heading'] ?? 0.0,
      floor: appMap['floor'],
      speed: appMap['speed'] ?? 0.0,
      speedAccuracy: appMap['speed_accuracy'] ?? 0.0,
      isMocked: appMap['is_mocked'] ?? false,
    );
  }

  // toJSON creates a dynamic map for JSON (push).
  Map<String, dynamic> toJSON() {
    return {
      'accuracy': accuracy,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'speed_accuracy': speed_accuracy,
      'heading': heading,
      'heading_accuracy': heading_accuracy,
      'altitude': altitude,
      'altitude_accuracy': altitude_accuracy,
    };
  }
}

Future<int> countTracks() async {
  final Database db = await database();
  return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_cTableName'));
}

Future<int> lastId() async {
  final Database db = await database();
  var x = await db.rawQuery('SELECT id LIMIT 1 FROM $_cTableName');
  int lastID = Sqflite.firstIntValue(x);
  return lastID;
}

Future<List<Position>> firstTracksWithLimit(int limit) async {
  final Database db = await database();
  final List<Map<String, dynamic>> maps =
      await db.query('$_cTableName', limit: limit, orderBy: 'id ASC');

  return List.generate(maps.length, (i) {
    return Position.fromMap(maps[i]);
  });
}

Future<void> deleteTracksBeforeInclusive(int ts) async {
  final Database db = await database();
  await db.delete(_cTableName, where: 'timestamp <= ?', whereArgs: [ts]);
}
