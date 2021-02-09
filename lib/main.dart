import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

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
// import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' show basename, join;
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

void main() async {
  // Avoid errors cased by flutter upgrade
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();

  // // Development: reset (rm -rf db) if exists.
  // resetDB();

  // Initialize preferences singleton.
  await prefs.sharedPrefs.init();

  // Run app.
  runApp(MyApp());

  bg.BackgroundGeolocation.registerHeadlessTask(headlessTask);
}

void _handleStreamLocationSave(bg.Location location) async {
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

  // Persist the position.
  var ap = AppPoint.fromLocationProvider(location);
  await insertTrack(ap);
}

/// Receives all events from BackgroundGeolocation while app is terminated:
void headlessTask(bg.HeadlessEvent headlessEvent) async {
  // print('[HeadlessTask]: ${headlessEvent}');

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
      // print('- Location: ${location}');
      _handleStreamLocationSave(location);
      break;
    case bg.Event.MOTIONCHANGE:
      bg.Location location = headlessEvent.event;
      // print('- Location: ${location}');
      _handleStreamLocationSave(location);
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

Icon buildConnectStatusIcon(String status, {Color color, double size}) {
  /*

                value: _connectionStatus.split(".").length > 1
                    ? _connectionStatus.split('.')[1]
                    : _connectionStatus,
                options: {
  */
  if (status.toLowerCase().contains('wifi'))
    return Icon(
      Icons.wifi,
      color: color ?? MyTheme.colorScheme.onSurface,
      size: size,
    );
  if (status.toLowerCase().contains('mobile'))
    return Icon(
      Icons.signal_cellular_alt,
      color: color ?? MyTheme.colorScheme.onSurface,
    );
  return Icon(
    Icons.do_disturb_alt_outlined,
    color: color ?? MyTheme.colorScheme.onError,
  );
}

const Map<String, Color> activityColors = {
  'Stationary': Colors.deepOrange,
  'still': Colors.deepOrange,
  //
  'Walking': Colors.amber,
  'on_foot': Colors.amber,
  'walking': Colors.amber,
  //
  'Running': Colors.green,
  'running': Colors.green,
  //
  'Bike': Colors.lightBlue,
  'on_bicycle': Colors.lightBlue,
  //
  'Automotive': Colors.purple,
  'in_vehicle': Colors.purple,
};

Color getActivityColor(String activityType) {
  if (activityColors.containsKey(activityType))
    return activityColors[activityType];
  return Colors.deepOrange;
}

String developmentGuessActivityType(double speed) {
  if (speed > 50 / 3.6) return 'in_vehicle';
  if (speed > 12 / 3.6) return 'on_bicycle';
  if (speed > 6 / 3.6) return 'running';
  if (speed > 3 / 3.6) return 'walking';
  return 'still';
}

class ShapesPainter extends CustomPainter {
  List<AppPoint> locations = [];

  ShapesPainter({this.locations});

  @override
  void paint(Canvas canvas, Size size) {
    if (locations.length == 0) return;

    double minLat, minLon, maxLat, maxLon, minAlt, maxAlt;
    for (var loc in locations) {
      if (minLat == null || loc.latitude < minLat) minLat = loc.latitude;
      if (maxLat == null || loc.latitude > maxLat) maxLat = loc.latitude;
      if (minLon == null || loc.longitude < minLon) minLon = loc.longitude;
      if (maxLon == null || loc.longitude > maxLon) maxLon = loc.longitude;

      // altitude
      if (minAlt == null || loc.altitude < minAlt) minAlt = loc.altitude;
      if (maxAlt == null || loc.altitude > maxAlt) maxAlt = loc.altitude;
    }

    var dH = maxLon - minLon;
    var dW = maxLat - minLat;

    if (dH == 0) dH = 10 / 111111;
    if (dW == 0) dW = 10 / 111111;

    double sizeW = size.width * 0.95;
    double sizeH = size.height * 0.95;
    double wMargin = (size.width - sizeW) / 2;
    double hMargin = (size.height - sizeH) / 2;

    bool mapPortrait = sizeH > sizeW;
    double mapMinEdge = mapPortrait ? sizeW : sizeH;
    bool territoryPortrait = dH > dW;
    double territoryMaxEdge = territoryPortrait ? dH : dW;

    double scale = mapMinEdge / territoryMaxEdge;

    Path path = Path();

    // Altitude/elevation stuff
    double sizeAltW = sizeW;
    double sizeAltH = sizeH / 4;

    Paint lastElevPointPaint = Paint()
      ..color = Colors.tealAccent
      ..style = PaintingStyle.fill;
    Path elevPath = Path();
    final elevPaint = Paint();
    elevPaint.color = Colors.cyan.withAlpha(155);
    elevPaint.style = PaintingStyle.stroke;
    elevPaint.strokeWidth = 1;
    double elevSpread = (maxAlt - minAlt);
    double elevScaleY = sizeAltH / (elevSpread > 0 ? elevSpread : 1);
    double elevScaleX = sizeAltW / locations.length;
    Offset elevGraphOrigin = Offset(wMargin, sizeAltH);

    final paintStationaryConnections = Paint();
    paintStationaryConnections.color = Colors.white24;
    paintStationaryConnections.strokeWidth = 0.8;
    paintStationaryConnections.style = PaintingStyle.stroke;

    final paint = Paint();
    paint.color = Colors.deepOrange;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    List<String> uniqActivities = [
      // 'still',
      // 'walking',
      // 'on_bicycle',
      // 'running',
      // 'in_vehicle'
    ];

    int i = 0;
    for (var loc in locations) {
      if (!uniqActivities.contains(loc.activity_type))
        uniqActivities.add(loc.activity_type);

      bool isLast = i == locations.length - 1;
      bool isFirst = i == 0;

      Color activityColor =
          getActivityColor(loc.activity_type); //.withAlpha(255 - accFade);
      paint.color = activityColor;

      // }

      i++;
      var x = loc.longitude;
      var y = loc.latitude;

      // Build the drawable coords.
      double relX = scale * (x - minLon) + wMargin;
      double relY = sizeH - (scale * (y - minLat)) + hMargin;

      // Center the drawing.
      relX += (sizeW - (scale * (maxLon - minLon))) / 2;
      relY -= (sizeH - (scale * (maxLat - minLat))) / 2;

      // shape the path
      Offset elevPoint = elevGraphOrigin.translate(
          elevScaleX * i.toDouble(), -1 * (loc.altitude - minAlt) * elevScaleY);

      if (loc.activity_type == 'still') {
      } else {}

      if (isFirst) {
        if (loc.activity_type == 'still') paint.style = PaintingStyle.fill;

        canvas.drawCircle(Offset(relX, relY), isLast ? 4.0 : 2.0, paint);
        paint.style = PaintingStyle.stroke;

        path.moveTo(relX, relY);
        elevPath.moveTo(elevPoint.dx, elevPoint.dy);
      } else {
        if (loc.activity_type == 'still') {
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(Offset(relX, relY), isLast ? 4.0 : 2.0, paint);
          paint.style = PaintingStyle.stroke;

          // path = Path();
          // path.moveTo(relX, relY);
          path.arcToPoint(Offset(relX, relY));
          canvas.drawPath(path, paintStationaryConnections);
          path = Path();
          path.moveTo(relX, relY);
        } else {
          path.arcToPoint(Offset(relX, relY));

          canvas.drawPath(path, paint);

          if (!isLast) {
            path = Path();
            path.moveTo(relX, relY);
          }
        }
        elevPath.arcToPoint(elevPoint);
      }

      if (isLast) {
        // draw radius fill circle
        double accRadius = loc.accuracy / 111111 * scale;
        if (accRadius > mapMinEdge / 2) accRadius = mapMinEdge / 2;
        paint.color = MyTheme.buttonColor.withAlpha(100);
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(relX, relY), accRadius, paint);

        if (loc.activity_type != 'still') {
          paint.color = activityColor;
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 1;
          canvas.drawCircle(Offset(relX, relY), 6, paint);
        } else {
          paint.color = MyTheme.accentColor;
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 1;
          canvas.drawCircle(Offset(relX, relY), 6, paint);
        }

        // Draw dot indicating last elevation point.
        if (locations.length > 30 && elevSpread > 5)
          canvas.drawCircle(elevPoint, 4, lastElevPointPaint);
      }
    } // for loc in locations

    // Draw the elevation path.
    if (locations.length > 30 && elevSpread > 5)
      canvas.drawPath(elevPath, elevPaint);

    // elevPaint.style = PaintingStyle.fill;
    // elevPaint.color = elevPaint.color.withAlpha(30);
    // elevPath.close();

    // legend
    const double tickSize = 8;
    double maxDistMeters = Haversine.fromDegrees(
            latitude1: minLat,
            latitude2: maxLat,
            longitude1: minLon,
            longitude2: maxLon)
        .distance();

    String legendLabel = '1cm';
    double legendScaleDist = 0.01;
    if (maxDistMeters > 1000000) {
      legendScaleDist = 1000000;
      legendLabel = "1000km";
    } else if (maxDistMeters > 100000) {
      legendScaleDist = 100000;
      legendLabel = "100km";
    } else if (maxDistMeters > 10000) {
      legendScaleDist = 10000;
      legendLabel = "10km";
    } else if (maxDistMeters > 3000) {
      legendScaleDist = 3000;
      legendLabel = "3km";
    } else if (maxDistMeters > 1000) {
      legendScaleDist = 1000;
      legendLabel = "1km";
    } else if (maxDistMeters > 500) {
      legendScaleDist = 500;
      legendLabel = "500m";
    } else if (maxDistMeters > 250) {
      legendScaleDist = 250;
      legendLabel = "250m";
    } else if (maxDistMeters > 100) {
      legendScaleDist = 100;
      legendLabel = "100m";
    } else if (maxDistMeters > 50) {
      legendScaleDist = 50;
      legendLabel = "50m";
    } else if (maxDistMeters > 10) {
      legendScaleDist = 10;
      legendLabel = "10m";
    } else if (maxDistMeters > 1) {
      legendScaleDist = 1;
      legendLabel = "1m";
    } else if (maxDistMeters > 0.1) {
      legendScaleDist = 0.1;
      legendLabel = "10cm";
    }

    // Scale legend.
    paint.color = Colors.grey;
    paint.strokeWidth = 1;

    // horizontal
    Offset horizontalEnd = Offset(wMargin + (legendScaleDist * scale / 111111),
        size.height - hMargin * 0.2);
    canvas.drawLine(
        Offset(wMargin, size.height - hMargin * 0.2), horizontalEnd, paint);
    //tick
    canvas.drawLine(
        horizontalEnd, horizontalEnd.translate(0, -tickSize), paint);

    // vertical
    Offset verticalStart = Offset(wMargin,
        size.height - hMargin * 0.2 - (legendScaleDist * scale / 111111));
    canvas.drawLine(
        verticalStart, Offset(wMargin, size.height - hMargin * 0.2), paint);
    //tick
    canvas.drawLine(verticalStart, verticalStart.translate(tickSize, 0), paint);

    // rect!
    paint.style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromPoints(verticalStart, horizontalEnd),
        paint..color = paint.color.withAlpha(20));
    paint.color = paint.color.withAlpha(255); // reset alptha

    TextSpan ts = TextSpan(
        text: legendLabel,
        style: MyTheme.copyWith()
            .textTheme
            .apply(bodyColor: paint.color)
            .overline);
    var tp =
        TextPainter(text: ts, maxLines: 1, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(wMargin, size.height /*- hMargin - 16*/));

    // Elevation legend.
    lastElevPointPaint.color = MyTheme.buttonColor;
    if (locations.length > 30 && elevSpread > 5) {
      canvas.drawLine(Offset(sizeW + wMargin, 0),
          Offset(sizeW + wMargin, sizeAltH), lastElevPointPaint);

      TextSpan tsa = TextSpan(
          text: '${elevSpread ~/ 1}',
          style: MyTheme.copyWith()
              .textTheme
              .apply(bodyColor: lastElevPointPaint.color.withAlpha(155))
              .overline);
      tp.text = tsa;
      tp.layout();
      tp.paint(
          canvas, Offset(wMargin + sizeW - (tp.width), -tp.height - 4 / 2));

      canvas.drawRect(
          Rect.fromPoints(
              Offset(wMargin, 0), Offset(sizeW + wMargin, sizeAltH)),
          elevPaint
            ..color = elevPaint.color.withAlpha(10)
            ..style = PaintingStyle.fill);
    }

    // Color legend.
    paint.style = PaintingStyle.fill;

    int ii = -1;
    double activityLegendItemHeight = 16;
    double withTextWidth = 0;
    Offset activityColorLegendOrigin = Offset(sizeW, size.height);
    for (var act in uniqActivities) {
      ii++;
      paint.color = getActivityColor(act);

      Offset circleOffset = activityColorLegendOrigin.translate(
          -ii * activityLegendItemHeight / 3 * 2 - withTextWidth,
          activityLegendItemHeight / 2); // -4 is extra space

      canvas.drawCircle(circleOffset, activityLegendItemHeight / 4, paint);

      TextSpan tss = TextSpan(
          text: act.replaceAll('in_', '').replaceAll('on_', ''),
          style: MyTheme.copyWith()
              .textTheme
              .apply(bodyColor: paint.color.withAlpha(155))
              .overline);
      tp.text = tss;
      tp.layout();
      withTextWidth += tp.width + activityLegendItemHeight / 2;
      tp.paint(
          canvas,
          circleOffset.translate(-tp.width - activityLegendItemHeight / 2,
              -activityLegendItemHeight / 4 * 2));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Icon buildActivityIcon(BuildContext context, String activity, double size) {
  switch (activity) {
    case 'still':
      return Icon(
        Icons.airline_seat_legroom_extra,
        size: size,
        // color: Theme.of(context).primaryColor,
        color: getActivityColor(activity),
        // color: Theme.of(context).accentColor,
      );
    case 'on_foot':
      return Icon(
        Icons.directions_walk,
        size: size,
        color: getActivityColor(activity),
      );
    case 'walking':
      return Icon(
        Icons.directions_walk,
        size: size,
        color: getActivityColor(activity),
      );
    case 'on_bicycle':
      return Icon(
        Icons.directions_bike,
        size: size,
        color: getActivityColor(activity),
      );
    case 'running':
      return Icon(
        Icons.directions_run,
        size: size,
        color: getActivityColor(activity),
      );
    case 'in_vehicle':
      return Icon(
        Icons.directions_car,
        size: size,
        // color: Theme.of(context).primaryColor,
        color: getActivityColor(activity), // boring and lame...
      );

    default:
      return Icon(
        Icons.do_disturb_on_rounded,
        size: size,
        color: getActivityColor(activity),
      );
  }
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

final ThemeData MyTheme = ThemeData(
    // This is the theme of your application.
    //
    // Try running your application with "flutter run". You'll see the
    // application has a blue toolbar. Then, without quitting the app, try
    // changing the primarySwatch below to Colors.green and then invoke
    // "hot reload" (press "r" in the console where you ran "flutter run",
    // or simply save your changes to "hot reload" in a Flutter IDE).
    // Notice that the counter didn't reset back to zero; the application
    // is not restarted.
    brightness: Brightness.dark,
    // canvasColor: Colors.blueGrey[900],
    canvasColor: Color.fromRGBO(18, 18, 36, 1), // Colors.blueGrey[900],
    accentColor: Colors.lightGreenAccent,
    textTheme: TextTheme(headline4: TextStyle(fontFamily: 'mono'))
    // primarySwatch: Colors.lightGreen, // Colors.amber,
    // backgroundColor: Colors.limeAccent,
    // canvasColor: Colors.deepOrange,
    // primaryColor: Colors.white,
    );

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: MyTheme.canvasColor,
      systemNavigationBarIconBrightness: Theme.of(context).brightness,
      systemNavigationBarColor: MyTheme.canvasColor,
    ));
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'global cat positioning system',
      theme: MyTheme,
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
    // var mytheme = Theme.of(context).textTheme.overline;
    // mytheme = mytheme.apply(color: Colors.white70);
    return Container(
        padding: const EdgeInsets.all(8),
        // color: Colors.green[500],
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$keyname', style: Theme.of(context).textTheme.overline,
                // style: mytheme,
              ),
              value.runtimeType == String ||
                      value.runtimeType == double ||
                      value.runtimeType == int ||
                      value.runtimeType == DateTime
                  ? Text(
                      '$value',
                      style: options != null && options.containsKey('t2.font')
                          ? options['t2.font']
                          : Theme.of(context).textTheme.headline5,
                      maxLines: 2,
                    )
                  : value,
              options != null && options['third'] != null
                  ? options['third']
                  : Text('')
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
  double elev_0 = 0;
  double elev_up = 0;
  double elev_dn = 0;

  double elev_rel() {
    return elev_up - elev_dn;
  }

  get up {
    return elev_up.toInt();
  }

  get dn {
    return elev_dn.toInt();
  }

  reset() {
    distance = 0;
    elev_0 = 0;
    elev_up = 0;
    elev_dn = 0;
    _last_lon = null;
    _last_lat = null;
    _last_elev = null;
  }

  double _last_lon;
  double _last_lat;
  double _last_elev;

  final bool filterStill;

  DistanceTracker({this.filterStill});

  double add({double lon, double lat, double elevation, bool isMoving}) {
    // print("lon=" +
    //     lon.toString() +
    //     " lat=" +
    //     lat.toString() +
    //     " isMoving=" +
    //     isMoving.toString());
    if (elevation != null) elevation = elevation.roundToDouble();

    if (!filterStill || isMoving) {
      distance += Haversine.fromDegrees(
              latitude1: _last_lat ?? lat,
              longitude1: _last_lon ?? lon,
              latitude2: lat,
              longitude2: lon)
          .distance();
    }
    if (elevation != null && _last_elev != null) {
      if (elevation > _last_elev) elev_up += (elevation - _last_elev);
      if (elevation < _last_elev) elev_dn -= (elevation - _last_elev);
    }
    if (elevation != null && _last_elev == null) elev_0 = elevation;
    _last_lon = lon;
    _last_lat = lat;
    _last_elev = elevation;
    return distance;
  }
}

