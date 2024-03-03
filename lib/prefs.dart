// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:gcps/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:gcps/track.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'config.dart';

// Network settings
const String kAllowPushWithMobile = "allowPushWithMobile"; //
const String kAllowPushWithWifi = "allowPushWithWifi"; //
const String kPushInterval = "pushIntervalNumber"; // in TRACKS count
const String kPushIntervalSeconds = "pushIntervalSeconds"; //
const String kPushBatchSize = "pushBatchSize"; //
const String kPushUrl = "pushUrl"; //

// BackgroundLocation settings
const String kLocationUpdateInterval = "locationUpdateInterval"; //
const String kLocationUpdateDistanceFilter = "locationUpdateDistanceFilter"; //
const String kLocationUpdateStopTimeout = "locationUpdateStopTimeout"; //
const String kLocationGarneringDesiredAccuracy =
    'kLocationGarneringDesiredAccuracy'; //
const String kLocationGarneringElasticityMultiplier =
    'locationGarneringElasticityMultiplier';
const String kLocationDisableStopDetection = 'kLocationDisableStopDetection'; //
const String kLocationDeviceInMotion = 'kLocationDeviceInMotion';
const String kTurboMode = 'kTurboMode';
const String kTurboModeInterval = 'kTurboModeInterval';

// App settings
const String kHomeLocationLatitude = 'homeLocationLatitude';
const String kHomeLocationLongitude = 'homeLocationLongitude';

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
      case kPushIntervalSeconds:
        return _sharedPrefs.get(kPushIntervalSeconds) ?? 0;
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
      case kTurboModeInterval:
        return _sharedPrefs.get(kTurboModeInterval) ?? 1;
        break;
      case kHomeLocationLatitude:
        return _sharedPrefs.get(kHomeLocationLatitude) ?? 45.5710383;
        break;
      case kHomeLocationLongitude:
        return _sharedPrefs.get(kHomeLocationLongitude) ?? -111.6902772;
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
      case kPushIntervalSeconds:
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
      case kTurboModeInterval:
        break;
      case kHomeLocationLatitude:
        break;
      case kHomeLocationLongitude:
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
      case kTurboMode:
        return _sharedPrefs.get(kTurboMode) ?? false;
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
      case kTurboMode:
        break;
      default:
        print('!!!! I AM IMPOSSIBILITY');
        return;
    }
    _sharedPrefs.setBool(key, value);
  }

  String getString(String key) {
    switch (key) {
      case kPushUrl:
        return _sharedPrefs.get(kPushUrl) ?? postEndpoint;
      case kLocationGarneringDesiredAccuracy:
        return _sharedPrefs.get(kLocationGarneringDesiredAccuracy) ??
            'NAVIGATION';
    }
  }

  setString(String key, String value) {
    switch (key) {
      case kPushUrl:
        return _sharedPrefs.setString(kPushUrl, value);
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

double prefLocationDesiredAccuracyStringToSliderDouble(String value) {
  switch (value) {
    case 'NAVIGATION':
      return 5;
    case 'HIGH':
      return 4;
    case 'MEDIUM':
      return 3;
    case 'LOW':
      return 2;
    case 'VERY_LOW':
      return 1;
    case 'LOWEST':
      return 0;
  }
  return 5;
}

String prefLocationDesiredAccuracySliderDoubleToString(double value) {
  switch (value.toInt()) {
    case 5:
      return 'NAVIGATION';
    case 4:
      return 'HIGH';
    case 3:
      return 'MEDIUM';
    case 2:
      return 'LOW';
    case 1:
      return 'VERY_LOW';
    case 0:
      return 'LOWEST';
  }
  return 'NAVIGATION';
}

TextTheme settingsThemeText(context) {
  return Theme.of(context).textTheme.apply(bodyColor: Colors.tealAccent);
}

Widget _buildButtonTile({
  BuildContext context,
  Widget leading,
  Widget buttonChild,
  String title,
  String subtitle,
  void Function(bool) onPressed,
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
    trailing: ElevatedButton(
      onPressed: () {
        onPressed(true);
      },
      child: buttonChild ?? Text('Press me'),
    ),
  );
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
  String customTrailing,
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
    trailing: Text(customTrailing ?? '${value.toInt()}',
        style: settingsThemeText(context).headline5),
  );
}

/*
TextFormField(
  controller: _controller,
  keyboardType: TextInputType.number,
  inputFormatters: <TextInputFormatter>[
   // for below version 2 use this
 FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
// for version 2 and greater youcan also use this
 FilteringTextInputFormatter.digitsOnly

  ],
  decoration: InputDecoration(
    labelText: "whatever you want",
    hintText: "whatever you want",
    icon: Icon(Icons.phone_iphone)
  )
)
 */


Widget _buildNumberInputTile({
  BuildContext context,
  Widget leading,
  String title,
  String subtitle,
  String label,
  String hint,
  double min,
  double max,
  double value,
  void Function(double value) onChanged,
  String customTrailing,
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
      Text(min.toInt().toString() + "  "),
      Expanded(
        child: TextField(
            onSubmitted: (String value) {
              onChanged(double.parse(value));
            },
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              // for below version 2 use this
              // FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
// for version 2 and greater youcan also use this
              FilteringTextInputFormatter.digitsOnly

            ],
            decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                // icon: Icon(Icons.keyboard)
            )
        )

      ),
      Text(max.toInt().toString()),
    ]),
    trailing: Text(customTrailing ?? '${value.toInt()}',
        style: settingsThemeText(context).headline5),
  );
}

