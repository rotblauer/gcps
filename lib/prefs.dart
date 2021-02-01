// import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:flutter/material.dart';

const String kAllowPushWithMobile = "allowPushWithMobile";
const String kAllowPushWithWifi = "allowPushWithWifi";
const String kPushInterval = "pushIntervalNumber";
const String kPushBatchSize = "pushBatchSize";

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

class MySettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: "Settings",
      children: [
        SwitchSettingsTile(
          settingKey: kAllowPushWithWifi,
          title: 'Push with wifi data',
          icon: Icon(Icons.wifi),
          defaultValue: true,
        ),
        SwitchSettingsTile(
          settingKey: kAllowPushWithMobile,
          title: 'Push with mobile data',
          icon: Icon(Icons.settings_cell_outlined),
          defaultValue: false,
        ),
        Settings().onDoubleChanged(
            settingKey: kPushInterval,
            defaultValue: 100,
            childBuilder: (BuildContext context, double value) {
              return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SettingsContainer(
                      children: [
                        // Text('Push interval',
                        //     style: Theme.of(context).textTheme.bodyText2),
                        Text(
                          value.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ],
                    )
                  ]);
            }),
        SliderSettingsTile(
          settingKey: kPushInterval,
          title: 'Push interval',
          // title: 'How often to maybe push points',
          subtitle: 'How often to maybe push points',
          icon: Icon(Icons.timelapse_rounded),
          minValue: 100.0,
          defaultValue: 100,
          maxValue: 3600.0,
          step: 100.0,
          maxIcon: Icon(Icons.arrow_upward),
          minIcon: Icon(Icons.arrow_downward),
        ),
        Settings().onDoubleChanged(
            settingKey: kPushBatchSize,
            defaultValue: 100,
            childBuilder: (BuildContext context, double value) {
              return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SettingsContainer(
                      children: [
                        // Text('Batch size',
                        //     style: Theme.of(context).textTheme.bodyText2),
                        Text(
                          value.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ],
                    )
                  ]);
            }),
        SliderSettingsTile(
          settingKey: kPushBatchSize,
          title: 'Push batch size',
          subtitle: 'Max number of points to push with each upload',
          icon: Icon(Icons.file_upload),
          minValue: 100.0,
          defaultValue: 100,
          maxValue: 3600.0,
          step: 100.0,
          maxIcon: Icon(Icons.arrow_upward),
          minIcon: Icon(Icons.arrow_downward),
        ),
      ],
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