String secondsToPrettyDuration(double seconds, [bool abbrev]) {
  int secondsRound = seconds ~/ 1;
  int hours = secondsRound ~/ 3600;
  secondsRound = secondsRound % 3600;
  int minutes = secondsRound ~/ 60;
  secondsRound = secondsRound % 60;
  String out = "";
  hours > 0 ? out += hours.toString() + 'h ' : null;
  minutes > 0 ? out += minutes.toString() + 'm ' : null;
  if (out.length > 0 && abbrev) return out;
  out += secondsRound.toString() + 's';
  return out;
}

Color colorForDurationSinceLastPoint(int duration) {
  if (duration == null) duration = 0;
  final int offset = duration > 255 ? 255 : duration;
  Color c = Color.fromRGBO(255, 255 - offset, 255 - offset, 1);
  if (duration < 10) {
    c = c.withAlpha(duration / 10 * 255 ~/ 1);
  }
  return c;
  // ..withBlue(offset)
  // ..withGreen(offset);
  // if (duration < 3) return Colors.white;
  // if (duration < 10) return Colors.red[100];
  // if (duration < 20) return Colors.red[200];
  // if (duration < 60) return Colors.red[300];
  // if (duration < 120) return Colors.red[400];
  // if (duration < 360) return Colors.red[500];
  // if (duration < 720) return Colors.red[600];
  // if (duration < 1200) return Colors.red[700];
  // if (duration < 2400) return Colors.red[800];
  // return Colors.red[900];
}

