// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:gcps/config.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:just_debounce_it/just_debounce_it.dart';

const String kAllowPushWithMobile = "allowPushWithMobile";
const String kAllowPushWithWifi = "allowPushWithWifi";
const String kPushInterval = "pushIntervalNumber";
const String kPushBatchSize = "pushBatchSize";
const String kLocationUpdateInterval = "locationUpdateInterval";
const String kLocationUpdateDistanceFilter = "locationUpdateDistanceFilter";
const String kLocationUpdateStopTimeout = "locationUpdateStopTimeout";
const String kLocationGarneringDesiredAccuracy =
    'kLocationGarneringDesiredAccuracy';
const String kLocationGarneringElasticityMultiplier =
    'locationGarneringElasticityMultiplier';
const String kLocationGarneringStationaryTimeout =
    'locationGarneringStationaryTimeout';
const String kLocationDisableStopDetection = 'kLocationDisableStopDetection';
const String kLocationDeviceInMotion = 'kLocationDeviceInMotion';
// const String kLocationUpdateStopTimeou = "locationUpdateStopTimeout";

class SharedPrefs {
  static SharedPreferences _sharedPrefs;

  init() async {
    if (_sharedPrefs == null) {
      _sharedPrefs = await SharedPreferences.getInstance();
    }
  }

  double getDouble(String key) {
    switch (key) {
      case kPushInterval:
        return _sharedPrefs.get(kPushInterval) ?? 100;
        break;
      case kPushBatchSize:
        return _sharedPrefs.get(kPushBatchSize) ?? 100;
        break;
      case kLocationUpdateInterval:
        return _sharedPrefs.get(kLocationUpdateInterval) ?? 0;
        break;
      case kLocationUpdateDistanceFilter:
        return _sharedPrefs.get(kLocationUpdateDistanceFilter) ?? 1;
        break;
      case kLocationUpdateStopTimeout:
        return _sharedPrefs.get(kLocationUpdateStopTimeout) ?? 5;
        break;

      case kLocationGarneringElasticityMultiplier:
        return _sharedPrefs.get(kLocationGarneringElasticityMultiplier) ?? 0;
        break;
      case kLocationGarneringStationaryTimeout:
        return _sharedPrefs.get(kLocationGarneringStationaryTimeout) ?? 0;
        break;
      default:
        print('!!!! I AM IMPOSSIBILITY');
        return 0;
    }
  }

  setDouble(String key, double value) {
    // Validations.
    switch (key) {
      case kPushInterval:
        break;
      case kPushBatchSize:
        if (value > 3600) value = 3600;
        break;
      case kLocationUpdateInterval:
        break;
      case kLocationUpdateDistanceFilter:
        break;
      case kLocationUpdateStopTimeout:
        break;
      case kLocationGarneringDesiredAccuracy:
        break;
      case kLocationGarneringElasticityMultiplier:
        break;
      case kLocationGarneringStationaryTimeout:
        break;
      default:
        print('!!!! I AM IMPOSSIBILITY');
        return;
    }
    _sharedPrefs.setDouble(key, value);
  }

  bool getBool(String key) {
    switch (key) {
      case kAllowPushWithMobile:
        return _sharedPrefs.getBool(kAllowPushWithMobile) ?? true;
      case kAllowPushWithWifi:
        return _sharedPrefs.getBool(kAllowPushWithWifi) ?? true;
      case kLocationDisableStopDetection:
        return _sharedPrefs.getBool(kLocationDisableStopDetection) ?? false;
      case kLocationDeviceInMotion:
        return _sharedPrefs.getBool(kLocationDeviceInMotion) ?? true;
      default:
        print('!!!! I AM IMPOSSIBILITY');
        return false;
    }
  }

  setBool(String key, bool value) {
    switch (key) {
      case kAllowPushWithMobile:
        break;
      case kAllowPushWithWifi:
        break;
      case kLocationDisableStopDetection:
        break;
      case kLocationDeviceInMotion:
        break;
      default:
        print('!!!! I AM IMPOSSIBILITY');
        return;
    }
    _sharedPrefs.setBool(key, value);
  }

  String getString(String key) {
    switch (key) {
      case kLocationGarneringDesiredAccuracy:
        return _sharedPrefs.get(kLocationGarneringDesiredAccuracy) ??
            'NAVIGATION';
    }
  }

