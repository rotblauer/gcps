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
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
// import 'package:gallery_saver/gallery_saver.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';

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
  double locLat = 0;
  double locAcc = 0;
  double locSpeed = 0;
  double locSpeedAcc = 0;
  int locHeading = 0;
  double locElevation = 0;

  // Display data history information
  int _countStored = 0;
  int _countPushed = 0;

  List<CameraDescription> cameras;
  CameraDescription firstCamera;

  // Camera
  Future<void> _initCameras() async {
    // Obtain a list of the available cameras on the device.
    cameras = await availableCameras();

    // Get a specific camera from the list of available cameras.
    firstCamera = cameras.first;
  }

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

    _initCameras();
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
      output['lat'] = num.parse(original['latitude'].toStringAsFixed(9));
      output['long'] = num.parse(original['longitude'].toStringAsFixed(9));
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
      locLng = num.parse(position.longitude.toDouble().toStringAsFixed(9));
      locLat = num.parse(position.latitude.toDouble().toStringAsFixed(9));
      locAcc = num.parse(position.accuracy.toDouble().toStringAsFixed(2));
      locSpeed = num.parse(position.speed.toDouble().toStringAsFixed(2));
      locSpeedAcc =
          num.parse(position.speedAccuracy.toDouble().toStringAsFixed(2));
      locHeading = num.parse(position.heading.toStringAsFixed(0));
      locElevation = num.parse(position.altitude.toDouble().toStringAsFixed(1));
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
        setState(() {
          _countPushed += tracks.length;
        });
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

      In some cases it is necessary to ask the user and update their device settings. 
      For example when the user initially permanently denied permissions to access 
      the device's location or if the location services are not enabled 
      (and, on Android, automatic resolution didn't work). In these cases you 
      can use the openAppSettings or openLocationSettings methods to immediately 
      redirect the user to the device's settings page.

      On Android the openAppSettings method will redirect the user to the App 
      specific settings where the user can update necessary permissions. 
      The openLocationSettings method will redirect the user to the location 
      settings where the user can enable/ disable the location services.

      On iOS we are not allowed to open specific setting pages so both methods 
      will redirect the user to the Settings App from where the user can navigate 
      to the correct settings category to update permissions or enable/ disable 
      the location services.
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
          InfoDisplay(keyname: "latitude", value: locLat),
          InfoDisplay(keyname: "accuracy", value: locAcc),
          InfoDisplay(keyname: "elevation", value: locElevation),
          InfoDisplay(keyname: "heading", value: locHeading),
          InfoDisplay(keyname: "speed", value: locSpeed),
          InfoDisplay(keyname: "speed accuracy", value: locSpeedAcc),
          InfoDisplay(keyname: "stored", value: _countStored),
          InfoDisplay(keyname: "pushed", value: _countPushed),
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
              )),
          TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TakePictureScreen(camera: firstCamera),
                  ),
                );
              },
              child: Text("Camera!"))
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
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
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
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
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
              '${DateTime.now().millisecondsSinceEpoch}.png',
            );

            // Attempt to take a picture and log where it's been saved.
            final xpath = await _controller.takePicture();
            xpath.saveTo(path);

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: path),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
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
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: () async {
          // await GallerySaver.saveImage(imagePath ?? "");
          // await ImageGallerySaver.saveFile(imagePath);
        },
      ),
    );
  }
}
