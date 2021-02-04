import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert'; // jsonEncode
// import 'package:english_words/english_words.dart' as ew;
import 'package:flutter/services.dart';
import 'package:gcps/haversine.dart/lib/src/haversine_base.dart';

import 'package:ip_geolocation_api/ip_geolocation_api.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:flutter/widgets.dart';
import 'package:device_info/device_info.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
// import 'package:workmanager/workmanager.dart';
// import 'package:gallery_saver/gallery_saver.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

// import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

import 'track.dart';
import 'prefs.dart' as prefs;
import 'config.dart';

void main() {
  // Avoid errors cased by flutter upgrade
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();

  // Development: reset (rm -rf db) if exists.
  // resetDB();

  // Run app.
  runApp(MyApp());
}

Future<String> _getId() async {
  var deviceInfo = DeviceInfoPlugin();
  if (Platform.isIOS) {
    // import 'dart:io'
    var iosDeviceInfo = await deviceInfo.iosInfo;
    return iosDeviceInfo.identifierForVendor; // unique ID on iOS
  } else {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    return androidDeviceInfo.androidId; // unique ID on Android
  }
}

Future<String> _getName() async {
  var deviceInfo = DeviceInfoPlugin();
  if (Platform.isIOS) {
    // import 'dart:io'
    var iosDeviceInfo = await deviceInfo.iosInfo;
    return iosDeviceInfo.name; // user-given name
  } else {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    if (!androidDeviceInfo.isPhysicalDevice) {
      return 'sofia3585 moto g power';
    }
    return '${androidDeviceInfo.board}-${androidDeviceInfo.model.split(" ")[0]}-${androidDeviceInfo.androidId.substring(0, 4)}'; // unique ID on Android
  }
}

/// _buildSnackBar builds the app flavored snackbars for alertable status updates.
SnackBar _buildSnackBar(Widget content, {MaterialColor backgroundColor}) {
  return SnackBar(
      content: content,
      elevation: 1,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(8.0),
      backgroundColor: backgroundColor ?? Colors.lightBlue);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.deepOrange,
        statusBarColor: Colors.deepOrange));
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'global cat positioning system',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        brightness: Brightness.light,
        primarySwatch: Colors.amber,
        backgroundColor: Colors.limeAccent,
        canvasColor: Colors.deepOrange,
      ),
      home: MyHomePage(title: 'Global Cat Positioning System'),
      showPerformanceOverlay: false,
      debugShowMaterialGrid: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class InfoDisplay extends StatelessWidget {
  InfoDisplay({this.keyname, this.value, this.options});

  final String keyname;
  final dynamic value;
  Map<String, dynamic> options;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(8),
        // color: Colors.green[500],
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$keyname',
                style: Theme.of(context).textTheme.overline,
              ),
              Text(
                '$value',
                style: options != null && options.containsKey('t2.font')
                    ? options['t2.font']
                    : Theme.of(context).textTheme.headline4,
                maxLines: 2,
              ),
            ]));
  }
}

class MovingAverager {
  final int max;
  List<double> vals;

  MovingAverager({this.max});

  void push(double value) {
    vals.add(value);
    if (vals.length > max) {
      vals.removeAt(0);
    }
  }

  double avg() {
    double out = 0;
    vals.forEach((element) => out += element);
    return out / vals.length.toDouble();
  }
}

class DistanceTracker {
  double distance = 0;
  double _last_lon;
  double _last_lat;

  final bool filterStill;

  DistanceTracker({this.filterStill});

  double add({double lon, double lat, bool isMoving}) {
    print("lon=" +
        lon.toString() +
        " lat=" +
        lat.toString() +
        " isMoving=" +
        isMoving.toString());

    if (!filterStill || isMoving) {
      distance += Haversine.fromDegrees(
              latitude1: _last_lat ?? lat,
              longitude1: _last_lon ?? lon,
              latitude2: lat,
              longitude2: lon)
          .distance();
    }
    _last_lon = lon;
    _last_lat = lat;
    return distance;
  }
}

String secondsToPrettyDuration(double seconds) {
  int secondsRound = seconds ~/ 1;
  int hours = secondsRound ~/ 3600;
  secondsRound = secondsRound % 3600;
  int minutes = secondsRound ~/ 60;
  secondsRound = secondsRound % 60;
  String out = "";
  hours > 0 ? out += hours.toString() + 'h ' : null;
  minutes > 0 ? out += minutes.toString() + 'm ' : null;
  out += secondsRound.toString() + 's';
  return out;
}

class _MyHomePageState extends State<MyHomePage> {
  String _appErrorStatus = "";
  String _deviceUUID = "";
  String _deviceName = "";
  String _deviceAppVersion = "";
  bool _isPushing = false;

  DistanceTracker _distanceTracker = DistanceTracker(filterStill: true);

  // int _counter = 0;
  // String geolocation_text = '<ip.somewhere>';
  // String geolocation_api_text = '<api.somewhere>';
  // String geolocation_api_stream_text = '<apistream.somewhere>';
  GeolocationData geolocationData;
  DateTime _appStarted;

  String _connectionStatus = 'Unknown';
  ConnectivityResult _connectionResult;
  final Connectivity _connectivity = Connectivity();