  setString(String key, String value) {
    switch (key) {
      case kLocationGarneringDesiredAccuracy:
        return _sharedPrefs.setString(kLocationGarneringDesiredAccuracy, value);
    }
  }
}

final sharedPrefs = SharedPrefs();

int prefLocationDesiredAccuracy(String value) {
  switch (value) {
    case 'NAVIGATION':
      return bg.Config.DESIRED_ACCURACY_NAVIGATION;
    case 'HIGH':
      return bg.Config.DESIRED_ACCURACY_HIGH;
    case 'MEDIUM':
      return bg.Config.DESIRED_ACCURACY_MEDIUM;
    case 'LOW':
      return bg.Config.DESIRED_ACCURACY_LOW;
    case 'VERY_LOW':
      return bg.Config.DESIRED_ACCURACY_VERY_LOW;
    case 'LOWEST':
      return bg.Config.DESIRED_ACCURACY_LOWEST;
  }
  return bg.Config.DESIRED_ACCURACY_NAVIGATION;
}

TextTheme settingsThemeText(context) {
  return Theme.of(context).textTheme.apply(bodyColor: Colors.tealAccent);
}

Widget _buildSwitchTile({
  BuildContext context,
  Widget leading,
  String title,
  String subtitle,
  bool value,
  void Function(bool) onChanged,
}) {
  return ListTile(
    leading: leading,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(title),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.caption,
        )
      ],
    ),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
    ),
  );
}

Widget _buildSliderTile({
  BuildContext context,
  Widget leading,
  String title,
  String subtitle,
  double min,
  double max,
  int divisions,
  double value,
  void Function(double value) onChanged,
}) {
  return ListTile(
    leading: leading,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: EdgeInsets.only(top: 6), child: Text(title)),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.caption,
        )
      ],
    ),
    subtitle: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(min.toInt().toString()),
      Expanded(
        child: Slider(
            min: min,
            max: max,
            value: value,
            divisions: divisions,
            onChanged: onChanged),
      ),
      Text(max.toInt().toString()),
    ]),
    trailing:
        Text('${value.toInt()}', style: settingsThemeText(context).headline5),
  );
}

class MySettingsScreen extends StatefulWidget {
  final String deviceUUID;
  final String deviceName;
  final String deviceVersion;

  const MySettingsScreen({
    Key key,
    this.deviceUUID,
    this.deviceName,
    this.deviceVersion,
  }) : super(key: key);

  @override
  _SettingsScreen createState() => _SettingsScreen(
        deviceUUID: this.deviceUUID,
        deviceName: this.deviceName,
        deviceVersion: this.deviceVersion,
      );
}

class _SettingsScreen extends State<MySettingsScreen> {
  final String deviceUUID;
  final String deviceName;
  final String deviceVersion;

  _SettingsScreen({
    Key key,
    this.deviceUUID,
    this.deviceName,
    this.deviceVersion,
  });

