// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:gcps/config.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

const String kAllowPushWithMobile = "allowPushWithMobile";
const String kAllowPushWithWifi = "allowPushWithWifi";
const String kPushInterval = "pushIntervalNumber";
const String kPushBatchSize = "pushBatchSize";
const String kLocationUpdateInterval = "locationUpdateInterval";
const String kLocationUpdateDistanceFilter = "locationUpdateDistanceFilter";
const String kLocationUpdateStopTimeout = "locationUpdateStopTimeout";
// const String kLocationUpdateStopTimeou = "locationUpdateStopTimeout";

// class SharedPreferencesHelper {
//   Future<bool> getAllowPushWithMobile() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(kAllowPushWithMobile) ?? false;
//   }

//   // Future<bool> setAllowPushWithMobile(bool value) async {
//   //   final SharedPreferences prefs = await SharedPreferences.getInstance();
//   //   return prefs.setBool(kAllowPushWithMobile, value);
//   // }

//   Future<bool> getAllowPushWithWifi() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(kAllowPushWithWifi) ?? false;
//   }

//   // Future<bool> setAllowPushWithWifi(String value) async {
//   //   final SharedPreferences prefs = await SharedPreferences.getInstance();
//   //   return prefs.setString(kAllowPushWithWifi, value);
//   // }

//   Future<double> getPushInterval() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getDouble(kPushInterval) ?? 100;
//   }

//   Future<bool> setPushInterval(double value) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.setDouble(kPushInterval, value);
//   }

//   Future<double> getPushBatchSize() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getDouble(_kPushBatchSize) ?? 100;
//   }

//   Future<bool> setPushBatchSize(double value) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.setDouble(_kPushBatchSize, value);
//   }
// }

// class MySettingsScreen extends StatefulWidget {
//   const MySettingsScreen({
//     Key key,
//   }) : super(key: key);

//   @override
//   _SettingsScreen createState() => _SettingsScreen();
// }

class MySettingsScreen extends StatelessWidget {
  final String deviceUUID;
  final String deviceName;
  final String deviceVersion;

  MySettingsScreen({
    Key key,
    this.deviceUUID,
    this.deviceName,
    this.deviceVersion,
  }) : super(key: key);

  final Settings _settings = Settings();

  double _locationUpdateDistanceFilter;
  double _locationUpdateInterval;

  handleLocationUpdateChanges(String changedKey, double newValue) {
    // double _locationUpdateDistanceFilter;
    // double _locationUpdateInterval;

    // _settings.getDouble(kLocationUpdateDistanceFilter, 1).then((value) {
    //   _locationUpdateDistanceFilter = value;
    // });
    // _settings.getDouble(kLocationUpdateInterval, 0).then((value) {
    //   _locationUpdateInterval = value;
    // });

    if (changedKey == kLocationUpdateDistanceFilter) {
      if (_locationUpdateDistanceFilter == newValue) return;
      // Distance filter changed, adjust the interval.
      _locationUpdateDistanceFilter = newValue;
      //
      if (newValue != 0 && _locationUpdateInterval != 0) {
        _locationUpdateInterval = 0.0;
        _settings.save(kLocationUpdateInterval, _locationUpdateInterval);
      } else if (newValue == 0 && _locationUpdateInterval == 0) {
        _locationUpdateInterval = 1.0;
        _settings.save(kLocationUpdateInterval, _locationUpdateInterval);
      }
      // _settings.save(kLocationUpdateInterval, _locationUpdateInterval);
      //
      // _settings.pingDouble(kLocationUpdateDistanceFilter, 1);
      // _settings.pingDouble(kLocationUpdateInterval, 0);
    } else {
      if (_locationUpdateInterval == newValue) return;
      // Interval changed, adjust the distance filter.
      _locationUpdateInterval = newValue;
      //
      if (newValue != 0 && _locationUpdateDistanceFilter != 0) {
        _locationUpdateDistanceFilter = 0.0;
        _settings.save(
            kLocationUpdateDistanceFilter, _locationUpdateDistanceFilter);
      } else if (newValue == 0 && _locationUpdateDistanceFilter == 0) {
        _locationUpdateDistanceFilter = 1.0;
        _settings.save(
            kLocationUpdateDistanceFilter, _locationUpdateDistanceFilter);
      }

      // _settings.pingDouble(kLocationUpdateDistanceFilter, 1);
      // _settings.pingDouble(kLocationUpdateInterval, 0);
      //
    }
  }