  // Subscriptions
  // StreamSubscription<Position> positionStream;
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Display location information
  bg.Location glocation = new bg.Location({
    'timestamp': DateTime.now().toIso8601String(),
    'isMoving': false,
    'uuid': 'abc',
    'odometer': 42,
    'coords': {
      'latitude': 42.0,
      'longitude': -69.0,
      'accuracy': 42.0,
      'altitude': 69.0,
      'speed': 69.0,
      'heading': 69.0,
    },
    'battery': {
      'level': 1.0,
      'status': 'full',
    },
    'activity': {
      'type': 'still',
      'confidence': 9000,
    },
  });

  // Display data history information
  int _countStored = 0;
  int _countSnaps = 0;
  int _countPushed = 0;
  int _pushEvery = 100;

  // Future<void> initPrefs() async {
  //   var v = await SharedPreferencesHelper().getPushBatchSize();
  //   await SharedPreferencesHelper().setPushBatchSize(v);
  //   v = await SharedPreferencesHelper().getPushInterval();
  //   await SharedPreferencesHelper().setPushInterval(v);
  // }

  List<CameraDescription> cameras;
  CameraDescription firstCamera;

  // Camera
  Future<void> _initCameras() async {
    // Obtain a list of the available cameras on the device.
    cameras = await availableCameras();

    // Get a specific camera from the list of available cameras.
    firstCamera = cameras.first;
  }

  // void _incrementCounter() {
  //   setState(() {
  //     // This call to setState tells the Flutter framework that something has
  //     // changed in this State, which causes it to rerun the build method below
  //     // so that the display can reflect the updated values. If we changed
  //     // _counter without calling setState(), then the build method would not be
  //     // called again, and so nothing would appear to happen.
  //     _counter++;
  //   });
  // }

  // static const fetchLocationBackground = "fetchLocationBackground";
  // void callbackDispatcher() {
  //   Workmanager.executeTask((task, inputData) async {
  //     switch (task) {
  //       case fetchLocationBackground:
  //         Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
  //             .then((Position pos) {
  //           _handleStreamLocationUpdate(pos);
  //         }).catchError((err) {
  //           print(err.toString());
  //         });

  //         break;
  //     }
  //     return Future.value(true);
  //   });
  // }

  /// Receives all events from BackgroundGeolocation while app is terminated:
  void headlessTask(bg.HeadlessEvent headlessEvent) async {
    print('[HeadlessTask]: ${headlessEvent}');

    // Implement a `case` for only those events you're interested in.
    switch (headlessEvent.name) {
      // case bg.Event.TERMINATE:
      //   bg.State state = headlessEvent.event;
      //   print('- State: ${state}');
      //   break;
      // case bg.Event.HEARTBEAT:
      //   bg.HeartbeatEvent event = headlessEvent.event;
      //   print('- HeartbeatEvent: ${event}');
      //   break;
      case bg.Event.LOCATION:
        bg.Location location = headlessEvent.event;
        print('- Location: ${location}');
        _handleStreamLocationUpdate(location);
        break;
      case bg.Event.MOTIONCHANGE:
        bg.Location location = headlessEvent.event;
        print('- Location: ${location}');
        _handleStreamLocationUpdate(location);
        break;
      // case bg.Event.GEOFENCE:
      //   bg.GeofenceEvent geofenceEvent = headlessEvent.event;
      //   print('- GeofenceEvent: ${geofenceEvent}');
      //   break;
      // case bg.Event.GEOFENCESCHANGE:
      //   bg.GeofencesChangeEvent event = headlessEvent.event;
      //   print('- GeofencesChangeEvent: ${event}');
      //   break;
      // case bg.Event.SCHEDULE:
      //   bg.State state = headlessEvent.event;
      //   print('- State: ${state}');
      //   break;
      // case bg.Event.ACTIVITYCHANGE:
      //   bg.ActivityChangeEvent event = headlessEvent.event;
      //   print('ActivityChangeEvent: ${event}');
      //   break;
      // case bg.Event.HTTP:
      //   bg.HttpEvent response = headlessEvent.event;
      //   print('HttpEvent: ${response}');
      //   break;
      // case bg.Event.POWERSAVECHANGE:
      //   bool enabled = headlessEvent.event;
      //   print('ProviderChangeEvent: ${enabled}');
      //   break;
      // case bg.Event.CONNECTIVITYCHANGE:
      //   bg.ConnectivityChangeEvent event = headlessEvent.event;
      //   print('ConnectivityChangeEvent: ${event}');
      //   break;
      // case bg.Event.ENABLEDCHANGE:
      //   bool enabled = headlessEvent.event;
      //   print('EnabledChangeEvent: ${enabled}');
      //   break;
    }
  }