  bool _kAllowPushWithMobile = sharedPrefs.getBool(kAllowPushWithMobile);
  bool _kAllowPushWithWifi = sharedPrefs.getBool(kAllowPushWithWifi);
  bool _kLocationDisableStopDetection =
      sharedPrefs.getBool(kLocationDisableStopDetection);
  bool _kLocationDeviceInMotion = sharedPrefs.getBool(kLocationDeviceInMotion);
  double _kPushInterval = sharedPrefs.getDouble(kPushInterval);
  double _kPushBatchSize = sharedPrefs.getDouble(kPushBatchSize);
  double _kLocationUpdateInterval =
      sharedPrefs.getDouble(kLocationUpdateInterval);
  double _kLocationUpdateDistanceFilter =
      sharedPrefs.getDouble(kLocationUpdateDistanceFilter);
  double _kLocationUpdateStopTimeout =
      sharedPrefs.getDouble(kLocationUpdateStopTimeout);
  double _kLocationGarneringElasticityMultiplier =
      sharedPrefs.getDouble(kLocationGarneringElasticityMultiplier);
  double _kLocationGarneringStationaryTimeout =
      sharedPrefs.getDouble(kLocationGarneringStationaryTimeout);
  String _kLocationGarneringDesiredAccuracy =
      sharedPrefs.getString(kLocationGarneringDesiredAccuracy);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        // backgroundColor: Colors.amber,
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Push (upload) configuration',
                    style: Theme.of(context).textTheme.overline),
              ),
            ],
          ),

          _buildSwitchTile(
              context: context,
              leading: Icon(Icons.wifi),
              title: 'Push with wifi',
              subtitle: 'Allow automatic upload with a wifi connection.',
              value: _kAllowPushWithWifi,
              onChanged: (bool value) {
                setState(() {
                  _kAllowPushWithWifi = value;
                  sharedPrefs.setBool(kAllowPushWithWifi, value);
                });
              }),

          _buildSwitchTile(
              context: context,
              leading: Icon(Icons.network_cell),
              title: 'Push with mobile',
              subtitle: 'Allow automatic upload with a mobile connection.',
              value: _kAllowPushWithMobile,
              onChanged: (bool value) {
                setState(() {
                  _kAllowPushWithMobile = value;
                  sharedPrefs.setBool(kAllowPushWithMobile, value);
                });
              }),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Location garnering configuration',
                    style: Theme.of(context).textTheme.overline),
              ),
            ],
          ),

          _buildSliderTile(
              context: context,
              leading: Icon(Icons.airline_seat_legroom_extra_outlined),
              title: 'Stop timeout',
              subtitle: 'Minutes of stillness before cat naps.',
              min: 1,
              max: 10,
              divisions: 10,
              value: _kLocationUpdateStopTimeout,
              onChanged: (value) {
                setState(() {
                  _kLocationUpdateStopTimeout = value.ceilToDouble();
                  sharedPrefs.setDouble(kLocationUpdateStopTimeout, value);
                });
              }),

          // SettingsContainer(
          //     child: Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Text('Location update configuration',
          //         style: Theme.of(context).textTheme.overline),
          //   ],
          // )),
          // Stack(
          //   children: [
          //     SliderSettingsTile(
          //       settingKey: kLocationUpdateDistanceFilter,
          //       title: 'Distance filter',
          //       subtitle:
          //           'Δ meters triggering a location update.\nZero causes time updates.',
          //       icon: Icon(Icons.my_location_outlined),
          //       minValue: 0.0,
          //       defaultValue: 1,
          //       maxValue: 100.0,
          //       step: 1.0,
          //       maxIcon: Icon(Icons.arrow_upward),
          //       minIcon: Icon(Icons.arrow_downward),
          //     ),
          //     _settings.onDoubleChanged(
          //         settingKey: kLocationUpdateDistanceFilter,
          //         defaultValue: 1,
          //         childBuilder:
          //             (BuildContext context, double newDistanceFilterValue) {
          //           handleLocationUpdateChanges(
          //               kLocationUpdateDistanceFilter, newDistanceFilterValue);

          //           return Container(
          //               alignment: Alignment.topRight,
          //               padding: EdgeInsets.only(right: 16),
          //               child: Text(
          //                 newDistanceFilterValue.toStringAsFixed(0),
          //                 style: settingsTheme.headline5,
          //               ));
          //         }),
          //   ],
          // ),
          // Stack(
          //   children: [
          //     SliderSettingsTile(
          //       settingKey: kLocationUpdateInterval,
          //       title: 'Time interval',
          //       subtitle:
          //           'Δ seconds triggering a location update.\nZero causes distance updates.',
          //       icon: Icon(Icons.timer),
          //       minValue: 0.0,
          //       defaultValue: 0,
          //       maxValue: 60.0,
          //       step: 1.0,
          //       maxIcon: Icon(Icons.arrow_upward),
          //       minIcon: Icon(Icons.arrow_downward),
          //     ),
          //     _settings.onDoubleChanged(
          //         settingKey: kLocationUpdateInterval,
          //         defaultValue: 0,
          //         childBuilder:
          //             (BuildContext context, double newIntervalValue) {
          //           handleLocationUpdateChanges(
          //               kLocationUpdateInterval, newIntervalValue);

          //           return Container(
          //               alignment: Alignment.topRight,
          //               padding: EdgeInsets.only(right: 16),
          //               child: Text(
          //                 newIntervalValue.toStringAsFixed(0),
          //                 style: settingsTheme.headline5,
          //               ));
          //         }),
          //   ],
          // ),

          // Stack(
          //   children: [
          //     SliderSettingsTile(
          //       settingKey: kLocationGarneringStationaryTimeout,
          //       title: 'Stationary timeout',
          //       subtitle: 'Minutes without motion means cat napping.',
          //       icon: Icon(Icons.airline_seat_legroom_extra_outlined),
          //       minValue: 1.0,
          //       defaultValue: 2,
          //       maxValue: 10.0,
          //       step: 1.0,
          //       maxIcon: Icon(Icons.arrow_upward),
          //       minIcon: Icon(Icons.arrow_downward),
          //     ),
          //     _settings.onDoubleChanged(
          //         settingKey: kLocationGarneringStationaryTimeout,
          //         defaultValue: 0,
          //         childBuilder: (BuildContext context, double value) {
          //           print('[update stopTimeout]: ${value.floor()}');
          //           bg.BackgroundGeolocation.setConfig(bg.Config(
          //             stopTimeout: value.floor(),
          //             isMoving: true,
          //           ));

          //           return Container(
          //               alignment: Alignment.topRight,
          //               padding: EdgeInsets.only(right: 16),
          //               child: Text(
          //                 value.floorToDouble().toStringAsFixed(0),
          //                 style: settingsTheme.headline5,
          //               ));
          //         }),
          //   ],
          // ),

          // // kLocationDisableStopDetection
          // SwitchSettingsTile(
          //   settingKey: kLocationDisableStopDetection,
          //   title: 'Enable stop detection',
          //   subtitle:
          //       'Location tracking toggled automatically\nwhen device is active/stationary.',
          //   subtitleIfOff:
          //       'Location tracking depends on manual cativation and decativation.',
          //   icon: Icon(Icons.trip_origin),
          //   defaultValue: true,
          // ),
          // _settings.onBoolChanged(
          //     settingKey: kLocationDisableStopDetection,
          //     defaultValue: true,
          //     childBuilder: (BuildContext context, bool value) {
          //       bg.BackgroundGeolocation.setConfig(
          //           bg.Config(disableStopDetection: value));
          //       return Container();
          //     }),

          // SwitchSettingsTile(
          //   settingKey: kLocationDeviceInMotion,
          //   title: 'Location tracking active',
          //   icon: Icon(Icons.circle),
          //   defaultValue: true,
          // ),
          // _settings.onBoolChanged(
          //     settingKey: kLocationDeviceInMotion,
          //     defaultValue: true,
          //     childBuilder: (BuildContext context, bool value) {
          //       print('#changePace: ${value}');
          //       bg.BackgroundGeolocation.changePace(value);
          //       return Container();
          //     }),

          //
          // SwitchSettingsTile(
          //   settingKey: kAllowPushWithWifi,
          //   title: 'Push with wifi data',
          //   icon: Icon(Icons.wifi),
          //   defaultValue: true,
          // ),
          // SwitchSettingsTile(
          //   settingKey: kAllowPushWithMobile,
          //   title: 'Push with mobile data',
          //   icon: Icon(Icons.network_cell),
          //   defaultValue: false,
          // ),
          // Stack(
          //   children: [
          //     SliderSettingsTile(
          //       settingKey: kPushInterval,
          //       title: 'Push interval',
          //       // title: 'How often to maybe push points',
          //       subtitle: 'How often to maybe push points.',
          //       icon: Icon(Icons.timelapse_rounded),
          //       minValue: 100.0,
          //       defaultValue: 100,
          //       maxValue: 3600.0,
          //       step: 100.0,
          //       maxIcon: Icon(Icons.arrow_upward),
          //       minIcon: Icon(Icons.arrow_downward),
          //     ),
          //     _settings.onDoubleChanged(
          //         settingKey: kPushInterval,
          //         defaultValue: 100,
          //         childBuilder: (BuildContext context, double value) {
          //           return Container(
          //               alignment: Alignment.topRight,
          //               padding: EdgeInsets.only(right: 16),
          //               child: Text(
          //                 value.toStringAsFixed(0),
          //                 style: settingsThemeText(context).headline5,
          //               ));
          //         }),
          //   ],
          // ),
          // Stack(
          //   children: [
          //     SliderSettingsTile(
          //       settingKey: kPushBatchSize,
          //       title: 'Push batch size',
          //       subtitle: 'Max points in each upload request.',
          //       icon: Icon(Icons.file_upload),
          //       minValue: 100.0,
          //       defaultValue: 100,
          //       maxValue: 3600.0,
          //       step: 100.0,
          //       maxIcon: Icon(Icons.arrow_upward),
          //       minIcon: Icon(Icons.arrow_downward),
          //     ),
          //     _settings.onDoubleChanged(
          //         settingKey: kPushBatchSize,
          //         defaultValue: 100,
          //         childBuilder: (BuildContext context, double value) {
          //           return Container(
          //               alignment: Alignment.topRight,
          //               padding: EdgeInsets.only(right: 16),
          //               child: Text(
          //                 value.toStringAsFixed(0),
          //                 style: settingsThemeText(context).headline5,
          //               ));
          //         }),
          //   ],
          // ),