  @override
  Widget build(BuildContext context) {
    TextTheme settingsTheme =
        Theme.of(context).textTheme.apply(bodyColor: Colors.tealAccent);
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        // backgroundColor: Colors.amber,
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsContainer(
            child: Text('Location update configuration',
                style: Theme.of(context).textTheme.overline),
          ),
          Stack(
            children: [
              SliderSettingsTile(
                settingKey: kLocationUpdateDistanceFilter,
                title: 'Distance filter',
                subtitle:
                    'Δ meters triggering a location update.\nZero causes time updates.',
                icon: Icon(Icons.my_location_outlined),
                minValue: 0.0,
                defaultValue: 1.0,
                maxValue: 100.0,
                step: 1.0,
                maxIcon: Icon(Icons.arrow_upward),
                minIcon: Icon(Icons.arrow_downward),
              ),
              _settings.onDoubleChanged(
                  settingKey: kLocationUpdateDistanceFilter,
                  defaultValue: 1,
                  childBuilder:
                      (BuildContext context, double newDistanceFilterValue) {
                    handleLocationUpdateChanges(
                        kLocationUpdateDistanceFilter, newDistanceFilterValue);

                    // // Update BackgroundLocation config.
                    // bg.BackgroundGeolocation.setConfig(bg.Config(
                    //   distanceFilter: value,
                    //   locationUpdateInterval: _locationUpdateInterval == 0
                    //       ? null
                    //       : _locationUpdateInterval ~/ 1 * 1000,
                    // ));

                    return Container(
                        alignment: Alignment.topRight,
                        padding: EdgeInsets.only(right: 16),
                        child: Text(
                          newDistanceFilterValue.toStringAsFixed(0) + 'm',
                          style: settingsTheme.headline5,
                        ));
                  }),
            ],
          ),
          Stack(
            children: [
              SliderSettingsTile(
                settingKey: kLocationUpdateInterval,
                title: 'Time interval',
                subtitle:
                    'Δ seconds triggering a location update.\nZero causes distance updates.',
                icon: Icon(Icons.timer),
                minValue: 0.0,
                defaultValue: 1.0,
                maxValue: 180.0,
                step: 1.0,
                maxIcon: Icon(Icons.arrow_upward),
                minIcon: Icon(Icons.arrow_downward),
              ),
              _settings.onDoubleChanged(
                  settingKey: kLocationUpdateInterval,
                  defaultValue: 0,
                  childBuilder:
                      (BuildContext context, double newIntervalValue) {
                    handleLocationUpdateChanges(
                        kLocationUpdateInterval, newIntervalValue);

                    // // Update BackgroundLocation config.
                    // bg.BackgroundGeolocation.setConfig(bg.Config(
                    //   distanceFilter: _locationDistanceFilter,
                    //   locationUpdateInterval:
                    //       value == 0 ? null : value ~/ 1 * 1000,
                    // ));

                    return Container(
                        alignment: Alignment.topRight,
                        padding: EdgeInsets.only(right: 16),
                        child: Text(
                          newIntervalValue.toStringAsFixed(0) + 's',
                          style: settingsTheme.headline5,
                        ));
                  }),
            ],
          ),
          SettingsContainer(
            child: Text('Push (upload) configuration',
                style: Theme.of(context).textTheme.overline),
          ),
          SwitchSettingsTile(
            settingKey: kAllowPushWithWifi,
            title: 'Push with wifi data',
            icon: Icon(Icons.wifi),
            defaultValue: true,
          ),
          SwitchSettingsTile(
            settingKey: kAllowPushWithMobile,
            title: 'Push with mobile data',
            icon: Icon(Icons.network_cell),
            defaultValue: false,
          ),
          Stack(
            children: [
              SliderSettingsTile(
                settingKey: kPushInterval,
                title: 'Push interval',
                // title: 'How often to maybe push points',
                subtitle: 'How often to maybe push points.',
                icon: Icon(Icons.timelapse_rounded),
                minValue: 100.0,
                defaultValue: 100,
                maxValue: 3600.0,
                step: 100.0,
                maxIcon: Icon(Icons.arrow_upward),
                minIcon: Icon(Icons.arrow_downward),
              ),
              _settings.onDoubleChanged(
                  settingKey: kPushInterval,
                  defaultValue: 100,
                  childBuilder: (BuildContext context, double value) {
                    return Container(
                        alignment: Alignment.topRight,
                        padding: EdgeInsets.only(right: 16),
                        child: Text(
                          value.toStringAsFixed(0),
                          style: settingsTheme.headline5,
                        ));
                  }),
            ],
          ),
          Stack(
            children: [
              SliderSettingsTile(
                settingKey: kPushBatchSize,
                title: 'Push batch size',
                subtitle: 'Max points in each upload request.',
                icon: Icon(Icons.file_upload),
                minValue: 100.0,
                defaultValue: 100,
                maxValue: 3600.0,
                step: 100.0,
                maxIcon: Icon(Icons.arrow_upward),
                minIcon: Icon(Icons.arrow_downward),
              ),
              _settings.onDoubleChanged(
                  settingKey: kPushBatchSize,
                  defaultValue: 100,
                  childBuilder: (BuildContext context, double value) {
                    return Container(
                        alignment: Alignment.topRight,
                        padding: EdgeInsets.only(right: 16),
                        child: Text(
                          value.toStringAsFixed(0),
                          style: settingsTheme.headline5,
                        ));
                  }),
            ],
          ),
          SettingsContainer(
            children: [
              Text('App version', style: Theme.of(context).textTheme.overline),
              Text(deviceVersion),
              Text('UUID', style: Theme.of(context).textTheme.overline),
              Text(deviceUUID),
              Text('Name', style: Theme.of(context).textTheme.overline),
              Text(deviceName),
            ],
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