  @override
  void initState() {
    _appStarted = DateTime.now().toUtc();
    super.initState();
    // this.getIp();
    _getId().then((value) {
      _deviceUUID = value;
      print("uuid: " + value);
    });
    _getName().then((value) {
      _deviceName = value;
      print("device name: " + value);
    });

    getAppVersion().then((value) {
      _deviceAppVersion = value;
      print("device app version: " + value);
    });
    // initPrefs();
    // this._startStream();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    _initCameras();

    // Workmanager.initialize(callbackDispatcher, isInDebugMode: true);
    // /*
    // fuck
    //  // When no frequency is provided the default 15 minutes is set.
    // // Minimum frequency is 15 min. Android will automatically change your frequency to 15 min if you have configured a lower frequency.
    // */
    // Workmanager.registerPeriodicTask("1", fetchLocationBackground,
    //     frequency: Duration(seconds: 1));

    ////
    // 1.  Listen to events (See docs for all 12 available events).
    // https://pub.dev/documentation/flutter_background_geolocation/latest/flt_background_geolocation/BackgroundGeolocation-class.html
    /*
    onLocation	Fired with each recorded Location
    onMotionChange	Fired when the plugin changes state between moving / stationary
    onHttp	Fired with each HTTP response from your server. (see Config.url).

    onActivityChange	Fired with each change in device motion-activity.
    Subscribe to changes in motion activity.

    Your callback will be executed each time the activity-recognition system receives an event (still, on_foot, in_vehicle, on_bicycle, running).

    onProviderChange	Fired after changes to device location-services configuration.
    onHeartbeat	Periodic timed events. See Config.heartbeatInterval. iOS requires Config.preventSuspend.
    onGeofence	Fired with each Geofence transition event (ENTER, EXIT, DWELL).
    onGeofencesChange	Fired when the list of actively-monitored geofences changed. See Config.geofenceProximityRadius.
    onSchedule	Fired for Config.schedule events.
    onConnectivityChange	Fired when network-connectivity changes (connected / disconnected).
    onPowerSaveChange	Fired when state of operating-system's "power-saving" feature is enabled / disabled.
    onEnabledChange	Fired when the plugin is enabled / disabled via its start / stop methods.
    onNotificationAction	(Android only) Fired when a Notification.actions button is clicked upon a custom Notification.layout
    */
    //

    // Fired whenever a location is recorded
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      // print('[location] - ${location.toString(compact: false)}');
      // var j = jsonEncode(location.toMap());
      // print('[location] - ${j}');
      _handleStreamLocationUpdate(location);
    });

    // Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[motionchange] - ${location.toString(compact: false)}');
      _handleStreamLocationUpdate(location);
    });

    // Fired whenever the state of location-services changes.  Always fired at boot
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('[providerchange] - $event');
    });

    bg.BackgroundGeolocation.registerHeadlessTask(headlessTask);

    ////
    // 2.  Configure the plugin
    //
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,

            // This OVERRIDES the locationUpdateInterval, which otherwise
            // wants to do some sort-of-configurable dynamic things.
            distanceFilter: 1.0,
            disableElasticity: true,
            // locationUpdateInterval: 1000,
            fastestLocationUpdateInterval: 1000,

            // 100 m/s ~> 223 mi/h; planes grounded.
            speedJumpFilter: 100,

            //
            // isMoving: true,
            stopTimeout: 2, // minutes... right?
            minimumActivityRecognitionConfidence: 25, // default: 75

            // We must know what we're doing.
            disableStopDetection: true,
            stopOnStationary: false,
            pausesLocationUpdatesAutomatically: false,

            // But we probably don't really know what we're doing.
            // preventSuspend: true,

            disableAutoSyncOnCellular: true,
            maxRecordsToPersist: 3600,
            activityRecognitionInterval: 10000, // default=10000=10s
            allowIdenticalLocations: false,

            // I can't believe they let you do this.
            stopOnTerminate: false,
            enableHeadless: true,
            startOnBoot: true,
            heartbeatInterval: 1200,

            // Buggers.
            debug: false,
            logLevel: bg.Config.LOG_LEVEL_INFO))
        .then((bg.State state) {
      if (!state.enabled) {
        ////
        // 3.  Start the plugin.
        //
        bg.BackgroundGeolocation.start();
        bg.BackgroundGeolocation.setOdometer(0);
      }
    });

    eachSecond();
  }

  // Future<void> sensors() async {
  //   var sensors = await bg.BackgroundGeolocation.sensors;
  //   sensors..
  // }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    // positionStream.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    _connectionResult = result;
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.none:
        setState(() => _connectionStatus = result.toString());
        break;
      default:
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        break;
    }
  }

  // Future<void> getIp() async {
  //   geolocationData = await GeolocationAPI.getData();
  //   if (geolocationData != null) {
  //     setState(() {
  //       geolocation_text = geolocationData.ip;
  //     });
  //   }
  // }

  Future<http.Response> postTracks(List<Map<String, dynamic>> body) {
    print("body.length: " + body.length.toString());
    print(jsonEncode(body));

    // Dio dio = new Dio();
    // dio.options.connectTimeout = 60000; // 60s
    // dio.options.receiveTimeout = 60000; // 60s
    // dio.options.headers = postHeaders;
    // var rs = await dio.post(postEndpoint, data: body);
    // return rs.statusCode;

    final headers = <String, String>{
      'Content-Type': 'application/json',
      // 'Accept': 'application/json',
    };
    postHeaders.forEach((key, value) {
      headers[key] = value;
    });
    print("body.length: " + body.length.toString());
    print(jsonEncode(body));
    return http.post(
      postEndpoint,
      headers: headers,
      encoding: Encoding.getByName("utf-8"),
      body: jsonEncode(body),
    );
    // .timeout(const Duration(seconds: 60));

    // return res.statusCode;
  }

  Future<int> _pushTracks(List<AppPoint> tracks) async {
    print("=====> ... Pushing tracks: " + tracks.length.toString());

    final List<Map<String, dynamic>> pushable =
        List.generate(tracks.length, (index) {
      var c = tracks[index].toCattrackJSON(
        uuid: _deviceUUID,
        name: _deviceName,
        version: _deviceAppVersion,
        tripStarted: _appStarted.toUtc().toIso8601String(),
        distance: _distanceTracker.distance.toPrecision(1),
      );

      // c['tripStarted'] = _appStarted.toUtc().toIso8601String();
      // c['uuid'] = _deviceUUID;
      // c['name'] = _deviceName;
      // c['version'] = _deviceAppVersion;

      return c;
    });

    print("=====> ... Pushing tracks: " +
        tracks.length.toString() +
        "/" +
        pushable.length.toString());

    // print(jsonEncode(pushable));
    final res = await postTracks(pushable);
    return res.statusCode;
  }

  Future<void> _pushTracksBatching() async {
    print("=====> Attempting push");
    setState(() {
      _isPushing = true;
    });

    // All conditions passed, attempt to push all stored points.
    int resCode = 0;
    for (var count = await countTracks();
        count > 0;
        count = await countTracks()) {
      var tracks = await firstTracksWithLimit(
          (await Settings().getDouble(prefs.kPushBatchSize, 100)).toInt());
      resCode = await _pushTracks(tracks);

      if (resCode == HttpStatus.ok) {
        // Push yielded success, delete the tracks we just pushed.
        // Note that the delete condition used assumes tracks are ordered
        // earliest -> latest.
        print("🗸 PUSH OK");
        setState(() {
          _countPushed += tracks.length;
        });
        deleteTracksBeforeInclusive(tracks[tracks.length - 1].timestamp);
      } else {
        print("✘ PUSH FAILED, status: " + resCode.toString());
        break;
      }
    }
    var count = await countTracks();
    int snapCount;
    if (count == 0) {
      snapCount = 0;
      bg.BackgroundGeolocation.sync(); // delete from database
    } else {
      snapCount = await countSnaps();
    }

    // Awkwardly placed but whatever.
    // Update the persistent-state display.
    setState(() {
      _countStored = count;
      _countSnaps = snapCount;
      _isPushing = false;
    });

    if (resCode == 200) {
      setState(() {
        _appErrorStatus = "";
      });

      // ScaffoldMessenger.of(context).showSnackBar(
      //   _buildSnackBar(Text('Push successful'), backgroundColor: Colors.green),
      // );
    } else {
      setState(() {
        _appErrorStatus = 'Push failed. Status code: ' + resCode.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(Text(_appErrorStatus), backgroundColor: Colors.red),
      );

      //   _buildSnackBar(Text('Push failed. Status code: ' + resCode.toString()),
      //       backgroundColor: Colors.red),
      // );

    }
  }

  void _handleStreamLocationUpdate(bg.Location location) async {
    // Short circuit if position is null or timestamp is null.
    if (location == null ||
        location.timestamp == null ||
        location.timestamp == "" ||
        location.coords == null) {
      print("streamed position: unknown or null timestamp");
      // setState(() {
      //   geolocation_api_stream_text = 'Unknown';
      // });
      return;
    }

    // // debug
    // print(
    //     jsonEncode(AppPoint.fromLocationProvider(location).toCattrackJSON()));

    // Got a position!
    // print("streamed position: " + location.toString());

    // Update display
    setState(() {
      glocation = location;
    });

    // Persist the position.
    print("saving position");
    await insertTrack(AppPoint.fromLocationProvider(location));

    _distanceTracker.add(
        lon: location.coords.longitude,
        lat: location.coords.latitude,
        isMoving: location.isMoving && location.activity.type != "still");

    var countStored = await countTracks();
    var vcountSnaps = await countSnaps();

    // Update the persistent-state display.
    setState(() {
      _countStored = countStored;
      _countSnaps = vcountSnaps;
    });

    // If we're not at a push mod, we're done.
    var pushevery =
        (await Settings().getDouble(prefs.kPushInterval, 100)).toInt();

    setState(() {
      _pushEvery = pushevery;
    });
    if (countStored % pushevery != 0) {
      return;
    }

    if (_connectionResult == null ||
        _connectionResult == ConnectivityResult.none) return;

    var connectedWifi = _connectionResult == ConnectivityResult.wifi;
    var connectedMobile = _connectionResult == ConnectivityResult.mobile;

    var allowWifi = await Settings().getBool(prefs.kAllowPushWithWifi, true);
    var allowMobile =
        await Settings().getBool(prefs.kAllowPushWithMobile, true);

    if ((connectedWifi && allowWifi) || (connectedMobile && allowMobile)) {
      await _pushTracksBatching();
    }
  }

  // void _startStream() {
  //   positionStream =
  //       Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.best)
  //           .listen(_handleStreamLocationUpdate);
  // }

  // /// Determine the current position of the device.
  // ///
  // /// When the location services are not enabled or permissions
  // /// are denied the `Future` will return an error.
  // Future<Position> _determinePosition() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     return Future.error('Location services are disabled.');
  //   }

  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.deniedForever) {
  //     /*
  //     Settings

  //     In some cases it is necessary to ask the user and update their device settings.
  //     For example when the user initially permanently denied permissions to access
  //     the device's location or if the location services are not enabled
  //     (and, on Android, automatic resolution didn't work). In these cases you
  //     can use the openAppSettings or openLocationSettings methods to immediately
  //     redirect the user to the device's settings page.

  //     On Android the openAppSettings method will redirect the user to the App
  //     specific settings where the user can update necessary permissions.
  //     The openLocationSettings method will redirect the user to the location
  //     settings where the user can enable/ disable the location services.

  //     On iOS we are not allowed to open specific setting pages so both methods
  //     will redirect the user to the Settings App from where the user can navigate
  //     to the correct settings category to update permissions or enable/ disable
  //     the location services.
  //     */
  //     // await Geolocator.openAppSettings();
  //     await Geolocator.openLocationSettings();
  //     return Future.error(
  //         'Location permissions are permantly denied, we cannot request permissions.');
  //   }

  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission != LocationPermission.whileInUse &&
  //         permission != LocationPermission.always) {
  //       return Future.error(
  //           'Location permissions are denied (actual value: $permission).');
  //     }
  //   }

  //   return await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.best);
  // }

  // runs every 1 second

  int _secondsSinceLastPoint = 0;
  void eachSecond() {
    Timer.periodic(new Duration(seconds: 1), (timer) {
      var s = (DateTime.now().millisecondsSinceEpoch -
              DateTime.parse(glocation.timestamp).millisecondsSinceEpoch) ~/
          1000;
      setState(() {
        _secondsSinceLastPoint = s;
      });
    });
  }

  Widget _exampleStuff() {
    return Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SafeArea(
      child: Column(
        // Column is also a layout widget. It takes a list of children and
        // arranges them vertically. By default, it sizes itself to fit its
        // children horizontally, and tries to be as tall as its parent.
        //
        // Invoke "debug painting" (press "p" in the console, choose the
        // "Toggle Debug Paint" action from the Flutter Inspector in Android
        // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
        // to see the wireframe for each widget.
        //
        // Column has various properties to control how it sizes itself and
        // how it positions its children. Here we use mainAxisAlignment to
        // center the children vertically; the main axis here is the vertical
        // axis because Columns are vertical (the cross axis would be
        // horizontal).
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text('uuid:${_deviceUUID}',
          //         style: Theme.of(context).textTheme.bodyText2),
          //   ],
          // ),

          // Visibility(
          //   visible: _isPushing,
          //   child: LinearProgressIndicator(
          //     backgroundColor: Colors.deepOrange,
          //     minHeight: 3,
          //   ),
          // ),

          Visibility(
            visible: _appErrorStatus != "",
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [Text(_appErrorStatus)],
            ),
          ),

          LinearProgressIndicator(
            minHeight: 3,
            value: _isPushing
                ? null
                : _countStored.toDouble() / _pushEvery.toDouble(),
            backgroundColor: Colors.red,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                  child: Container(
                padding: EdgeInsets.all(8.0),
                // child: Expanded(
                child: ElevatedButton(
                    // MaterialStateProperty.all<Color>(Colors.lime)),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.green[300])),
                    onPressed: () async {
                      var loc =
                          await bg.BackgroundGeolocation.getCurrentPosition();
                      _handleStreamLocationUpdate(loc);

                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   _buildSnackBar(Text('Points!'),
                      //       backgroundColor: Colors.green),
                      // );
                    },
                    child: Icon(Icons.plus_one,
                        semanticLabel: 'Point', color: Colors.white)),
              )),
              Expanded(
                  child: Container(
                padding: EdgeInsets.all(8.0),
                // child: Expanded(
                child: ElevatedButton(
                    // MaterialStateProperty.all<Color>(Colors.lime)),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.cyan)),
                    onPressed: () {
                      // snaps().then((value) {
                      //   print("stored snapsy");
                      //   for (var item in value) {
                      //     print(jsonEncode(item.toCattrackJSON()));
                      //   }
                      // });
                      this._pushTracksBatching();
                    },
                    child: Icon(Icons.cloud_upload,
                        semanticLabel: 'Push', color: Colors.white)),
              )),
              Expanded(
                  child: Container(
                padding: EdgeInsets.all(8.0),
                // child: Expanded(
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => prefs.MySettingsScreen(
                            deviceUUID: _deviceUUID,
                            deviceName: _deviceName,
                            deviceVersion: _deviceAppVersion,
                          ),
                        ),
                      );
                    },
                    child: Text('Settings')),
              )),
            ],
          ),

          // Row(
          //   // children: () {
          //   //   List<Widget> out = [];
          //   //   for (var i = 0; i < _countStored && i < _pushEvery; i++) {
          //   //     out.add(Icon(Icons.control_point));
          //   //   }
          //   //   return out;
          //   // }(),
          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //   children: [
          //     Container(
          //       padding: EdgeInsets.symmetric(horizontal: 8.0),
          //       child: Text(('|' * (_countStored % _pushEvery) +
          //           (_countStored <= _pushEvery
          //               ? ('.' * (_pushEvery - _countStored))
          //               : ''))),
          //     )
          //   ],
          // ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InfoDisplay(
                keyname: "snaps",
                value: _countSnaps,
                options: {
                  // 't2.font': Theme.of(context).textTheme.bodyText2,
                },
              ),
              InfoDisplay(
                keyname: "points",
                value: _countStored,
                options: {
                  // 't2.font': Theme.of(context).textTheme.bodyText2,
                },
              ),
              InfoDisplay(
                keyname: "pushed",
                value: _countPushed,
                options: {
                  // 't2.font': Theme.of(context).textTheme.bodyText2,
                },
              ),
            ],
          ),

          Row(
            // primary: false,
            // padding: const EdgeInsets.all(20),
            // crossAxisSpacing: 10,
            // mainAxisSpacing: 10,
            // crossAxisCount: 2,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // InfoDisplay(
              //   keyname: "uuid",
              //   value: _deviceUUID,
              //   options: {
              //     't2.font': Theme.of(context).textTheme.bodyText2,
              //   },
              // ),
              InfoDisplay(
                keyname: "longitude,latitude",
                value: '${glocation.coords.longitude}' +
                    ',' +
                    '${glocation.coords.latitude}',
                options: {
                  't2.font': Theme.of(context).textTheme.bodyText2,
                },
              ),
              InfoDisplay(
                keyname: "connection",
                value: _connectionStatus.split(".").length > 1
                    ? _connectionStatus.split('.')[1]
                    : _connectionStatus,
                options: {
                  't2.font': Theme.of(context).textTheme.bodyText2,
                },
              ),
            ],
          ),
          // Row(
          //   children: [
          //     InfoDisplay(
          //       keyname: "name",
          //       value: _deviceName,
          //       options: {
          //         't2.font': Theme.of(context).textTheme.bodyText2,
          //       },
          //     ),
          //   ],
          // ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //   children: [
          //     InfoDisplay(
          //       keyname: "longitude,latitude",
          //       value: '${glocation.coords.longitude}' +
          //           ',' +
          //           '${glocation.coords.latitude}',
          //       options: {
          //         't2.font': Theme.of(context).textTheme.bodyText2,
          //       },
          //     ),
          //   ],
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InfoDisplay(
                  keyname: "accuracy", value: glocation.coords.accuracy),
              InfoDisplay(
                keyname: "since last point",
                value:
                    secondsToPrettyDuration(_secondsSinceLastPoint.toDouble()),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InfoDisplay(
                  keyname: "km/h",
                  value: glocation.coords.speed <= 0
                      ? 0
                      : ((glocation.coords.speed ?? 0) * 3.6).toPrecision(1)

                  /*
                  () {
                    if (glocation.coords.speed == 0) return 0;
                    return ((glocation.coords.speed ?? 0) * 3.6).toPrecision(1);
                  }()
                  */
                  ),
              InfoDisplay(
                  keyname: "speed accuracy",
                  value: glocation.coords.speedAccuracy),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InfoDisplay(
                  keyname: "heading",
                  value: degreeToCardinalDirection(glocation.coords.heading)),
              InfoDisplay(
                  keyname: "heading accuracy",
                  value: glocation.coords.headingAccuracy != null
                      ? glocation.coords.headingAccuracy.toPrecision(1)
                      : -1),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InfoDisplay(
                  keyname: "elevation", value: glocation.coords.altitude),
              InfoDisplay(
                  keyname: "elevation accuracy",
                  value: glocation.coords.altitudeAccuracy),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InfoDisplay(
                  keyname: "odometer", value: glocation.odometer.toInt()),
              InfoDisplay(
                  keyname: "distance", value: _distanceTracker.distance ~/ 1),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InfoDisplay(keyname: "activity", value: glocation.activity.type),
              InfoDisplay(
                  keyname: "activity confidence",
                  value: glocation.activity.confidence),
            ],
          ),
          // Row(children: []),
          // Row(children: []),
          // Row(children: []),
          Row(
            children: [
              Expanded(
                  child: Container(
                      height: 128,
                      padding: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.lime)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TakePictureScreen(camera: firstCamera),
                            ),
                          );
                        },
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text('Cat snap',
                                  style: Theme.of(context).textTheme.overline),
                              Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: Colors.green, // green
                              ),
                            ]),
                      )))
            ],
          )

          // Text(
          //   'You done ${ew.adjectives[_counter]}ly caressed the button this many times:',
          // ),
          // Text(
          //   '$_counter',
          //   style: Theme.of(context).textTheme.headline4,
          // ),
          // Text('Geolocate (IP): ' + geolocation_text),
          // TextButton(
          //     onPressed: () {
          //       this.getIp().then((value) => {
          //             if (geolocationData != null)
          //               {
          //                 setState(() {
          //                   geolocation_text =
          //                       jsonEncode(geolocationData.toJson());
          //                 })
          //               }
          //             else
          //               {
          //                 setState(() {
          //                   geolocation_text =
          //                       "could not get location data from IP";
          //                 })
          //               }
          //           });
          //     },
          //     child: Text(
          //       "Get location from IP",
          //     )),
          // Text("Geolocate (API): " + geolocation_api_text),
          // TextButton(
          //     onPressed: () {
          //       bg.BackgroundGeolocation.getCurrentPosition().then((value) {
          //         this._handleStreamLocationUpdate(value);
          //       });
          //     },
          //     child: Text(
          //       "Get geolocation from  API",
          //     )),
          // Text("Geolocate Stream (API): " + geolocation_api_stream_text),
          // TextButton(
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) =>
          //               TakePictureScreen(camera: firstCamera),
          //         ),
          //       );
          //     },
          //     child: Text("Camera!"))
        ],
      ),
    ));
  }

  // int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      // appBar: AppBar(
      //   // Here we take the value from the MyHomePage object that was created by
      //   // the App.build method, and use it to set our appbar title.
      //   title: Text(widget.title),
      // ),
      // title: Icon(Icons.map)),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _currentIndex,
      //   onTap: (value) {
      //     // Respond to item press.
      //     setState(() => _currentIndex = value);
      //   },
      //   items: [
      //     BottomNavigationBarItem(
      //       title: Text('Cat Tracking'),
      //       icon: Icon(Icons.map_outlined),
      //     ),
      //     BottomNavigationBarItem(
      //       title: Text('Settings'),
      //       icon: Icon(Icons.settings),
      //     ),
      //   ],
      // ),
      // persistentFooterButtons: [
      //   // TextButton(onPressed: () {}, child: Text('left')),
      //   // ElevatedButton(
      //   //     onPressed: () {
      //   //       Navigator.push(context,
      //   //           MaterialPageRoute(builder: (context) => SettingsScreen()));
      //   //     },
      //   //     child: Text('Settings')),
      //   Expanded(
      //       child: Container(
      //           padding: EdgeInsets.symmetric(horizontal: 8.0),
      //           child: Expanded(
      //             child: ElevatedButton(
      //                 onPressed: () {
      //                   // snaps().then((value) {
      //                   //   print("stored snapsy");
      //                   //   for (var item in value) {
      //                   //     print(jsonEncode(item.toCattrackJSON()));
      //                   //   }
      //                   // });
      //                   this._pushTracksBatching();
      //                 },
      //                 child: Icon(Icons.cloud_upload)),
      //           ))),
      //   Expanded(
      //       child: Container(
      //           padding: EdgeInsets.symmetric(horizontal: 8.0),
      //           child: Expanded(
      //             child: ElevatedButton(
      //                 onPressed: () {
      //                   Navigator.push(
      //                       context,
      //                       MaterialPageRoute(
      //                           builder: (context) => SettingsScreen()));
      //                 },
      //                 child: Text('Settings')),
      //           ))),
      //   // Row(
      //   //   mainAxisAlignment: MainAxisAlignment.spaceAround,
      //   //   children: [
      //   //     Expanded(
      //   //         child: Container(
      //   //             padding: EdgeInsets.symmetric(horizontal: 8.0),
      //   //             child: Expanded(
      //   //               child: ElevatedButton(
      //   //                   onPressed: () {
      //   //                     // snaps().then((value) {
      //   //                     //   print("stored snapsy");
      //   //                     //   for (var item in value) {
      //   //                     //     print(jsonEncode(item.toCattrackJSON()));
      //   //                     //   }
      //   //                     // });
      //   //                     this._pushTracksBatching();
      //   //                   },
      //   //                   child: Icon(Icons.cloud_upload)),
      //   //             ))),
      //   //     Expanded(
      //   //         child: Container(
      //   //             padding: EdgeInsets.symmetric(horizontal: 8.0),
      //   //             child: Expanded(
      //   //               child: ElevatedButton(
      //   //                   onPressed: () {
      //   //                     Navigator.push(
      //   //                         context,
      //   //                         MaterialPageRoute(
      //   //                             builder: (context) => SettingsScreen()));
      //   //                   },
      //   //                   child: Text('Settings')),
      //   //             ))),
      //   //   ],
      //   // ),
      // ],
      body: _exampleStuff(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: FloatingActionButton(
      //   materialTapTargetSize: MaterialTapTargetSize.padded,
      //   foregroundColor: Colors.green,
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => TakePictureScreen(camera: firstCamera),
      //       ),
      //     );
      //   },
      //   tooltip: 'Camera',
      //   child: Icon(Icons.camera),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

// https://flutter.dev/docs/cookbook/plugins/picture-using-camera

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cat snap'),
        backgroundColor: Colors.lime,
      ),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                return CameraPreview(_controller);
              } else {
                // Otherwise, display a loading indicator.
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          Row(
            children: [
              Expanded(
                  child: Container(
                      height: 128,
                      padding: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.lime)),
                        onPressed: () async {
                          // Take the Picture in a try / catch block. If anything goes wrong,
                          // catch the error.
                          try {
                            // Ensure that the camera is initialized.
                            await _initializeControllerFuture;

                            // Construct the path where the image should be saved using the
                            // pattern package.
                            final path = join(
                              // Store the picture in the temp directory.
                              // Find the temp directory using the `path_provider` plugin.
                              (await getTemporaryDirectory()).path,
                              '${DateTime.now().millisecondsSinceEpoch}.jpg',
                            );

                            // Attempt to take a picture and log where it's been saved.
                            // var xpath =
                            await _controller
                                .takePicture()
                                .then((value) => value.saveTo(path));
                            // _controller.setFlashMode(FlashMode.off);
                            // xpath.saveTo(path);

                            // If the picture was taken, display it on a new screen.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DisplayPictureScreen(imagePath: path),
                              ),
                            );
                          } catch (e) {
                            // If an error occurs, log the error to the console.
                            print(e);
                          }
                        },
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Text('Cat snap',
                              //     style: Theme.of(context).textTheme.overline),
                              Icon(
                                Icons.camera,
                                size: 48,
                                color: Colors.green, // green
                              ),
                            ]),
                      )))
            ],
          )
        ],
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.tealAccent,
      //   materialTapTargetSize: MaterialTapTargetSize.padded,
      //   child: Icon(Icons.camera_alt),
      //   // Provide an onPressed callback.
      //   onPressed: () async {
      //     // Take the Picture in a try / catch block. If anything goes wrong,
      //     // catch the error.
      //     try {
      //       // Ensure that the camera is initialized.
      //       await _initializeControllerFuture;

      //       // Construct the path where the image should be saved using the
      //       // pattern package.
      //       final path = join(
      //         // Store the picture in the temp directory.
      //         // Find the temp directory using the `path_provider` plugin.
      //         (await getTemporaryDirectory()).path,
      //         '${DateTime.now().millisecondsSinceEpoch}.jpg',
      //       );

      //       // Attempt to take a picture and log where it's been saved.
      //       // var xpath =
      //       await _controller.takePicture().then((value) => value.saveTo(path));
      //       // _controller.setFlashMode(FlashMode.off);
      //       // xpath.saveTo(path);

      //       // If the picture was taken, display it on a new screen.
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //           builder: (context) => DisplayPictureScreen(imagePath: path),
      //         ),
      //       );
      //     } catch (e) {
      //       // If an error occurs, log the error to the console.
      //       print(e);
      //     }
      //   },
      // ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviewing cat snap'),
        backgroundColor: Colors.lime,
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Column(children: [
        Image.file(File(imagePath)),
        Row(
          children: [
            Expanded(
                child: Container(
                    height: 128,
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.lime)),
                      onPressed: () async {
                        // Get location.
                        var location =
                            await bg.BackgroundGeolocation.getCurrentPosition();

                        // Read and rotate the image according to exif data as needed.
                        final img.Image capturedImage = img
                            .decodeImage(await File(imagePath).readAsBytes());
                        final img.Image orientedImage =
                            img.bakeOrientation(capturedImage);
                        await File(imagePath).writeAsBytes(
                            img.encodeJpg(orientedImage),
                            flush: true);

                        // Add the snap to the cat track.
                        var p = AppPoint.fromLocationProvider(location);
                        p.imgB64 =
                            base64Encode(File(imagePath).readAsBytesSync());

                        // Save it.
                        await insertTrackForce(p);

                        // Delete the original image file.
                        File(imagePath).deleteSync();

                        // Go back home.
                        Navigator.popUntil(context, ModalRoute.withName('/'));

                        return null;
                      },
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(
                              Icons.save_outlined,
                              size: 48,
                              color: Colors.green, // green
                            ),
                          ]),
                    )))
          ],
        )
      ]),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.save),
      //   onPressed: () async {
      //     // Get location.
      //     var location = await bg.BackgroundGeolocation.getCurrentPosition();

      //     // Read and rotate the image according to exif data as needed.
      //     final img.Image capturedImage =
      //         img.decodeImage(await File(imagePath).readAsBytes());
      //     final img.Image orientedImage = img.bakeOrientation(capturedImage);
      //     await File(imagePath)
      //         .writeAsBytes(img.encodeJpg(orientedImage), flush: true);

      //     // Add the snap to the cat track.
      //     var p = AppPoint.fromLocationProvider(location);
      //     p.imgB64 = base64Encode(File(imagePath).readAsBytesSync());

      //     // Save it.
      //     await insertTrackForce(p);

      //     // Delete the original image file.
      //     File(imagePath).deleteSync();

      //     // Go back home.
      //     Navigator.popUntil(context, ModalRoute.withName('/'));

      //     return null;
      //   },
      // ),
    );
  }
}

String degreeToCardinalDirection(double heading) {
/*
    --- Return wind direction as a string.
    local function to_direction(degrees)
        -- Ref: https://www.campbellsci.eu/blog/convert-wind-directions
        if degrees == nil then
            return "Unknown dir"
        end
        local directions = {
            "N",
            "NNE",
            "NE",
            "ENE",
            "E",
            "ESE",
            "SE",
            "SSE",
            "S",
            "SSW",
            "SW",
            "WSW",
            "W",
            "WNW",
            "NW",
            "NNW",
            "N",
        }
        return directions[math.floor((degrees % 360) / 22.5) + 1]
    end
*/
  var directions = [
    "N",
    "NNE",
    "NE",
    "ENE",
    "E",
    "ESE",
    "SE",
    "SSE",
    "S",
    "SSW",
    "SW",
    "WSW",
    "W",
    "WNW",
    "NW",
    "NNW",
    "N",
  ];
  return directions[((heading % 360) ~/ 22.5) + 1];
}