// // MY SLIDER
//           ListTile(
//             leading: Icon(Icons.ac_unit),
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                     padding: EdgeInsets.only(top: 6),
//                     child: Text('My setting')),
//                 Text(
//                   'A helpful description.',
//                   style: Theme.of(context).textTheme.caption,
//                 )
//               ],
//             ),
//             subtitle: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('0'),
//                   Expanded(
//                     child: Slider(
//                         min: 0,
//                         max: 10,
//                         value: _stopTimeoutValue,
//                         divisions: 10,
//                         onChanged: (double value) {
//                           setState(() {
//                             _stopTimeoutValue = value;
//                           });
//                           print('slider slide: ${value}');
//                         }),
//                   ),
//                   Text('10'),
//                 ]),
//             trailing:
//                 Text('${_stopTimeoutValue}', style: settingsTheme.headline5),
//           ),

          //
          // SettingsContainer(
          //     child: Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Text('Location garnering configuration',
          //         style: Theme.of(context).textTheme.overline),
          //   ],
          // )),

          // RadioSettingsTile(
          //   settingKey: kLocationGarneringDesiredAccuracy,
          //   icon: Icon(Icons.location_searching),
          //   title: 'Desired location accuracy',
          //   defaultKey: 'NAVIGATION',
          //   expandable: true,
          //   initiallyExpanded: false,
          //   values: {
          //     'NAVIGATION': 'Navigation',
          //     'HIGH': 'High',
          //     'MEDIUM': 'Medium',
          //     'LOW': 'Low',
          //     'VERY_LOW': 'Very low',
          //     'LOWEST': 'Lowest',
          //   },
          // ),
          // _settings.onStringChanged(
          //     settingKey: kLocationGarneringDesiredAccuracy,
          //     defaultValue: 'NAVIGATION',
          //     childBuilder: (BuildContext context, String value) {
          //       bg.BackgroundGeolocation.setConfig(bg.Config(
          //         desiredAccuracy: prefLocationDesiredAccuracy(value),
          //         isMoving: true,
          //       ));

          //       return Container();
          //     }),

          // Stack(
          //   children: [
          //     SliderSettingsTile(
          //       settingKey: kLocationGarneringElasticityMultiplier,
          //       title: 'Location elasticity multiplier',
          //       subtitle: 'Higher values yield fewer points for fast cats.',
          //       icon: Icon(Icons.speed_outlined),
          //       minValue: 0.0,
          //       defaultValue: 0,
          //       maxValue: 8,
          //       step: 1.0,
          //       maxIcon: Icon(Icons.arrow_upward),
          //       minIcon: Icon(Icons.arrow_downward),
          //     ),
          //     _settings.onDoubleChanged(
          //         settingKey: kLocationGarneringElasticityMultiplier,
          //         defaultValue: 0,
          //         childBuilder: (BuildContext context, double value) {
          //           bg.BackgroundGeolocation.setConfig(bg.Config(
          //             elasticityMultiplier: value.floorToDouble(),
          //             isMoving: true,
          //           ));

          //           return Container(
          //               alignment: Alignment.topRight,
          //               padding: EdgeInsets.only(right: 16),
          //               child: Text(
          //                 value.floorToDouble().toStringAsFixed(0),
          //                 style: settingsTheme.headline5,
          //               ));
          //         }),
          //   ],
          // ),

          // App metadata
          //
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App version',
                    style: Theme.of(context).textTheme.overline),
                Row(
                  children: [Text(deviceVersion)],
                  mainAxisAlignment: MainAxisAlignment.end,
                ),
                Text('UUID', style: Theme.of(context).textTheme.overline),
                Row(
                  children: [Text(deviceUUID)],
                  mainAxisAlignment: MainAxisAlignment.end,
                ),
                Text('Name', style: Theme.of(context).textTheme.overline),
                Row(
                  children: [Text(deviceName)],
                  mainAxisAlignment: MainAxisAlignment.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    // return Scaffold(
    //   appBar: AppBar(title: Text('Settings')),
    //   body: Container(
    //     child: ListView(
    //       children: [
    //         SwitchSettingsTile(
    //           settingKey: kAllowPushWithMobile,
    //           title: 'Push with mobile data',
    //           defaultValue: false,
    //         ),
    //         SwitchSettingsTile(
    //           settingKey: kAllowPushWithWifi,
    //           title: 'Push with wifi data',
    //           defaultValue: true,
    //         ),
    //         SliderSettingsTile(
    //           settingKey: kPushInterval,
    //           title: 'Push interval',
    //           subtitle: 'How often to maybe push points',
    //           minValue: 100.0,
    //           defaultValue: 100.0,
    //           maxValue: 3600.0,
    //           step: 100.0,
    //         ),
    //         SliderSettingsTile(
    //           settingKey: kPushBatchSize,
    //           title: 'Push batch size',
    //           subtitle: 'How many points to push with each upload',
    //           minValue: 100.0,
    //           defaultValue: 100.0,
    //           maxValue: 3600.0,
    //           step: 100.0,
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}

