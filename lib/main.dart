import 'package:flutter/material.dart';
import 'dart:convert'; // jsonEncode
import 'package:english_words/english_words.dart' as ew;
import 'package:ip_geolocation_api/ip_geolocation_api.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
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
        primarySwatch: Colors.deepOrange,
        backgroundColor: Colors.lime,
        canvasColor: Colors.yellow,
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

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String geolocation_text = '<ip.somewhere>';
  String geolocation_api_text = '<api.somewhere>';
  GeolocationData geolocationData;

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

  // void initState() {
  //   super.initState();
  //   this.getIp();
  // }

  Future<void> getIp() async {
    geolocationData = await GeolocationAPI.getData();
    if (geolocationData != null) {
      setState(() {
        geolocation_text = geolocationData.ip;
      });
    }
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
      // await Geolocator.openLocationSettings();
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
          Text(
            'You done ${ew.adjectives[_counter]}ly caressed the button this many times:',
          ),
          Text(
            '$_counter',
            style: Theme.of(context).textTheme.headline4,
          ),
          Text('Geolocate (IP): ' + geolocation_text),
          FlatButton(
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
