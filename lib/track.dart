import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:geojson_vi/geojson_vi.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
// import 'config.dart' as config;

const _cDatabaseName = 'cattracks_database.db';
const _cTableName = "cattracks";
const dbSchemaColumns = [
  'uuid text',
  'time text',
  'timestamp integer UNIQUE',
  'accuracy real',
  'latitude real',
  'longitude real',
  'speed real',
  'speed_accuracy real',
  'heading real',
  'heading_accuracy real',
  'altitude real',
  'altitude_accuracy real',
  'odometer real',
  'activity_confidence integer',
  'activity_type text',
  'battery_level real',
  'battery_is_charging integer',
  'distance real',
  'trip_started text',
  'trip_started_timestamp integer',
  'is_moving integer',
  'event text',
  'image_file_path text',
  'uploaded integer',
  'barometer real',
  'lightmeter real',
  'ambient_temp real',
  'humidity real',
  'accelerometer_x real',
  'accelerometer_y real',
  'accelerometer_z real',
  'user_accelerometer_x real',
  'user_accelerometer_y real',
  'user_accelerometer_z real',
  'gyroscope_x real',
  'gyroscope_y real',
  'gyroscope_z real',
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

class AppPoint {
  final DateTime time;
  final int timestamp;
  final double accuracy;
  final double latitude;
  final double longitude;
  final double speed;
  final double speed_accuracy;
  final double heading;
  final double heading_accuracy;
  final double altitude;
  final double altitude_accuracy;
  final double odometer;
  final int activity_confidence;
  final String activity_type;
  final double battery_level;
  final bool battery_is_charging;
  final String event;
  final bool isMoving;

  int uploaded;

  double distance;
  DateTime _tripStarted;
  int _tripStartedTimestamp;

  set tripStarted(DateTime start) {
    _tripStarted = start;
    if (start != null) {
      _tripStartedTimestamp = _tripStarted.millisecondsSinceEpoch ~/ 1000;
    }
  }

  DateTime get tripStarted {
    return _tripStarted;
  }

  int get tripStartedTimestamp {
    return _tripStartedTimestamp;
  }

  double barometer;
  double lightmeter;
  double ambient_temp;
  double humidity;

  double accelerometer_x;
  double accelerometer_y;
  double accelerometer_z;
  double user_accelerometer_x;
  double user_accelerometer_y;
  double user_accelerometer_z;
  double gyroscope_x;
  double gyroscope_y;
  double gyroscope_z;

  String _uuid;
  String _imgB64;
  String _image_file_path;

  String get uuid {
    return _uuid;
  }

  set uuid(String uuid) {
    this._uuid = uuid;
  }

  String get image_file_path {
    return _image_file_path;
  }

  set image_file_path(String path) {
    this._image_file_path = path;
  }

  String get imgB64 {
    return _imgB64;
  }

  set imgB64(String i) {
    this._imgB64 = i;
  }

  bool isUploaded() {
    return this.uploaded != null && this.uploaded != 0;
  }

  AppPoint({
    this.time,
    this.timestamp,
    this.accuracy,
    this.latitude,
    this.longitude,
    this.speed,
    this.speed_accuracy,
    this.heading,
    this.heading_accuracy,
    this.altitude,
    this.altitude_accuracy,
    this.odometer,
    this.activity_confidence,
    this.activity_type,
    this.battery_level,
    this.battery_is_charging,
    this.isMoving,
    this.event,
    this.uploaded,
  });

  // toMap creates a dynamic map for persistence.
  Map<String, dynamic> toMap() {
    /*
    'uuid': uuid,
    'name': name,
    'version': version,
    'tripStarted': tripStarted,
    'time': time.toUtc().toIso8601String(),
    'timestamp': timestamp,
    'lat': latitude.toPrecision(9),
    'long': longitude.toPrecision(9),
    'accuracy': accuracy.toPrecision(2),
    'speed': speed.toPrecision(2),
    'speed_accuracy': speed_accuracy.toPrecision(2),
    'heading': heading.toPrecision(0),
    'heading_accuracy': heading_accuracy.toPrecision(1),
    'elevation': altitude.toPrecision(2),
    'vAccuracy': altitude_accuracy.toPrecision(1),
    'notes': notesString,
    */
    // print('apppoint -> toMap: event=${event}');
    return {
      'time': time.toUtc().toIso8601String(),
      'timestamp': timestamp,
      'accuracy': accuracy?.toPrecision(2),
      'latitude': latitude?.toPrecision(9),
      'longitude': longitude?.toPrecision(9),
      'speed': speed?.toPrecision(2),
      'speed_accuracy': speed_accuracy?.toPrecision(2),
      'heading': heading?.toPrecision(0),
      'heading_accuracy': heading_accuracy?.toPrecision(0),
      'altitude': altitude?.toPrecision(2),
      'altitude_accuracy': altitude_accuracy?.toPrecision(1),
      'odometer': odometer?.floorToDouble(),
      'activity_confidence': activity_confidence,
      'activity_type': activity_type,
      'battery_level': battery_level?.toPrecision(2),
      'battery_is_charging': battery_is_charging ? 1 : 0,
      'distance': distance?.floorToDouble(),
      'trip_started': _tripStarted?.toUtc()?.toIso8601String(),
      'trip_started_timestamp': _tripStartedTimestamp,
      'is_moving': isMoving ? 1 : 0,
      'event': event,
      'image_file_path': image_file_path,
      // 'uploaded': uploaded,

      'barometer': barometer?.toPrecision(2),
      'lightmeter': lightmeter?.toPrecision(2),
      'ambient_temp': ambient_temp?.toPrecision(2),
      'humidity': humidity?.toPrecision(2),

      'accelerometer_x': accelerometer_x?.toPrecision(2),
      'accelerometer_y': accelerometer_y?.toPrecision(2),
      'accelerometer_z': accelerometer_z?.toPrecision(2),
      'user_accelerometer_x': user_accelerometer_x?.toPrecision(2),
      'user_accelerometer_y': user_accelerometer_y?.toPrecision(2),
      'user_accelerometer_z': user_accelerometer_z?.toPrecision(2),
      'gyroscope_x': gyroscope_x?.toPrecision(2),
      'gyroscope_y': gyroscope_y?.toPrecision(2),
      'gyroscope_z': gyroscope_z?.toPrecision(2),
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
    if (!appMap.containsKey('time')) {
      throw ArgumentError.value(appMap, 'appMap',
          'The supplied map doesn\'t contain the mandatory key `time`.');
    }

    // print('apppoint <- fromMap: event=${appMap["event"]}');
    var ap = AppPoint(
      timestamp: appMap['timestamp'],
      time: DateTime.parse(appMap['time']),
      latitude: appMap['latitude'],
      longitude: appMap['longitude'],
      accuracy: appMap['accuracy'] ?? -1.0,
      altitude: appMap['altitude'] ?? 0.0,
      altitude_accuracy: appMap['altitude_accuracy'] ?? -1.0,
      heading: appMap['heading'] ?? 0.0,
      heading_accuracy: appMap['heading_accuracy'] ?? -1.0,
      speed: appMap['speed'] ?? 0.0,
      speed_accuracy: appMap['speed_accuracy'] ?? -1.0,
      odometer: appMap['odometer'] ?? 0.0,
      activity_confidence: appMap['activity_confidence'] ?? 0.0,
      activity_type: appMap['activity_type'] ?? "Unknown",
      battery_level: appMap['battery_level'] ?? -1.0,
      battery_is_charging: appMap['battery_is_charging'] == 1 ? true : false,
      isMoving: appMap['is_moving'] == 1,
      event: appMap['event'] ?? "",
      uploaded: appMap['uploaded'] ?? 0,
    );

    if (appMap['image_file_path'] != null && appMap['image_file_path'] != "") {
      ap.image_file_path = appMap['image_file_path'].toString();
    }

    ap.distance = appMap['distance'] ?? 0.0;

    var tripStart = appMap['trip_started'] != null
        ? DateTime.parse(appMap['trip_started'])
        : null;
    ap.tripStarted = tripStart;

    ap.barometer = appMap['barometer'];
    ap.lightmeter = appMap['lightmeter'];
    ap.ambient_temp = appMap['ambient_temp'];
    ap.humidity = appMap['humidity'];

    ap.accelerometer_x = appMap['accelerometer_x'];
    ap.accelerometer_y = appMap['accelerometer_y'];
    ap.accelerometer_z = appMap['accelerometer_z'];
    ap.user_accelerometer_x = appMap['user_accelerometer_x'];
    ap.user_accelerometer_y = appMap['user_accelerometer_y'];
    ap.user_accelerometer_z = appMap['user_accelerometer_z'];
    ap.gyroscope_x = appMap['gyroscope_x'];
    ap.gyroscope_y = appMap['gyroscope_y'];
    ap.gyroscope_z = appMap['gyroscope_z'];

    return ap;
  }

  static AppPoint fromLocationProvider(bg.Location location) {
    if (location.timestamp == "") {
      throw ArgumentError.value(location, 'location',
          'The supplied location doesn\'t contain the mandatory key `timestamp`.');
    }
    if (location.coords == null || location.coords.latitude == null) {
      throw ArgumentError.value(location, 'location',
          'The supplied location doesn\'t contain the mandatory key `coords.latitude`.');
    }
    if (location.coords == null || location.coords.longitude == null) {
      throw ArgumentError.value(location, 'location',
          'The supplied location doesn\'t contain the mandatory key `coords.longitude`.');
    }

    final DateTime dt = DateTime.parse(location.timestamp);

    // print('apppoint -> fromLocationProvider: event=${location.event}');

    return new AppPoint(
      timestamp: dt.millisecondsSinceEpoch ~/ 1000,
      time: dt,
      latitude: location.coords.latitude,
      longitude: location.coords.longitude,
      accuracy: location.coords.accuracy,
      altitude: location.coords.altitude,
      altitude_accuracy: location.coords.altitudeAccuracy,
      heading: location.coords.heading,
      heading_accuracy: location.coords.headingAccuracy,
      speed: location.coords.speed,
      speed_accuracy: location.coords.speedAccuracy,
      odometer: location.odometer,
      activity_confidence: location.activity.confidence,
      activity_type: location.activity.type,
      battery_level: location.battery.level,
      battery_is_charging: location.battery.isCharging,
      event: location.event,
      isMoving: location.isMoving,
      uploaded: 0,
    );
  }

  Future<GeoJSONFeature> toGeoJSONFeature({
    String uuid = "",
    String name = "",
    String version = "",
  }) async {
    var feat = GeoJSONFeature(GeoJSONPoint([longitude, latitude]), properties: {
      /*
        	props["UUID"] = trackPointCurrent.Uuid
          props["Name"] = trackPointCurrent.Name
          props["Time"] = trackPointCurrent.Time
          props["UnixTime"] = trackPointCurrent.Time.Unix()
          props["Version"] = trackPointCurrent.Version
          props["Speed"] = toFixed(trackPointCurrent.Speed, 3)
          props["Elevation"] = toFixed(trackPointCurrent.Elevation, 2)
          props["Heading"] = toFixed(trackPointCurrent.Heading, 1)
          props["Accuracy"] = toFixed(trackPointCurrent.Accuracy, 2)

          	if ns.HasValidVisit() {
			// TODO: ok to use mappy sub interface here?
			props["Visit"] = ns.Visit
		}

		if trackPointCurrent.HeartRate == 0 {
			if i := ns.HeartRateI(); i > 0 {
				props["HeartRate"] = toFixed(i, 2)
			}
		}

		// these properties might exist in the track, but we haven't been dumping them to json,
		// they're not deal breakers, but nice to have
		if ns.NumberOfSteps > 0 {
			props["NumberOfSteps"] = ns.NumberOfSteps
		}
		if ns.AverageActivePace > 0 {
			props["AverageActivePace"] = toFixed(ns.AverageActivePace, 2)
		}
		if ns.CurrentPace > 0 {
			props["CurrentPace"] = toFixed(ns.CurrentPace, 2)
		}
		if ns.CurrentCadence > 0 {
			props["CurrentCadence"] = toFixed(ns.CurrentCadence, 2)
		}
		if ns.CustomNote != "" {
			props["CustomNote"] = ns.CustomNote
		}
		if ns.FloorsAscended > 0 {
			props["FloorsAscended"] = ns.FloorsAscended
		}
		if ns.FloorsDescended > 0 {
			props["FloorsDescended"] = ns.FloorsDescended
		}
		if !ns.CurrentTripStart.IsZero() {
			props["CurrentTripStart"] = ns.CurrentTripStart
		}
		if ns.Distance > 0 {
			props["Distance"] = toFixed(ns.Distance, 2)
		}

		if ns.Lightmeter > 0 {
			props["Lightmeter"] = toFixed(ns.Lightmeter, 2)
		}
		if ns.AmbientTemp > 0 {
			props["AmbientTemp"] = toFixed(ns.AmbientTemp, 2)
		}
		if ns.Humidity > 0 {
			props["Humidity"] = toFixed(ns.Humidity, 2)
		}
		if v := ns.Accelerometer.X; v != nil {
			props["AccelerometerX"] = *v
		}
		if v := ns.Accelerometer.Y; v != nil {
			props["AccelerometerY"] = *v
		}
		if v := ns.Accelerometer.Z; v != nil {
			props["AccelerometerZ"] = *v
		}
		if v := ns.UserAccelerometer.X; v != nil {
			props["UserAccelerometerX"] = *v
		}
		if v := ns.UserAccelerometer.Y; v != nil {
			props["UserAccelerometerY"] = *v
		}
		if v := ns.UserAccelerometer.Z; v != nil {
			props["UserAccelerometerZ"] = *v
		}
		if v := ns.Gyroscope.X; v != nil {
			props["GyroscopeX"] = *v
		}
		if v := ns.Gyroscope.Y; v != nil {
			props["GyroscopeY"] = *v
		}
		if v := ns.Gyroscope.Z; v != nil {
			props["GyroscopeZ"] = *v
		}
		if v := ns.BatteryStatus; v != "" {
			bs := BatteryStatus{}
			if err := json.Unmarshal([]byte(v), &bs); err == nil {
				props["BatteryStatus"] = bs.Status
				props["BatteryLevel"] = toFixed(bs.Level, 2)
			}
		}
		if v := ns.NetworkInfo; v != "" {
			props["NetworkInfo"] = v
		}
         */
      'UUID': uuid,
      'Name': name,
      'Time': time.toUtc().toIso8601String(),
      'UnixTime': time.millisecondsSinceEpoch / 1000 ~/ 1,
      'Version': version,
      'Speed': speed.toPrecision(2),
      'Elevation': altitude.toPrecision(2),
      'Heading': heading.toPrecision(0),
      'Accuracy': accuracy.toPrecision(2),
      'vAccuracy': altitude_accuracy.toPrecision(0),
      'speed_accuracy': speed_accuracy.toPrecision(1),
      'heading_accuracy': heading_accuracy.toPrecision(0),
      'Activity': activityTypeApp(activity_type),
      'ActivityConfidence': activity_confidence,
      'BatteryLevel': battery_level.toPrecision(2),
      'BatteryStatus': battery_is_charging
          ? (battery_level == 1 ? 'full' : 'charging')
          : 'unplugged',
      'CurrentTripStart': tripStarted?.toUtc()?.toIso8601String(),
      'NumberOfSteps': odometer.toInt(),
      'Pressure': barometer?.toPrecision(1),
      'Lightmeter': lightmeter?.toPrecision(1),
      'AmbientTemp': ambient_temp?.toPrecision(1),
      'Distance': distance.toPrecision(2),
      'AccelerometerX': accelerometer_x?.toPrecision(2),
      'AccelerometerY': accelerometer_y?.toPrecision(2),
      'AccelerometerZ': accelerometer_z?.toPrecision(2),
      'UserAccelerometerX': user_accelerometer_x?.toPrecision(2),
      'UserAccelerometerY': user_accelerometer_y?.toPrecision(2),
      'UserAccelerometerZ': user_accelerometer_z?.toPrecision(2),
      'GyroscopeX': gyroscope_x?.toPrecision(2),
      'GyroscopeY': gyroscope_y?.toPrecision(2),
      'GyroscopeZ': gyroscope_z?.toPrecision(2),
    });

    if (image_file_path != null && image_file_path != '') {
      // Add the snap to the cat track.
      var encoded = base64Encode(File(image_file_path).readAsBytesSync());
      // print('ENCODED image as base64: ${encoded}');
      feat.properties['imgb64'] = encoded;
    }

    return feat;
  }

  // toCattrackJSON creates a dynamic map for JSON (push).
  Future<Map<String, dynamic>> toCattrackJSON({
    String uuid = "",
    String name = "",
    String version = "",
  }) async {
    /*
    type TrackPoint struct {
      Uuid       string    `json:"uuid"`
      PushToken  string    `json:"pushToken"`
      Version    string    `json:"version"`
      ID         int64     `json:"id"` //either bolt auto id or unixnano //think nano is better cuz can check for dupery
      Name       string    `json:"name"`
      Lat        float64   `json:"lat"`
      Lng        float64   `json:"long"`
      Accuracy   float64   `json:"accuracy"`  // horizontal, in meters
      VAccuracy  float64   `json:"vAccuracy"` // vertical, in meteres
      Elevation  float64   `json:"elevation"` //in meters
      Speed      float64   `json:"speed"`     //in kilometers per hour
      Tilt       float64   `json:"tilt"`      //degrees?
      Heading    float64   `json:"heading"`   //in degrees
      HeartRate  float64   `json:"heartrate"` // bpm
      Time       time.Time `json:"time"`
      Floor      int       `json:"floor"` // building floor if available
      Notes      string    `json:"notes"` //special events of the day
      COVerified bool      `json:"COVerified"`
      RemoteAddr string    `json:"remoteaddr"`
    }
    */
    // GOTCHA: Notes are strings.
    String notesString = "";
    String batteryStatusString = "";
    var batteryStatus = <String, dynamic>{
      'level': battery_level.toPrecision(2),
      'status': battery_is_charging
          ? (battery_level == 1 ? 'full' : 'charging')
          : 'unplugged', // full/unplugged
    };
    batteryStatusString = jsonEncode(batteryStatus);
    var notes = <String, dynamic>{
      'activity': activityTypeApp(activity_type),
      'activity_confidence': activity_confidence,
      'numberOfSteps': odometer.toInt(),
      'distance': distance,
      'batteryStatus': batteryStatusString,
      'currentTripStart': tripStarted?.toUtc()?.toIso8601String(),
      'pressure': barometer,
      'lightmeter': lightmeter,
      'ambient_temp': ambient_temp,
      'humidity': humidity,
      'accelerometer_x': accelerometer_x,
      'accelerometer_y': accelerometer_y,
      'accelerometer_z': accelerometer_z,
      'user_accelerometer_x': user_accelerometer_x,
      'user_accelerometer_y': user_accelerometer_y,
      'user_accelerometer_z': user_accelerometer_z,
      'gyroscope_x': gyroscope_x,
      'gyroscope_y': gyroscope_y,
      'gyroscope_z': gyroscope_z,
    };
    if (_tripStarted != null) {
      notes['currentTripStart'] = _tripStarted.toUtc().toIso8601String();
    }
    if (image_file_path != null && image_file_path != '') {
      // Add the snap to the cat track.
      var encoded = base64Encode(File(image_file_path).readAsBytesSync());
      // print('ENCODED image as base64: ${encoded}');
      notes['imgb64'] = encoded;
    }
    // if (imgB64 != null && imgB64 != "") {
    //   notes['imgb64'] = imgB64;
    // }
    notesString = jsonEncode(notes);
    return {
      'uuid': uuid,
      'name': name,
      'version': version,
      'time': time.toUtc().toIso8601String(),
      'timestamp': timestamp,
      'lat': latitude.toPrecision(9),
      'long': longitude.toPrecision(9),
      'accuracy': accuracy.toPrecision(2),
      'speed': speed.toPrecision(2),
      'speed_accuracy': speed_accuracy.toPrecision(2),
      'heading': heading.toPrecision(0),
      'heading_accuracy': heading_accuracy.toPrecision(1),
      'elevation': altitude.toPrecision(2),
      'notes': notesString,
    };
  }
}

extension Precision on double {
  double toPrecision(int fractionDigits) {
    if (this == null || this.isInfinite || this.isNaN || this == 0) return 0;
    double mod = pow(10, fractionDigits.toDouble());
    double out;
    try {
      out = ((this * mod).round().toDouble() / mod);
    } catch (err) {
      print('toPrecision failed: ${err.toString()} (value was: ${this}');
    }
    return out;
  }
}

String activityTypeApp(String original) {
  switch (original) {
    case 'still':
      return 'Stationary';
    case 'on_foot':
      return 'Walking';
    case 'walking':
      return 'Walking';
    case 'on_bicycle':
      return 'Bike';
    case 'running':
      return 'Running';
    case 'in_vehicle':
      return 'Automotive';
    default:
      return 'Unknown';
  }
}

Future<void> insertTrack(AppPoint point) async {
  final Database db = await database();
  await db.insert(
    _cTableName,
    point.toMap(),
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

Future<void> insertTrackForce(AppPoint point) async {
  final Database db = await database();
  await db.insert(
    _cTableName,
    point.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<int> countTracks({bool excludeUploaded: true}) async {
  final Database db = await database();
  var q = 'SELECT COUNT(*) FROM $_cTableName';
  if (excludeUploaded) {
    q += ' WHERE uploaded IS NULL';
  }
  return Sqflite.firstIntValue(await db.rawQuery(q));
}

Future<int> countSnaps() async {
  final Database db = await database();
  return Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $_cTableName WHERE image_file_path IS NOT NULL'));
}

Future<int> countPushed() async {
  final Database db = await database();
  return Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $_cTableName WHERE uploaded IS NOT NULL'));
}

deleteOldUploadedTracks({int age}) async {
  final Database db = await database();

  await db.delete(_cTableName,
      where: 'uploaded IS NOT NULL AND timestamp < ?',
      whereArgs: [(DateTime.now().millisecondsSinceEpoch / 1000 ~/ 1) - age]);
}

Future<int> lastId() async {
  final Database db = await database();
  var x = await db.rawQuery('SELECT id LIMIT 1 FROM $_cTableName');
  int lastID = Sqflite.firstIntValue(x);
  return lastID;
}

Future<List<AppPoint>> firstTracksWithLimit(int limit,
    {bool excludeUploaded: true}) async {
  final Database db = await database();

  String where;
  List<dynamic> whereargs;
  if (excludeUploaded) {
    where = 'uploaded IS NULL';
    whereargs = [];
  }

  final List<Map<String, dynamic>> maps = await db.query('$_cTableName',
      where: where, whereArgs: whereargs, limit: limit, orderBy: 'id ASC');

  return List.generate(maps.length, (i) {
    return AppPoint.fromMap(maps[i]);
  });
}

Future<List<AppPoint>> lastTracksWithLimit(int limit,
    {bool excludeUploaded: true}) async {
  final Database db = await database();
  String where;
  List<dynamic> whereargs;
  if (excludeUploaded) {
    where = 'uploaded IS NULL';
    whereargs = [];
  }
  final List<Map<String, dynamic>> maps = await db.query('$_cTableName',
      where: where, whereArgs: whereargs, limit: limit, orderBy: 'id DESC');

  return List.generate(maps.length, (i) {
    return AppPoint.fromMap(maps[i]);
  });
}

Future<void> setTracksUploadedByTimeRange(
    int first, int last, int uploaded) async {
  final Database db = await database();
  await db.update(_cTableName, {'uploaded': uploaded},
      where: 'timestamp >= ? AND timestamp <= ?', whereArgs: [first, last]);
}

Future<void> deleteTracksBeforeInclusive(int ts) async {
  final Database db = await database();
  await db.delete(_cTableName, where: 'timestamp <= ?', whereArgs: [ts]);
}

Future<List<AppPoint>> snaps() async {
  final Database db = await database();
  final List<Map<String, dynamic>> maps =
      await db.query('$_cTableName', where: 'image_file_path IS NOT NULL');
  return List.generate(maps.length, (i) {
    return AppPoint.fromMap(maps[i]);
  });
}

deleteSnap(AppPoint snap) async {
  final Database db = await database();
  await db.delete(_cTableName,
      where: 'image_file_path IS ?', whereArgs: [snap.image_file_path]);
  // Delete the original image file.
  File(snap.image_file_path).deleteSync();
}