// class MySettingsScreen extends StatefulWidget {
//   const MySettingsScreen({
//     Key key,
//   }) : super(key: key);

//   @override
//   _SettingsScreen createState() => _SettingsScreen();
// }

// class _SettingsScreen extends State<MySettingsScreen> {
//   double defaultPushInterval = 100;
//   double defaultBatchSize = 100;

//   Future<void> oninit() async {
//     defaultPushInterval = await Settings().getDouble(kPushInterval, 100);
//     defaultBatchSize = await Settings().getDouble(kPushBatchSize, 100);
//   }

//   @override
//   void initState() {
//     super.initState();
//     oninit();
//   }

//   @override
//   void dispose() {
//     // Dispose of the controller when the widget is disposed.
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SettingsScreen(
//       title: "Settings",
//       children: [
//         SwitchSettingsTile(
//           settingKey: kAllowPushWithMobile,
//           title: 'Push with mobile data',
//           icon: Icon(Icons.settings_cell_outlined),
//           defaultValue: false,
//         ),
//         SwitchSettingsTile(
//           settingKey: kAllowPushWithWifi,
//           title: 'Push with wifi data',
//           icon: Icon(Icons.wifi),
//           defaultValue: true,
//         ),
//         SliderSettingsTile(
//           settingKey: kPushInterval,
//           title: 'Push interval',
//           subtitle: 'How often to maybe push points',
//           icon: Icon(Icons.timelapse_rounded),
//           minValue: 100.0,
//           defaultValue: defaultPushInterval,
//           maxValue: 3600.0,
//           step: 100.0,
//         ),
//         SliderSettingsTile(
//           settingKey: kPushBatchSize,
//           title: 'Push batch size',
//           subtitle: 'How many points to push with each upload',
//           icon: Icon(Icons.file_upload),
//           minValue: 100.0,
//           defaultValue: defaultBatchSize,
//           maxValue: 3600.0,
//           step: 100.0,
//         ),
//       ],
//     );
//     // return Scaffold(
//     //   appBar: AppBar(title: Text('Settings')),
//     //   body: Container(
//     //     child: ListView(
//     //       children: [
//     //         SwitchSettingsTile(
//     //           settingKey: kAllowPushWithMobile,
//     //           title: 'Push with mobile data',
//     //           defaultValue: false,
//     //         ),
//     //         SwitchSettingsTile(
//     //           settingKey: kAllowPushWithWifi,
//     //           title: 'Push with wifi data',
//     //           defaultValue: true,
//     //         ),
//     //         SliderSettingsTile(
//     //           settingKey: kPushInterval,
//     //           title: 'Push interval',
//     //           subtitle: 'How often to maybe push points',
//     //           minValue: 100.0,
//     //           defaultValue: 100.0,
//     //           maxValue: 3600.0,
//     //           step: 100.0,
//     //         ),
//     //         SliderSettingsTile(
//     //           settingKey: kPushBatchSize,
//     //           title: 'Push batch size',
//     //           subtitle: 'How many points to push with each upload',
//     //           minValue: 100.0,
//     //           defaultValue: 100.0,
//     //           maxValue: 3600.0,
//     //           step: 100.0,
//     //         ),
//     //       ],
//     //     ),
//     //   ),
//     // );
//   }
// }