Widget _buildStringInputTile({
  BuildContext context,
  Widget leading,
  String title,
  String subtitle,
  String label,
  String hint,
  String value,
  void Function(String value) onChanged,
  String customTrailing,
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
      Expanded(
          child: TextField(
              onSubmitted: (String value) {
                onChanged(value);
              },
              keyboardType: TextInputType.url,
              inputFormatters: <TextInputFormatter>[],
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                // icon: Icon(Icons.keyboard)
              )
          )

      ),
    ]),
    // trailing: Text(customTrailing ?? 'value',
    //     style: settingsThemeText(context).headline5),
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
  bool _kTurboMode = sharedPrefs.getBool(kTurboMode);
  double _kTurboModeInterval = sharedPrefs.getDouble(kTurboModeInterval);
  double _kPushInterval = sharedPrefs.getDouble(kPushInterval);
  double _kPushIntervalSeconds = sharedPrefs.getDouble(kPushIntervalSeconds);
  double _kPushBatchSize = sharedPrefs.getDouble(kPushBatchSize);
  double _kLocationUpdateInterval =
      sharedPrefs.getDouble(kLocationUpdateInterval);
  double _kLocationUpdateDistanceFilter =
      sharedPrefs.getDouble(kLocationUpdateDistanceFilter);
  double _kLocationUpdateStopTimeout =
      sharedPrefs.getDouble(kLocationUpdateStopTimeout);
  // double _kLocationGarneringElasticityMultiplier =
  //     sharedPrefs.getDouble(kLocationGarneringElasticityMultiplier);

  double _kHomeLocationLatitude = sharedPrefs.getDouble(kHomeLocationLatitude);
  double _kHomeLocationLongitude = sharedPrefs.getDouble(kHomeLocationLongitude);
  String _kLocationGarneringDesiredAccuracy =
      sharedPrefs.getString(kLocationGarneringDesiredAccuracy);
  String _kPushUrl = sharedPrefs.getString(kPushUrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        // backgroundColor: Colors.amber,
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        children: [

          // Network/upload settings
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
                });
                sharedPrefs.setBool(kAllowPushWithWifi, value);
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
                });
                sharedPrefs.setBool(kAllowPushWithMobile, value);
              }),

          _buildSwitchTile(
              context: context,
              leading: Icon(Icons.fast_forward),
              title: 'Turbo mode',
              subtitle: 'Collect points every N seconds.',
              value: _kTurboMode,
              onChanged: (bool value) {
                setState(() {
                  _kTurboMode = value;
                });
                sharedPrefs.setBool(kTurboMode, value);
              }),

          if (_kTurboMode)
            _buildNumberInputTile(
                context: context,
                leading: Icon(Icons.timer),
                title: 'Turbo mode: track interval',
                subtitle: 'Minimum seconds between turbo mode points.',
                label: 'Seconds',
                hint: '',
                min: 1,
                max: 3600,
                value: _kTurboModeInterval,
                onChanged: (value) {
                  setState(() {
                    _kTurboModeInterval = value.floorToDouble();
                  });
                  sharedPrefs.setDouble(kTurboModeInterval, value);
                }),

          _buildNumberInputTile(
              context: context,
              leading: Icon(Icons.timelapse_rounded),
              title: 'Push interval - tracks',
              subtitle: 'Trigger push when track count mod N == 0.',
              min: 0,
              max: 86400,
              hint: _kPushInterval.floor().toString(),
              value: _kPushInterval,
              onChanged: (value) {
                setState(() {
                  _kPushInterval = value.floorToDouble();
                });
                sharedPrefs.setDouble(kPushInterval, value);
              }),

          _buildNumberInputTile(
              context: context,
              leading: Icon(Icons.timelapse_rounded),
              title: 'Push interval - seconds',
              subtitle: 'Trigger push when interval since last push > N && N != 0.',
              label: 'Seconds',
              min: 0,
              max: 86400,
              hint: _kPushIntervalSeconds.floor().toString(),
              value: _kPushIntervalSeconds,
              onChanged: (value) {
                setState(() {
                  _kPushIntervalSeconds = value.floorToDouble();
                });
                sharedPrefs.setDouble(kPushIntervalSeconds, value);
              }),

          _buildNumberInputTile(
              context: context,
              leading: Icon(Icons.file_upload),
              title: 'Push batch size',
              subtitle: 'Max points in each upload request.',
              min: 1,
              max: 3600,
              hint: _kPushBatchSize.floor().toString(),
              value: _kPushBatchSize,
              onChanged: (value) {
                value = value.floorToDouble();
                setState(() {
                  _kPushBatchSize = value;
                });
                sharedPrefs.setDouble(kPushBatchSize, value);
              }),

          _buildStringInputTile(
              context: context,
              leading: Icon(Icons.cloud_upload_outlined),
              title: 'Push URL',
              subtitle: 'Where to push the cat tracks.',
              hint: _kPushUrl,
              value: _kPushUrl,
              onChanged: (value) {
                setState(() {
                  _kPushUrl = value;
                });
                sharedPrefs.setString(kPushUrl, value);
              }),

          // Location settings
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

          _buildNumberInputTile(
              context: context,
              leading: Icon(Icons.my_location_outlined),
              title: 'Distance filter',
              subtitle:
                  'Δ meters triggering a location update.\nZero causes time updates.',
              min: 0,
              max: 10000,
              hint: _kLocationUpdateDistanceFilter.floor().toString(),
              value: _kLocationUpdateDistanceFilter,
              onChanged: (value) {
                value = value.floorToDouble();
                setState(() {
                  _kLocationUpdateDistanceFilter = value;
                });
                if (value == 0) {
                  setState(() {
                    _kLocationUpdateInterval = 1;
                  });
                } else if (_kLocationUpdateInterval != 0) {
                  setState(() {
                    _kLocationUpdateInterval = 0;
                  });
                }
                sharedPrefs.setDouble(kLocationUpdateDistanceFilter,
                    _kLocationUpdateDistanceFilter);
                sharedPrefs.setDouble(
                    kLocationUpdateInterval, _kLocationUpdateInterval);
                bg.BackgroundGeolocation.state.then((st) {
                  st.set('distanceFilter', _kLocationUpdateDistanceFilter);
                  st.set('locationUpdateInterval',
                      (_kLocationUpdateInterval * 1000).toInt());
                  bg.BackgroundGeolocation.setConfig(st);
                });
              }),

          _buildNumberInputTile(
              context: context,
              leading: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.timer),
                    Icon(Icons.android),
                  ]),
              title: 'Time interval',
              subtitle:
                  'Δ seconds triggering a location update.\nZero causes distance updates.\nActual results may be imprecise.',
              min: 0,
              max: 3600,
              hint: _kLocationUpdateInterval.floor().toString(),
              value: _kLocationUpdateInterval,
              onChanged: (value) {
                value = value.floorToDouble();
                setState(() {
                  _kLocationUpdateInterval = value;
                });
                if (value == 0) {
                  setState(() {
                    _kLocationUpdateDistanceFilter = 1;
                  });
                } else if (_kLocationUpdateDistanceFilter != 0) {
                  setState(() {
                    _kLocationUpdateDistanceFilter = 0;
                  });
                }
                sharedPrefs.setDouble(kLocationUpdateDistanceFilter,
                    _kLocationUpdateDistanceFilter);
                sharedPrefs.setDouble(
                    kLocationUpdateInterval, _kLocationUpdateInterval);
                bg.BackgroundGeolocation.state.then((st) {
                  st.set('distanceFilter', _kLocationUpdateDistanceFilter);
                  st.set('locationUpdateInterval',
                      (_kLocationUpdateInterval * 1000).toInt());
                  st.set('locationTimeout', 60);
                  bg.BackgroundGeolocation.setConfig(st);
                });
              }),

          _buildSwitchTile(
              context: context,
              leading: Icon(Icons.trip_origin),
              title: 'Disable stop detection',
              subtitle: _kLocationDisableStopDetection
                  ? 'Location tracking will not disengage when cat is stationary; location services will NEVER turn off if cat is moving.'
                  : 'Location tracking will automatically disengage when device is stationary for ${_kLocationUpdateStopTimeout.toInt()} minutes.',
              value: _kLocationDisableStopDetection,
              onChanged: (bool value) {
                setState(() {
                  _kLocationDisableStopDetection = value;
                });
                sharedPrefs.setBool(kLocationDisableStopDetection, value);
                bg.BackgroundGeolocation.state.then((st) {
                  st.set('disableStopDetection', value);
                  st.set(
                    'pausesLocationUpdatesAutomatically',
                    !value,
                  );
                  bg.BackgroundGeolocation.setConfig(st);

                  if (!st.isMoving && !value) {
                    setState(() {
                      _kLocationDeviceInMotion = true;
                    });
                    bg.BackgroundGeolocation.changePace(
                        _kLocationDeviceInMotion);
                  }
                });
              }),

          if (_kLocationDisableStopDetection)
            _buildSwitchTile(
                context: context,
                leading: Icon(Icons.circle),
                title: 'Cat is moving',
                subtitle: _kLocationDeviceInMotion
                    ? 'Location is tracking.'
                    : 'Cat is napping. Location not tracking.',
                value: _kLocationDeviceInMotion,
                onChanged: (bool value) {
                  setState(() {
                    _kLocationDeviceInMotion = value;
                  });
                  sharedPrefs.setBool(kLocationDeviceInMotion, value);
                  bg.BackgroundGeolocation.changePace(value);
                }),

          if (!_kLocationDisableStopDetection)
            _buildNumberInputTile(
                context: context,
                leading: Icon(Icons.airline_seat_legroom_extra_outlined),
                title: 'Stop timeout',
                subtitle: 'Minutes of stillness before cat naps.',
                min: 1,
                max: 30,
                hint: _kLocationUpdateStopTimeout.floor().toString(),
                value: _kLocationUpdateStopTimeout,
                onChanged: (value) {
                  value = value.ceilToDouble();
                  setState(() {
                    _kLocationUpdateStopTimeout = value;
                  });
                  sharedPrefs.setDouble(kLocationUpdateStopTimeout, value);
                  bg.BackgroundGeolocation.state.then((st) {
                    st.set('stopTimeout', value.toInt());
                    bg.BackgroundGeolocation.setConfig(st);
                  });
                }),

          _buildSliderTile(
              context: context,
              leading: Icon(Icons.airline_seat_legroom_extra_outlined),
              title: 'Desired location accuracy',
              subtitle: 'How hard you want the GPS to work for precision.',
              min: 0,
              max: 5,
              divisions: 6,
              value: prefLocationDesiredAccuracyStringToSliderDouble(
                  _kLocationGarneringDesiredAccuracy),
              customTrailing: _kLocationGarneringDesiredAccuracy,
              onChanged: (value) {
                value = value.floorToDouble(); // normalize
                setState(() {
                  _kLocationGarneringDesiredAccuracy =
                      prefLocationDesiredAccuracySliderDoubleToString(value);
                });
                sharedPrefs.setString(
                  kLocationGarneringDesiredAccuracy,
                  _kLocationGarneringDesiredAccuracy, // storing stored double (NOT location provider enumerable/constant)
                );
                bg.BackgroundGeolocation.state.then((st) {
                  st.set(
                      'desiredAccuracy',
                      prefLocationDesiredAccuracy(
                          _kLocationGarneringDesiredAccuracy));
                  bg.BackgroundGeolocation.setConfig(st);
                });
              }),

          _buildButtonTile(
              context: context,
              leading: Icon(Icons.home),
              buttonChild: Text('Here'),
              title: 'Home location',
              subtitle: 'Tracks will auto-upload when near home.\n[ ${_kHomeLocationLongitude} , ${_kHomeLocationLatitude} ]',
              onPressed: (bool value) {
                bg.BackgroundGeolocation.getCurrentPosition(samples: 3, desiredAccuracy: 10)
                    .then((value) => {
                  sharedPrefs.setDouble(kHomeLocationLatitude, value.coords.latitude.toPrecision(6)),
                  sharedPrefs.setDouble(kHomeLocationLongitude, value.coords.longitude.toPrecision(6)),
                  setState(() {
                    _kHomeLocationLatitude = value.coords.latitude;
                    _kHomeLocationLongitude = value.coords.longitude;
                  }),

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