class _MyHomePageState extends State<MyHomePage> {
  String _appErrorStatus = "";
  String _appLocationErrorStatus = "";
  String _deviceUUID = "";
  String _deviceName = "";
  String _deviceAppVersion = "";
  bool _isPushing = false;
  bool _isManuallyRequestingLocation = false;
  double _tripDistance = 0.0;
  List<AppPoint> _paintList = [];

  // MapboxMapController mapController;
  // bool _mapboxStyleLoaded = false;

  DistanceTracker _distanceTracker = DistanceTracker(filterStill: true);

  // int _counter = 0;
  // String geolocation_text = '<ip.somewhere>';
  // String geolocation_api_text = '<api.somewhere>';
  // String geolocation_api_stream_text = '<apistream.somewhere>';
  GeolocationData geolocationData;
  DateTime _tripStarted;
  bool _bgGeolocationIsEnabled = false;

  String _connectionStatus = '-';
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

  @override
  void initState() {
    _tripStarted = DateTime.now().toUtc();
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

    lastTracksWithLimit(3600).then((value) {
      _paintList = value;
    });

    countTracks().then((value) {
      _countStored = value;
    });
    countSnaps().then((value) {
      _countSnaps = value;
    });
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
    }, _handleStreamLocationError);

    // Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[motionchange] - ${location.toString(compact: false)}');
      _handleStreamLocationUpdate(location);
    });

    bg.BackgroundGeolocation.onActivityChange((bg.ActivityChangeEvent event) {
      print('[activityChange]');
      glocation.timestamp = DateTime.now().toUtc().toIso8601String();
      glocation.activity.type = event.activity;
      glocation.activity.confidence = event.confidence;
      _handleStreamLocationUpdate(glocation);
    });

    bg.BackgroundGeolocation.onHeartbeat((bg.HeartbeatEvent event) {
      bg.BackgroundGeolocation.getCurrentPosition().then((location) {
        _handleStreamLocationUpdate(location);
      });
    });

    bg.BackgroundGeolocation.onEnabledChange((bool value) {
      print('[enabledChange]');
      setState(() {
        _bgGeolocationIsEnabled = value;
      });
      if (value) {
        bg.BackgroundGeolocation.getCurrentPosition().then((location) {
          _handleStreamLocationUpdate(location);
        });
      }
    });

    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
      _handleStreamLocationUpdate(event.location);
    });

    // bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
    //   _handleStreamLocationUpdate(event.location);
    // });

    // // Fired whenever the state of location-services changes.  Always fired at boot
    // bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
    //   print('[providerchange] - $event');
    // });

    ////
    // 2.  Configure the plugin
    //

    bg.Config bgConfig = bg.Config(
      // All configuration settings which are read from preferences are
      // converted from
      // - doubles -> ints via .floor()

      desiredAccuracy: prefs.prefLocationDesiredAccuracy(
          prefs.sharedPrefs.getString(prefs.kLocationGarneringDesiredAccuracy)),

      // This OVERRIDES the locationUpdateInterval, which otherwise
      // wants to do some sort-of-configurable dynamic things.
      distanceFilter:
          prefs.sharedPrefs.getDouble(prefs.kLocationUpdateDistanceFilter),
      // disableElasticity: true, // == elasticityMultiplier = 0
      elasticityMultiplier: prefs.sharedPrefs
          .getDouble(prefs.kLocationGarneringElasticityMultiplier),
      locationUpdateInterval:
          (prefs.sharedPrefs.getDouble(prefs.kLocationUpdateInterval) * 1000)
              .toInt(),
      fastestLocationUpdateInterval: 1000,

      // 100 m/s ~> 223 mi/h; planes grounded.
      speedJumpFilter: 100,

      //
      isMoving: prefs.sharedPrefs.getBool(prefs.kLocationDeviceInMotion),
      stopTimeout: prefs.sharedPrefs
          .getDouble(prefs.kLocationUpdateStopTimeout)
          .floor(), // minutes... right? seconds is default

      // We must know what we're doing.
      disableStopDetection:
          prefs.sharedPrefs.getBool(prefs.kLocationDisableStopDetection),
      stopOnStationary: false,
      pausesLocationUpdatesAutomatically:
          !prefs.sharedPrefs.getBool(prefs.kLocationDisableStopDetection),

      // But we probably don't really know what we're doing.
      // preventSuspend: true,

      disableAutoSyncOnCellular: true,
      maxRecordsToPersist: 3600,
      activityRecognitionInterval: 10000, // default=10000=10s
      minimumActivityRecognitionConfidence: 25, // default: 75
      allowIdenticalLocations: true,

      // I can't believe they let you do this.
      stopOnTerminate: false,
      enableHeadless: true,
      startOnBoot: true,
      heartbeatInterval: 1800,

      // Buggers.
      debug: false,
      logLevel: bg.Config.LOG_LEVEL_INFO,
      persistMode: bg.Config.PERSIST_MODE_NONE,

      backgroundPermissionRationale: bg.PermissionRationale(
        message: "Cats love it",
      ),
    );

    bg.BackgroundGeolocation.ready(bgConfig).then((bg.State state) {
      setState(() {
        _bgGeolocationIsEnabled = state.enabled;
      });
      if (!state.enabled) {
        ////
        // 3.  Start the plugin.
        //
        bg.BackgroundGeolocation.start().then((bg.State state) {
          print('[start] success - ${state}');
        });
        // bg.BackgroundGeolocation.setOdometer(0);
      } else {
        bg.BackgroundGeolocation.start().then((bg.State state) {
          print('[start] success (already) - ${state}');
        });
      }
    }).catchError((err) {
      print('[start] error - ${err.toString()}');
    });

    // _isManuallyRequestingLocation = true;
    // bg.BackgroundGeolocation.getCurrentPosition().then((value) {
    //   _handleStreamLocationUpdate(value);
    //   _isManuallyRequestingLocation = false;
    // });

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
    // print(jsonEncode(body));

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
    // print("body.length: " + body.length.toString());
    // print(jsonEncode(body));
    return http
        .post(
          postEndpoint,
          headers: headers,
          encoding: Encoding.getByName("utf-8"),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    // return res.statusCode;
  }

  Future<int> _pushTracks(List<AppPoint> tracks) async {
    print("=====> ... Pushing tracks: " + tracks.length.toString());

    final List<Map<String, dynamic>> pushable = [];
    for (var t in tracks) {
      Map<String, dynamic> js = await t.toCattrackJSON(
        uuid: _deviceUUID,
        name: _deviceName,
        version: _deviceAppVersion,
        tripStarted: _tripStarted.toUtc().toIso8601String(),
        distance: _tripDistance.toPrecision(1),
      );
      pushable.add(js);
    }
    print("=====> ... Pushing tracks: " +
        tracks.length.toString() +
        "/" +
        pushable.length.toString());

    // print(jsonEncode(pushable));

    int resCode = 9696;
    try {
      final res = await postTracks(pushable);
      resCode = res.statusCode;
    } catch (err) {
      setState(() {
        _appErrorStatus = err.toString();
      });
    }
    return resCode;
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
          (prefs.sharedPrefs.getDouble(prefs.kPushBatchSize)).toInt());
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

        // delete (clean up) cat snaps files
        tracks.where((element) {
          return element.image_file_path != null &&
              element.image_file_path != '';
        }).forEach((element) {
          File(element.image_file_path).deleteSync();
        });
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
    } else if (resCode == 9696) {
    } else {
      setState(() {
        _appErrorStatus = 'Push failed. Status code: ' + resCode.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(Text(_appErrorStatus),
            backgroundColor: MyTheme.errorColor),
      );

      //   _buildSnackBar(Text('Push failed. Status code: ' + resCode.toString()),
      //       backgroundColor: Colors.red),
      // );

    }
  }

  void _handleStreamLocationError(bg.LocationError err) async {
    setState(() {
      String errS = 'Location error: ' + err.toString();
      /*
      Error Codes
      Code	Error
      0	Location unknown
      1	Location permission denied
      2	Network error
      408	Location timeout
      */
      switch (err.code) {
        case 0:
          errS = 'Location unknown.';
          break;
        case 1:
          errS = 'Location permission denied.';
          break;
        case 2:
          errS = 'Network error.';
          break;
        case 408:
          errS = 'Location timeout.';
          break;
      }

      _appLocationErrorStatus = errS;
    });
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

    if (postEndpoint.contains('http://10.0.2.2')) {
      location.activity.type =
          developmentGuessActivityType(location.coords.speed);
    }

    // print('handle location update: event=${location.event}');
    // // debug
    // print(
    //     jsonEncode(AppPoint.fromLocationProvider(location).toCattrackJSON()));

    // Got a position!
    // print("streamed position: " + location.toString());

    // Update display
    setState(() {
      _appLocationErrorStatus = '';
      glocation = location;
    });

    // Persist the position.
    // print("saving position");
    var ap = AppPoint.fromLocationProvider(location);
    await insertTrack(ap);

    _distanceTracker.add(
        lon: location.coords.longitude,
        lat: location.coords.latitude,
        elevation: location.coords.altitude,
        isMoving: location.isMoving && location.activity.type != "still");

    // if (mapController != null && _mapboxStyleLoaded) {
    //   mapController.addCircle(CircleOptions(
    //     geometry: LatLng(location.coords.latitude, location.coords.longitude),
    //     circleColor: '#ff0000',
    //     // circleRadius: 4,
    //   ));

    //   mapController.animateCamera(CameraUpdate.newLatLng(
    //       LatLng(location.coords.latitude, location.coords.longitude)));
    // }

    var countStored = await countTracks();
    var vcountSnaps = await countSnaps();

    // Update the persistent-state display.
    setState(() {
      _tripDistance = _distanceTracker.distance;
      _countStored = countStored;
      _countSnaps = vcountSnaps;
      _paintList.add(ap);
      if (_paintList.length > 3600) {
        _paintList.removeAt(0);
      }
    });

    // If we're not at a push mod, we're done.
    var pushevery = (prefs.sharedPrefs.getDouble(prefs.kPushInterval)).toInt();

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

    var allowWifi = prefs.sharedPrefs.getBool(prefs.kAllowPushWithWifi);
    var allowMobile = prefs.sharedPrefs.getBool(prefs.kAllowPushWithMobile);

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Visibility(
            visible: _appErrorStatus != "" || _appLocationErrorStatus != '',
            child: Container(
              color: MyTheme.errorColor,
              // decoration: BoxDecoration(
              //     border: Border(
              //         top: BorderSide(color: MyTheme.errorColor, width: 4))),
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                      child: Text(
                    [_appErrorStatus, _appLocationErrorStatus].join(' '),
                  ))
                ],
              ),
            ),
          ),

          // Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       children: [
          //         // Expanded(
          //         //   flex: 2,
          //         //   child: Container(
          //         //     padding: EdgeInsets.all(4),
          //         //     child: Row(
          //         //       mainAxisAlignment: MainAxisAlignment.center,
          //         //       children: [
          //         //         _bgGeolocationIsEnabled
          //         //             ? Icon(Icons.check_box_outlined,
          //         //                 color: Colors.green[700], size: 16)
          //         //             : Icon(Icons.check_box_outline_blank,
          //         //                 color: Colors.red[700], size: 16)
          //         //       ],
          //         //     ),
          //         //     // decoration: BoxDecoration(
          //         //     //     border: Border(
          //         //     //         bottom:
          //         //     //             BorderSide(color: Colors.white, width: 4))),
          //         //   ),
          //         // ),
          //         // Expanded(
          //         //     // flex: 2,
          //         //     child: Container(
          //         //       // padding: EdgeInsets.all(8.0),
          //         //       // child: Expanded(
          //         //       height: 24,
          //         //       child: Container(),
          //         //       // RawMaterialButton(
          //         //       //     // MaterialStateProperty.all<Color>(Colors.lime)),
          //         //       //     elevation: 4.0,
          //         //       //     // shape: CircleBorder(),
          //         //       //     // padding: EdgeInsets.all(8.0),
          //         //       //     fillColor: Colors.deepOrange,
          //         //       //     onPressed: () async {
          //         //       //       var loc = await bg.BackgroundGeolocation
          //         //       //           .getCurrentPosition();
          //         //       //       _handleStreamLocationUpdate(loc);
          //         //       //       // ScaffoldMessenger.of(context).showSnackBar(
          //         //       //       //   _buildSnackBar(Text('Points!'),
          //         //       //       //       backgroundColor: Colors.green),
          //         //       //       // );
          //         //       //     },
          //         //       //     child: Icon(Icons.plus_one,
          //         //       //         semanticLabel: 'Point', size: 16)
          //         //       //         ),
          //         //     )),
          //         Expanded(
          //             flex: 2,
          //             child: Container(
          //               height: 36,
          //               // padding: EdgeInsets.all(8.0),
          //               child: RawMaterialButton(
          //                   // fillColor: _countStored > 0 &&
          //                   //         (_connectionStatus.contains('wifi') ||
          //                   //             _connectionStatus.contains('mobile'))
          //                   //     ? MyTheme.buttonColor
          //                   //     : Colors.grey,
          //                   onPressed: _countStored > 0 &&
          //                           (_connectionStatus.contains('wifi') ||
          //                               _connectionStatus.contains('mobile'))
          //                       ? () {
          //                           if (_countStored == 0) return;

          //                           // set up the buttons
          //                           Widget cancelButton = ElevatedButton(
          //                             child: Text("Cancel"),
          //                             style: ButtonStyle(
          //                                 backgroundColor:
          //                                     MaterialStateProperty.all<Color>(
          //                                         Colors.grey)),
          //                             onPressed: () {
          //                               Navigator.of(context,
          //                                       rootNavigator: true)
          //                                   .pop('dialog');
          //                             },
          //                           ); // set up the AlertDialog
          //                           Widget continueButton = ElevatedButton(
          //                             child: Text("Yes, upload"),
          //                             onPressed: () async {
          //                               this._pushTracksBatching();
          //                               Navigator.of(context,
          //                                       rootNavigator: true)
          //                                   .pop('dialog');
          //                             },
          //                           ); // set up the AlertDialog
          //                           AlertDialog alert = AlertDialog(
          //                             title: Text("Confirm upload"),
          //                             content: Text(
          //                                 'Would you like to upload ${_countStored} tracks?'),
          //                             actions: [
          //                               cancelButton,
          //                               continueButton,
          //                             ],
          //                           ); // show the dialog
          //                           showDialog(
          //                             context: context,
          //                             builder: (BuildContext context) {
          //                               return alert;
          //                             },
          //                           );
          //                         }
          //                       : null,
          //                   child: Row(
          //                       mainAxisAlignment: MainAxisAlignment.center,
          //                       children: [
          //                         Icon(
          //                           Icons.cloud_upload,
          //                           semanticLabel: 'Push',
          //                           size: 16,
          //                         ),
          //                         Container(
          //                           width: 8,
          //                           alignment: Alignment.center,
          //                           child: Text(':',
          //                               style:
          //                                   TextStyle(/*color: Colors.white*/)),
          //                         ),
          //                         buildConnectStatusIcon(_connectionStatus,
          //                             size: 16),
          //                       ])),
          //             )),

          //         Visibility(
          //           visible: _isManuallyRequestingLocation,
          //           child: Container(
          //             height: 8,
          //             width: 24,
          //             child: LinearProgressIndicator(
          //               minHeight: 2,
          //               backgroundColor: Colors.deepOrange,
          //             ),
          //           ),
          //         ),

          //         // To settings.
          //         Expanded(
          //             flex: 2,
          //             child: Container(
          //               // padding: EdgeInsets.all(8.0),
          //               // child: Expanded(

          //               height: 36,
          //               child: RawMaterialButton(
          //                   // fillColor: Colors.indigo,
          //                   onPressed: () {
          //                     Navigator.push(
          //                       context,
          //                       MaterialPageRoute(
          //                         builder: (context) => prefs.MySettingsScreen(
          //                           deviceUUID: _deviceUUID,
          //                           deviceName: _deviceName,
          //                           deviceVersion: _deviceAppVersion,
          //                         ),
          //                       ),
          //                     );
          //                   },
          //                   onLongPress: () {
          //                     Navigator.push(
          //                         context,
          //                         MaterialPageRoute(
          //                             builder: (context) => LoggerScreen()));
          //                   },
          //                   child: Icon(
          //                     Icons.settings,
          //                     size: 16,
          //                   )),
          //             )),
          //       ],
          //     ),

          //     // LinearProgressIndicator(
          //     //   minHeight: 4,
          //     //   value: _isPushing
          //     //       ? null
          //     //       : _countStored.toDouble() / _pushEvery.toDouble(),
          //     //   // backgroundColor: ,
          //     // ),
          //   ],
          // ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  // padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onLongPress: _countStored > 0 &&
                                (_connectionStatus.contains('wifi') ||
                                    _connectionStatus.contains('mobile'))
                            ? () {
                                if (_countStored == 0) return;

                                // set up the buttons
                                Widget cancelButton = ElevatedButton(
                                  child: Text("Cancel"),
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.grey)),
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop('dialog');
                                  },
                                ); // set up the AlertDialog
                                Widget continueButton = ElevatedButton(
                                  child: Text("Yes, upload"),
                                  onPressed: () async {
                                    this._pushTracksBatching();
                                    Navigator.of(context, rootNavigator: true)
                                        .pop('dialog');
                                  },
                                ); // set up the AlertDialog
                                AlertDialog alert = AlertDialog(
                                  title: Text("Confirm upload"),
                                  content: Text(
                                      'Would you like to upload ${_countStored} tracks?'),
                                  actions: [
                                    cancelButton,
                                    continueButton,
                                  ],
                                ); // show the dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return alert;
                                  },
                                );
                              }
                            : null,
                        child: Container(
                          padding: EdgeInsets.only(left: 8.0, right: 4),
                          child: buildConnectStatusIcon(_connectionStatus),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          setState(() {
                            _isManuallyRequestingLocation = true;
                          });
                          try {
                            var loc = await bg.BackgroundGeolocation
                                .getCurrentPosition();
                            _handleStreamLocationUpdate(loc);
                          } catch (err) {
                            _handleStreamLocationError(err);
                          }
                          setState(() {
                            _isManuallyRequestingLocation = false;
                          });
                        },
                        onLongPress: () async {
                          var targetState = !glocation?.isMoving ?? true;
                          bg.BackgroundGeolocation.changePace(targetState);
                          ScaffoldMessenger.of(context).showSnackBar(
                            _buildSnackBar(
                                Text(targetState
                                    ? 'Device is in motion.'
                                    : 'Device is stationary.'),
                                backgroundColor:
                                    targetState ? Colors.green : Colors.red),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 4.0),
                              child: buildActivityIcon(
                                  context, glocation.activity.type, null),
                            ),
                            Visibility(
                              visible: !glocation?.isMoving ?? false,
                              child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                                  // margin: EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.trip_origin,
                                    color: Colors.red[700],
                                  )),
                            ),
                            Visibility(
                              visible: glocation?.isMoving ?? false,
                              child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                                  // margin: EdgeInsets.only(left: 6),
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      value: 1 -
                                          ((DateTime.now().millisecondsSinceEpoch /
                                                          1000) -
                                                      DateTime.parse(glocation
                                                                  .timestamp)
                                                              .millisecondsSinceEpoch /
                                                          1000)
                                                  .toDouble() /
                                              (prefs.sharedPrefs.getDouble(prefs
                                                      .kLocationUpdateStopTimeout) *
                                                  60),
                                      strokeWidth: 4,
                                      backgroundColor: Colors.deepOrange)),
                            ),
                            Visibility(
                              visible: true,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                padding: EdgeInsets.only(
                                    left: 4, right: 4, bottom: 4),
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color:
                                                colorForDurationSinceLastPoint(
                                                    _secondsSinceLastPoint),
                                            width: 2))),
                                child: Row(
                                  children: [
                                    Icon(Icons.timelapse,
                                        color: colorForDurationSinceLastPoint(
                                            _secondsSinceLastPoint),
                                        size: 16),
                                    Container(
                                      width: 4,
                                    ),
                                    Text(
                                      '-' +
                                          secondsToPrettyDuration(
                                              _secondsSinceLastPoint.toDouble(),
                                              true),
                                      style: TextStyle(
                                          color: colorForDurationSinceLastPoint(
                                              _secondsSinceLastPoint)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Visibility(
                              visible: _isManuallyRequestingLocation,
                              child: Container(
                                padding: EdgeInsets.only(left: 4.0),
                                height: 4,
                                width: 24,
                                child: LinearProgressIndicator(
                                  minHeight: 2,
                                  backgroundColor: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onLongPress: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackListScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Icon(Icons.storage,
                                  color: MyTheme.accentColor, size: 16),
                              Container(
                                width: 4,
                              ),
                              Text(
                                (_countStored).toString(),
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: MyTheme.accentColor, width: 2))),
                        ),
                      ),

                      InkWell(
                        onLongPress: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyCatSnapsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  color: Colors.deepPurple[400], size: 16),
                              Container(
                                width: 4,
                              ),
                              Text(
                                _countSnaps.toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.deepPurple[700],
                                      width: 2))),
                        ),
                      ),

                      if (_isPushing)
                        Container(
                          width: 24,
                          padding: EdgeInsets.all(4),
                          child: LinearProgressIndicator(
                            backgroundColor: MyTheme.buttonColor,
                          ),
                        ),

                      // LinearProgressIndicator(
                      //   minHeight: 4,
                      //   value: _isPushing
                      //       ? null
                      //       : _countStored.toDouble() / _pushEvery.toDouble(),
                      //   // backgroundColor: ,
                      // ),
                      Container(
                        padding: EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_done_outlined,
                              color: MyTheme.buttonColor,
                              size: 16,
                            ),
                            Container(
                              width: 4,
                            ),
                            Text(
                              _countPushed.toString(),
                              style: TextStyle(color: Colors.white),
                            )
                          ],
                        ),
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: MyTheme.buttonColor, width: 2))),
                      ),
                      Container(
                        padding: EdgeInsets.all(4),
                        child: InkWell(
                          onTap: () {
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
                          onLongPress: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoggerScreen()));
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color:
                                    MyTheme.colorScheme.onSurface.withAlpha(64),
                              ),
                            ],
                          ),
                        ),
                        // decoration: BoxDecoration(
                        //     border: Border(
                        //         bottom: BorderSide(
                        //             color: MyTheme.accentColor, width: 2))),
                      ),
                    ],
                  ),
                ],
              )),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 16),
                  child: CustomPaint(
                    // size: Size.infinite,
                    painter: ShapesPainter(locations: _paintList),
                    child: Container(
                      height: 400,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InfoDisplay(
                keyname: "km/h",
                value: glocation.coords.speed <= 0
                    ? 0
                    : ((glocation.coords.speed ?? 0) * 3.6).toPrecision(1),
                options: {
                  'third': Text(glocation.coords.speedAccuracy != null
                      ? glocation.coords.speedAccuracy.toString()
                      : '')
                },
              ),
              // InkWell(
              //   onTap: () async {
              //     setState(() {
              //       _isManuallyRequestingLocation = true;
              //     });
              //     var loc = await bg.BackgroundGeolocation.getCurrentPosition();
              //     _handleStreamLocationUpdate(loc);
              //     setState(() {
              //       _isManuallyRequestingLocation = false;
              //     });

              //     // ScaffoldMessenger.of(context).showSnackBar(
              //     //   _buildSnackBar(Text('Points!'),
              //     //       backgroundColor: Colors.green),
              //     // );
              //   },
              //   child: Column(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     children: [
              //       // cativity icon
              //       Container(
              //         width: 96,
              //         height: 64,
              //         child: buildActivityIcon(
              //             context,
              //             glocation.activity.type,
              //             64 - _secondsSinceLastPoint.toDouble() > 16
              //                 ? 64 - _secondsSinceLastPoint.toDouble()
              //                 : 16),
              //       ),
              //     ],
              //   ),
              // ),
              InfoDisplay(
                keyname: "heading",
                value: degreeToCardinalDirection(glocation.coords.heading),
                options: {
                  'third': Text(glocation.coords.headingAccuracy
                      ?.toPrecision(1)
                      .toString())
                },
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              InfoDisplay(
                  keyname: "accuracy", value: glocation.coords.accuracy),

              // InkWell(
              //   onTap: () async {
              //     setState(() {
              //       _isManuallyRequestingLocation = true;
              //     });
              //     var loc = await bg.BackgroundGeolocation.getCurrentPosition();
              //     _handleStreamLocationUpdate(loc);
              //     setState(() {
              //       _isManuallyRequestingLocation = false;
              //     });

              //     // ScaffoldMessenger.of(context).showSnackBar(
              //     //   _buildSnackBar(Text('Points!'),
              //     //       backgroundColor: Colors.green),
              //     // );
              //   },
              //   child: Column(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Container(
              //         padding: EdgeInsets.only(left: 4, right: 4, bottom: 8),
              //         child: Column(
              //           mainAxisAlignment: MainAxisAlignment.spaceAround,
              //           mainAxisSize: MainAxisSize.min,
              //           children: [
              //             Visibility(
              //                 visible: true,
              //                 child: (glocation?.isMoving ?? false)
              //                     ? Container(
              //                         // margin: EdgeInsets.only(left: 6),
              //                         child: Icon(
              //                         Icons.circle,
              //                         color: MyTheme.accentColor,
              //                       ))
              //                     : Container(
              //                         margin: EdgeInsets.symmetric(vertical: 6),
              //                         child: Icon(
              //                           Icons.trip_origin,
              //                           color: Colors.red[700],
              //                         ))),
              //             Visibility(
              //               visible: _secondsSinceLastPoint > 3,
              //               child: Row(
              //                 children: [
              //                   Icon(Icons.timelapse,
              //                       color: colorForDurationSinceLastPoint(
              //                           _secondsSinceLastPoint),
              //                       size: 16),
              //                   Container(
              //                     width: 4,
              //                   ),
              //                   Text(
              //                     '-' +
              //                         secondsToPrettyDuration(
              //                             _secondsSinceLastPoint.toDouble()),
              //                     style: TextStyle(color: Colors.white),
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ],
              //         ),
              //         // decoration: BoxDecoration(
              //         //     border: Border(
              //         //         bottom: BorderSide(
              //         //             color: colorForDurationSinceLastPoint(
              //         //                 _secondsSinceLastPoint),
              //         //             width: 0))),
              //       ),
              //     ],
              //   ),
              // ),

              InfoDisplay(
                keyname: "elevation",
                value: glocation.coords.altitude,
                options: {
                  'third': Text(glocation.coords.altitudeAccuracy
                      ?.toPrecision(1)
                      .toString())
                },
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.only(topRight: Radius.circular(8)),
                child: Container(
                  padding: EdgeInsets.all(12),
                  child: InfoDisplay(
                    keyname: "distance",
                    value: _tripDistance < 1000
                        ? (_tripDistance ~/ 1).toString() + 'm'
                        : ((_tripDistance / 1000).toPrecision(2)).toString() +
                            'km',
                    options: {
                      't2.font': Theme.of(context).textTheme.headline6,
                      'third':
                          Text(glocation.odometer.toInt().toString() + ' steps')
                    },
                  ),
                ),
                onLongPress: () {
                  // set up the buttons
                  Widget cancelButton = ElevatedButton(
                    child: Text("Cancel"),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.grey)),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop('dialog');
                    },
                  ); // set up the AlertDialog
                  Widget continueButton = ElevatedButton(
                    child: Text('Yes, reset'),
                    onPressed: () {
                      setState(() {
                        bg.BackgroundGeolocation.setOdometer(0);
                        _distanceTracker.reset();
                        _paintList = [];
                        _tripStarted = DateTime.now().toUtc();
                      });

                      Navigator.of(context, rootNavigator: true).pop('dialog');

                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildSnackBar(Text('Trip has been reset.'),
                            backgroundColor: Colors.green),
                      );
                    },
                  ); // set up the AlertDialog
                  AlertDialog alert = AlertDialog(
                    title: Text("Confirm trip reset"),
                    content: Text(
                        "This will reset the map, odometer, and distance."),
                    actions: [
                      cancelButton,
                      continueButton,
                    ],
                  ); // show the dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return alert;
                    },
                  );
                },
              ),
              // InfoDisplay(
              //   keyname: "odometer",
              //   value: glocation.odometer.toInt(),
              //   options: {
              //     't2.font': Theme.of(context).textTheme.headline6,
              //   },
              // ),
              // Expanded(
              //   child: Container(
              //     width: 72,
              //   ),
              // ),

              Container(
                padding: EdgeInsets.all(12),
                child: InfoDisplay(
                    keyname: "elevation Δ",
                    value: '+${_distanceTracker.up}-${_distanceTracker.dn}',
                    options: {
                      't2.font': Theme.of(context).textTheme.headline6,
                      'third': Text(
                          (_distanceTracker.elev_rel()).toInt().toString()),
                    }),
              ),
            ],
          ),

          // Row(
          //   children: [
          //     Expanded(
          //         child: Container(
          //       height: 128,
          //       padding:
          //           const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          //       // child: ElevatedButton(
          //       //   style: ElevatedButton.styleFrom(
          //       //       elevation: 3.0,
          //       //       primary: Colors.deepPurple[700],
          //       //       padding: EdgeInsets.all(8)),
          //       //   onPressed: () {
          //       //     Navigator.push(
          //       //       context,
          //       //       MaterialPageRoute(
          //       //         builder: (context) =>
          //       //             TakePictureScreen(camera: firstCamera),
          //       //       ),
          //       //     );
          //       //   },
          //       //   child: Row(
          //       //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //       //       children: [
          //       //         // Text('Cat snap',
          //       //         //     style: Theme.of(context).textTheme.overline),
          //       //         Icon(Icons.add_a_photo_outlined,
          //       //             size: 48,
          //       //             color: Colors.deepOrange /*green[300]*/),

          //       //         // Icon(
          //       //         //   Icons.camera_alt,
          //       //         //   size: 64,
          //       //         //   color: Colors.lime, // green
          //       //         // ),
          //       //       ]),
          //       // )
          //     ))
          //   ],
          // )

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.deepOrange,
        elevation: 50,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakePictureScreen(camera: firstCamera),
            ),
          );
          countSnaps().then((value) {
            setState(() {
              _countSnaps = value;
            });
          });
        },
        tooltip: 'Camera',
        icon: Icon(Icons.camera),
        label: Text('Catsnap!'),
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
      ResolutionPreset.veryHigh,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  takePicture() async {
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
      await _controller.takePicture().then((value) => value.saveTo(path));
      // _controller.setFlashMode(FlashMode.off);
      // xpath.saveTo(path);

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
        title: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Icon(
            Icons.add_a_photo_outlined,
            color: Colors.deepOrange,
          ),
          // Container(
          //   width: 16,
          // ),
          // Text('Cat snap')
        ]),
        backgroundColor: MyTheme.canvasColor,
        foregroundColor: Colors.deepOrange,
      ),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
              child: FutureBuilder<void>(
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
          )),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        autofocus: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.deepPurple[700],
        child: Icon(Icons.camera),
        onPressed: takePicture,
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
      appBar: AppBar(
        backgroundColor: MyTheme.canvasColor,
        foregroundColor: Colors.deepOrange,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.deepOrange),
            Icon(Icons.library_add_check, color: Colors.deepOrange),
          ],
        ),

        // backgroundColor: Colors.lime,
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Flexible(child: Image.file(File(imagePath))),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.save),
        label: Text('Save'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.deepOrange,
        onPressed: () async {
          // Get location.
          var location = await bg.BackgroundGeolocation.getCurrentPosition();

          // Read and rotate the image according to exif data as needed.
          final img.Image capturedImage =
              img.decodeImage(await File(imagePath).readAsBytes());
          final img.Image orientedImage = img.bakeOrientation(capturedImage);

          // Move the image from the temporary store to persistent app data.
          Directory persistentDir = await getApplicationDocumentsDirectory();
          String persistentPath = join(persistentDir.path, basename(imagePath));

          await File(persistentPath)
              .writeAsBytes(img.encodeJpg(orientedImage), flush: true);

          // Add the snap to the cat track.
          var p = AppPoint.fromLocationProvider(location);
          p.image_file_path = persistentPath;
          // p.imgB64 = base64Encode(File(imagePath).readAsBytesSync());

          // Save it.
          await insertTrackForce(p);

          // Delete the original image file.
          File(imagePath).deleteSync();

          // Go back home.
          Navigator.popUntil(context, ModalRoute.withName('/'));

          ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(
              Text('Cat snap saved.'),
              backgroundColor: Colors.lightGreen));

          return null;
        },
      ),
    );
  }
}

