import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert'; // jsonEncode
import 'package:english_words/english_words.dart' as ew;
import 'package:flutter/services.dart';
import 'package:gcps/secrets.dart';
import 'package:ip_geolocation_api/ip_geolocation_api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/widgets.dart';
import 'package:device_info/device_info.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';

import 'track.dart';

void main() {
  // Avoid errors caused by flutter upgrade.
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

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        primarySwatch: Colors.yellow,
        backgroundColor: Colors.limeAccent,
        canvasColor: Colors.deepOrange,
      ),
      home: MyHomePage(title: 'gcps'),
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
  InfoDisplay({this.keyname, this.value});

  final String keyname;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Text('Key: $keyname, Value: $value');
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String geolocation_text = '<ip.somewhere>';
  String geolocation_api_text = '<api.somewhere>';
  String geolocation_api_stream_text = '<apistream.somewhere>';
  GeolocationData geolocationData;

  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();

  // Subscriptions
  StreamSubscription<Position> positionStream;
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Display location information
  String _deviceUUID;
  double locLng = 0;

  // Display data history information
  int _countStored = 0;
  int _countPushed = 0;

  //

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();
    // this.getIp();
    _getId().then((value) {
      _deviceUUID = value;
      print("uuid: " + value);
    });
    this._startStream();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    positionStream.cancel();
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

  Future<void> getIp() async {
    geolocationData = await GeolocationAPI.getData();
    if (geolocationData != null) {
      setState(() {
        geolocation_text = geolocationData.ip;
      });
    }
  }

  Future<http.Response> postTracks(List<Map<String, dynamic>> body) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    postHeaders.forEach((key, value) {
      headers[key] = value;
    });
    return http.post(
      postEndpoint,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<int> _pushTracks(List<Position> tracks) async {
    print("Got batched tracks:");

    final List<Map<String, dynamic>> pushable =
        List.generate(tracks.length, (index) {
      final Map<String, dynamic> original = tracks[index].toJson();
      final Map<String, dynamic> output = {};

      output['version'] = appVersion;
      output['name'] = deviceName;
      output['uuid'] = _deviceUUID;
      output['timestamp'] = (original['timestamp'] / 1000).floor();
      output['time'] =
          DateTime.fromMillisecondsSinceEpoch(original['timestamp'])
              .toUtc()
              .toIso8601String();
      output['lat'] = num.parse(original['latitude'].toStringAsFixed(8));
      output['long'] = num.parse(original['longitude'].toStringAsFixed(8));
      output['elevation'] = num.parse(original['altitude'].toStringAsFixed(1));
      output['accuracy'] = num.parse(original['accuracy'].toStringAsFixed(1));
      output['speed'] = num.parse(original['speed'].toStringAsFixed(1));
      output['speed_accuracy'] =
          num.parse(original['speed_accuracy'].toStringAsFixed(1));
      output['heading'] = num.parse(original['heading'].toStringAsFixed(0));
      original['floor'] != null
          ? output['floor'] = num.parse(original['floor'].toStringAsFixed(0))
          // ignore: unnecessary_statements
          : null;

      return output;
    });

    // print(jsonEncode(pushable));
    final res = await postTracks(pushable);

    // TODO
    return res.statusCode;
  }

  void _handleStreamLocationUpdate(Position position) async {
    // Short circuit if position is null or timestamp is null.
    if (position == null || position.timestamp == null) {
      print("streamed position: unknown or null timestamp");
      setState(() {
        geolocation_api_stream_text = 'Unknown';
      });
      return;
    }

    // Got a position!
    print("streamed position: " + position.toString());

    // Update display
    setState(() {
      geolocation_api_stream_text =
          position.latitude.toString() + ', ' + position.longitude.toString();
      locLng = position.longitude.toDouble();
    });

    // Persist the position.
    print("saving position");
    await insertTrack(position);
    var count = await countTracks();

    // Update the persistent-state display.
    setState(() {
      _countStored = count;
    });

    // If we're not at a push mod, we're done.
    if (count % 100 != 0) {
      return;
    }
    if (!_connectionStatus.contains("wifi") &&
        !_connectionStatus.contains("mobile")) {
      print("no positive connectivity, no attempt push");
      return;
    }

    // All conditions passed, attempt to push all stored points.
    for (var count = await countTracks();
        count > 0;
        count = await countTracks()) {
      var tracks = await firstTracksWithLimit(100);
      var resCode = await _pushTracks(tracks);

      if (resCode == 200) {
        // Push yielded success, delete the tracks we just pushed.
        // Note that the delete condition used assumes tracks are ordered
        // earliest -> latest.
        deleteTracksBeforeInclusive(
            tracks[tracks.length - 1].timestamp.millisecondsSinceEpoch);
      } else {
        print("bad status: " + resCode.toString());
        break;
      }
    }
    // Awkwardly placed but whatever.
    // Update the persistent-state display.
    setState(() {
      _countStored = count;
    });
  }

  void _startStream() {
    positionStream =
        Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.best)
            .listen(_handleStreamLocationUpdate);
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      /*
      Settings

      In some cases it is necessary to ask the user and update their device settings. For example when the user initially permanently denied permissions to access the device's location or if the location services are not enabled (and, on Android, automatic resolution didn't work). In these cases you can use the openAppSettings or openLocationSettings methods to immediately redirect the user to the device's settings page.

      On Android the openAppSettings method will redirect the user to the App specific settings where the user can update necessary permissions. The openLocationSettings method will redirect the user to the location settings where the user can enable/ disable the location services.

      On iOS we are not allowed to open specific setting pages so both methods will redirect the user to the Settings App from where the user can navigate to the correct settings category to update permissions or enable/ disable the location services.
      */
      // await Geolocator.openAppSettings();
      await Geolocator.openLocationSettings();
      return Future.error(
          'Location permissions are permantly denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error(
            'Location permissions are denied (actual value: $permission).');
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
  }

  Widget _exampleStuff() {
    return Center(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          InfoDisplay(keyname: "uuid", value: _deviceUUID),
          InfoDisplay(keyname: "connection status", value: _connectionStatus),
          InfoDisplay(keyname: "longitude", value: locLng),
          InfoDisplay(keyname: "stored", value: _countStored),
          Text(
            'You done ${ew.adjectives[_counter]}ly caressed the button this many times:',
          ),
          Text(
            '$_counter',
            style: Theme.of(context).textTheme.headline4,
          ),
          Text('Geolocate (IP): ' + geolocation_text),
          TextButton(
              onPressed: () {
                this.getIp().then((value) => {
                      if (geolocationData != null)
                        {
                          setState(() {
                            geolocation_text =
                                jsonEncode(geolocationData.toJson());
                          })
                        }
                      else
                        {
                          setState(() {
                            geolocation_text =
                                "could not get location data from IP";
                          })
                        }
                    });
              },
              child: Text(
                "Get location from IP",
              )),
          Text("Geolocate (API): " + geolocation_api_text),
          TextButton(
              onPressed: () {
                this
                    ._determinePosition()
                    .then((value) => {
                          setState(() {
                            geolocation_api_text = value.toString();
                          })
                        })
                    .catchError((err) => {
                          setState(() {
                            geolocation_api_text = err.toString();
                          })
                        });
              },
              child: Text(
                "Get geolocation from  API",
              )),
          Text("Geolocate Stream (API): " + geolocation_api_stream_text),
          TextButton(
              onPressed: () {
                this._startStream();
              },
              child: Text(
                "Get streaming geolocation from API",
              ))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: _exampleStuff(),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