String degreeToCardinalDirection(double heading) {
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

// A widget that displays the picture taken by the user.
class LoggerScreen extends StatelessWidget {
  const LoggerScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.pageview),
          ],
        ),
        // backgroundColor: Colors.lime,
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: ListView(
        children: [
          new FutureBuilder<bg.State>(
            future: bg.BackgroundGeolocation.state, // a Future<String> or null
            builder: (BuildContext context, AsyncSnapshot<bg.State> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return new Text('Initializing...');
                case ConnectionState.waiting:
                  return new Text('Awaiting result...');
                default:
                  if (snapshot.hasError)
                    return new Text('Error: ${snapshot.error}');
                  else
                    return new Text(
                      '${snapshot.data.toString()}',
                      style: Theme.of(context)
                          .textTheme
                          .apply(fontSizeFactor: 0.8)
                          .bodyText2,
                    );
              }
            },
          ),
          new FutureBuilder<String>(
            future: bg.Logger.getLog(), // a Future<String> or null
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return new Text('Initializing...');
                case ConnectionState.waiting:
                  return new Text('Awaiting result...');
                default:
                  if (snapshot.hasError)
                    return new Text('Error: ${snapshot.error}');
                  else
                    return new Text(
                      '${snapshot.data.split("\n").reversed.join("\n")}',
                      style: Theme.of(context)
                          .textTheme
                          .apply(fontSizeFactor: 0.8)
                          .bodyText2,
                    );
              }
            },
          ),
        ],
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class TrackListScreen extends StatelessWidget {
  const TrackListScreen({Key key}) : super(key: key);

  Widget _buildListTileTitle(
      {BuildContext context, AppPoint prev, AppPoint point, AppPoint next}) {
    Row row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [],
    );

    if (prev == null) row.children.add(Text('${point.time} '));

    row.children.add(Text(
        '${next != null ? "+" + secondsToPrettyDuration((point.timestamp - next.timestamp).toDouble()) : ""}'));

    if (point.event != '')
      row.children.add(Chip(
        backgroundColor: Colors.teal,
        label: Text(point.event),
      ));

    return row;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.storage_outlined,
            ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.deepOrange,
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: SafeArea(
        child: new FutureBuilder<List<AppPoint>>(
          future: lastTracksWithLimit(3600), // a Future<String> or null
          builder:
              (BuildContext context, AsyncSnapshot<List<AppPoint>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return new Text('Initializing...');
              case ConnectionState.waiting:
                return new Text('Awaiting result...');
              default:
                if (snapshot.hasError)
                  return new Text('Error: ${snapshot.error}');
                else
                  return ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        int sdl = snapshot.data.length;
                        // if (index >= snapshot.data.length) return Container();
                        final AppPoint prev = (index - 1 >= 0)
                            ? snapshot.data.elementAt(index - 1)
                            : null;
                        final AppPoint point = snapshot.data.elementAt(index);
                        final AppPoint next = (index + 1 <= sdl - 1)
                            ? snapshot.data.elementAt(index + 1)
                            : null;

                        return ListTile(
                          dense: true,
                          leading: buildActivityIcon(
                              context, point.activity_type, 16),
                          title: _buildListTileTitle(
                            context: context,
                            prev: prev,
                            point: point,
                            next: next,
                          ),
                          subtitle: Text(
                              '+/-${point.accuracy}m  ${(point.speed * 3.6).toPrecision(1)}km/h  ↑${point.altitude}m'),
                        );
                      });
              // return new Text(
              //   '${snapshot.data.split("\n").reversed.join("\n")}',
              //   style: Theme.of(context)
              //       .textTheme
              //       .apply(fontSizeFactor: 0.8)
              //       .bodyText2,
              // );
            }
          },
        ),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class MyCatSnapsScreen extends StatelessWidget {
  const MyCatSnapsScreen({Key key}) : super(key: key);

  // Widget _buildListTileTitle(
  //     {BuildContext context, AppPoint prev, AppPoint point, AppPoint next}) {
  //   Row row = Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [],
  //   );

  //   if (prev == null) row.children.add(Text('${point.time} '));

  //   row.children.add(Text(
  //       '${next != null ? "+" + secondsToPrettyDuration((point.timestamp - next.timestamp).toDouble()) : ""}'));

  //   if (point.event != '')
  //     row.children.add(Chip(
  //       backgroundColor: Colors.teal,
  //       label: Text(point.event),
  //     ));

  //   return row;
  // }

  List<Widget> _buildSnaps(List<AppPoint> snaps) {
    List<Widget> out = [];
    for (var snap in snaps) {
      out.add(Row(
        children: [
          Flexible(
              child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Image.file(File(snap.image_file_path)))),
        ],
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.image, color: Colors.deepOrange),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.deepOrange,
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: SafeArea(
        child: new FutureBuilder<List<AppPoint>>(
          future: snaps(), // a Future<String> or null
          builder:
              (BuildContext context, AsyncSnapshot<List<AppPoint>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return new Text('Initializing...');
              case ConnectionState.waiting:
                return new Text('Awaiting result...');
              default:
                if (snapshot.hasError)
                  return new Text('Error: ${snapshot.error}');
                else
                  return ListView(
                    children: _buildSnaps(snapshot.data),
                  );
              // return new Text(
              //   '${snapshot.data.split("\n").reversed.join("\n")}',
              //   style: Theme.of(context)
              //       .textTheme
              //       .apply(fontSizeFactor: 0.8)
              //       .bodyText2,
              // );
            }
          },
        ),
      ),
    );
  }
}
